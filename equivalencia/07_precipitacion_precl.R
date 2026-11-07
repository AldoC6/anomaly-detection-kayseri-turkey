# Precipitación mensual de Develi y Kayseri - NOAA PREC/L (malla 0.5°)
# Descarga con el servicio NetcdfSubset de NOAA PSL solo la zona de Kayseri
# (4 celdas alrededor de Develi y Kayseri) para 1975-2007, extrae la celda de
# cada estación y guarda la precipitación mensual en mm.
#
#
# Fuente: Chen, M., P. Xie, J. E. Janowiak, and P. A. Arkin, 2002: Global Land
# Precipitation: A 50-yr Monthly Analysis Based on Gauge Observations.
# J. Hydrometeorology, 3, 249-266. https://psl.noaa.gov/data/gridded/data.precl.html
# ============================================================

library(ncdf4)

base    <- "https://psl.noaa.gov/thredds/ncss/grid/Datasets/precl/0.5deg/"
caja    <- "&north=39.0&west=35.0&east=36.0&south=38.0&horizStride=1"
fechas  <- "&time_start=1975-01-01T00:00:00Z&time_end=2007-12-01T00:00:00Z"
archivos <- c(
  precip       = "precip.mon.mean.0.5x0.5.nc"
)
carpeta <- "data/equivalencia/fuentes/precl"
salida  <- "data/equivalencia/procesados/precip_precl_develi_kayseri_1975-2007.csv"

# Celda 0.5° que contiene a cada estación (centro de la celda)
celdas <- data.frame(
  estacion  = c("DEVELI", "KAYSERI"),
  celda_lat = c(38.3833, 38.7704),  
  celda_lon = c(35.5, 35.4954)    
)

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Descargar el recorte de la zona (pesa unos KB) ----
for (a in archivos) {
  destino <- file.path(carpeta, sub("\\.nc$", "_kayseri_1975-2007.nc", a))
  if (!file.exists(destino)) {
    url <- paste0(base, a, "?var=precip", caja, fechas, "&accept=netcdf3")
    download.file(url, destino, mode = "wb")
  }
}

# ---- 2. Leer un archivo y regresar la serie de una celda ----
leer_celda <- function(archivo, la, lo) {
  nc  <- nc_open(file.path(carpeta, sub("\\.nc$", "_kayseri_1975-2007.nc", archivo)))
  lat <- ncvar_get(nc, "lat")
  lon <- ncvar_get(nc, "lon")
  tie <- ncvar_get(nc, "time")                       # horas desde 1800-01-01
  val <- ncvar_get(nc, "precip")                     # arreglo [lon, lat, time]
  nc_close(nc)
  fecha <- as.Date(as.POSIXct(tie * 3600, origin = "1800-01-01", tz = "UTC"))
  data.frame(
    anio  = as.integer(format(fecha, "%Y")),
    mes   = as.integer(format(fecha, "%m")),
    valor = val[which.min(abs(lon - lo)), which.min(abs(lat - la)), ]
  )
}

# ---- 3. Armar la tabla mensual por estación ----
mensual <- do.call(rbind, lapply(seq_len(nrow(celdas)), function(i) {
  c_i <- celdas[i, ]
  p <- leer_celda(archivos["precip"],       c_i$celda_lat, c_i$celda_lon)
  # días del mes: último día del mes = primer día del mes siguiente - 1
  sig  <- as.Date(sprintf("%d-%02d-01", p$anio + (p$mes == 12),
                          ifelse(p$mes == 12, 1, p$mes + 1)))
  dias <- as.integer(format(sig - 1, "%d"))
  data.frame(
    estacion     = c_i$estacion,
    celda_lat    = c_i$celda_lat,
    celda_lon    = c_i$celda_lon,
    anio         = p$anio,
    mes          = p$mes,
    precip_mm    = round(p$valor * dias, 1)
  )
}))

# ---- 4. Revisión ----
cat("Meses:", nrow(mensual), "| faltantes:", sum(is.na(mensual$precip_mm)), "\n")
for (e in celdas$estacion) {
  d <- mensual[mensual$estacion == e, ]
  anual <- aggregate(precip_mm ~ anio, data = d, FUN = mean)   # media mensual por año
  cat(e, ": media mensual por año", round(mean(anual$precip_mm), 2),
      "± DE", round(sd(anual$precip_mm), 2), "mm/mes\n")
}

write.csv(mensual, salida, row.names = FALSE)
