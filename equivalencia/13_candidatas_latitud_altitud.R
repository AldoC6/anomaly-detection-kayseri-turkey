# PROVISIONAL - Estaciones del mundo con latitud y altitud parecidas a Develi
# Busca en la lista de estaciones de GHCNh (todo el mundo) las que estan cerca del
# paralelo de Develi y a una altitud parecida, y les agrega el resultado del filtro
# de temperatura del paso 10 (GHCN-M v4 qcu) cuando hay una estacion de GHCN-M a
# menos de 5 km.
#   - Develi: 38.3833 N, 35.5 E, 1180 m.
#   - Opcional: incluir el hemisferio sur (latitud -38.38), donde las estaciones
#     tienen las estaciones del anio invertidas (habria que desfasar 6 meses).
# Entradas: fuentes/ghcnh-station-list.txt (lista de estaciones de GHCNh)
#           privado/resumen_temp_1975-2007.csv (paso 10)
# Salida:   privado/candidatas_latitud_altitud.csv
# ============================================================

develi     <- c(lat = 38.3833, lon = 35.5, elev = 1180)
dif_lat    <- 0.5        # grados de latitud (+-)
dif_elev   <- 150        # metros (+-)
hemis_sur  <- FALSE      # TRUE: buscar tambien alrededor de 38.38 S
salida     <- "data/equivalencia/privado/candidatas_latitud_altitud.csv"

# ---- 1. Lista de estaciones de GHCNh (ancho fijo) ----
lineas <- readLines("data/equivalencia/fuentes/ghcnh-station-list.txt", warn = FALSE)
campo  <- function(ini, fin) trimws(substr(lineas, ini, fin))
est <- data.frame(
  id     = campo(1, 11),
  lat    = suppressWarnings(as.numeric(campo(13, 20))),
  lon    = suppressWarnings(as.numeric(campo(22, 30))),
  elev   = suppressWarnings(as.numeric(campo(32, 37))),
  nombre = campo(42, 71),
  pais   = substr(lineas, nchar(lineas) - 1, nchar(lineas))
)
est <- est[!is.na(est$lat) & !is.na(est$elev) & est$elev > -999, ]

# ---- 2. Filtro por latitud y altitud ----
lat_ref <- if (hemis_sur) c(develi["lat"], -develi["lat"]) else develi["lat"]
cerca_lat <- sapply(est$lat, function(l) min(abs(l - lat_ref))) <= dif_lat
cerca_ele <- abs(est$elev - develi["elev"]) <= dif_elev
cand <- est[cerca_lat & cerca_ele, ]
cand$dif_lat  <- round(cand$lat  - develi["lat"],  3)
cand$dif_elev <- round(cand$elev - develi["elev"])

# Distancia a Develi (haversine), solo como referencia
rad <- pi / 180
cand$dist_km <- round(2 * 6371 * asin(sqrt(
  sin((cand$lat - develi["lat"]) * rad / 2)^2 +
  cos(develi["lat"] * rad) * cos(cand$lat * rad) * sin((cand$lon - develi["lon"]) * rad / 2)^2)))

# ---- 3. Agregar el filtro de temperatura del paso 10 (GHCN-M a <= 5 km) ----
temp <- read.csv("data/equivalencia/privado/resumen_temp_1975-2007.csv")
cerca <- function(la, lo) {
  d <- 2 * 6371 * asin(sqrt(sin((temp$lat - la) * rad / 2)^2 +
                            cos(la * rad) * cos(temp$lat * rad) * sin((temp$lon - lo) * rad / 2)^2))
  i <- which.min(d)
  if (length(i) == 0 || d[i] > 5) return(c(NA, NA, NA))
  c(temp$anios[i], temp$anios_sobre[i], round(temp$temp_media[i], 2))
}
t <- t(mapply(cerca, cand$lat, cand$lon))
cand$t_anios       <- t[, 1]   # anios completos de temperatura en GHCN-M (1975-2007)
cand$t_anios_sobre <- t[, 2]   # anios con diferencia > 10 % contra Develi
cand$t_media       <- t[, 3]

cand <- cand[order(is.na(cand$t_anios_sobre), cand$t_anios_sobre, -cand$t_anios), ]
write.csv(cand, salida, row.names = FALSE)

cat("Estaciones en la lista:", nrow(est), "| con latitud y altitud parecidas:", nrow(cand),
    "| con temperatura en GHCN-M:", sum(!is.na(cand$t_anios)), "\n")
print(head(cand[!is.na(cand$t_anios) & cand$t_anios >= 15,
                c("id", "nombre", "pais", "dif_lat", "dif_elev", "dist_km", "t_anios", "t_anios_sobre", "t_media")], 30),
      row.names = FALSE)
