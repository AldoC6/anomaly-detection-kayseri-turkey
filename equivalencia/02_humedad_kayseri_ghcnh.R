# Humedad relativa y temperatura del Aeropuerto de Kayseri (Erkilet) - NOAA GHCNh
# Calcula la humedad relativa y la temperatura de Kayseri con el mismo metodo que
# usa MGM para Develi, para comparar igual contra igual:
#      - MGM define la humedad media diaria como la suma de las lecturas de
#        07:00, 14:00 y 21:00 hora local dividida entre 3 (MGM, "Tanimlar",
#        resmi istatistikler).
#      - MGM define la temperatura media diaria como la suma de las lecturas de
#        07:00 y 14:00 mas el doble de la de 21:00, dividida entre 4:
#        (T07 + T14 + 2 x T21) / 4 (MGM, "Tanimlar").
#      - En ambos casos la media mensual es el promedio de los dias del mes.
#      - La hora local de las observaciones climatologicas es la hora solar media
#        del lugar (segun la longitud de la estacion; MGM, Klimatolojik Rasat El
#        Kitabi). Para Kayseri (35.50 E) es UTC + 35.50/15 h = UTC + 2 h 22 min, asi
#        que 07, 14 y 21 h locales son 04:38, 11:38 y 18:38 UTC.
# Las funciones del metodo estan en equivalencia/funciones_mgm.R.
# Entrada: fuentes/ghcnh_raw/ (archivos horarios que descarga el paso 1)
# Salidas: procesados/kayseri-erkilet-relative-humidity-diario.csv (por dia)
#          procesados/kayseri-erkilet-relative-humidity-mensual.csv (por mes)
#          procesados/kayseri-erkilet-relative-humidity.csv (por anio)
#          procesados/kayseri-erkilet-temperature-diario.csv (por dia)
#          procesados/kayseri-erkilet-temperature-mensual.csv (por mes)
#          procesados/kayseri-erkilet-temperature.csv (por anio)
# ============================================================

source("equivalencia/funciones_mgm.R")

# ---- 1. Leer las observaciones horarias ----
estacion <- "TUI0000LTAU"
anios    <- 1975:2007
carpeta  <- "data/equivalencia/fuentes/ghcnh_raw"
salida_hr_diario  <- "data/equivalencia/procesados/kayseri-erkilet-relative-humidity-diario.csv"
salida_hr_mensual <- "data/equivalencia/procesados/kayseri-erkilet-relative-humidity-mensual.csv"
salida_hr_anual   <- "data/equivalencia/procesados/kayseri-erkilet-relative-humidity.csv"
salida_t_diario   <- "data/equivalencia/procesados/kayseri-erkilet-temperature-diario.csv"
salida_t_mensual  <- "data/equivalencia/procesados/kayseri-erkilet-temperature-mensual.csv"
salida_t_anual    <- "data/equivalencia/procesados/kayseri-erkilet-temperature.csv"

archivos <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, estacion, anios)
archivos <- archivos[file.exists(archivos)]
obs  <- leer_ghcnh(archivos)
meta <- read.delim(archivos[1], sep = "|", nrows = 1)[, c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION")]
horas_utc <- horas_utc_mgm(meta$LONGITUDE)
cat(sprintf("Longitud %.4f E -> lecturas a %s UTC\n", meta$LONGITUDE,
            paste(sprintf("%02d:%02d", floor(horas_utc), round(horas_utc %% 1 * 60)), collapse = ", ")))

# ---- 2. Valor diario a partir de las lecturas de 07, 14 y 21 h ----
diario <- diario_tabla_mgm(obs, meta$LONGITUDE)

# ---- 3. Media mensual (promedio de los dias) y media anual (de los 12 meses) ----
hr <- resumir_mgm(diario, "hr",   "relative_humidity")
tp <- resumir_mgm(diario, "temp", "temperature")

# ---- 4. Revision ----
revisar <- function(columna, res, nombre, unidad) {
  n_dias <- aggregate(!is.na(diario[[columna]]),
                      by = list(Anio = diario$Anio, Mes = diario$Mes), FUN = sum)
  cat(sprintf("\n%s: dias con las 3 lecturas: %d de %d | meses con menos de 15 dias: %d | meses: %d | anios: %d\n",
              nombre, sum(!is.na(diario[[columna]])), nrow(diario), sum(n_dias$x < 15),
              nrow(res$mensual), nrow(res$anual)))
  cat(sprintf("%s media 1975-2007: %.2f %s  DE anual: %.3f\n", nombre,
              mean(res$anual[[2]]), unidad, sd(res$anual[[2]])))
}
revisar("hr",   hr, "Humedad",     "%")
revisar("temp", tp, "Temperatura", "C")

# Diario: estacion, fecha, coordenadas y valor (dias sin las 3 lecturas quedan NA)
diario_salida <- function(columna, nombre) {
  d <- data.frame(STATION = meta$STATION, DATE = diario$DATE,
                  LATITUDE = meta$LATITUDE, LONGITUDE = meta$LONGITUDE,
                  ELEVATION = meta$ELEVATION, valor = round(diario[[columna]], 2))
  names(d)[6] <- nombre
  d
}
write.csv(diario_salida("hr",   "relative_humidity"), salida_hr_diario, row.names = FALSE)
write.csv(diario_salida("temp", "temperature"),       salida_t_diario,  row.names = FALSE)

hr$mensual$relative_humidity <- round(hr$mensual$relative_humidity, 2)
tp$mensual$temperature       <- round(tp$mensual$temperature, 2)
write.csv(hr$mensual, salida_hr_mensual, row.names = FALSE)
write.csv(hr$anual,   salida_hr_anual,   row.names = FALSE)
write.csv(tp$mensual, salida_t_mensual,  row.names = FALSE)
write.csv(tp$anual,   salida_t_anual,    row.names = FALSE)
