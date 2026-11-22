# Candidatas - Paso 1: temperatura de las 4 estaciones candidatas (GHCN-M v4)
# Extrae la temperatura media mensual y anual de las 4 estaciones que pasan el
# filtro de temperatura con GHCN-M v4 ajustado (ver filtro_ghcnm_v4/01):
#   Nigde    TUM00017250
#   Kirsehir TUM00017160
#   Konya    TUM00017244
#   Afyon    TUM00017190
# Se leen dos versiones de NOAA:
#   - qfe: ajustada (PHA) + meses faltantes estimados por NOAA (DMFLAG = "E")
#   - qcf: ajustada (PHA) sin estimaciones; un mes sin dato queda vacio
# Asi se ve, mes por mes, que valor es medido (ajustado) y cual es estimado.
# Un mes medido con bandera de calidad (QCFLAG) se descarta. Un anio solo tiene
# media anual si tiene sus 12 meses.
# Todo es dato publico de NOAA, por eso las salidas van en procesados/.
# Fuente: Menne, M. J., et al. (2018). GHCN-Monthly Version 4. NOAA NCEI.
#         https://doi.org/10.7289/V5XW4GTH
# Entradas: fuentes/ghcnm_v4/*qfe.dat  y  fuentes/ghcnm_v4/*qcf.dat
# Salidas:  procesados/candidatas/temp_candidatas_mensual_<inicio>-<fin>.csv
#           procesados/candidatas/temp_candidatas_anual_<inicio>-<fin>.csv
#           procesados/candidatas/temp_candidatas_resumen_<inicio>-<fin>.csv
# ============================================================

inicio  <- 1975                # periodo del paper
fin     <- 2007
carpeta <- "data/equivalencia/fuentes/ghcnm_v4"
dir_sal <- "data/equivalencia/procesados/candidatas"
dir.create(dir_sal, showWarnings = FALSE, recursive = TRUE)

estaciones <- data.frame(
  id     = c("TUM00017250", "TUM00017160", "TUM00017244", "TUM00017190"),
  nombre = c("NIGDE", "KIRSEHIR", "KONYA", "AFYON")
)

# ---- 1. Ubicar los archivos .dat (el mas reciente de cada version) ----
if (!any(grepl("qfe\\.dat$", list.files(carpeta, recursive = TRUE))))
  untar(file.path(carpeta, "ghcnm.tavg.latest.qfe.tar.gz"), exdir = carpeta)
buscar <- function(patron) {
  f <- sort(list.files(carpeta, pattern = patron, recursive = TRUE, full.names = TRUE),
            decreasing = TRUE)[1]
  if (is.na(f)) stop("No se encontro ", patron, " en ", carpeta)
  cat("Archivo leido:", f, "\n")
  f
}
dat_qfe <- buscar("qfe\\.dat$")
dat_qcf <- buscar("qcf\\.dat$")

# ---- 2. Leer el formato de ancho fijo de GHCN-M v4 ----
# Columnas: ID 1-11, anio 12-15, elemento 16-19; luego 12 bloques de 8:
#   valor (5, centesimas de grado; -9999 = faltante), DMFLAG, QCFLAG, DSFLAG
leer_ghcnm <- function(archivo) {
  lineas <- readLines(archivo)
  lineas <- lineas[substr(lineas, 1, 11) %in% estaciones$id]
  anio   <- as.integer(substr(lineas, 12, 15))
  lineas <- lineas[anio >= inicio & anio <= fin]
  filas  <- lapply(1:12, function(m) {
    p <- 20 + (m - 1) * 8
    data.frame(id     = substr(lineas, 1, 11),
               anio   = as.integer(substr(lineas, 12, 15)),
               mes    = m,
               valor  = as.numeric(substr(lineas, p, p + 4)),
               dmflag = substr(lineas, p + 5, p + 5),
               qcflag = substr(lineas, p + 6, p + 6))
  })
  d <- do.call(rbind, filas)
  # Faltante (-9999) o con bandera de calidad -> NA. Excepcion: en qfe, un valor
  # estimado (DMFLAG "E") conserva la QCFLAG del dato original que reemplaza,
  # asi que el estimado si se conserva.
  quitar <- d$valor == -9999 | (d$qcflag != " " & d$dmflag != "E")
  d$valor[quitar] <- NA
  d$valor <- d$valor / 100
  d
}
qfe <- leer_ghcnm(dat_qfe)
qcf <- leer_ghcnm(dat_qcf)

