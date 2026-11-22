# Filtro Monthly v4 - Paso 1: temperatura ajustada (qfe) de Develi vs todo el mundo
# Compara la temperatura media anual de Develi en GHCN-M v4 qfe (TUXLT848934) con
# la de todas las estaciones de GHCN-M v4 qfe, con el criterio del docente:
#   |Develi - estacion| * 100 / Develi <= 10 %   en cada anio del periodo
#   - qfe = serie ajustada (homogeneizada) de NOAA; para Develi los valores
#     posteriores a 1990 son estimados, no medidos.
#   - Solo cuentan los meses con valor y sin bandera de calidad; un anio sin sus
#     12 meses no se compara.
#   - Se usan todos los anios de Develi en qfe (1961-2010) contra los mismos anios
#     de cada estacion. Una estacion pasa si tiene al menos min_anios anios
#     comparables y ninguno supera el umbral.
# Todo es dato publico de NOAA (no usa la serie medida de Develi), por eso las
# salidas van en procesados/.
# Fuente: Menne, M. J., et al. (2018). GHCN-Monthly Version 4. NOAA NCEI.
#         https://doi.org/10.7289/V5XW4GTH
# Entrada: fuentes/ghcnm_v4/ghcnm.tavg.latest.qfe.tar.gz
# Salidas: procesados/filtro_ghcnm_v4/temp_qfe_candidatas_<inicio>-<fin>.csv (las que pasan)
#          procesados/filtro_ghcnm_v4/temp_qfe_resumen_<inicio>-<fin>.csv    (todas)
# ============================================================

inicio    <- 1961            # periodo completo de Develi en qfe (1961-2010)
fin       <- 2010
umbral    <- 10              # % maximo de diferencia por anio
min_anios <- 33              # anios comparables minimos (los 33 anios del paper)
id_develi <- "TUXLT848934"
carpeta   <- "data/equivalencia/fuentes/ghcnm_v4"
dir_sal   <- "data/equivalencia/procesados/filtro_ghcnm_v4"
dir.create(dir_sal, showWarnings = FALSE, recursive = TRUE)

# ---- 1. Descomprimir y ubicar el .dat y el .inv ----
untar(file.path(carpeta, "ghcnm.tavg.latest.qfe.tar.gz"), exdir = carpeta)
dat <- sort(list.files(carpeta, pattern = "qfe\\.dat$", recursive = TRUE, full.names = TRUE), decreasing = TRUE)[1]
inv <- sort(list.files(carpeta, pattern = "qfe\\.inv$", recursive = TRUE, full.names = TRUE), decreasing = TRUE)[1]
cat("Archivo leido:", dat, "\n")

# ---- 2. Temperatura media anual de cada estacion (ancho fijo) ----
lineas <- readLines(dat)
anio   <- as.integer(substr(lineas, 12, 15))
lineas <- lineas[anio >= inicio & anio <= fin]

id   <- substr(lineas, 1, 11)
anio <- as.integer(substr(lineas, 12, 15))
meses <- sapply(0:11, function(m) {
  ini   <- 20 + m * 8
  valor <- as.integer(substr(lineas, ini, ini + 4))
  qc    <- substr(lineas, ini + 6, ini + 6)
  ifelse(valor == -9999 | qc != " ", NA, valor / 100)
})
temp <- ifelse(rowSums(is.na(meses)) == 0, rowMeans(meses), NA)
anual <- data.frame(id = id, anio = anio, temp = temp)
anual <- anual[!is.na(anual$temp), ]

# ---- 3. Comparar contra Develi anio por anio ----
develi <- anual[anual$id == id_develi, c("anio", "temp")]
names(develi)[2] <- "temp_develi"
cat("Anios completos de Develi (qfe):", nrow(develi), "\n")

comp <- merge(anual[anual$id != id_develi, ], develi, by = "anio")
comp$dif_pct <- abs(comp$temp_develi - comp$temp) * 100 / comp$temp_develi

resumen <- data.frame(
  id          = names(tapply(comp$dif_pct, comp$id, length)),
  anios       = as.vector(tapply(comp$dif_pct, comp$id, length)),
  anios_sobre = as.vector(tapply(comp$dif_pct > umbral, comp$id, sum)),
  dif_max_pct = as.vector(tapply(comp$dif_pct, comp$id, max))
)

# ---- 4. Nombre, ubicacion y distancia a Develi ----
lin_inv <- readLines(inv)
inventario <- data.frame(
  id     = substr(lin_inv, 1, 11),
  lat    = as.numeric(substr(lin_inv, 13, 20)),
  lon    = as.numeric(substr(lin_inv, 22, 30)),
  elev_m = as.numeric(substr(lin_inv, 32, 37)),
  nombre = trimws(substr(lin_inv, 39, 68))
)
d <- inventario[inventario$id == id_develi, ]
rad <- pi / 180
inventario$dist_km <- round(6371 * acos(pmin(1,
  sin(d$lat * rad) * sin(inventario$lat * rad) +
  cos(d$lat * rad) * cos(inventario$lat * rad) * cos((inventario$lon - d$lon) * rad))))

resumen <- merge(inventario, resumen, by = "id")
resumen <- resumen[order(resumen$anios < min_anios, resumen$anios_sobre, resumen$dist_km), ]
pasan   <- resumen[resumen$anios >= min_anios & resumen$anios_sobre == 0, ]

write.csv(pasan,   file.path(dir_sal, sprintf("temp_qfe_candidatas_%d-%d.csv", inicio, fin)), row.names = FALSE)
write.csv(resumen, file.path(dir_sal, sprintf("temp_qfe_resumen_%d-%d.csv",    inicio, fin)), row.names = FALSE)

cat("Estaciones con", min_anios, "o mas anios comparables:", sum(resumen$anios >= min_anios),
    "| pasan temperatura:", nrow(pasan), "\n")
print(pasan[, c("id", "nombre", "dist_km", "anios", "dif_max_pct")], row.names = FALSE)
