# Estaciones candidatas - temperatura y humedad con el metodo de MGM (NOAA GHCNh)
# Para las estaciones que pasaron el filtro grueso de temperatura (paso 10, con
# umbral de 16 % para absorber la diferencia de metodo) y que tienen datos horarios,
# descarga GHCNh y calcula temperatura y humedad relativa igual que MGM en Develi:
#   T = (T07 + T14 + 2 x T21) / 4,  HR = (HR07 + HR14 + HR21) / 3,
# en hora solar local segun la longitud de cada estacion (equivalencia/funciones_mgm.R).
# La media mensual es el promedio de los dias con las 3 lecturas; se guarda tambien
# cuantos dias validos tuvo cada mes, para poder descartar meses con pocos dias.
# Fuente: Menne, M. J., et al. (2023). GHCNh, Version 1. NOAA NCEI.
#         https://doi.org/10.25921/jp3d-3v19
# Entrada: descarga de GHCNh por estacion y anio (en fuentes/ghcnh_raw/, fuera de git)
# Salida:  procesados/candidatas_mgm_mensual.csv
#          (estacion, nombre, anio, mes, temp, dias_temp, hr, dias_hr)
# ============================================================

source("equivalencia/funciones_mgm.R")

candidatas <- data.frame(
  id     = c("TUU00017092", "TUM00017189", "TUI0000LTAH", "TUM00017084",
             "TUI0000LTAN", "TUI0000LTAD", "CHU00056172"),
  nombre = c("ERZINCAN", "AFYONKARAHISAR", "AFYON (aeropuerto)", "CORUM",
             "KONYA (aeropuerto)", "ANKARA ETIMESGUT", "BARKAM (MALKANG)")
)
anios    <- 1975:2009        # la humedad de Develi llega a 2009-07
url_base <- "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/%d/psv/GHCNh_%s_%d.psv"
carpeta  <- "data/equivalencia/fuentes/ghcnh_raw"
salida   <- "data/equivalencia/procesados/candidatas_mgm_mensual.csv"

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
options(timeout = 600)

# ---- 1. Descargar (un archivo por estacion y anio; se salta lo ya descargado) ----
for (id in candidatas$id) for (a in anios) {
  destino <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, id, a)
  if (file.exists(destino)) next
  ok <- tryCatch({
    download.file(sprintf(url_base, a, id, a), destino, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE, warning = function(w) FALSE)
  if (!ok && file.exists(destino)) file.remove(destino)
  cat(id, a, if (ok) "descargado" else "no disponible", "\n")
}

# ---- 2. Metodo MGM por estacion ----
mensual_estacion <- function(id, nombre) {
  archivos <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, id, anios)
  archivos <- archivos[file.exists(archivos)]
  if (length(archivos) == 0) return(NULL)
  obs <- leer_ghcnh(archivos)
  lon <- read.delim(archivos[1], sep = "|", nrows = 1)$LONGITUDE
  d   <- diario_tabla_mgm(obs, lon)
  grupos <- list(anio = d$Anio, mes = d$Mes)
  m <- aggregate(cbind(temp = d$temp, hr = d$hr), by = grupos,
                 FUN = function(x) mean(x, na.rm = TRUE))
  n <- aggregate(cbind(dias_temp = !is.na(d$temp), dias_hr = !is.na(d$hr)),
                 by = grupos, FUN = sum)
  m <- merge(m, n, by = c("anio", "mes"))
  m$temp[is.nan(m$temp)] <- NA
  m$hr[is.nan(m$hr)]     <- NA
  cat(sprintf("%-20s lon %7.3f | meses: %d | con >= 15 dias de T: %d | de HR: %d\n",
              nombre, lon, nrow(m), sum(m$dias_temp >= 15), sum(m$dias_hr >= 15)))
  data.frame(estacion = id, nombre = nombre, m[, c("anio", "mes", "temp", "dias_temp", "hr", "dias_hr")])
}

resultado <- do.call(rbind, Map(mensual_estacion, candidatas$id, candidatas$nombre))
resultado <- resultado[order(resultado$estacion, resultado$anio, resultado$mes), ]
resultado$temp <- round(resultado$temp, 2)
resultado$hr   <- round(resultado$hr, 2)
write.csv(resultado, salida, row.names = FALSE)
