# Paso 16 - Meses y años que pasan el 10 % (criterio del inge, 18/11/2026)
# Compara Develi (MGM 17836) contra otras estaciones en temperatura, humedad
# relativa y precipitación, mes por mes y año por año, 1975-2007.
#   Criterio: |Develi - Estación| * 100 / Develi  <= 10 %
#   - Mensual: cada uno de los 396 meses.
#   - Anual: temperatura y humedad = promedio de los 12 meses; precipitación =
#     suma de los 12 meses. Solo años con los 12 meses en ambas estaciones.
#   - Temperatura: además de °C se reporta en Kelvin, porque el porcentaje en °C
#     se dispara cuando Develi está cerca de 0 °C (el 0 °C no es un cero real).
# Entradas:
#   privado/develi_referencia_mensual.csv  (paso 9: temp y precip de la Prof.
#     Altın, HR de la Prof. Dadaşer-Çelik, unidas por año y mes)
#   privado/temp_menFiliz_1975-2007.csv    (opcional: temperatura de Filiz)
#   procesados/kayseri-erkilet-temperature-mensual.csv
#   procesados/kayseri-erkilet-relative-humidity-mensual.csv
#   procesados/kayseri_precip_ghcnm_v4_1975-2007.csv
#   procesados/candidatas_mgm_mensual.csv  (aeropuertos de Ankara, Afyon, Konya,
#     y Çorum: T y HR por el método del MGM)
#   procesados/candidatas/temp_candidatas_mensual_1975-2007.csv   (GHCN-M v4 qcf:
#     Niğde, Kırşehir, Konya, Afyon; sin estimados)
#   procesados/candidatas/precip_candidatas_mensual_1975-2007.csv (GHCN-M v4)
#   procesados/candidatas_lat_alt_mgm_mensual.csv (HR de Niğde, desde 1988)
#   procesados/precip_gpcc025_develi_kayseri_1975-2007.csv (GPCC, celda Erkilet)
# Salidas:
#   procesados/resumen_meses_anios_10pct.csv  (solo conteos)
#   privado/comparacion_10pct/<variable>_<estacion>.csv  (una tabla por variable y
#     estación: Anio, Mes, Develi, Estación, Diferencia_pct; incluye datos de Develi)
# ============================================================

dir_priv <- "data/equivalencia/privado"
dir_proc <- "data/equivalencia/procesados"
anios    <- 1975:2007
umbral   <- 10

# Temperatura de Develi: "altin" (versión actual del MGM) o "filiz" (la del paper)
fuente_temp_develi <- "altin"

# ---- 1. Develi ----
develi <- read.csv(file.path(dir_priv, "develi_referencia_mensual.csv"))
names(develi) <- c("anio", "mes", "temp", "precip", "hr")
if (fuente_temp_develi == "filiz") {
  filiz <- read.csv(file.path(dir_priv, "temp_menFiliz_1975-2007.csv"))
  names(filiz) <- c("anio", "mes", "temp_filiz")
  develi <- merge(develi, filiz, by = c("anio", "mes"), all.x = TRUE)
  develi$temp <- develi$temp_filiz
  develi$temp_filiz <- NULL
}
develi <- develi[develi$anio %in% anios, ]

# ---- 2. Estaciones a comparar (una fila por estación y mes) ----
leer <- function(archivo, nombre_valor) {
  d <- read.csv(file.path(dir_proc, archivo))
  names(d) <- c("anio", "mes", nombre_valor)
  d
}
erkilet <- merge(merge(leer("kayseri-erkilet-temperature-mensual.csv", "temp"),
                       leer("kayseri-erkilet-relative-humidity-mensual.csv", "hr"),
                       by = c("anio", "mes"), all = TRUE),
                 leer("kayseri_precip_ghcnm_v4_1975-2007.csv", "precip"),
                 by = c("anio", "mes"), all = TRUE)
erkilet$estacion <- "KAYSERI ERKILET"

cols <- c("anio", "mes", "temp", "hr", "precip", "estacion")

# Aeropuertos con T y HR por el método del MGM (GHCNh, paso 11)
cand <- read.csv(file.path(dir_proc, "candidatas_mgm_mensual.csv"))
cand <- data.frame(anio = cand$anio, mes = cand$mes, temp = cand$temp,
                   hr = cand$hr, precip = NA, estacion = cand$nombre)

# Estaciones MGM de GHCN-M v4: T sin ajustes ni estimados (qcf) y precipitación
t_v4 <- read.csv(file.path(dir_proc, "candidatas", "temp_candidatas_mensual_1975-2007.csv"))
t_v4 <- data.frame(anio = t_v4$anio, mes = t_v4$mes, temp = t_v4$temp_qcf,
                   nombre = t_v4$nombre)
p_v4 <- read.csv(file.path(dir_proc, "candidatas", "precip_candidatas_mensual_1975-2007.csv"))
p_v4 <- p_v4[p_v4$nombre != "DEVELI", ]          # Develi ya va como referencia
p_v4 <- data.frame(anio = p_v4$anio, mes = p_v4$mes, precip = p_v4$precip,
                   nombre = p_v4$nombre)
v4 <- merge(t_v4, p_v4, by = c("anio", "mes", "nombre"), all = TRUE)

