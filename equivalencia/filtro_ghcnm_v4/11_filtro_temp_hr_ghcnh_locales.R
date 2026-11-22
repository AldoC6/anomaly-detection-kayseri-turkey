# Filtro exploratorio 11: temperatura y humedad relativa anual con el método MGM
# para las estaciones horarias descargadas (GHCNh) y Erzincan (ISD)
#
# Para cada estación con archivos en fuentes/ghcnh_raw/ calcula, igual que MGM
# en Develi:
#   T diaria  = (T07 + T14 + 2 x T21) / 4
#   HR diaria = (HR07 + HR14 + HR21) / 3
# con las horas en hora solar local (hora UTC = hora local - longitud / 15).
# Cada lectura es la observación a +-30 min de la hora; si no hay, se interpola
# linealmente entre la observación anterior y la siguiente, siempre que ambas
# estén a 3 h o menos. Si falta alguna de las 3 lecturas, el día queda NA.
#   - Mensual: promedio de los días; NA si el mes tiene menos de 15 días válidos.
#   - Anual: promedio de los 12 meses; NA si falta alguno.
# Después compara cada año (1975-2007) con Develi:
#   diferencia % = |estación - Develi| x 100 / Develi, y cuenta los años > 10 %.
#
# Es parte de la carpeta exploratoria: sirvió para descartar estaciones y NO
# alimenta el dataset. Antes estaba en Python; esta es la versión en R.
#
# Entradas:
#   data/equivalencia/privado/develi_referencia_anual.csv   (paso 9, no se publica)
#   data/equivalencia/fuentes/ghcnh-station-list.txt        (lista de estaciones GHCNh)
#   data/equivalencia/fuentes/ghcnh_raw/GHCNh_<ID>_<AAAA>.psv
#   data/equivalencia/fuentes/isd/17092099999_<AAAA>.csv    (Erzincan, NOAA ISD)
# Salidas (en privado/ porque se comparan contra Develi):
#   data/equivalencia/privado/filtro_temp_hr_mgm_ghcnh_locales.csv  (resumen por estación)
#   data/equivalencia/privado/temp_hr_mgm_anual_candidatas.csv      (serie anual por estación)
# Fuentes:
#   Menne, M. J., et al. (2023). GHCNh, Version 1. NOAA NCEI. https://doi.org/10.25921/jp3d-3v19
#   NOAA NCEI. Integrated Surface Database (ISD). https://www.ncei.noaa.gov/products/land-based-station/integrated-surface-database
# ============================================================

dir_eq   <- "data/equivalencia"
dir_raw  <- file.path(dir_eq, "fuentes", "ghcnh_raw")
dir_isd  <- file.path(dir_eq, "fuentes", "isd")
dir_priv <- file.path(dir_eq, "privado")
anios    <- 1975:2007
umbral   <- 10     # % de diferencia anual contra Develi
min_dias <- 15     # días válidos mínimos para aceptar un mes

ref <- read.csv(file.path(dir_priv, "develi_referencia_anual.csv"))
ref <- ref[match(anios, ref$anio), ]

# ---- Funciones ----

# HR a partir de temperatura y punto de rocío (Magnus, Alduchov y Eskridge 1996)
hr_magnus <- function(t, td) {
  100 * exp(17.625 * td / (243.04 + td)) / exp(17.625 * t / (243.04 + t))
}

