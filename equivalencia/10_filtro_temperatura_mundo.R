# Filtro mundial de temperatura - NOAA GHCN-Monthly v4 (qcu, sin ajustar)
# Busca, entre todas las estaciones de GHCN-M v4, las que cumplen el criterio del
# docente en temperatura contra Develi: en cada anio del periodo,
#   |Develi - estacion| * 100 / Develi <= 10 %
# usando la temperatura media anual (promedio de los 12 meses).
#   - Se usa la variante qcu (sin homogeneizar ni estimar): la qfe se descarto
#     para Develi porque esta ajustada y estimada desde 1991.
#   - Solo cuentan los meses con valor y sin bandera de control de calidad (QCFLAG
#     en blanco); un anio sin sus 12 meses no se puede comparar.
#   - Una estacion pasa si tiene al menos min_anios anios completos en el periodo y
#     los cumple todos (casi ninguna estacion tiene los 33 anios completos).
# Las salidas comparan contra la serie de Develi (uso restringido), asi que van
# en privado/: con la diferencia y el dato publico de la estacion se podria
# reconstruir la serie de Develi.
# Fuente: Menne, M. J., et al. (2018). GHCN-Monthly Version 4. NOAA NCEI.
#         https://doi.org/10.7289/V5XW4GTH
# Entradas: fuentes/ghcnm_v4/ghcnm.tavg.latest.qcu.tar.gz
#           privado/develi_referencia_anual.csv (sale del paso 9)
# Salidas:  privado/candidatas_temp_<inicio>-<fin>.csv (las que pasan)
#           privado/resumen_temp_<inicio>-<fin>.csv    (todas las estaciones, para explorar)
# ============================================================

inicio  <- 1975
fin     <- 2007
umbral    <- 10                                  # % maximo de diferencia por anio
min_anios <- 20                                  # anios completos minimos para evaluar
carpeta <- "data/equivalencia/fuentes/ghcnm_v4"
salida  <- sprintf("data/equivalencia/privado/candidatas_temp_%d-%d.csv", inicio, fin)
salida_resumen <- sprintf("data/equivalencia/privado/resumen_temp_%d-%d.csv", inicio, fin)

# ---- 1. Descomprimir y ubicar el .dat y el .inv ----
untar(file.path(carpeta, "ghcnm.tavg.latest.qcu.tar.gz"), exdir = carpeta)
dat <- list.files(carpeta, pattern = "qcu\\.dat$", recursive = TRUE, full.names = TRUE)
inv <- list.files(carpeta, pattern = "qcu\\.inv$", recursive = TRUE, full.names = TRUE)
dat <- sort(dat, decreasing = TRUE)[1]           # la version mas reciente
inv <- sort(inv, decreasing = TRUE)[1]
cat("Archivo leido:", dat, "\n")

# ---- 2. Leer solo los anios del periodo (ancho fijo) ----
# Formato: ID(11) ANIO(4) ELEMENTO(4) y 12 bloques de VALOR(5) DMFLAG QCFLAG DSFLAG
lineas <- readLines(dat)
anio   <- as.integer(substr(lineas, 12, 15))
lineas <- lineas[anio >= inicio & anio <= fin]

id   <- substr(lineas, 1, 11)
anio <- as.integer(substr(lineas, 12, 15))
meses <- sapply(0:11, function(m) {
  ini   <- 20 + m * 8
  valor <- as.integer(substr(lineas, ini, ini + 4))
  qc    <- substr(lineas, ini + 6, ini + 6)
  ifelse(valor == -9999 | qc != " ", NA, valor / 100)   # centesimas de grado -> grados
})
temp_anual <- ifelse(rowSums(is.na(meses)) == 0, rowMeans(meses), NA)
estaciones <- data.frame(id = id, anio = anio, temp = temp_anual)
estaciones <- estaciones[!is.na(estaciones$temp), ]

# ---- 3. Comparar contra Develi anio por anio ----
develi <- read.csv("data/equivalencia/privado/develi_referencia_anual.csv")
develi <- develi[develi$anio >= inicio & develi$anio <= fin, c("anio", "temp")]
names(develi)[2] <- "temp_develi"

comp <- merge(estaciones, develi, by = "anio")
comp$dif_pct <- abs(comp$temp_develi - comp$temp) * 100 / comp$temp_develi

n_anios <- fin - inicio + 1
resumen <- data.frame(
  id            = names(tapply(comp$dif_pct, comp$id, length)),
  anios         = as.vector(tapply(comp$dif_pct, comp$id, length)),
  anios_sobre   = as.vector(tapply(comp$dif_pct > umbral, comp$id, sum)),
  dif_max_pct   = as.vector(tapply(comp$dif_pct, comp$id, max)),
  temp_media    = as.vector(tapply(comp$temp, comp$id, mean))
)
pasan <- resumen[resumen$anios >= min_anios & resumen$anios_sobre == 0, ]

# ---- 4. Agregar nombre y ubicacion (inventario) ----
lin_inv <- readLines(inv)
inventario <- data.frame(
  id     = substr(lin_inv, 1, 11),
  lat    = as.numeric(substr(lin_inv, 13, 20)),
  lon    = as.numeric(substr(lin_inv, 22, 30)),
  elev_m = as.numeric(substr(lin_inv, 32, 37)),
  nombre = trimws(substr(lin_inv, 39, 68))
)
pasan   <- merge(inventario, pasan, by = "id")
pasan   <- pasan[order(-pasan$anios, pasan$dif_max_pct), ]
resumen <- merge(inventario, resumen, by = "id")
resumen <- resumen[order(resumen$anios_sobre, -resumen$anios), ]

write.csv(pasan,   salida,         row.names = FALSE)
write.csv(resumen, salida_resumen, row.names = FALSE)

cat("Estaciones con datos en el periodo:", length(unique(estaciones$id)),
    "| con", min_anios, "o mas anios completos:", sum(resumen$anios >= min_anios),
    "| pasan temperatura:", nrow(pasan), "\n")
print(pasan[, c("id", "nombre", "lat", "lon", "anios", "dif_max_pct")], row.names = FALSE)
