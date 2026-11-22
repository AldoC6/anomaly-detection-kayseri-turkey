# Filtro Monthly v4 - Paso 8: todas las celdas de GPCC del mundo contra Develi
# Compara la precipitacion anual de cada celda de la malla GPCC 0.25 (todo el mundo)
# contra la precipitacion MEDIDA de Develi (MGM), con el criterio del docente:
#   |Develi - celda| * 100 / Develi <= 10 %   en cada anio
# y calcula dos cosas por celda:
#   1. En 1975-2007: cuantos anios se pueden comparar y cuantos superan el 10 %.
#   2. En todos los anios que cubren los archivos de GPCC y Develi (1971-2010 con las
#      cuatro decadas descargadas): la racha mas larga de anios SEGUIDOS que cumplen
#      (para ver si cambiando el periodo aparece alguna celda equivalente).
#   - Total anual = suma de los 12 meses; si falta un mes, ese anio no cuenta y corta
#     la racha.
#   - Se lee un anio a la vez (12 meses de todo el mundo) para no llenar la memoria.
# Usa la precipitacion de Develi (uso restringido): la salida va en privado/.
# Fuente: Schneider, U., et al. (2020). GPCC Full Data Monthly Product V2020 at 0.25.
#         https://doi.org/10.5676/DWD_GPCC/FD_M_V2020_025
# Entradas: fuentes/gpcc/*_025.nc (paso 7 del flujo principal)
#           privado/develi_referencia_anual.csv (paso 9; precip = media de 12 meses)
# Salida:   privado/filtro_precipitacion_celdas_gpcc.csv (las mejores celdas)
# ============================================================

library(ncdf4)

inicio <- 1975                     # periodo del paper (para el conteo 1)
fin    <- 2007
umbral <- 10
top    <- 50                       # celdas a guardar
salida <- "data/equivalencia/privado/filtro_precipitacion_celdas_gpcc.csv"

# ---- 1. Precipitacion anual medida de Develi (todo su periodo) ----
develi <- read.csv("data/equivalencia/privado/develi_referencia_anual.csv")
develi <- develi[!is.na(develi$precip), ]
p_develi <- setNames(develi$precip * 12, develi$anio)   # media mensual -> total anual

# ---- 2. Recorrer los anios en orden ----
archivos <- sort(list.files("data/equivalencia/fuentes/gpcc", pattern = "_025\\.nc$", full.names = TRUE))
n <- NULL
anio_previo <- NA

for (archivo in archivos) {
  nc  <- nc_open(archivo)
  lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); tie <- ncvar_get(nc, "time")
  u   <- ncatt_get(nc, "time", "units")$value
  anio <- as.integer(format(as.Date(as.POSIXct(sub(".*since ", "", u), tz = "UTC") +
                    tie * (if (grepl("^hours", u)) 3600 else 86400)), "%Y"))
  if (is.null(n)) {
    n <- length(lon) * length(lat)
    anios_comp <- integer(n); fallas <- integer(n)     # conteo 1975-2007
    racha <- integer(n); racha_max <- integer(n); racha_fin <- integer(n)
  }
  for (a in sort(intersect(unique(anio), as.integer(names(p_develi))))) {
    idx <- which(anio == a)
    if (length(idx) != 12) next
    if (!is.na(anio_previo) && a != anio_previo + 1) racha[] <- 0L   # hueco de anios
    anio_previo <- a

    x <- ncvar_get(nc, "precip", start = c(1, 1, idx[1]), count = c(-1, -1, 12))
    dim(x) <- c(n, 12)
    total  <- rowSums(x)                          # NA si falta algun mes (o es mar)
    pct    <- abs(p_develi[as.character(a)] - total) * 100 / p_develi[as.character(a)]
    cumple <- !is.na(pct) & pct <= umbral

    # Conteo en el periodo del paper
    if (a >= inicio && a <= fin) {
      ok <- !is.na(pct)
      anios_comp[ok] <- anios_comp[ok] + 1L
      fallas[ok]     <- fallas[ok] + (pct[ok] > umbral)
    }
    # Racha de anios seguidos que cumplen
    racha <- ifelse(cumple, racha + 1L, 0L)
    nueva <- racha > racha_max
    racha_max[nueva] <- racha[nueva]
    racha_fin[nueva] <- a
    cat(a, "listo\n")
  }
  nc_close(nc)
}

# ---- 3. Resultados ----
celdas <- expand.grid(lon = lon, lat = lat)      # mismo orden que las filas de x
celdas$anios        <- anios_comp
celdas$anios_sobre  <- fallas
celdas$racha_max    <- racha_max
celdas$racha_inicio <- ifelse(racha_max > 0, racha_fin - racha_max + 1L, NA)
celdas$racha_fin    <- ifelse(racha_max > 0, racha_fin, NA)
celdas <- celdas[celdas$anios > 0, ]

cat("\nCeldas de tierra evaluadas:", nrow(celdas), "\n")
cat("\n", inicio, "-", fin, ": celdas sin ningun anio fuera del 10 %\n", sep = "")
for (m in c(fin - inicio + 1, 30, 25, 20, 15, 10)) {
  cat("  con >=", m, "anios:", sum(celdas$anios >= m & celdas$anios_sobre == 0), "\n")
}
cat("\nRacha mas larga de anios seguidos que cumplen:\n")
print(table(celdas$racha_max[celdas$racha_max > 0]))

mejores <- head(celdas[order(-celdas$racha_max, celdas$anios_sobre), ], top)
write.csv(mejores, salida, row.names = FALSE)
cat("\nLas 20 celdas con la racha mas larga:\n")
print(head(mejores, 20), row.names = FALSE)
