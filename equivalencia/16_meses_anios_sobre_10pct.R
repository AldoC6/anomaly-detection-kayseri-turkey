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
#   fuentes/ghcnm_v4/*qcf.dat y fuentes/ghcnm_v4/prcp/csv/<ID>.csv (Tomarza,
#     Pınarbaşı y Sarız, estaciones MGM de la provincia de Kayseri; hasta 1990)
# Outliers (se marcan, NO se rellenan ni se inventan datos):
#   A = el porcentaje no tiene sentido porque Develi está casi en 0: precipitación
#       de Develi < 1 mm, o temperatura de Develi entre -1 y 1 °C. Se excluyen del
#       conteo de meses sobre el 10 % (se reportan aparte).
#   B = diferencia anómala en unidades reales (°C, puntos de HR, mm): fuera de
#       Q1 - 1.5·IQR o Q3 + 1.5·IQR (criterio de Tukey), por estación y variable.
#       NO se excluyen: son meses a investigar contra estaciones vecinas.
# Salidas:
#   procesados/resumen_meses_anios_10pct.csv  (solo conteos)
#   privado/comparacion_10pct/<variable>_<estacion>.csv  (una tabla por variable y
#     estación: Anio, Mes, Develi, Estación, Diferencia, Diferencia_pct, Outlier;
#     incluye datos de Develi)
# ============================================================

dir_priv <- "data/equivalencia/privado"
dir_proc <- "data/equivalencia/procesados"
anios    <- 1975:2007
umbral   <- 10
lim_precip_A <- 1      # mm: Develi por debajo -> outlier A
lim_temp_A   <- 1      # °C: |Develi| por debajo -> outlier A

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

# Estaciones MGM de la provincia de Kayseri en GHCN-M v4 (solo llegan a 1990):
# temperatura sin ajustes ni estimados (qcf) y precipitación
prov <- data.frame(
  nombre    = c("TOMARZA", "PINARBASI", "SARIZ"),
  id_temp   = c("TUXLT520551", "TUXLT319538", "TUXLT231672"),
  id_precip = c("TUXLP331320", "TUXLP331298", "TUXLP331342")
)
dir_v4  <- "data/equivalencia/fuentes/ghcnm_v4"
dat_qcf <- sort(list.files(dir_v4, pattern = "qcf\\.dat$", recursive = TRUE,
                           full.names = TRUE), decreasing = TRUE)[1]
lineas  <- readLines(dat_qcf)
lineas  <- lineas[substr(lineas, 1, 11) %in% prov$id_temp]
t_prov  <- do.call(rbind, lapply(1:12, function(m) {
  p <- 20 + (m - 1) * 8                    # formato de ancho fijo de GHCN-M v4
  v <- as.numeric(substr(lineas, p, p + 4))
  q <- substr(lineas, p + 6, p + 6)        # bandera de calidad
  data.frame(id_temp = substr(lineas, 1, 11), anio = as.integer(substr(lineas, 12, 15)),
             mes = m, temp = ifelse(v == -9999 | q != " ", NA, v / 100))
}))
p_prov <- do.call(rbind, lapply(prov$id_precip, function(id) {
  x <- read.csv(file.path(dir_v4, "prcp", "csv", paste0(id, ".csv")), header = FALSE,
                strip.white = TRUE, colClasses = "character")
  v <- as.integer(x$V7)                    # décimas de mm; -1 = traza; -9999 = falta
  data.frame(id_precip = id, anio = as.integer(x$V6) %/% 100, mes = as.integer(x$V6) %% 100,
             precip = ifelse(v == -9999 | x$V9 != "", NA, pmax(v, 0) / 10))
}))
t_prov <- merge(t_prov, prov[, c("nombre", "id_temp")], by = "id_temp")
p_prov <- merge(p_prov, prov[, c("nombre", "id_precip")], by = "id_precip")
prov_m <- merge(t_prov[, c("anio", "mes", "nombre", "temp")],
                p_prov[, c("anio", "mes", "nombre", "precip")],
                by = c("anio", "mes", "nombre"), all = TRUE)
prov_m <- data.frame(anio = prov_m$anio, mes = prov_m$mes, temp = prov_m$temp, hr = NA,
                     precip = prov_m$precip, estacion = paste(prov_m$nombre, "(GHCN-M v4)"))

estaciones <- rbind(erkilet[, cols], prov_m[, cols], cand[, cols], v4[, cols], gpcc[, cols])
estaciones <- estaciones[estaciones$anio %in% anios, ]

# ---- 3. Diferencia porcentual (fórmula del inge) ----
pct <- function(d, e) abs(d - e) * 100 / abs(d)

variables <- list(
  temp     = list(col = "temp",   anual = mean, kelvin = FALSE, lim_A = lim_temp_A),
  temp_K   = list(col = "temp",   anual = mean, kelvin = TRUE,  lim_A = NA),
  hr       = list(col = "hr",     anual = mean, kelvin = FALSE, lim_A = NA),
  precip   = list(col = "precip", anual = sum,  kelvin = FALSE, lim_A = lim_precip_A)
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
    # Outlier A (con el valor original de Develi, antes de pasar a Kelvin)
    out_A <- if (is.na(cfg$lim_A)) rep(FALSE, length(d)) else hay & abs(d) < cfg$lim_A
    if (cfg$kelvin) { d <- d + 273.15; x <- x + 273.15 }
    ok  <- hay & d != 0                  # en el mes no se puede dividir entre 0

    # Outlier B: diferencia en unidades fuera de Q1 - 1.5 IQR / Q3 + 1.5 IQR
    dif <- d - x
    q   <- quantile(dif[hay], c(0.25, 0.75))
    out_B <- hay & (dif < q[1] - 1.5 * diff(q) | dif > q[2] + 1.5 * diff(q))

    # Mensual (todos los meses y sin outliers A)
    p_mes   <- pct(d[ok], x[ok])
    ok_sinA <- ok & !out_A
    p_sinA  <- pct(d[ok_sinA], x[ok_sinA])

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
      outliers_A      = sum(out_A),
      meses_sin_A     = length(p_sinA),
      sobre_10_sin_A  = sum(p_sinA > umbral),
      pct_sobre_sin_A = round(100 * mean(p_sinA > umbral), 1),
      outliers_B      = sum(out_B),
      anios           = length(p_anio),
      anios_sobre_10  = sum(p_anio > umbral),
      pct_anios_sobre = if (length(p_anio)) round(100 * mean(p_anio > umbral), 1) else NA,
      dif_abs_media   = round(mean(abs(d[hay] - x[hay])), 2)
    )
    # Tabla mes a mes: Anio, Mes, Develi, Estación, Diferencia (en unidades),
    # Diferencia (%) y Outlier (A, B o vacío; si es A y B se marca A)
    # (si Develi vale 0 la diferencia queda vacía: no se puede dividir entre 0)
    tabla <- data.frame(Anio = j$anio[hay], Mes = j$mes[hay],
                        Develi = round(d[hay], 2), Estacion = round(x[hay], 2),
                        Diferencia = round(dif[hay], 2),
                        Diferencia_pct = round(ifelse(d[hay] != 0, pct(d[hay], x[hay]), NA), 2),
                        Outlier = ifelse(out_A[hay], "A", ifelse(out_B[hay], "B", "")))
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
