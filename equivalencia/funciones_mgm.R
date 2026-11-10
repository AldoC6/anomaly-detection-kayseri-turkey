# Funciones del metodo de MGM para temperatura y humedad relativa (GHCNh)
# Las usa el paso 2 (Kayseri/Erkilet); estan aparte para poder calcular otras
# estaciones exactamente igual.
#   - MGM define la humedad media diaria como (HR07 + HR14 + HR21) / 3 y la
#     temperatura media diaria como (T07 + T14 + 2 x T21) / 4; la media mensual es
#     el promedio de los dias (MGM, "Tanimlar", resmi istatistikler).
#   - Las horas son hora solar media del lugar, segun la longitud de la estacion
#     (MGM, Klimatolojik Rasat El Kitabi): hora UTC = hora local - longitud / 15.
# ============================================================

horas_locales_mgm <- c(7, 14, 21)

# Hora solar local (07, 14, 21 h) -> hora UTC, segun la longitud
horas_utc_mgm <- function(lon) horas_locales_mgm - lon / 15

# Lee los archivos horarios .psv de GHCNh y deja temperatura y humedad limpias
leer_ghcnh <- function(archivos) {
  leer <- function(archivo) {
    d <- read.delim(archivo, sep = "|", stringsAsFactors = FALSE)
    d <- d[, c("Year", "Month", "Day", "Hour", "Minute", "relative_humidity", "temperature")]
    d$relative_humidity <- suppressWarnings(as.numeric(d$relative_humidity))
    d$temperature       <- suppressWarnings(as.numeric(d$temperature))
    d
  }
  obs <- do.call(rbind, lapply(archivos, leer))
  # Valores fuera de rango -> NA (cada variable se filtra por separado)
  obs$relative_humidity[!is.na(obs$relative_humidity) &
                          (obs$relative_humidity < 0 | obs$relative_humidity > 100)] <- NA
  obs$temperature[!is.na(obs$temperature) &
                    (obs$temperature < -50 | obs$temperature > 50)] <- NA
  obs$min  <- obs$Hour * 60 + obs$Minute                       # minutos desde 00:00 UTC
  obs$DATE <- as.Date(sprintf("%d-%02d-%02d", obs$Year, obs$Month, obs$Day))
  obs
}

# Valor a una hora dada: observacion a +-30 min, o interpolacion lineal (max 3 h)
valor_a_la_hora <- function(t, x, hora) {
  objetivo <- hora * 60
  dif <- abs(t - objetivo)
  if (any(dif <= 30)) return(x[which.min(dif)])
  antes   <- which(t < objetivo & t >= objetivo - 180)
  despues <- which(t > objetivo & t <= objetivo + 180)
  if (length(antes) == 0 || length(despues) == 0) return(NA)
  i <- antes[which.max(t[antes])]
  j <- despues[which.min(t[despues])]
  x[i] + (x[j] - x[i]) * (objetivo - t[i]) / (t[j] - t[i])
}

# Promedio diario ponderado de las 3 lecturas (si falta alguna, el dia queda NA)
#   humedad:     pesos 1, 1, 1 -> (HR07 + HR14 + HR21) / 3
#   temperatura: pesos 1, 1, 2 -> (T07 + T14 + 2 x T21) / 4
diario_mgm <- function(obs, variable, pesos, horas_utc) {
  sapply(split(obs, obs$DATE), function(d) {
    ok <- !is.na(d[[variable]])
    v <- sapply(horas_utc, function(h) valor_a_la_hora(d$min[ok], d[[variable]][ok], h))
    if (any(is.na(v))) NA else sum(v * pesos) / sum(pesos)
  })
}

# Tabla diaria con temperatura y humedad por el metodo de MGM
diario_tabla_mgm <- function(obs, lon) {
  h <- horas_utc_mgm(lon)
  diario <- data.frame(DATE = sort(unique(obs$DATE)))
  diario$hr   <- diario_mgm(obs, "relative_humidity", c(1, 1, 1), h)
  diario$temp <- diario_mgm(obs, "temperature",       c(1, 1, 2), h)
  diario$Anio <- as.integer(format(diario$DATE, "%Y"))
  diario$Mes  <- as.integer(format(diario$DATE, "%m"))
  diario
}

# Media mensual (promedio de los dias) y media anual (promedio de los 12 meses;
# NA si al anio le falta algun mes)
resumir_mgm <- function(diario, columna, nombre) {
  mensual <- aggregate(diario[[columna]], by = list(Anio = diario$Anio, Mes = diario$Mes),
                       FUN = mean, na.rm = TRUE)
  names(mensual)[3] <- nombre
  mensual[[nombre]][is.nan(mensual[[nombre]])] <- NA
  mensual <- mensual[order(mensual$Anio, mensual$Mes), ]
  anual <- aggregate(mensual[[nombre]], by = list(Anio = mensual$Anio),
                     FUN = function(v) if (length(v) == 12 && !anyNA(v)) mean(v) else NA)
  names(anual)[2] <- nombre
  list(mensual = mensual, anual = anual)
}
