# Precipitación mensual de Develi y Kayseri desde NOAA GHCN-M v2 (v2.prcp)
# Formato de ancho fijo (ver v2.prcp.readme): estación (11), duplicado (1),
# año (4) y 12 meses de 5 caracteres cada uno, en décimas de mm.

archivo <- "data/equivalencia/fuentes/v2.prcp"   # ~84 MB, no se sube a git (ver docs/fuentes.md)
meses   <- c("ene","feb","mar","abr","may","jun","jul","ago","sep","oct","nov","dic")

# 1. Leer solo las líneas de nuestras dos estaciones (el archivo es de todo el mundo)
lineas <- readLines(archivo)
lineas <- lineas[substr(lineas, 1, 11) %in% c("64917195000", "64917195006")]

# 2. Separar por posiciones fijas
prcp <- read.fwf(textConnection(lineas),
                 widths     = c(11, 1, 4, rep(5, 12)),
                 col.names  = c("estacion", "duplicado", "anio", meses),
                 colClasses = c("character", rep("integer", 14)))

# 3. Pasar los meses de columnas a filas (una fila por mes)
largo <- reshape(prcp, direction = "long",
                 varying = meses, v.names = "decimas_mm",
                 timevar = "mes", times = 1:12,
                 idvar = c("estacion", "anio"))

# 4. Convertir a mm: -9999 = sin dato, -8888 = lluvia inapreciable (0)
largo$precip_mm <- ifelse(largo$decimas_mm == -9999, NA,
                          ifelse(largo$decimas_mm == -8888, 0, largo$decimas_mm / 10))
largo$nombre <- ifelse(largo$estacion == "64917195006", "Develi", "Aeropuerto Kayseri")

# 5. Ordenar y guardar
largo <- largo[order(largo$estacion, largo$anio, largo$mes),
               c("estacion", "nombre", "anio", "mes", "decimas_mm", "precip_mm")]
write.csv(largo, "data/equivalencia/procesados/precipitacion_GHCNMv2_Develi_Kayseri.csv", row.names = FALSE)

cat("Filas:", nrow(largo), "\n")   # deberían ser 1,008 (84 años x 12 meses)
