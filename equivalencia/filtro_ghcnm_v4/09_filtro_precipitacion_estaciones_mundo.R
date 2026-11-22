# Filtro Monthly v4 - Paso 9: precipitacion de todas las estaciones del mundo contra Develi
# Compara la precipitacion anual MEDIDA de Develi (MGM) contra la de cada estacion de
# GHCN-M v4 (precipitacion medida, ~128 mil estaciones), con el criterio del docente:
#   |Develi - estacion| * 100 / Develi <= 10 %   en cada anio
# y calcula dos cosas por estacion:
#   1. En 1975-2007: cuantos anios se pueden comparar y cuantos superan el 10 %.
#   2. En todo el periodo medido de Develi: la racha mas larga de anios SEGUIDOS que
#      cumplen (para ver si cambiando el periodo aparece alguna equivalente).
#   - Total anual = suma de los 12 meses; si falta un mes o tiene bandera de calidad,
#     ese anio no cuenta. La traza (-1) se toma como 0.
# Usa la precipitacion de Develi (uso restringido): la salida va en pr ivado/.
# Fuente: Applequist, S., Durre, I., & Vose, R. (2024). GHCN-M Precipitation v4.
#         https://doi.org/10.25921/67zp-5m03
# Entradas: fuentes/ghcnm_v4/prcp/ghcn-m_v4.00.00_prcp_*.tar.gz
#           privado/develi_referencia_anual.csv (paso 9; precip = media de 12 meses)
# Salida:   privado/filtro_precipitacion_estaciones_mundo.csv
# ============================================================

inicio <- 1975
fin    <- 2007
umbral <- 10
min_anios <- 10
carpeta <- "data/equivalencia/fuentes/ghcnm_v4/prcp"
salida  <- "data/equivalencia/privado/filtro_precipitacion_estaciones_mundo.csv"

# ---- 1. Precipitacion anual medida de Develi (todo su periodo) ----
develi <- read.csv("data/equivalencia/privado/develi_referencia_anual.csv")
develi <- develi[!is.na(develi$precip), ]
p_develi <- setNames(develi$precip * 12, develi$anio)   # media mensual -> total anual
anios_develi <- as.integer(names(p_develi))

# ---- 2. Descomprimir una sola vez (~128 mil CSV, uno por estacion) ----
dir_csv <- file.path(carpeta, "csv")
if (!dir.exists(dir_csv)) {
  untar(list.files(carpeta, pattern = "\\.tar\\.gz$", full.names = TRUE)[1], exdir = dir_csv)
}
archivos <- list.files(dir_csv, pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
cat("Estaciones:", length(archivos), "\n")

# ---- 3. Una estacion: totales anuales, anios que cumplen y racha mas larga ----
evaluar <- function(archivo) {
  x <- tryCatch(read.csv(archivo, header = FALSE, strip.white = TRUE,
                         colClasses = c("character", "character", "numeric", "numeric", "numeric",
                                        "integer", "integer", "character", "character",
                                        "character", "character")),
                error = function(e) NULL)
  if (is.null(x) || nrow(x) == 0) return(NULL)
  x$anio <- x$V6 %/% 100
  x <- x[x$anio %in% anios_develi & !is.na(x$V7) & x$V7 != -9999 & x$V9 == "", ]
  if (nrow(x) == 0) return(NULL)
  x$mm <- pmax(x$V7, 0) / 10                       # decimas de mm -> mm (traza = 0)
  meses <- tapply(x$mm, x$anio, length)
  total <- tapply(x$mm, x$anio, sum)[meses == 12]
  if (length(total) == 0) return(NULL)
  anios <- as.integer(names(total))
  cumple <- abs(p_develi[as.character(anios)] - total) * 100 / p_develi[as.character(anios)] <= umbral

  # Racha mas larga de anios seguidos que cumplen
  ok <- anios_develi %in% anios[cumple]
  r <- rle(ok)
  largo <- ifelse(any(r$values), max(r$lengths[r$values]), 0)
  fin_racha <- if (largo > 0) anios_develi[cumsum(r$lengths)[r$values & r$lengths == largo][1]] else NA

  periodo <- anios >= inicio & anios <= fin
  data.frame(id = x$V1[1], nombre = x$V2[1], lat = x$V3[1], lon = x$V4[1], elev = x$V5[1],
             anios = sum(periodo), anios_sobre = sum(!cumple[periodo]),
             racha_max = largo, racha_inicio = fin_racha - largo + 1, racha_fin = fin_racha)
}

# ---- 4. Todas las estaciones (tarda varios minutos) ----
res <- vector("list", length(archivos))
for (i in seq_along(archivos)) {
  res[[i]] <- evaluar(archivos[i])
  if (i %% 10000 == 0) cat(i, "estaciones revisadas\n")
}
res <- do.call(rbind, res)
res <- res[order(-res$racha_max, res$anios_sobre), ]
write.csv(res, salida, row.names = FALSE)

# ---- 5. Resultados ----
cat("\nEstaciones con datos comparables:", nrow(res), "\n")
cat("\n", inicio, "-", fin, ": estaciones sin ningun anio fuera del 10 %\n", sep = "")
for (m in c(fin - inicio + 1, 30, 25, 20, 15, min_anios)) {
  cat("  con >=", m, "anios:", sum(res$anios >= m & res$anios_sobre == 0), "\n")
}
cat("\nRacha mas larga de anios seguidos que cumplen (", min(anios_develi), "-",
    max(anios_develi), "):\n", sep = "")
print(table(res$racha_max[res$racha_max > 0]))
cat("\nLas 20 rachas mas largas:\n")
print(head(res[, c("id", "nombre", "lat", "lon", "elev", "racha_max", "racha_inicio", "racha_fin")], 20),
      row.names = FALSE)
