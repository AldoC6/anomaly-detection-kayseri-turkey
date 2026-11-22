# Candidatas - Paso 2: precipitacion de las 4 candidatas y de Develi (GHCN-M v4)
# Extrae la precipitacion mensual y anual de:
#   Nigde    TUM00017250   (ojo: en precipitacion NOAA la nombra "ULUKISLA")
#   Kirsehir TUM00017160
#   Konya    TUM00017244
#   Afyon    TUM00017190
#   Develi   TUXLP331235
# GHCN-M v4 de precipitacion tiene una sola version (no hay qcu/qcf/qfe ni
# estimaciones): lo que viene es lo reportado, con banderas de calidad.
#   - Un mes con bandera de calidad (columna 9) o -9999 cuenta como faltante.
#   - -1 = traza; se toma como 0 mm.
#   - Un anio solo tiene total anual si tiene sus 12 meses.
# Todo es dato publico de NOAA, por eso las salidas van en procesados/.
# Fuente: Menne, M. J., et al. (2025). GHCN-Monthly Version 4 Precipitation. NOAA NCEI.
#         https://www.ncei.noaa.gov/products/land-based-station/global-historical-climatology-network-monthly
# Entrada:  fuentes/ghcnm_v4/prcp/csv/<ID>.csv   (descomprimido en filtro_ghcnm_v4/09)
# Salidas:  procesados/candidatas/precip_candidatas_mensual_<inicio>-<fin>.csv
#           procesados/candidatas/precip_candidatas_anual_<inicio>-<fin>.csv
#           procesados/candidatas/precip_candidatas_resumen_<inicio>-<fin>.csv
# ============================================================

inicio  <- 1975                # periodo del paper
fin     <- 2007
carpeta <- "data/equivalencia/fuentes/ghcnm_v4/prcp"
dir_sal <- "data/equivalencia/procesados/candidatas"
dir.create(dir_sal, showWarnings = FALSE, recursive = TRUE)

estaciones <- data.frame(
  id     = c("TUM00017250", "TUM00017160", "TUM00017244", "TUM00017190", "TUXLP331235"),
  nombre = c("NIGDE", "KIRSEHIR", "KONYA", "AFYON", "DEVELI")
)

# ---- 1. Descomprimir si hace falta (una sola vez) ----
dir_csv <- file.path(carpeta, "csv")
if (!dir.exists(dir_csv))
  untar(list.files(carpeta, pattern = "\\.tar\\.gz$", full.names = TRUE)[1], exdir = dir_csv)

# ---- 2. Leer cada estacion ----
# Columnas: ID, nombre, lat, lon, elev, AAAAMM, valor (decimas de mm),
#           bandera de medicion, bandera de calidad, fuente, id de fuente
leer <- function(id, nombre) {
  archivo <- file.path(dir_csv, paste0(id, ".csv"))
  if (!file.exists(archivo)) stop("No se encontro ", archivo)
  x <- read.csv(archivo, header = FALSE, strip.white = TRUE,
                colClasses = c("character", "character", "numeric", "numeric", "numeric",
                               "integer", "integer", "character", "character",
                               "character", "character"))
  cat(sprintf("%-9s %s  nombre NOAA: %-10s lat %.2f lon %.2f elev %.0f m\n",
              nombre, id, x$V2[1], x$V3[1], x$V4[1], x$V5[1]))
  x <- data.frame(anio = x$V6 %/% 100, mes = x$V6 %% 100,
                  valor = x$V7, qcflag = x$V9)
  x <- x[x$anio >= inicio & x$anio <= fin, ]
  x$precip <- ifelse(x$valor == -9999 | x$qcflag != "", NA, pmax(x$valor, 0) / 10)
  base <- expand.grid(mes = 1:12, anio = inicio:fin)
  d <- merge(base, x[, c("anio", "mes", "precip", "qcflag")], by = c("anio", "mes"), all.x = TRUE)
  data.frame(id = id, nombre = nombre, d[order(d$anio, d$mes), ])
}
mensual <- do.call(rbind, Map(leer, estaciones$id, estaciones$nombre))
rownames(mensual) <- NULL

# ---- 3. Total anual (solo con los 12 meses) ----
suma12 <- function(x) if (sum(!is.na(x)) == 12) round(sum(x), 1) else NA
anual <- aggregate(precip ~ id + nombre + anio, data = mensual,
                   FUN = suma12, na.action = na.pass)
names(anual)[4] <- "precip_anual"
anual$meses_con_dato <- aggregate(precip ~ id + anio, data = mensual,
                                  FUN = function(x) sum(!is.na(x)), na.action = na.pass)$precip
anual <- anual[order(match(anual$id, estaciones$id), anual$anio), ]

# ---- 4. Resumen por estacion ----
resumen <- do.call(rbind, lapply(estaciones$id, function(i) {
  g <- mensual[mensual$id == i, ]
  a <- anual[anual$id == i, ]
  f <- g[is.na(g$precip), ]
  data.frame(id = i, nombre = g$nombre[1],
             anios_completos = sum(!is.na(a$precip_anual)),
             meses_faltantes = nrow(f),
             media_anual = round(mean(a$precip_anual, na.rm = TRUE), 1),
             de_anual    = round(sd(a$precip_anual, na.rm = TRUE), 1),
             lista_faltantes = if (nrow(f) == 0) "ninguno" else
               paste(sprintf("%d-%02d", f$anio, f$mes), collapse = " "))
}))

# ---- 5. Guardar ----
sufijo <- paste0(inicio, "-", fin, ".csv")
write.csv(mensual, file.path(dir_sal, paste0("precip_candidatas_mensual_", sufijo)), row.names = FALSE)
write.csv(anual,   file.path(dir_sal, paste0("precip_candidatas_anual_",   sufijo)), row.names = FALSE)
write.csv(resumen, file.path(dir_sal, paste0("precip_candidatas_resumen_", sufijo)), row.names = FALSE)

cat("\n"); print(resumen[, -7], row.names = FALSE)
cat("\nMeses faltantes:\n")
for (i in seq_len(nrow(resumen))) cat(" ", resumen$nombre[i], ":", resumen$lista_faltantes[i], "\n")
cat("\nGuardado en", dir_sal, "\n")
