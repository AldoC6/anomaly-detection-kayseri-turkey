# Precipitación mensual y número de pluviómetros - GPCC Full Data V2020 (0.25°)
# Reemplaza a PREC/L (ver equivalencia/descartados/precipitacion_precl.R).
# Descarga del servidor de DWD los archivos por década de GPCC a 0.25°, extrae
# las celdas de Develi y Kayseri (precipitación y número de estaciones) y guarda
# una tabla pequeña 1975-2007. Los archivos completos pesan ~270 MB por década
# (comprimidos) y no se suben a git.
#
# GPCC (Global Precipitation Climatology Centre, DWD) interpola pluviómetros que
# los servicios meteorológicos nacionales entregan directamente, además de los
# de la red OMM. La variable numgauge dice cuántas estaciones usó cada celda.
#
# Celdas (centro de la celda 0.25°):
#   DEVELI        38.375 N 35.625 E -> contiene la ubicación registrada de Develi
#                                      (38.4 N, 35.5 E en GHCN/GPCC) y su pluviómetro
#   DEVELI_PUEBLO 38.375 N 35.375 E -> contiene el pueblo (MGM 38.3744 N, 35.4797 E);
#                                      sin pluviómetro propio, solo de referencia
#   KAYSERI       38.875 N 35.375 E -> contiene Kayseri/Erkilet (38.7704 N, 35.4954 E)
#
# Fuente: Schneider, U., Becker, A., Finger, P., Rustemeier, E., Ziese, M. (2020).
# GPCC Full Data Monthly Product Version 2020 at 0.25°. DWD.
# https://doi.org/10.5676/DWD_GPCC/FD_M_V2020_025
# ============================================================

library(ncdf4)

base    <- "https://opendata.dwd.de/climate_environment/GPCC/full_data_monthly_v2020/025/"
decadas <- c("1971_1980", "1981_1990", "1991_2000", "2001_2010")
carpeta <- "data/equivalencia/fuentes/gpcc"          # pesado, no se sube a git
inicio  <- 1975
fin     <- 2007
salida  <- "data/equivalencia/procesados/precip_gpcc025_develi_kayseri_1975-2007.csv"

# Centros de celda 0.25° (se usan los centros para no depender de coordenadas en el borde)
celdas <- data.frame(
  estacion  = c("DEVELI", "DEVELI_PUEBLO", "KAYSERI"),
  celda_lat = c(38.375, 38.375, 38.875),
  celda_lon = c(35.625, 35.375, 35.375)
)

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
options(timeout = 3600)

# ---- 1. Descargar y descomprimir cada década (.nc.gz -> .nc) ----
descomprimir <- function(gz, destino) {
  ent <- gzfile(gz, "rb"); sal <- file(destino, "wb")
  repeat {
    b <- readBin(ent, "raw", 1e7)
    if (length(b) == 0) break
    writeBin(b, sal)
  }
  close(ent); close(sal)
}

archivos_nc <- sapply(decadas, function(d) {
  nombre <- paste0("full_data_monthly_v2020_", d, "_025.nc")
  nc_loc <- file.path(carpeta, nombre)
  if (!file.exists(nc_loc)) {
    gz_loc <- paste0(nc_loc, ".gz")
    if (!file.exists(gz_loc)) download.file(paste0(base, nombre, ".gz"), gz_loc, mode = "wb")
    descomprimir(gz_loc, nc_loc)
  }
  nc_loc
})

# ---- 2. Leer solo las celdas elegidas (sin cargar el mundo entero) ----
leer_celdas <- function(archivo) {
  nc  <- nc_open(archivo)
  lat <- ncvar_get(nc, "lat")
  lon <- ncvar_get(nc, "lon")
  tie <- ncvar_get(nc, "time")
  u   <- ncatt_get(nc, "time", "units")$value          # p. ej. "hours since 1991-1-1 00:00:00"
  origen <- as.POSIXct(sub(".*since ", "", u), tz = "UTC")
  paso   <- if (grepl("^hours", u)) 3600 else 86400
  fecha  <- as.Date(origen + tie * paso)

  res <- do.call(rbind, lapply(seq_len(nrow(celdas)), function(k) {
    j <- which.min(abs(lon - celdas$celda_lon[k]))
    i <- which.min(abs(lat - celdas$celda_lat[k]))
    leer <- function(v) ncvar_get(nc, v, start = c(j, i, 1), count = c(1, 1, -1))
    data.frame(
      estacion     = celdas$estacion[k],
      celda_lat    = lat[i],
      celda_lon    = lon[j],
      anio         = as.integer(format(fecha, "%Y")),
      mes          = as.integer(format(fecha, "%m")),
      precip_mm    = round(leer("precip"), 1),
      pluviometros = leer("numgauge")
    )
  }))
  nc_close(nc)
  res
}

mensual <- do.call(rbind, lapply(archivos_nc, leer_celdas))
mensual <- mensual[mensual$anio >= inicio & mensual$anio <= fin, ]
mensual <- mensual[order(mensual$estacion, mensual$anio, mensual$mes), ]
rownames(mensual) <- NULL

# ---- 3. Revisión ----
cat("Meses:", nrow(mensual), "| faltantes:", sum(is.na(mensual$precip_mm)), "\n")
for (e in celdas$estacion) {
  d <- mensual[mensual$estacion == e, ]
  cat("\n", e, "- celda", d$celda_lat[1], "N", d$celda_lon[1], "E\n")
  anual <- aggregate(precip_mm ~ anio, data = d, FUN = mean)   # media mensual por año
  cat("  Media mensual por año:", round(mean(anual$precip_mm), 2),
      "± DE", round(sd(anual$precip_mm), 2), "mm/mes\n")
  g <- aggregate(pluviometros ~ anio, data = d, FUN = mean)
  cat("  Pluviómetros promedio por año:\n")
  print(setNames(round(g$pluviometros, 1), g$anio))
  cat("  Meses sin pluviómetro:", sum(d$pluviometros == 0), "de", nrow(d), "\n")
}

write.csv(mensual, salida, row.names = FALSE)