# Valor en cada hora objetivo (t y objetivo en minutos desde 1970-01-01 UTC):
# observación a +-30 min o interpolación lineal con vecinas a <= 180 min
valor_a_las_horas <- function(t, x, objetivo) {
  n <- length(t)
  out <- rep(NA_real_, length(objetivo))
  if (n == 0) return(out)
  i  <- findInterval(objetivo, t, left.open = TRUE)  # cuántas observaciones son < objetivo
  il <- pmax(i, 1)                                    # última observación antes
  ir <- pmin(i + 1, n)                                # primera observación en o después
  dl <- ifelse(i >= 1, objetivo - t[il], Inf)
  dr <- ifelse(i < n,  t[ir] - objetivo, Inf)
  cerca <- ifelse(abs(dl) <= abs(dr), il, ir)
  dn <- pmin(abs(dl), abs(dr))
  out <- ifelse(dn <= 30, x[cerca], NA_real_)
  interp <- dn > 30 & dl > 0 & dl <= 180 & dr > 0 & dr <= 180
  out[interp] <- x[il][interp] + (x[ir][interp] - x[il][interp]) *
    dl[interp] / (dl[interp] + dr[interp])
  out
}

# obs: data.frame con min (minutos UTC desde 1970), temp, hr
# Devuelve la serie anual (anio, temp, hr) con el método MGM
anual_mgm <- function(obs, lon) {
  dias <- seq(as.Date(sprintf("%d-01-01", min(anios))),
              as.Date(sprintf("%d-12-31", max(anios))), by = "day")
  min_dia <- as.numeric(dias) * 1440
  obs <- obs[order(obs$min), ]
  diario <- data.frame(anio = as.integer(format(dias, "%Y")),
                       mes  = as.integer(format(dias, "%m")))
  for (v in list(list(var = "temp", pesos = c(1, 1, 2)),
                 list(var = "hr",   pesos = c(1, 1, 1)))) {
    ok <- !is.na(obs[[v$var]])
    lecturas <- sapply(c(7, 14, 21), function(h)
      valor_a_las_horas(obs$min[ok], obs[[v$var]][ok], min_dia + (h - lon / 15) * 60))
    diario[[v$var]] <- as.vector(lecturas %*% v$pesos) / sum(v$pesos)
  }
  anual <- data.frame(anio = anios)
  for (var in c("temp", "hr")) {
    media <- aggregate(diario[[var]], by = diario[c("anio", "mes")],
                       FUN = function(x) if (sum(!is.na(x)) >= min_dias) mean(x, na.rm = TRUE) else NA)
    a <- aggregate(media$x, by = list(anio = media$anio),
                   FUN = function(x) if (all(!is.na(x))) mean(x) else NA)
    anual[[var]] <- a$x[match(anios, a$anio)]
  }
  anual
}

# Compara la serie anual de una estación contra Develi
resumir <- function(id, nombre, lat, lon, elev, anual) {
  fila <- data.frame(id = id, nombre = nombre, lat = lat, lon = lon, elev = elev)
  for (var in c("temp", "hr")) {
    d <- abs(anual[[var]] - ref[[var]]) * 100 / ref[[var]]
    fila[[paste0(var, "_anios")]] <- sum(!is.na(d))
    fila[[paste0(var, "_sobre")]] <- sum(d > umbral, na.rm = TRUE)
    fila[[paste0(var, "_max")]]   <- if (any(!is.na(d))) round(max(d, na.rm = TRUE), 1) else NA
    fila[[paste0(var, "_media")]] <- if (any(!is.na(anual[[var]]))) round(mean(anual[[var]], na.rm = TRUE), 2) else NA
  }
  fila
}

# ---- Lista de estaciones GHCNh (ancho fijo) ----
lineas <- readLines(file.path(dir_eq, "fuentes", "ghcnh-station-list.txt"), warn = FALSE)
lista <- data.frame(
  id     = trimws(substr(lineas, 1, 11)),
  lat    = suppressWarnings(as.numeric(substr(lineas, 13, 20))),
  lon    = suppressWarnings(as.numeric(substr(lineas, 22, 30))),
  elev   = suppressWarnings(as.numeric(substr(lineas, 32, 37))),
  nombre = trimws(substr(lineas, 42, 71)),
  stringsAsFactors = FALSE
)

