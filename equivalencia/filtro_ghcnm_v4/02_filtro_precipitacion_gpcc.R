# Filtro Monthly v4 - Paso 2: precipitacion en malla (GPCC) de las candidatas del paso 1
# Compara la precipitacion anual de la celda de Develi con la celda de cada
# estacion que paso el filtro de temperatura, con el criterio del docente:
#   |Develi - estacion| * 100 / Develi <= 10 %   en cada anio del periodo
#   - GPCC es una malla interpolada de pluviometros (no la medicion de la
#     estacion): se usa porque NOAA no tiene precipitacion de Develi despues de 1990.
#   - Celda de Develi: la misma del paso 7 (38.375 N, 35.625 E), que contiene la
#     coordenada registrada de la estacion y su pluviometro.
#   - Cada candidata usa la celda que contiene su coordenada de GHCN-M v4.
#   - Tambien se evalua el criterio con la media y la DE de los totales anuales
#     del periodo (asi se evaluo la temperatura el 30/10).
# Todo es dato publico, por eso la salida va en procesados/.
# Fuente: Schneider, U., et al. (2020). GPCC Full Data Monthly Product Version 2020
#         at 0.25°. DWD. https://doi.org/10.5676/DWD_GPCC/FD_M_V2020_025
# Requiere: los .nc de GPCC en fuentes/gpcc/ (se descargan corriendo el paso 7)
# Entrada: procesados/filtro_ghcnm_v4/temp_qfe_candidatas_<inicio>-<fin>.csv (paso 1)
# Salida:  procesados/filtro_ghcnm_v4/precip_gpcc_resumen_<inicio>-<fin>.csv
# ============================================================

library(ncdf4)

inicio  <- 1975
fin     <- 2007
umbral  <- 10                                   # % maximo de diferencia por anio
carpeta <- "data/equivalencia/fuentes/gpcc"
dir_sal <- "data/equivalencia/procesados/filtro_ghcnm_v4"

candidatas <- read.csv(file.path(dir_sal, sprintf("temp_qfe_candidatas_%d-%d.csv", inicio, fin)))
celdas <- rbind(
  data.frame(id = "DEVELI", nombre = "DEVELI", lat = 38.375, lon = 35.625),
  candidatas[, c("id", "nombre", "lat", "lon")]
)

# ---- 1. Precipitacion mensual de cada celda (un archivo por decada) ----
archivos <- list.files(carpeta, pattern = "_025\\.nc$", full.names = TRUE)
if (length(archivos) == 0) stop("No hay archivos .nc en ", carpeta, ": corre primero el paso 7")

leer_celdas <- function(archivo) {
  nc  <- nc_open(archivo)
  lat <- ncvar_get(nc, "lat")
  lon <- ncvar_get(nc, "lon")
  tie <- ncvar_get(nc, "time")
  u   <- ncatt_get(nc, "time", "units")$value
  origen <- as.POSIXct(sub(".*since ", "", u), tz = "UTC")
  paso   <- if (grepl("^hours", u)) 3600 else 86400
  anio   <- as.integer(format(as.Date(origen + tie * paso), "%Y"))

  res <- do.call(rbind, lapply(seq_len(nrow(celdas)), function(k) {
    j <- which.min(abs(lon - celdas$lon[k]))
    i <- which.min(abs(lat - celdas$lat[k]))
    data.frame(id = celdas$id[k], anio = anio,
               precip = ncvar_get(nc, "precip", start = c(j, i, 1), count = c(1, 1, -1)))
  }))
  nc_close(nc)
  res
}
mensual <- do.call(rbind, lapply(archivos, leer_celdas))
mensual <- mensual[mensual$anio >= inicio & mensual$anio <= fin, ]

# ---- 2. Total anual (solo anios con los 12 meses) ----
anual <- aggregate(precip ~ id + anio, data = mensual, FUN = function(x) if (length(x) == 12) sum(x) else NA)
anual <- anual[!is.na(anual$precip), ]

# ---- 3. Comparar contra Develi anio por anio ----
develi <- anual[anual$id == "DEVELI", c("anio", "precip")]
names(develi)[2] <- "precip_develi"
comp <- merge(anual[anual$id != "DEVELI", ], develi, by = "anio")
comp$dif_pct <- abs(comp$precip_develi - comp$precip) * 100 / comp$precip_develi

resumen <- data.frame(
  id          = names(tapply(comp$dif_pct, comp$id, length)),
  anios       = as.vector(tapply(comp$dif_pct, comp$id, length)),
  anios_sobre = as.vector(tapply(comp$dif_pct > umbral, comp$id, sum)),
  dif_max_pct = as.vector(tapply(comp$dif_pct, comp$id, max))
)
resumen <- merge(candidatas[, c("id", "nombre", "dist_km")], resumen, by = "id")

# ---- 4. Criterio de media y desviacion estandar del periodo ----
# Mismo % del docente, aplicado a la media y a la DE de los totales anuales.
media <- tapply(anual$precip, anual$id, mean)
de    <- tapply(anual$precip, anual$id, sd)
resumen$dif_media_pct <- abs(media["DEVELI"] - media[resumen$id]) * 100 / media["DEVELI"]
resumen$dif_de_pct    <- abs(de["DEVELI"] - de[resumen$id]) * 100 / de["DEVELI"]
resumen$pasa_media_de <- resumen$dif_media_pct <= umbral & resumen$dif_de_pct <= umbral
resumen <- resumen[order(resumen$anios_sobre, resumen$dist_km), ]

write.csv(resumen, file.path(dir_sal, sprintf("precip_gpcc_resumen_%d-%d.csv", inicio, fin)), row.names = FALSE)

cat("Pasan precipitacion anio por anio (0 anios >", umbral, "%):", sum(resumen$anios_sobre == 0), "de", nrow(resumen), "\n")
cat("Pasan precipitacion por media y DE (<=", umbral, "%):", sum(resumen$pasa_media_de), "de", nrow(resumen), "\n")
print(resumen, row.names = FALSE, digits = 3)
