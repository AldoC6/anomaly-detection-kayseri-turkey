# Filtro Monthly v4 - Paso 6: estimar la humedad de Nigde con kriging (prueba)
# NOAA solo tiene humedad horaria de Nigde desde 2001. Aqui se prueba si se puede
# estimar 1975-2000 con kriging ordinario a partir de las estaciones vecinas que si
# tienen humedad (GHCNh, metodo MGM), en dos escenarios:
#   - meseta: Erkilet, Konya, Etimesgut y Corum (mismo tipo de clima que Nigde)
#   - todas:  las de meseta + las de la costa y Siria (Adana, Incirlik, Silifke,
#             Iskenderun, Alepo, Latakia), del otro lado de los montes Tauro
#   - Kriging ordinario hecho a mano (sin librerias): variograma exponencial
#     gamma(h) = 1 - exp(-h / rango). Con pocas estaciones no se puede ajustar el
#     variograma, asi que se prueban varios rangos. Cada mes usa las vecinas que
#     tengan dato ese mes.
#   - Validacion: se estima Nigde en 2001-2007, donde si hay datos, y se compara.
# Todo es dato publico de NOAA, por eso la salida va en procesados/.
# Entradas: procesados/kayseri-erkilet-relative-humidity-mensual.csv (paso 2)
#           procesados/candidatas_mgm_mensual.csv          (paso 11: Konya, Etimesgut, Corum)
#           procesados/candidatas_lat_alt_mgm_mensual.csv  (paso 14: Nigde)
#           procesados/filtro_ghcnm_v4/vecinas_nigde_mgm_mensual.csv (paso 5)
#           fuentes/ghcnh-station-list.txt (coordenadas)
# Salida:   procesados/filtro_ghcnm_v4/kriging_nigde_validacion.csv
# ============================================================

rangos   <- c(100, 300, 1000)     # km, rangos del variograma a probar
dias_min <- 15
pr       <- "data/equivalencia/procesados"
meseta   <- c("TUI0000LTAU", "TUI0000LTAN", "TUI0000LTAD", "TUM00017084")
costa    <- c("TUM00017351", "TUI0000LTAG", "TUMU0017330", "TUI0000LTAK",
              "SYI0000OSAP", "SYM00040022")
escenarios <- list(meseta = meseta, todas = c(meseta, costa))
nigde_id <- "TUM00017250"

# ---- 1. Humedad mensual (metodo MGM) de las vecinas y de Nigde ----
erk <- read.csv(file.path(pr, "kayseri-erkilet-relative-humidity-mensual.csv"))
datos <- data.frame(estacion = "TUI0000LTAU", anio = erk$Anio, mes = erk$Mes, hr = erk$relative_humidity)
for (f in c("candidatas_mgm_mensual.csv", "candidatas_lat_alt_mgm_mensual.csv",
            "filtro_ghcnm_v4/vecinas_nigde_mgm_mensual.csv")) {
  d <- read.csv(file.path(pr, f))
  d <- d[d$estacion %in% c(meseta, costa, nigde_id) & !is.na(d$hr) & d$dias_hr >= dias_min, ]
  datos <- rbind(datos, d[, c("estacion", "anio", "mes", "hr")])
}
datos <- unique(datos[!is.na(datos$hr), ])

# ---- 2. Coordenadas -> km en un plano local centrado en Nigde ----
lineas <- readLines("data/equivalencia/fuentes/ghcnh-station-list.txt", warn = FALSE)
coord <- data.frame(estacion = trimws(substr(lineas, 1, 11)),
                    lat = suppressWarnings(as.numeric(substr(lineas, 13, 20))),
                    lon = suppressWarnings(as.numeric(substr(lineas, 22, 30))))
coord <- coord[coord$estacion %in% c(meseta, costa, nigde_id), ]
n0 <- coord[coord$estacion == nigde_id, ]
coord$x <- (coord$lon - n0$lon) * 111.32 * cos(n0$lat * pi / 180)
coord$y <- (coord$lat - n0$lat) * 110.57

# ---- 3. Kriging ordinario: pesos de las vecinas para estimar Nigde ----
pesos_kriging <- function(vecinas, rango) {
  p <- coord[match(c(vecinas, nigde_id), coord$estacion), ]
  h <- as.matrix(dist(p[, c("x", "y")]))
  g <- 1 - exp(-h / rango)                       # variograma exponencial
  n <- length(vecinas)
  A <- rbind(cbind(g[1:n, 1:n], 1), c(rep(1, n), 0))
  b <- c(g[1:n, n + 1], 1)
  setNames(solve(A, b)[1:n], vecinas)            # el ultimo valor es el multiplicador
}

# ---- 4. Validacion 2001-2007: estimar Nigde donde si hay datos ----
real <- datos[datos$estacion == nigde_id & datos$anio >= 2001 & datos$anio <= 2007, ]
resultados <- list()
for (esc in names(escenarios)) for (r in rangos) {
  est <- sapply(seq_len(nrow(real)), function(i) {
    v <- datos[datos$anio == real$anio[i] & datos$mes == real$mes[i] &
               datos$estacion %in% escenarios[[esc]], ]
    if (nrow(v) < 2) return(NA)
    w <- pesos_kriging(v$estacion, r)
    sum(w * v$hr)
  })
  resultados[[length(resultados) + 1]] <- data.frame(
    escenario = esc, rango_km = r, anio = real$anio, mes = real$mes,
    nigde_real = real$hr, nigde_kriging = round(est, 2))
}
resultados <- do.call(rbind, resultados)
resultados$error <- resultados$nigde_kriging - resultados$nigde_real
write.csv(resultados, file.path(pr, "filtro_ghcnm_v4/kriging_nigde_validacion.csv"), row.names = FALSE)

# Error mensual y error del promedio anual (solo anios con los 12 meses)
for (esc in names(escenarios)) for (r in rangos) {
  d <- resultados[resultados$escenario == esc & resultados$rango_km == r & !is.na(resultados$error), ]
  completos <- names(which(table(d$anio) == 12))
  anual <- tapply(d$error, d$anio, mean)[completos]
  cat(sprintf("\n%-6s rango %4d km | meses: %d | RMSE mensual: %.2f pts | sesgo: %+.2f pts\n",
              esc, r, nrow(d), sqrt(mean(d$error^2)), mean(d$error)))
  cat("  Error del promedio anual:", paste(names(anual), sprintf("%+.2f", anual), collapse = " | "), "\n")
}