# Humedad de Niğde por el método del MGM (GHCNh, paso 14; solo desde 1988)
la <- read.csv(file.path(dir_proc, "candidatas_lat_alt_mgm_mensual.csv"))
hr_nigde <- la[la$nombre == "NIGDE", c("anio", "mes", "hr")]
hr_nigde$nombre <- "NIGDE"
v4 <- merge(v4, hr_nigde, by = c("anio", "mes", "nombre"), all.x = TRUE)
v4 <- data.frame(anio = v4$anio, mes = v4$mes, temp = v4$temp, hr = v4$hr,
                 precip = v4$precip, estacion = paste(v4$nombre, "(GHCN-M v4)"))

# Precipitación GPCC 0.25° en la celda de Erkilet: malla interpolada de
# pluviómetros, NO es medición directa de la estación (solo como referencia)
gpcc <- read.csv(file.path(dir_proc, "precip_gpcc025_develi_kayseri_1975-2007.csv"))
gpcc <- gpcc[gpcc$estacion == "KAYSERI", ]
gpcc <- data.frame(anio = gpcc$anio, mes = gpcc$mes, temp = NA, hr = NA,
                   precip = gpcc$precip_mm,
                   estacion = "KAYSERI ERKILET (GPCC, interpolado)")

estaciones <- rbind(erkilet[, cols], cand[, cols], v4[, cols], gpcc[, cols])
estaciones <- estaciones[estaciones$anio %in% anios, ]

# ---- 3. Diferencia porcentual (fórmula del inge) ----
pct <- function(d, e) abs(d - e) * 100 / abs(d)

variables <- list(
  temp     = list(col = "temp",   anual = mean, kelvin = FALSE),
  temp_K   = list(col = "temp",   anual = mean, kelvin = TRUE),
  hr       = list(col = "hr",     anual = mean, kelvin = FALSE),
  precip   = list(col = "precip", anual = sum,  kelvin = FALSE)
)
etiqueta <- c(temp = "Temperatura (C)", temp_K = "Temperatura (K)",
              hr = "Humedad relativa (%)", precip = "Precipitacion (mm)")
archivo_var <- c(temp = "temperatura_C", temp_K = "temperatura_K",
                 hr = "humedad_relativa", precip = "precipitacion")

dir_tablas <- file.path(dir_priv, "comparacion_10pct")
dir.create(dir_tablas, showWarnings = FALSE)
# Nombre de archivo sin espacios, acentos ni paréntesis
limpiar <- function(x) gsub("^_|_$", "", gsub("[^A-Za-z0-9]+", "_", x))

resumen <- list()

for (est in unique(estaciones$estacion)) {
  e <- estaciones[estaciones$estacion == est, ]
  j <- merge(develi, e, by = c("anio", "mes"), suffixes = c("_dev", "_est"))

  for (v in names(variables)) {
    cfg <- variables[[v]]
    d  <- j[[paste0(cfg$col, "_dev")]]
    x  <- j[[paste0(cfg$col, "_est")]]
    hay <- !is.na(d) & !is.na(x)        # meses con dato en ambas
    if (sum(hay) == 0) next
    if (cfg$kelvin) { d <- d + 273.15; x <- x + 273.15 }
    ok  <- hay & d != 0                  # en el mes no se puede dividir entre 0

    # Mensual
    p_mes <- pct(d[ok], x[ok])

    # Anual: solo años con los 12 meses en ambas estaciones (aquí sí cuentan
    # los meses con 0 mm, porque se suman)
    m <- data.frame(anio = j$anio[hay], d = d[hay], x = x[hay])
    completos <- names(which(table(m$anio) == 12))
    m <- m[m$anio %in% completos, ]
    p_anio <- if (nrow(m) > 0) {
      pct(tapply(m$d, m$anio, cfg$anual), tapply(m$x, m$anio, cfg$anual))
    } else numeric(0)

    resumen[[length(resumen) + 1]] <- data.frame(
      estacion        = est,
      variable        = etiqueta[[v]],
      meses           = length(p_mes),
      meses_sobre_10  = sum(p_mes > umbral),
      pct_meses_sobre = round(100 * mean(p_mes > umbral), 1),
      anios           = length(p_anio),
      anios_sobre_10  = sum(p_anio > umbral),
      pct_anios_sobre = if (length(p_anio)) round(100 * mean(p_anio > umbral), 1) else NA,
      dif_abs_media   = round(mean(abs(d[hay] - x[hay])), 2)
    )
    # Tabla mes a mes: Anio, Mes, Develi, Estación, Diferencia (%)
    # (si Develi vale 0 la diferencia queda vacía: no se puede dividir entre 0)
    tabla <- data.frame(Anio = j$anio[hay], Mes = j$mes[hay],
                        Develi = round(d[hay], 2), Estacion = round(x[hay], 2),
                        Diferencia_pct = round(ifelse(d[hay] != 0, pct(d[hay], x[hay]), NA), 2))
    tabla <- tabla[order(tabla$Anio, tabla$Mes), ]
    names(tabla)[4] <- limpiar(est)
    write.csv(tabla, file.path(dir_tablas, paste0(archivo_var[[v]], "_", limpiar(est), ".csv")),
              row.names = FALSE, na = "")
  }
}

resumen <- do.call(rbind, resumen)

write.csv(resumen, file.path(dir_proc, "resumen_meses_anios_10pct.csv"), row.names = FALSE)
cat("Tablas mes a mes en:", dir_tablas, "(", length(list.files(dir_tablas)), "archivos )\n")

cat("Temperatura de Develi:", fuente_temp_develi, "\n\n")
print(resumen, row.names = FALSE)
