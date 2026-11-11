# Compara la precipitación de Develi y Aeropuerto Kayseri (NOAA GHCN-M v2)
# en los años en común y genera el set mensual:
#   año, mes, Develi (mm), Kayseri (mm), si ambos tienen dato
# Los totales anuales, media y desviación estándar se calculan en EquivalenciaDataset.xlsx

archivo <- "data/equivalencia/procesados/precipitacion_GHCNMv2_Develi_Kayseri.csv"   # sale del script 04
inicio  <- 1975   # periodo comparable (el mismo de la tabla de temperatura)
fin     <- 1990   # último año con datos de Develi

prcp <- read.csv(archivo, colClasses = c(estacion = "character"))

# --- Separar estaciones ----------------------------------------------------
develi  <- prcp[prcp$nombre == "Develi",             c("anio", "mes", "precip_mm")]
kayseri <- prcp[prcp$nombre == "Aeropuerto Kayseri", c("anio", "mes", "precip_mm")]
names(develi)[3]  <- "develi_mm"
names(kayseri)[3] <- "kayseri_mm"

# --- Set mensual (año + mes en común) -------------------------------------
mensual <- merge(develi, kayseri, by = c("anio", "mes"))   # solo año-mes presentes en ambas
mensual <- mensual[mensual$anio >= inicio & mensual$anio <= fin, ]
mensual <- mensual[order(mensual$anio, mensual$mes), ]
mensual$ambos_con_dato <- !is.na(mensual$develi_mm) & !is.na(mensual$kayseri_mm)

cat("Años en común:", min(mensual$anio), "-", max(mensual$anio),
    "| meses:", nrow(mensual),
    "| meses con dato en ambas:", sum(mensual$ambos_con_dato), "\n")

# --- Guardar ----------------------------------------------------------------
write.csv(mensual, "data/equivalencia/procesados/precipitacion_mensual_comun.csv", row.names = FALSE)
