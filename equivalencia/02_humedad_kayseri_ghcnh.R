# Humedad relativa anual del Aeropuerto de Kayseri (Erkilet) - NOAA GHCNh
# Calcula la humedad relativa de Kayseri con el mismo metodo que usa MGM para
# Develi, para comparar igual contra igual:
#      - MGM define la humedad media diaria como la suma de las lecturas de
#        07:00, 14:00 y 21:00 hora local dividida entre 3, y la mensual como el
#        promedio de los dias (MGM, "Tanimlar", resmi istatistikler).
#      - La hora local de las observaciones climatologicas es la hora solar media
#        del lugar (segun la longitud de la estacion; MGM, Klimatolojik Rasat El
#        Kitabi). Para Kayseri (35.50 E) es UTC + 35.50/15 h = UTC + 2 h 22 min, asi
#        que 07, 14 y 21 h locales son 04:38, 11:38 y 18:38 UTC.
# Entrada: fuentes/ghcnh_raw/ (archivos horarios que descarga el paso 1)
# Salidas: procesados/kayseri-erkilet-relative-humidity-mensual.csv (por mes)
#          procesados/kayseri-erkilet-relative-humidity.csv (por anio)
# ============================================================

# ---- 1. Leer las observaciones horarias ----
estacion <- "TUI0000LTAU"
anios    <- 1975:2007
carpeta  <- "data/equivalencia/fuentes/ghcnh_raw"
salida_mensual <- "data/equivalencia/procesados/kayseri-erkilet-relative-humidity-mensual.csv"
salida_anual   <- "data/equivalencia/procesados/kayseri-erkilet-relative-humidity.csv"

horas_locales <- c(7, 14, 21)

leer <- function(archivo) {
  d <- read.delim(archivo, sep = "|", stringsAsFactors = FALSE)
  d <- d[, c("Year", "Month", "Day", "Hour", "Minute", "relative_humidity")]
  d$relative_humidity <- suppressWarnings(as.numeric(d$relative_humidity))
  d
}

archivos <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, estacion, anios)
archivos <- archivos[file.exists(archivos)]
obs <- do.call(rbind, lapply(archivos, leer))

obs <- obs[!is.na(obs$relative_humidity) &
             obs$relative_humidity >= 0 & obs$relative_humidity <= 100, ]
obs$min  <- obs$Hour * 60 + obs$Minute                       # minutos desde 00:00 UTC
lon      <- read.delim(archivos[1], sep = "|", nrows = 1)$LONGITUDE
horas_utc <- horas_locales - lon / 15                          # hora solar local -> UTC
cat(sprintf("Longitud %.4f E -> lecturas a %s UTC\n", lon,
            paste(sprintf("%02d:%02d", floor(horas_utc), round(horas_utc %% 1 * 60)), collapse = ", ")))
obs$DATE <- as.Date(sprintf("%d-%02d-%02d", obs$Year, obs$Month, obs$Day))

# ---- 2. Humedad diaria: promedio de las lecturas de 07, 14 y 21 h ----
# Humedad a una hora dada: observacion a +-30 min, o interpolacion lineal (max 3 h)
hr_a_la_hora <- function(t, rh, hora) {
  objetivo <- hora * 60
  dif <- abs(t - objetivo)
  if (any(dif <= 30)) return(rh[which.min(dif)])
  antes   <- which(t < objetivo & t >= objetivo - 180)
  despues <- which(t > objetivo & t <= objetivo + 180)
  if (length(antes) == 0 || length(despues) == 0) return(NA)
  i <- antes[which.max(t[antes])]
  j <- despues[which.min(t[despues])]
  rh[i] + (rh[j] - rh[i]) * (objetivo - t[i]) / (t[j] - t[i])
}

# Promedio diario con 3 lecturas (si falta alguna, el dia queda NA)
dias <- split(obs, obs$DATE)
diario_3obs <- function(horas) {
  sapply(dias, function(d) {
    v <- sapply(horas, function(h) hr_a_la_hora(d$min, d$relative_humidity, h))
    if (any(is.na(v))) NA else mean(v)
  })
}

diario <- data.frame(DATE = as.Date(names(dias)))
diario$mgm <- diario_3obs(horas_utc)
diario$Anio <- as.integer(format(diario$DATE, "%Y"))
diario$Mes  <- as.integer(format(diario$DATE, "%m"))

# ---- 3. Media mensual (promedio de los dias) y media anual (de los 12 meses) ----
mensual <- aggregate(mgm ~ Anio + Mes, data = diario, FUN = mean)
names(mensual)[3] <- "relative_humidity"
mensual <- mensual[order(mensual$Anio, mensual$Mes), ]

anual <- aggregate(relative_humidity ~ Anio, data = mensual, FUN = mean)

# ---- 4. Revision ----
cat("Dias con las 3 lecturas:", sum(!is.na(diario$mgm)), "de", nrow(diario), "\n")
n_dias <- aggregate(!is.na(diario$mgm), by = list(Anio = diario$Anio, Mes = diario$Mes), FUN = sum)
cat("Meses con menos de 15 dias:", sum(n_dias$x < 15), "| meses:", nrow(mensual), "| anios:", nrow(anual), "\n")
cat(sprintf("HR media 1975-2007: %.2f %%  DE anual: %.3f\n",
            mean(anual$relative_humidity), sd(anual$relative_humidity)))

mensual$relative_humidity <- round(mensual$relative_humidity, 2)
write.csv(mensual, salida_mensual, row.names = FALSE)
write.csv(anual, salida_anual, row.names = FALSE)
