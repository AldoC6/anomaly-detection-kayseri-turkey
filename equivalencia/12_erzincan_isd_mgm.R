# Erzincan - temperatura con el metodo de MGM (NOAA ISD, Global Hourly) y precipitacion
# (NOAA GHCN-M v4), comparadas anio por anio contra Develi
# Erzincan paso el filtro grueso de temperatura (paso 10) con 32 anios y ninguno
# sobre 10 %, pero GHCNh no tiene sus datos horarios despues de 1968. ISD si los
# tiene (estacion 17092099999), asi que se usa la temperatura horaria de ISD en su
# version CSV (Global Hourly). El campo TMP trae "valor,calidad" en decimas de grado;
# 9999 = sin dato, y se descartan las calidades 3 y 7 (erroneas).
#   - Solo temperatura y precipitacion: ISD no trae humedad relativa medida
#     (habria que calcularla con el punto de rocio), asi que la humedad no se evalua aqui.
#   - Metodo de MGM con equivalencia/funciones_mgm.R (lecturas de 07, 14 y 21 h en
#     hora solar local segun la longitud).
#   - Precipitacion mensual: GHCN-M v4, estacion TUM00017092.
#   - Criterio del docente: |Develi - Erzincan| * 100 / Develi <= 10 % en cada anio
#     y en cada variable (promedio anual de los 12 meses; un mes de temperatura
#     cuenta si tiene al menos 15 dias con las 3 lecturas).
# Fuentes: NOAA NCEI, Global Hourly - Integrated Surface Database (ISD), CSV.
#          https://www.ncei.noaa.gov/data/global-hourly/access/
#          (copia en AWS: https://noaa-global-hourly-pds.s3.amazonaws.com/)
#          Applequist, S., Durre, I., & Vose, R. (2024). GHCN-M Precipitation v4.
#          https://doi.org/10.25921/67zp-5m03
# Entradas: descarga de ISD Global Hourly (fuentes/isd/, fuera de git)
#           fuentes/ghcnm_v4/prcp/ghcn-m_v4.00.00_prcp_*.tar.gz
#           privado/develi_referencia_anual.csv (paso 9)
# Salidas:  procesados/erzincan_mensual.csv (anio, mes, temp, dias_temp, precip)
#           privado/erzincan_vs_develi_anual.csv (comparacion; usa datos de Develi)
# ============================================================

source("equivalencia/funciones_mgm.R")

isd_id   <- "17092099999"
ghcnm_id <- "TUM00017092"
lon      <- 39.517                      # longitud de la estacion en ISD
anios    <- 1975:2009
url_base <- c("https://www.ncei.noaa.gov/data/global-hourly/access/%d/%s.csv",
              "https://noaa-global-hourly-pds.s3.amazonaws.com/%d/%s.csv")   # copia de NOAA en AWS
carpeta  <- "data/equivalencia/fuentes/isd"
umbral   <- 10
dias_min <- 15

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Descargar ISD Global Hourly (un CSV por anio) ----
es_csv <- function(f) file.exists(f) && startsWith(readLines(f, n = 1), "\"STATION\"")
for (a in anios) {
  destino <- sprintf("%s/%s_%d.csv", carpeta, isd_id, a)
  if (es_csv(destino)) next
  ok <- FALSE
  for (u in url_base) {                  # si la primera direccion falla, prueba la copia
    ok <- tryCatch({
      download.file(sprintf(u, a, isd_id), destino, mode = "wb", quiet = TRUE)
      es_csv(destino)                    # si responde con una pagina HTML, no cuenta
    }, error = function(e) FALSE)
    if (ok) break
  }
  if (!ok && file.exists(destino)) file.remove(destino)
  cat(a, if (ok) "descargado" else "no disponible", "\n")
}

