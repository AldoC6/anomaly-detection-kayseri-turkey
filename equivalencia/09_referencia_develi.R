# Referencia de Develi (MGM 17836) - temperatura, precipitacion y humedad relativa
# Junta en una sola tabla mensual y anual los datos de Develi que se usan como
# referencia para buscar estaciones equivalentes (pasos 10 en adelante).
#   - Temperatura media y precipitacion mensual: MGM, datos de la Prof. Dr. Turkan
#     Bayer Altin (1965-2024).
#   - Humedad relativa mensual: MGM, datos de la Prof. Dr. Filiz Dadaser-Celik
#     (1975-01 a 2009-07).
#   - En precipitacion, las celdas vacias se toman como 0 mm: asi los totales
#     anuales coinciden con Barak (2009, Tabla 33) en los 32 anios de 1975-2006.
# Datos de uso restringido: entradas y salidas van en data/equivalencia/privado/
# (ignorada por git).
# Entradas: privado/temp-develi.csv, privado/precip-develi.csv (hojas del Excel de
#           la Prof. Altin exportadas a CSV), privado/17836_RelHum.csv
# Salidas:  privado/develi_referencia_mensual.csv (anio, mes, temp, precip, hr)
#           privado/develi_referencia_anual.csv   (promedio de los 12 meses; NA si falta alguno)
# ============================================================

carpeta <- "data/equivalencia/privado"

# ---- 1. Tablas anchas (anio x 12 meses) a una fila por mes ----
a_largo <- function(archivo, nombre) {
  ancho <- read.csv(file.path(carpeta, archivo), check.names = FALSE)
  largo <- data.frame(anio = rep(ancho$Year, each = 12),
                      mes  = rep(1:12, times = nrow(ancho)),
                      valor = as.vector(t(as.matrix(ancho[, as.character(1:12)]))))
  names(largo)[3] <- nombre
  largo
}

temp   <- a_largo("temp-develi.csv",   "temp")
precip <- a_largo("precip-develi.csv", "precip")
precip$precip[is.na(precip$precip)] <- 0          # celda vacia = 0 mm

# ---- 2. Humedad relativa (ya viene una fila por mes) ----
hr <- read.csv(file.path(carpeta, "17836_RelHum.csv"))
names(hr) <- c("estacion", "anio", "mes", "hr")  # el original trae "relative _humidity"
hr <- hr[, c("anio", "mes", "hr")]

# ---- 3. Unir y guardar ----
mensual <- merge(merge(temp, precip, by = c("anio", "mes"), all = TRUE),
                 hr, by = c("anio", "mes"), all = TRUE)
mensual <- mensual[order(mensual$anio, mensual$mes), ]

media_12 <- function(v) if (sum(!is.na(v)) == 12) mean(v) else NA
anual <- data.frame(
  anio   = sort(unique(mensual$anio)),
  temp   = tapply(mensual$temp,   mensual$anio, media_12),
  precip = tapply(mensual$precip, mensual$anio, media_12),
  hr     = tapply(mensual$hr,     mensual$anio, media_12)
)

write.csv(mensual, file.path(carpeta, "develi_referencia_mensual.csv"), row.names = FALSE)
write.csv(anual,   file.path(carpeta, "develi_referencia_anual.csv"),   row.names = FALSE)

cat("Meses:", nrow(mensual), "| anios con las 3 variables completas:",
    sum(complete.cases(anual)), "\n")
