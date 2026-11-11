# Precipitacion mensual del Aeropuerto de Kayseri (Erkilet) - NOAA GHCN-M v4
# Lee el CSV de la estacion TUMLP017196, deja 1975-2007 y lo guarda en Excel.
# Los meses que no vienen en el archivo quedan como NA.
#
# Fuente: Menne, M. J., et al. (2018). Global Historical Climatology Network -
# Monthly (GHCN-M), Version 4. NOAA NCEI. https://doi.org/10.7289/V5XW4GTH
# Requiere: install.packages("writexl")
# ============================================================

entrada <- "data/equivalencia/fuentes/ghcnm_v4_prcp_TUMLP017196.csv"
salida  <- "data/equivalencia/procesados/kayseri_precip_ghcnm_v4_1975-2007.csv"

# ---- 1. Leer (el archivo no trae encabezados) ----
prcp <- read.csv(entrada, header = FALSE, strip.white = TRUE,
                 col.names = c("id", "nombre", "lat", "lon", "elev", "fecha",
                               "valor", "mflag", "qflag", "sflag", "extra"))

prcp$anio      <- prcp$fecha %/% 100
prcp$mes       <- prcp$fecha %% 100
prcp$precip_mm <- prcp$valor / 10          # viene en decimas de mm

# ---- 2. Tabla completa 1975-2007 (los meses faltantes quedan en NA) ----
todos <- expand.grid(mes = 1:12, anio = 1975:2007)
kayseri <- merge(todos, prcp[, c("anio", "mes", "precip_mm")],
                 by = c("anio", "mes"), all.x = TRUE)
kayseri <- kayseri[order(kayseri$anio, kayseri$mes), ]

cat("Meses:", nrow(kayseri), "| sin dato:", sum(is.na(kayseri$precip_mm)), "\n")

# ---- 3. Guardar ----
write.csv(kayseri, salida, row.names = FALSE)
