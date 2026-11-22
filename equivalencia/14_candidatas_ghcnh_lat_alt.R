# Candidatas por latitud y altitud - temperatura y humedad con el metodo de MGM (GHCNh)
# Toma las estaciones del paso 13 (latitud y altitud parecidas a Develi, en todo el
# mundo) y, sin usar GHCN-M, calcula temperatura y humedad con los datos horarios de
# GHCNh igual que MGM en Develi (equivalencia/funciones_mgm.R):
#   T = (T07 + T14 + 2 x T21) / 4,  HR = (HR07 + HR14 + HR21) / 3,
# en hora solar local segun la longitud de cada estacion.
#   - Antes de bajar los 35 anios, prueba 1990 y 2005: si ninguno existe en GHCNh,
#     o si ninguno trae al menos lect_min lecturas de temperatura por dia en
#     promedio, la estacion se salta (sin ~4 lecturas al dia no se puede aplicar
#     la formula 07-14-21).
#   - Un mes cuenta si tiene al menos 15 dias con las 3 lecturas; un anio, si tiene
#     sus 12 meses.
#   - Criterio del docente: |Develi - estacion| * 100 / Develi <= 10 % en cada anio.
# Fuente: Menne, M. J., et al. (2023). GHCNh, Version 1. NOAA NCEI.
#         https://doi.org/10.25921/jp3d-3v19
# Entradas: privado/candidatas_latitud_altitud.csv (paso 13)
#           privado/develi_referencia_anual.csv (paso 9)
#           descarga de GHCNh por estacion y anio (fuentes/ghcnh_raw/, fuera de git)
# Salidas:  procesados/candidatas_lat_alt_mgm_mensual.csv (datos publicos de las estaciones)
#           privado/candidatas_lat_alt_resumen.csv (comparacion contra Develi)
# ============================================================

source("equivalencia/funciones_mgm.R")

anios    <- 1975:2009
url_base <- "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/%d/psv/GHCNh_%s_%d.psv"
carpeta  <- "data/equivalencia/fuentes/ghcnh_raw"
umbral   <- 10
dias_min <- 15
lect_min <- 4            # lecturas de temperatura por dia, en promedio, en 1990 o 2005

candidatas <- read.csv("data/equivalencia/privado/candidatas_latitud_altitud.csv")
develi     <- read.csv("data/equivalencia/privado/develi_referencia_anual.csv")
dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
options(timeout = 600)

bajar <- function(id, a) {
  destino <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, id, a)
  if (file.exists(destino)) return(TRUE)
  ok <- tryCatch({
    download.file(sprintf(url_base, a, id, a), destino, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok && file.exists(destino)) file.remove(destino)
  ok
}

# Lecturas de temperatura por dia en un archivo de prueba
lecturas_dia <- function(id, a) {
  f <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, id, a)
  if (!file.exists(f)) return(0)
  x <- suppressWarnings(as.numeric(read.delim(f, sep = "|")$temperature))
  sum(!is.na(x)) / 365
}

media_12 <- function(v) if (sum(!is.na(v)) == 12) mean(v) else NA

mensuales <- list()
resumen   <- list()
for (k in seq_len(nrow(candidatas))) {
  id <- candidatas$id[k]; nombre <- candidatas$nombre[k]

  # ---- 1. Probar dos anios y, si hay datos, bajar el resto ----
  if (!bajar(id, 1990) & !bajar(id, 2005)) {
    cat(sprintf("%-12s %-28s sin datos en GHCNh, se salta\n", id, nombre)); next
  }
  lect <- max(lecturas_dia(id, 1990), lecturas_dia(id, 2005))
  if (lect < lect_min) {
    cat(sprintf("%-12s %-28s solo %.1f lecturas/dia en 1990-2005, se salta\n", id, nombre, lect)); next
  }
  for (a in anios) bajar(id, a)
  archivos <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, id, anios)
  archivos <- archivos[file.exists(archivos)]

  # ---- 2. Metodo MGM: diario -> mensual (con dias validos) ----
  obs <- leer_ghcnh(archivos)
  lon <- read.delim(archivos[1], sep = "|", nrows = 1)$LONGITUDE
  d   <- diario_tabla_mgm(obs, lon)
  g   <- list(anio = d$Anio, mes = d$Mes)
  m   <- aggregate(cbind(temp = d$temp, hr = d$hr), by = g, FUN = function(x) mean(x, na.rm = TRUE))
  n   <- aggregate(cbind(dias_temp = !is.na(d$temp), dias_hr = !is.na(d$hr)), by = g, FUN = sum)
  m   <- merge(m, n, by = c("anio", "mes"))
  m$temp[m$dias_temp < dias_min | is.nan(m$temp)] <- NA
  m$hr[m$dias_hr < dias_min | is.nan(m$hr)]       <- NA
  mensuales[[id]] <- data.frame(estacion = id, nombre = nombre, m)

  # ---- 3. Anual y comparacion contra Develi ----
  anual <- data.frame(anio = sort(unique(m$anio)),
                      temp = tapply(m$temp, m$anio, media_12),
                      hr   = tapply(m$hr,   m$anio, media_12))
  comp <- merge(develi[, c("anio", "temp", "hr")], anual, by = "anio", suffixes = c("_dev", "_est"))
  dif_t <- abs(comp$temp_dev - comp$temp_est) * 100 / comp$temp_dev
  dif_h <- abs(comp$hr_dev   - comp$hr_est)   * 100 / comp$hr_dev
  fila <- data.frame(
    id = id, nombre = nombre, pais = candidatas$pais[k],
    dif_lat = candidatas$dif_lat[k], dif_elev = candidatas$dif_elev[k],
    t_anios = sum(!is.na(dif_t)), t_sobre = sum(dif_t > umbral, na.rm = TRUE),
    t_max = round(suppressWarnings(max(dif_t, na.rm = TRUE)), 1),
    hr_anios = sum(!is.na(dif_h)), hr_sobre = sum(dif_h > umbral, na.rm = TRUE),
    hr_max = round(suppressWarnings(max(dif_h, na.rm = TRUE)), 1)
  )
  resumen[[id]] <- fila
  cat(sprintf("%-12s %-28s T: %2d anios, %2d sobre 10%% | HR: %2d anios, %2d sobre 10%%\n",
              id, nombre, fila$t_anios, fila$t_sobre, fila$hr_anios, fila$hr_sobre))
}

mensual <- do.call(rbind, mensuales)
mensual$temp <- round(mensual$temp, 2); mensual$hr <- round(mensual$hr, 2)
write.csv(mensual, "data/equivalencia/procesados/candidatas_lat_alt_mgm_mensual.csv", row.names = FALSE)

resumen <- do.call(rbind, resumen)
resumen <- resumen[order(resumen$t_sobre + resumen$hr_sobre, -resumen$t_anios), ]
write.csv(resumen, "data/equivalencia/privado/candidatas_lat_alt_resumen.csv", row.names = FALSE)
cat("\nMejores (ordenadas por anios fuera del 10 % en T + HR):\n")
print(head(resumen, 15), row.names = FALSE)
