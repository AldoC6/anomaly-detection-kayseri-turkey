# Filtro Monthly v4 - Paso 10: Open-Meteo (reanalisis ERA5) celda contra celda
# Descarga de Open-Meteo (archivo historico, reanalisis ERA5/ERA5-Land) la temperatura
# media, la precipitacion y la humedad relativa diarias de 1975-2007 en las
# coordenadas de Develi y de las estaciones candidatas, y compara cada candidata
# contra Develi con el criterio del docente, las dos en el mismo modelo:
#   |Develi - estacion| * 100 / Develi <= 10 %   en cada anio y cada variable
#   - Son datos de modelo (estimados), no mediciones: la celda de Develi contra la
#     celda de cada estacion.
#   - Anual: temperatura y humedad = promedio de los dias; precipitacion = suma.
# Todo es dato publico, por eso la salida va en procesados/.
# Fuente: Open-Meteo Historical Weather API (https://open-meteo.com/en/docs/historical-weather-api),
#         basada en ERA5 y ERA5-Land de Copernicus (Hersbach et al., 2020; Munoz Sabater, 2019).
# Requiere: install.packages("jsonlite")
# Descargas: fuentes/open_meteo/ (una por punto y bloque de anios; fuera de git). Si
#            el script se corta, al volver a correrlo no descarga lo que ya tiene.
# Salida:   procesados/filtro_ghcnm_v4/open_meteo_anual_1975-2007.csv
# ============================================================

library(jsonlite)

inicio <- 1975
fin    <- 2007
umbral <- 10
salida <- sprintf("data/equivalencia/procesados/filtro_ghcnm_v4/open_meteo_anual_%d-%d.csv", inicio, fin)

puntos <- data.frame(
  nombre = c("DEVELI", "NIGDE", "KIRSEHIR", "KONYA", "AFYON", "ERKILET", "ETIMESGUT"),
  lat    = c(38.3744, 37.9670, 39.1500, 37.9790, 38.7264, 38.7704, 39.9498),
  lon    = c(35.4797, 34.6830, 34.1670, 32.5619, 30.6011, 35.4954, 32.6886)
)

# ---- 1. Descargar los datos diarios de cada punto ----
# (en bloques de 11 anios; pedir los 33 de una vez tarda mas que el limite de espera)
options(timeout = 600)
url <- paste0("https://archive-api.open-meteo.com/v1/archive?latitude=%f&longitude=%f",
              "&start_date=%d-01-01&end_date=%d-12-31",
              "&daily=temperature_2m_mean,precipitation_sum,relative_humidity_2m_mean",
              "&timezone=Europe%%2FIstanbul")
bloques <- split(inicio:fin, ceiling(seq_along(inicio:fin) / 11))
carpeta <- "data/equivalencia/fuentes/open_meteo"   # descargas (fuera de git)
dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# Descarga un bloque; si ya esta en disco lo lee. Si la API responde 429 (demasiadas
# peticiones), espera un minuto y reintenta.
descargar <- function(nombre, lat, lon, a, b) {
  archivo <- sprintf("%s/%s_%d-%d.csv", carpeta, nombre, a, b)
  if (file.exists(archivo)) return(read.csv(archivo))
  for (intento in 1:5) {
    x <- tryCatch(as.data.frame(fromJSON(sprintf(url, lat, lon, a, b))$daily),
                  error = function(e) NULL)
    if (!is.null(x)) break
    cat("  ", nombre, a, "-", b, ": la API no respondio, reintento en 60 s\n")
    Sys.sleep(60)
  }
  if (is.null(x)) stop("No se pudo descargar ", nombre, " ", a, "-", b, ": vuelve a correr el script mas tarde")
  write.csv(x, archivo, row.names = FALSE)
  Sys.sleep(10)                                  # no saturar la API
  x
}

anual <- do.call(rbind, lapply(seq_len(nrow(puntos)), function(k) {
  partes <- lapply(bloques, function(b)
    descargar(puntos$nombre[k], puntos$lat[k], puntos$lon[k], min(b), max(b)))
  d <- do.call(rbind, partes)
  anio <- as.integer(substr(d$time, 1, 4))
  cat(puntos$nombre[k], "descargado\n")
  data.frame(nombre = puntos$nombre[k], anio = sort(unique(anio)),
             temp   = round(tapply(d$temperature_2m_mean, anio, mean), 2),
             precip = round(tapply(d$precipitation_sum, anio, sum), 1),
             hr     = round(tapply(d$relative_humidity_2m_mean, anio, mean), 2))
}))
write.csv(anual, salida, row.names = FALSE)

# ---- 2. Comparar cada candidata contra Develi anio por anio ----
develi <- anual[anual$nombre == "DEVELI", ]
resumen <- do.call(rbind, lapply(setdiff(puntos$nombre, "DEVELI"), function(e) {
  s <- anual[anual$nombre == e, ]
  s <- s[match(develi$anio, s$anio), ]
  pct <- function(v) abs(develi[[v]] - s[[v]]) * 100 / develi[[v]]
  pt <- pct("temp"); pp <- pct("precip"); ph <- pct("hr")
  cumple <- pt <= umbral & pp <= umbral & ph <= umbral
  r <- rle(cumple)
  data.frame(estacion = e,
             fallan_temp = sum(pt > umbral), fallan_precip = sum(pp > umbral),
             fallan_hr = sum(ph > umbral), anios_cumplen_las_3 = sum(cumple),
             racha_max = if (any(r$values)) max(r$lengths[r$values]) else 0)
}))

cat("\nDeveli en Open-Meteo (promedio ", inicio, "-", fin, "): temp ",
    round(mean(develi$temp), 2), " C, precip ", round(mean(develi$precip)), " mm, hr ",
    round(mean(develi$hr), 1), " %\n", sep = "")
cat("Anios evaluados:", nrow(develi), "\n\n")
print(resumen, row.names = FALSE)
