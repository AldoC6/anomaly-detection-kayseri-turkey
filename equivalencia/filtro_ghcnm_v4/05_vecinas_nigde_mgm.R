# Filtro Monthly v4 - Paso 5: humedad (metodo MGM) de las vecinas de Nigde
# Descarga GHCNh de las estaciones a menos de ~300 km de Nigde que tienen humedad en
# 1975-2007 (inventario de GHCNh) y que aun no estaban descargadas, y calcula su
# humedad mensual con el metodo de MGM (07-14-21 hora local), igual que el paso 11.
# Las de meseta (Erkilet, Konya, Etimesgut, Corum) ya estan en los pasos 2 y 11.
# Fuente: Menne, M. J., et al. (2023). GHCNh, Version 1. NOAA NCEI.
#         https://doi.org/10.25921/jp3d-3v19
# Entrada: descarga de GHCNh por estacion y anio (en fuentes/ghcnh_raw/, fuera de git)
# Salida:  procesados/filtro_ghcnm_v4/vecinas_nigde_mgm_mensual.csv
#          (estacion, nombre, anio, mes, temp, dias_temp, hr, dias_hr)
# ============================================================

source("equivalencia/funciones_mgm.R")

vecinas <- data.frame(
  id     = c("TUM00017351", "TUI0000LTAG", "TUMU0017330", "TUI0000LTAK",
             "SYI0000OSAP", "SYM00040022"),
  nombre = c("ADANA", "INCIRLIK", "SILIFKE", "ISKENDERUN", "ALEPPO", "LATTAKIA")
)
anios    <- 1975:2007
url_base <- "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/%d/psv/GHCNh_%s_%d.psv"
carpeta  <- "data/equivalencia/fuentes/ghcnh_raw"
salida   <- "data/equivalencia/procesados/filtro_ghcnm_v4/vecinas_nigde_mgm_mensual.csv"

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)
options(timeout = 600)

# ---- 1. Descargar (un archivo por estacion y anio; se salta lo ya descargado) ----
for (id in vecinas$id) for (a in anios) {
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
  cat(sprintf("%-12s lon %7.3f | meses con >= 15 dias de HR: %d\n", nombre, lon, sum(m$dias_hr >= 15)))
  data.frame(estacion = id, nombre = nombre, m[, c("anio", "mes", "temp", "dias_temp", "hr", "dias_hr")])
}

resultado <- do.call(rbind, Map(mensual_estacion, vecinas$id, vecinas$nombre))
resultado <- resultado[order(resultado$estacion, resultado$anio, resultado$mes), ]
resultado$temp <- round(resultado$temp, 2)
resultado$hr   <- round(resultado$hr, 2)
write.csv(resultado, salida, row.names = FALSE)
