# Paso 15: temperatura cruda de Develi en GHCN-M v4 (qcu)
# Extrae la temperatura media mensual de la estacion DEVELI (TUXLT848934,
# 38.40 N, 35.50 E, 1180 m) del archivo qcu de GHCN-M v4.
#   - qcu: datos crudos (sin ajuste de homogeneidad ni estimaciones de NOAA).
#     Sirve para validar los datos de Develi recibidos por correo
#     (Dra. Filiz Dadaser-Celik y Prof. Dra. Turkan Bayer Altin).
# Formato del .dat (ancho fijo, ver readme de GHCN-M v4):
#   ID 1-11 | ANIO 12-15 | ELEMENTO 16-19 | 12 bloques de 8 caracteres:
#   VALOR (5, centesimas de grado C, -9999 = faltante) DMFLAG QCFLAG DSFLAG
#   DSFLAG "_" = fuente ISTI "russsource-ghcn".
# Un mes con bandera de calidad (QCFLAG distinto de vacio) se conserva pero se
# marca, para decidir despues si usarlo.
# Todo es dato publico de NOAA, por eso la salida va en procesados/.
# Fuente: Menne, M. J., et al. (2018). GHCN-Monthly Version 4. NOAA NCEI.
#         https://doi.org/10.7289/V5XW4GTH
# Entrada: fuentes/ghcnm_v4/**/*qcu.dat
# Salida:  procesados/develi_tavg_ghcnm_v4_qcu.csv
# ============================================================

id_develi <- "TUXLT848934"
carpeta   <- "data/equivalencia/fuentes/ghcnm_v4"
salida    <- "data/equivalencia/procesados/develi_tavg_ghcnm_v4_qcu.csv"

# ---- 1. Localizar el archivo qcu ----
archivo <- list.files(carpeta, pattern = "qcu\\.dat$", recursive = TRUE, full.names = TRUE)
if (length(archivo) == 0) stop("No se encontro ningun *qcu.dat en ", carpeta)
archivo <- sort(archivo, decreasing = TRUE)[1]       # el mas reciente
cat("Leyendo:", archivo, "\n")

# ---- 2. Leer solo las lineas de Develi (el archivo pesa ~170 MB) ----
lineas <- readLines(archivo)
lineas <- lineas[startsWith(lineas, id_develi)]
if (length(lineas) == 0) stop("La estacion ", id_develi, " no esta en el archivo")

# ---- 3. Separar los 12 meses de cada anio ----
develi <- do.call(rbind, lapply(lineas, function(l) {
  anio <- as.integer(substr(l, 12, 15))
  do.call(rbind, lapply(1:12, function(m) {
    ini <- 20 + (m - 1) * 8
    valor <- as.integer(substr(l, ini, ini + 4))
    data.frame(
      Anio   = anio,
      Mes    = m,
      Temp_mensual = ifelse(valor == -9999, NA, valor / 100),
      DMFLAG = trimws(substr(l, ini + 5, ini + 5)),
      QCFLAG = trimws(substr(l, ini + 6, ini + 6)),
      DSFLAG = trimws(substr(l, ini + 7, ini + 7))
    )
  }))
}))
develi <- develi[order(develi$Anio, develi$Mes), ]
rownames(develi) <- NULL

# ---- 4. Resumen ----
cat("Anios:", min(develi$Anio), "-", max(develi$Anio),
    "| meses con dato:", sum(!is.na(develi$Temp_mensual)),
    "| con bandera QC:", sum(develi$QCFLAG != "" & !is.na(develi$Temp_mensual)), "\n")
print(head(develi, 12))

# ---- 5. Exportar ----
dir.create(dirname(salida), showWarnings = FALSE, recursive = TRUE)
write.csv(develi, salida, row.names = FALSE)
cat("Guardado en", salida, "\n")
