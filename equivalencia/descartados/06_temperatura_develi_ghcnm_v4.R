# Temperatura media mensual de Develi - NOAA GHCN-Monthly v4 (archivo qfe)
# Descarga el paquete "latest" de GHCN-M v4 temperatura, extrae la estación
# DEVELI (TUXLT848934) y guarda la serie mensual 1975-2007 en °C.
#
# Fuente: Menne, M. J., et al. (2018). Global Historical Climatology Network -
# Monthly (GHCN-M), Version 4. NOAA NCEI. https://doi.org/10.7289/V5XW4GTH
# ============================================================

url      <- "https://www.ncei.noaa.gov/pub/data/ghcn/v4/ghcnm.tavg.latest.qfe.tar.gz"
carpeta  <- "data/equivalencia/fuentes/ghcnm_v4"   # pesado, no se sube a git
estacion <- "TUXLT848934"                           # DEVELI, 38.4 N 35.5 E, 1180 m
inicio   <- 1975
fin      <- 2007
salida   <- "data/equivalencia/procesados/develi_tavg_ghcnm_v4_qfe_1975-2007.csv"

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Descargar y descomprimir ----
destino <- file.path(carpeta, basename(url))
if (!file.exists(destino)) {
  options(timeout = 600)                            # el archivo pesa decenas de MB
  download.file(url, destino, mode = "wb")
}
untar(destino, exdir = carpeta)

# El paquete trae una carpeta ghcnm.v4.0.1.AAAAMMDD con el .dat y el .inv
archivo_dat <- list.files(carpeta, pattern = "qfe\\.dat$",
                          recursive = TRUE, full.names = TRUE)[1]
cat("Archivo leído:", archivo_dat, "\n")

# ---- 2. Leer solo las líneas de Develi (ancho fijo) ----
lineas <- readLines(archivo_dat)
lineas <- lineas[substr(lineas, 1, 11) == estacion]

# Formato: ID(11) AÑO(4) ELEMENTO(4) y 12 bloques de VALOR(5) DMFLAG(1) QCFLAG(1) DSFLAG(1)
meses   <- sprintf("%02d", 1:12)
anchos  <- c(11, 4, 4, rep(c(5, 1, 1, 1), 12))
nombres <- c("id", "anio", "elemento",
             as.vector(t(outer(meses, c("valor", "dm", "qc", "ds"),
                               function(m, v) paste0(v, "_", m)))))
tavg <- read.fwf(textConnection(lineas), widths = anchos, col.names = nombres,
                 colClasses = "character", strip.white = FALSE)

# ---- 3. Pasar a una fila por mes ----
mensual <- do.call(rbind, lapply(1:12, function(m) {
  mm <- sprintf("%02d", m)
  data.frame(
    estacion     = "DEVELI",
    ghcn_id      = estacion,
    anio         = as.integer(tavg$anio),
    mes          = m,
    valor        = as.integer(tavg[[paste0("valor_", mm)]]),
    dmflag       = trimws(tavg[[paste0("dm_", mm)]])
  )
}))

mensual$temp_media_c <- ifelse(mensual$valor == -9999, NA, mensual$valor / 100)

mensual <- mensual[mensual$anio >= inicio & mensual$anio <= fin, ]
mensual <- mensual[order(mensual$anio, mensual$mes),
                   c("estacion", "ghcn_id", "anio", "mes", "temp_media_c")]

# ---- 4. Revisión ----
cat("Meses:", nrow(mensual), "| faltantes:", sum(is.na(mensual$temp_media_c)), "\n")
print(table(mensual))
anual <- aggregate(temp_media_c ~ anio, data = mensual, FUN = mean)
cat("Media anual", inicio, "-", fin, ":", round(mean(anual$temp_media_c), 2),
    "± DE", round(sd(anual$temp_media_c), 2), "°C\n")

write.csv(mensual, salida, row.names = FALSE)
