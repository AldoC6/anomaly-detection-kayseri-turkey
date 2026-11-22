# Filtro Monthly v4 - Paso 7: dataset mensual de Ankara Etimesgut (1975-2007)
# Etimesgut es la unica estacion que cumple las tres variables contra Develi con el
# criterio de media y desviacion estandar (pasos 1, 2 y 4). Este script junta en una
# sola tabla mensual su temperatura, humedad relativa y precipitacion:
#   - Temperatura y humedad: GHCNh (TUI0000LTAD) con el metodo de MGM (07-14-21 hora
#     local), calculadas en el paso 11. Un mes cuenta si tiene >= 15 dias validos;
#     si no, queda NA.
#   - Precipitacion: GPCC Full Data V2020 0.25 (celda de Etimesgut), la misma fuente
#     del paso 2. NOAA no tiene precipitacion medida de Etimesgut despues de 1990.
# Todo es dato publico, por eso la salida va en procesados/.
# Fuentes: Menne, M. J., et al. (2023). GHCNh, Version 1. https://doi.org/10.25921/jp3d-3v19
#          Schneider, U., et al. (2020). GPCC Full Data Monthly V2020 at 0.25.
#          https://doi.org/10.5676/DWD_GPCC/FD_M_V2020_025
# Entradas: procesados/candidatas_mgm_mensual.csv (paso 11)
#           fuentes/gpcc/*_025.nc (paso 7 del flujo principal)
# Salida:   procesados/filtro_ghcnm_v4/etimesgut_mensual_1975-2007.csv
#           (anio, mes, temp, hr, precip)
# ============================================================

library(ncdf4)

inicio   <- 1975
fin      <- 2007
dias_min <- 15
etimesgut <- c(lat = 39.9498, lon = 32.6886)    # GHCNh TUI0000LTAD
salida   <- sprintf("data/equivalencia/procesados/filtro_ghcnm_v4/etimesgut_mensual_%d-%d.csv", inicio, fin)

# ---- 1. Temperatura y humedad (GHCNh, metodo MGM) ----
m <- read.csv("data/equivalencia/procesados/candidatas_mgm_mensual.csv")
m <- m[m$estacion == "TUI0000LTAD", ]
m$temp[is.na(m$dias_temp) | m$dias_temp < dias_min] <- NA
m$hr[is.na(m$dias_hr) | m$dias_hr < dias_min] <- NA

# ---- 2. Precipitacion (GPCC, celda de Etimesgut) ----
leer_gpcc <- function(archivo) {
  nc  <- nc_open(archivo)
  lat <- ncvar_get(nc, "lat"); lon <- ncvar_get(nc, "lon"); tie <- ncvar_get(nc, "time")
  u   <- ncatt_get(nc, "time", "units")$value
  fecha <- as.Date(as.POSIXct(sub(".*since ", "", u), tz = "UTC") +
                   tie * (if (grepl("^hours", u)) 3600 else 86400))
  j <- which.min(abs(lon - etimesgut["lon"])); i <- which.min(abs(lat - etimesgut["lat"]))
  p <- ncvar_get(nc, "precip", start = c(j, i, 1), count = c(1, 1, -1))
  nc_close(nc)
  data.frame(anio = as.integer(format(fecha, "%Y")), mes = as.integer(format(fecha, "%m")),
             precip = round(p, 1))
}
archivos <- list.files("data/equivalencia/fuentes/gpcc", pattern = "_025\\.nc$", full.names = TRUE)
p <- do.call(rbind, lapply(archivos, leer_gpcc))

# ---- 3. Tabla mensual completa (todos los meses del periodo) ----
tabla <- expand.grid(mes = 1:12, anio = inicio:fin)[, c("anio", "mes")]
tabla <- merge(tabla, m[, c("anio", "mes", "temp", "hr")], by = c("anio", "mes"), all.x = TRUE)
tabla <- merge(tabla, p, by = c("anio", "mes"), all.x = TRUE)
tabla <- tabla[order(tabla$anio, tabla$mes), ]
write.csv(tabla, salida, row.names = FALSE)

cat("Meses:", nrow(tabla), "| sin temperatura:", sum(is.na(tabla$temp)),
    "| sin humedad:", sum(is.na(tabla$hr)), "| sin precipitacion:", sum(is.na(tabla$precip)), "\n")
