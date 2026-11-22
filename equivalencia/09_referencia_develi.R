# Paso 9: serie mensual de referencia de Develi (17836), 1965-2024
#
# Junta en una sola tabla los datos de Develi que se usan como referencia
# en la comparación del paso 16:
#   - Temperatura media mensual (°C) y precipitación mensual (mm):
#     datos del MGM proporcionados por la Prof. Altın (versión actual del sistema).
#   - Humedad relativa mensual (%): datos del MGM proporcionados por la
#     Prof. Dadaşer-Çelik (1975-2008).
#
# Entradas (uso restringido, NO se publican):
#   data/equivalencia/privado/temp-develi.csv    (Year, 1..12)
#   data/equivalencia/privado/precip-develi.csv  (Year, 1..12)
#   data/equivalencia/privado/17836_RelHum.csv   (Station No, Year, Month, relative_humidity)
# Salida (uso restringido, NO se publica):
#   data/equivalencia/privado/develi_referencia_mensual.csv  (anio, mes, temp, precip, hr)
#
# Celdas vacías:
#   - Temperatura: no hay meses vacíos.
#   - Precipitación: 31 celdas vacías (22 entre 1975 y 2007), todas en julio,
#     agosto, septiembre y un noviembre, es decir, en la temporada seca. En la
#     tabla del MGM la celda vacía se interpreta como "sin precipitación" (0 mm).
#     No es un valor estimado: es la lectura de la celda. Para dejarlas como NA,
#     cambia vacio_precip_es_cero a FALSE.
#   - Humedad relativa: solo existe 1975-2008; fuera de ese periodo queda NA.

dir_priv <- "data/equivalencia/privado"
vacio_precip_es_cero <- TRUE

ancho_a_largo <- function(archivo, variable) {
  d <- read.csv(file.path(dir_priv, archivo), check.names = FALSE)
  largo <- data.frame(
    anio = rep(d$Year, each = 12),
    mes  = rep(1:12, times = nrow(d)),
    valor = as.vector(t(as.matrix(d[, as.character(1:12)])))
  )
  names(largo)[3] <- variable
  largo
}

temp   <- ancho_a_largo("temp-develi.csv", "temp")
precip <- ancho_a_largo("precip-develi.csv", "precip")
cat("Celdas vacías de precipitación:", sum(is.na(precip$precip)), "\n")
if (vacio_precip_es_cero) precip$precip[is.na(precip$precip)] <- 0

hr <- read.csv(file.path(dir_priv, "17836_RelHum.csv"), check.names = FALSE)
hr <- data.frame(anio = hr$Year, mes = hr$Month, hr = hr$relative_humidity)

develi <- merge(temp, precip, by = c("anio", "mes"), all = TRUE)
develi <- merge(develi, hr, by = c("anio", "mes"), all.x = TRUE)
develi <- develi[order(develi$anio, develi$mes), ]

write.csv(develi, file.path(dir_priv, "develi_referencia_mensual.csv"),
          row.names = FALSE)

cat("Develi referencia:", nrow(develi), "meses,",
    min(develi$anio), "-", max(develi$anio), "\n")
cat("Meses sin temp:", sum(is.na(develi$temp)),
    "| precip en NA:", sum(is.na(develi$precip)),
    "| con HR:", sum(!is.na(develi$hr)), "\n")
