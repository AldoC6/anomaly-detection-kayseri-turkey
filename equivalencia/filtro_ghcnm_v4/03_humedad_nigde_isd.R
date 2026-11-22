# Filtro Monthly v4 - Paso 3: humedad relativa de Nigde con ISD Global Hourly
# GHCNh solo tiene 4 anios completos de humedad de Nigde (TUM00017250); ISD
# (estacion 17250099999) puede tener mas. ISD no trae humedad relativa: se calcula
# con la temperatura (TMP) y el punto de rocio (DEW), igual que hace NOAA en GHCNh
# (la humedad de GHCNh tiene codigo de medicion D = derivada de T y Td).
#   - Formula: Magnus con los coeficientes de la OMM (WMO-No. 8, 2008):
#       e(t) = 6.112 * exp(17.62 * t / (243.12 + t))   y   HR = 100 * e(Td) / e(T)
#     Comparada contra la humedad publicada en GHCNh (Erkilet 1980 y 2005, Nigde 2005,
#     Etimesgut 1985), da el mismo entero en ~83 % de las horas y +-1 % en el resto;
#     fue la que mas coincidio de las formulas probadas (Alduchov-Eskridge, Bolton,
#     Tetens, Buck, Goff-Gratch).
#   - Metodo de MGM con equivalencia/funciones_mgm.R (07, 14 y 21 h en hora solar
#     local); un mes cuenta si tiene al menos 15 dias con las 3 lecturas.
#   - TMP y DEW vienen como "valor,calidad" en decimas de grado; 9999 = sin dato y
#     se descartan las calidades 3 y 7 (erroneas).
# Todo es dato publico de NOAA, por eso la salida va en procesados/.
# Fuente: NOAA NCEI, Global Hourly - Integrated Surface Database (ISD), CSV.
#         https://www.ncei.noaa.gov/data/global-hourly/access/
# Salida: procesados/filtro_ghcnm_v4/nigde_isd_mgm_mensual.csv
#         (estacion, nombre, anio, mes, temp, dias_temp, hr, dias_hr)
# ============================================================

source("equivalencia/funciones_mgm.R")

isd_id   <- "17250099999"
lon      <- 34.683                      # longitud de Nigde
anios    <- 1975:2007
url_base <- c("https://www.ncei.noaa.gov/data/global-hourly/access/%d/%s.csv",
              "https://noaa-global-hourly-pds.s3.amazonaws.com/%d/%s.csv")   # copia de NOAA en AWS
carpeta  <- "data/equivalencia/fuentes/isd"
salida   <- "data/equivalencia/procesados/filtro_ghcnm_v4/nigde_isd_mgm_mensual.csv"
dias_min <- 15

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Descargar ISD Global Hourly (un CSV por anio) ----
es_csv <- function(f) file.exists(f) && startsWith(readLines(f, n = 1), "\"STATION\"")
for (a in anios) {
  destino <- sprintf("%s/%s_%d.csv", carpeta, isd_id, a)
  if (es_csv(destino)) next
  ok <- FALSE
  for (u in url_base) {
    ok <- tryCatch({
      download.file(sprintf(u, a, isd_id), destino, mode = "wb", quiet = TRUE)
      es_csv(destino)
    }, error = function(e) FALSE)
    if (ok) break
  }
  if (!ok && file.exists(destino)) file.remove(destino)
  cat(a, if (ok) "descargado" else "no disponible", "\n")
}

# ---- 2. Leer temperatura y punto de rocio, y calcular la humedad ----
a_grados <- function(campo) {
  valor   <- as.integer(sub(",.*", "", campo))
  calidad <- sub(".*,", "", campo)
  ifelse(valor == 9999 | calidad %in% c("3", "7"), NA, valor / 10)
}
e_sat <- function(t) 6.112 * exp(17.62 * t / (243.12 + t))     # hPa, sobre agua

leer_isd <- function(archivo) {
  x <- read.csv(archivo, colClasses = "character")[, c("DATE", "TMP", "DEW")]
  t  <- a_grados(x$TMP)
  td <- a_grados(x$DEW)
  data.frame(fecha = as.POSIXct(x$DATE, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC"),
             temperature = t,
             relative_humidity = pmin(100, 100 * e_sat(td) / e_sat(t)))
}
archivos <- sprintf("%s/%s_%d.csv", carpeta, isd_id, anios)
obs <- do.call(rbind, lapply(archivos[file.exists(archivos)], leer_isd))
obs <- obs[!is.na(obs$fecha), ]
obs$min  <- as.integer(format(obs$fecha, "%H")) * 60 + as.integer(format(obs$fecha, "%M"))
obs$DATE <- as.Date(obs$fecha)

# ---- 3. Metodo MGM: diario y mensual (con dias validos por mes) ----
diario <- diario_tabla_mgm(obs, lon)
grupos <- list(anio = diario$Anio, mes = diario$Mes)
mensual <- aggregate(cbind(temp = diario$temp, hr = diario$hr), by = grupos,
                     FUN = function(x) mean(x, na.rm = TRUE))
dias <- aggregate(cbind(dias_temp = !is.na(diario$temp), dias_hr = !is.na(diario$hr)),
                  by = grupos, FUN = sum)
mensual <- merge(mensual, dias, by = c("anio", "mes"))
mensual$temp[mensual$dias_temp < dias_min | is.nan(mensual$temp)] <- NA
mensual$hr[mensual$dias_hr < dias_min | is.nan(mensual$hr)] <- NA
mensual <- mensual[order(mensual$anio, mensual$mes), ]

mensual <- data.frame(estacion = "TUM00017250", nombre = "NIGDE", mensual[, c("anio", "mes", "temp", "dias_temp", "hr", "dias_hr")])
write.csv(transform(mensual, temp = round(temp, 2), hr = round(hr, 2)), salida, row.names = FALSE)

cat("Anios con los 12 meses de humedad:",
    paste(names(which(tapply(!is.na(mensual$hr), mensual$anio, sum) == 12)), collapse = " "), "\n")