# ---- 2. Leer la temperatura (campo TMP = "valor,calidad") ----
leer_isd <- function(archivo) {
  x <- read.csv(archivo, colClasses = "character")[, c("DATE", "TMP")]
  valor   <- as.integer(sub(",.*", "", x$TMP))
  calidad <- sub(".*,", "", x$TMP)
  data.frame(fecha = as.POSIXct(x$DATE, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
             temperature = ifelse(valor == 9999 | calidad %in% c("3", "7"), NA, valor / 10))
}
archivos <- sprintf("%s/%s_%d.csv", carpeta, isd_id, anios)
obs <- do.call(rbind, lapply(archivos[file.exists(archivos)], leer_isd))
obs <- obs[!is.na(obs$fecha) & !is.na(obs$temperature), ]
obs$relative_humidity <- NA      # funciones_mgm.R espera la columna; no se usa
obs$min  <- as.integer(format(obs$fecha, "%H")) * 60 + as.integer(format(obs$fecha, "%M"))
obs$DATE <- as.Date(obs$fecha)

# ---- 3. Metodo MGM: temperatura diaria y mensual (con dias validos por mes) ----
diario <- data.frame(DATE = sort(unique(obs$DATE)))
diario$temp <- diario_mgm(obs, "temperature", c(1, 1, 2), horas_utc_mgm(lon))
grupos  <- list(anio = as.integer(format(diario$DATE, "%Y")),
                mes  = as.integer(format(diario$DATE, "%m")))
mensual <- aggregate(cbind(temp = diario$temp), by = grupos,
                     FUN = function(x) mean(x, na.rm = TRUE))
n <- aggregate(cbind(dias_temp = !is.na(diario$temp)), by = grupos, FUN = sum)
mensual <- merge(mensual, n, by = c("anio", "mes"))
mensual$temp[mensual$dias_temp < dias_min | is.nan(mensual$temp)] <- NA

# ---- 4. Precipitacion de GHCN-M v4 (solo el CSV de la estacion) ----
tar_prcp <- list.files("data/equivalencia/fuentes/ghcnm_v4/prcp", pattern = "\\.tar\\.gz$", full.names = TRUE)[1]
untar(tar_prcp, files = paste0(ghcnm_id, ".csv"), exdir = tempdir())
p <- read.csv(file.path(tempdir(), paste0(ghcnm_id, ".csv")), header = FALSE, strip.white = TRUE)
p <- data.frame(anio = p$V6 %/% 100, mes = p$V6 %% 100,
                precip = ifelse(p$V7 < 0, NA, p$V7 / 10))      # decimas de mm -> mm
mensual <- merge(mensual, p, by = c("anio", "mes"), all.x = TRUE)
mensual <- mensual[order(mensual$anio, mensual$mes), ]
write.csv(transform(mensual, temp = round(temp, 2)),
          "data/equivalencia/procesados/erzincan_mensual.csv", row.names = FALSE)

# ---- 5. Comparar anio por anio contra Develi ----
media_12 <- function(v) if (sum(!is.na(v)) == 12) mean(v) else NA
anual <- data.frame(anio   = sort(unique(mensual$anio)),
                    temp   = tapply(mensual$temp,   mensual$anio, media_12),
                    precip = tapply(mensual$precip, mensual$anio, media_12))
develi <- read.csv("data/equivalencia/privado/develi_referencia_anual.csv")[, c("anio", "temp", "precip")]
comp <- merge(develi, anual, by = "anio", suffixes = c("_develi", "_erzincan"))
for (v in c("temp", "precip")) {
  dev <- comp[[paste0(v, "_develi")]]
  comp[[paste0("dif_", v)]] <- abs(dev - comp[[paste0(v, "_erzincan")]]) * 100 / dev
}
comp$pasa_2 <- with(comp, dif_temp <= umbral & dif_precip <= umbral)
write.csv(comp, "data/equivalencia/privado/erzincan_vs_develi_anual.csv", row.names = FALSE)

# ---- 6. Resumen ----
for (v in c("temp", "precip")) {
  x <- comp[[paste0("dif_", v)]]
  cat(sprintf("%-7s anios con dato: %2d | sobre %d %%: %2d | maximo: %5.1f %% | anios: %s\n",
              v, sum(!is.na(x)), umbral, sum(x > umbral, na.rm = TRUE), max(x, na.rm = TRUE),
              paste(comp$anio[which(x > umbral)], collapse = " ")))
}
cat("Anios que pasan temperatura y precipitacion:", paste(comp$anio[which(comp$pasa_2)], collapse = " "), "\n")
