
# Aeropuerto de Kayseri (Erkilet) - NOAA GHCN-Hourly (GHCNh)
# Humedad relativa: convierte los datos horarios a diarios, 1975-2007
# ============================================================

estacion <- "TUI0000LTAU"
anios    <- 1975:2007
url_base <- "https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/%d/psv/GHCNh_%s_%d.psv"
carpeta  <- "data/equivalencia/fuentes/ghcnh_raw"   # ~193 MB, no se sube a git

dir.create(carpeta, recursive = TRUE, showWarnings = FALSE)

# ---- 1. Descargar un archivo por año ----
for (a in anios) {
  destino <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, estacion, a)
  if (file.exists(destino)) next
  ok <- tryCatch({
    download.file(sprintf(url_base, a, estacion, a), destino, mode = "wb", quiet = TRUE)
    TRUE
  }, error = function(e) FALSE)
  cat(a, if (ok) "descargado" else "NO DISPONIBLE", "\n")
}

# ---- 2. Leer solo las columnas necesarias ----
columnas <- c("STATION", "LATITUDE", "LONGITUDE", "ELEVATION",
              "Year", "Month", "Day", "Hour",
              "relative_humidity", "relative_humidity_Source_Code")

leer <- function(archivo) {
  d <- read.delim(archivo, sep = "|", stringsAsFactors = FALSE)
  d <- d[, columnas]
  d$relative_humidity <- suppressWarnings(as.numeric(d$relative_humidity))
  d
}

# Solo los archivos de 1975-2007 (en la carpeta puede haber otros años)
archivos <- sprintf("%s/GHCNh_%s_%d.psv", carpeta, estacion, anios)
archivos <- archivos[file.exists(archivos)]
horas    <- do.call(rbind, lapply(archivos, leer))

# Humedad fuera de 0-100 es imposible -> NA
horas$relative_humidity[horas$relative_humidity < 0 |
                          horas$relative_humidity > 100] <- NA

# ---- Origen de la humedad (código de fuente de NOAA) ----
cat("Horas con HR:", sum(!is.na(horas$relative_humidity)), "\n")
print(table(horas$relative_humidity_Source_Code, useNA = "ifany"))

# ---- 3. Agrupar por día ----
horas$DATE <- as.Date(sprintf("%d-%02d-%02d", horas$Year, horas$Month, horas$Day))

promedio <- function(x) if (all(is.na(x))) NA else mean(x, na.rm = TRUE)

diario <- aggregate(
  relative_humidity ~ DATE,
  data = horas, FUN = promedio, na.action = na.pass
)

# ---- 4. Tabla diaria ----
kayseri <- data.frame(
  STATION                    = estacion,
  DATE                       = format(diario$DATE, "%d/%m/%Y"),
  LATITUDE                   = horas$LATITUDE[1],
  LONGITUDE                  = horas$LONGITUDE[1],
  ELEVATION                  = horas$ELEVATION[1],
  mean_relative_humidity     = round(diario$relative_humidity, 1)
)

# ---- 5. Revisión ----
print(table(format(diario$DATE, "%Y")))
cat("\nDías totales:", nrow(kayseri), "\n")
cat("Días sin humedad:", sum(is.na(kayseri$mean_relative_humidity)), "\n")
cat("HR media 1975-2007:", round(mean(kayseri$mean_relative_humidity, na.rm = TRUE), 2), "%\n")

write.csv(kayseri, "data/equivalencia/procesados/AereopuertoKayseri_GHCNh_1975-2007.csv", row.names = FALSE)