# ---- Estaciones GHCNh ----
archivos <- sort(list.files(dir_raw, pattern = "^GHCNh_.*_[0-9]{4}\\.psv$", full.names = TRUE))
ids <- sort(unique(sub("^GHCNh_(.*)_[0-9]{4}\\.psv$", "\\1", basename(archivos))))

leer_psv <- function(archivo) {
  d <- read.delim(archivo, sep = "|", stringsAsFactors = FALSE, quote = "")
  data.frame(
    min  = as.numeric(as.Date(sprintf("%d-%02d-%02d", d$Year, d$Month, d$Day))) * 1440 +
           d$Hour * 60 + d$Minute,
    temp = suppressWarnings(as.numeric(d$temperature)),
    hr   = suppressWarnings(as.numeric(d$relative_humidity))
  )
}

resumen <- list()
series  <- list()
for (id in ids) {
  obs <- do.call(rbind, lapply(archivos[grepl(paste0("GHCNh_", id, "_"), archivos, fixed = TRUE)], leer_psv))
  obs <- obs[!is.na(obs$min), ]
  obs$temp[!is.na(obs$temp) & (obs$temp < -50 | obs$temp > 50)] <- NA
  obs$hr[!is.na(obs$hr) & (obs$hr < 0 | obs$hr > 100)] <- NA
  k <- match(id, lista$id)
  info <- if (is.na(k)) list(lat = NA, lon = NA, elev = NA, nombre = id) else lista[k, ]
  anual <- if (is.na(info$lon)) data.frame(anio = anios, temp = NA, hr = NA) else anual_mgm(obs, info$lon)
  resumen[[id]] <- resumir(id, info$nombre, info$lat, info$lon, info$elev, anual)
  series[[id]]  <- data.frame(anual, id = id, nombre = info$nombre)
  cat(id, info$nombre, "\n")
}

# ---- Erzincan (NOAA ISD): temperatura y punto de rocío -> HR con Magnus ----
leer_isd <- function(x) {
  partes <- do.call(rbind, strsplit(x, ","))
  v <- suppressWarnings(as.numeric(partes[, 1])) / 10
  v[grepl("9999", partes[, 1]) |
      !partes[, 2] %in% c("0", "1", "4", "5", "9", "A", "C", "I", "M", "P", "R", "U")] <- NA
  v
}
archivos_isd <- sort(list.files(dir_isd, pattern = "^17092099999_[0-9]{4}\\.csv$", full.names = TRUE))
if (length(archivos_isd) > 0) {
  isd <- do.call(rbind, lapply(archivos_isd, function(f)
    read.csv(f, stringsAsFactors = FALSE)[, c("DATE", "TMP", "DEW")]))
  ts <- as.POSIXct(isd$DATE, format = "%Y-%m-%dT%H:%M:%S", tz = "UTC")
  obs <- data.frame(min = as.numeric(ts) / 60, temp = leer_isd(isd$TMP))
  obs$hr <- hr_magnus(obs$temp, leer_isd(isd$DEW))
  obs <- obs[!is.na(obs$min), ]
  anual <- anual_mgm(obs, 39.5)
  resumen[["ERZ"]] <- resumir("TUM00017092 (ISD)", "ERZINCAN", 39.7, 39.5, 1215, anual)
  series[["ERZ"]]  <- data.frame(anual, id = "TUM00017092 (ISD)", nombre = "ERZINCAN")
  cat("ERZINCAN\n")
}

# ---- Guardar ----
resumen <- do.call(rbind, resumen)
resumen$ambas_sobre <- resumen$temp_sobre + resumen$hr_sobre
resumen <- resumen[order(resumen$ambas_sobre, resumen$hr_sobre), ]
write.csv(resumen, file.path(dir_priv, "filtro_temp_hr_mgm_ghcnh_locales.csv"), row.names = FALSE)
write.csv(do.call(rbind, series), file.path(dir_priv, "temp_hr_mgm_anual_candidatas.csv"), row.names = FALSE)
print(resumen, row.names = FALSE)