# ---- 3. Tabla mensual completa (todas las estaciones x todos los meses) ----
base <- expand.grid(mes = 1:12, anio = inicio:fin, id = estaciones$id,
                    stringsAsFactors = FALSE)[, c("id", "anio", "mes")]
mensual <- merge(base, estaciones, by = "id")
mensual <- merge(mensual,
                 setNames(qfe[, c("id", "anio", "mes", "valor", "dmflag")],
                          c("id", "anio", "mes", "temp_qfe", "dmflag_qfe")),
                 by = c("id", "anio", "mes"), all.x = TRUE)
mensual <- merge(mensual,
                 setNames(qcf[, c("id", "anio", "mes", "valor")],
                          c("id", "anio", "mes", "temp_qcf")),
                 by = c("id", "anio", "mes"), all.x = TRUE)
mensual$estimado_qfe <- !is.na(mensual$dmflag_qfe) & mensual$dmflag_qfe == "E"
mensual$dmflag_qfe   <- NULL
mensual <- mensual[order(match(mensual$id, estaciones$id), mensual$anio, mensual$mes),
                   c("id", "nombre", "anio", "mes", "temp_qfe", "estimado_qfe", "temp_qcf")]

# ---- 4. Media anual (solo con los 12 meses) ----
media12 <- function(x) if (sum(!is.na(x)) == 12) round(mean(x), 2) else NA
anual <- do.call(rbind, lapply(split(mensual, list(mensual$id, mensual$anio), drop = TRUE),
  function(g) data.frame(
    id = g$id[1], nombre = g$nombre[1], anio = g$anio[1],
    temp_qfe            = media12(g$temp_qfe),
    meses_estimados_qfe = sum(g$estimado_qfe),
    temp_qcf            = media12(g$temp_qcf),
    meses_qcf           = sum(!is.na(g$temp_qcf)))))
anual <- anual[order(match(anual$id, estaciones$id), anual$anio), ]

# ---- 5. Resumen por estacion ----
faltantes <- function(g) {
  f <- g[is.na(g$temp_qcf), ]
  if (nrow(f) == 0) return("ninguno")
  paste(sprintf("%d-%02d", f$anio, f$mes), collapse = " ")
}
resumen <- do.call(rbind, lapply(split(mensual, mensual$id), function(g) {
  a <- anual[anual$id == g$id[1], ]
  data.frame(id = g$id[1], nombre = g$nombre[1],
             anios_completos_qfe = sum(!is.na(a$temp_qfe)),
             anios_completos_qcf = sum(!is.na(a$temp_qcf)),
             meses_estimados_qfe = sum(g$estimado_qfe),
             meses_sin_dato_qcf  = sum(is.na(g$temp_qcf)),
             media_qfe = round(mean(a$temp_qfe, na.rm = TRUE), 2),
             media_qcf = round(mean(a$temp_qcf, na.rm = TRUE), 2),
             meses_faltantes_qcf = faltantes(g))
}))
resumen <- resumen[match(estaciones$id, resumen$id), ]

# ---- 6. Guardar ----
sufijo <- paste0(inicio, "-", fin, ".csv")
write.csv(mensual, file.path(dir_sal, paste0("temp_candidatas_mensual_", sufijo)), row.names = FALSE)
write.csv(anual,   file.path(dir_sal, paste0("temp_candidatas_anual_",   sufijo)), row.names = FALSE)
write.csv(resumen, file.path(dir_sal, paste0("temp_candidatas_resumen_", sufijo)), row.names = FALSE)

print(resumen[, -9], row.names = FALSE)
cat("\nMeses sin dato en qcf (los que qfe estima):\n")
for (i in seq_len(nrow(resumen))) cat(" ", resumen$nombre[i], ":", resumen$meses_faltantes_qcf[i], "\n")
cat("\nGuardado en", dir_sal, "\n")
