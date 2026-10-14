source("utils/deseason.R")

df_kayseri<- read.csv("data/AereopuertoKayseri_1975-2008.csv", header = TRUE)

df_kayseri$DATE <- as.Date(df_kayseri$DATE, format = "%d/%m/%Y")

kay <- df_kayseri[, c("DATE", "mean_temperature")]

kay$Anio <- as.integer(format(kay$DATE, "%Y"))
kay$Mes <- as.integer(format(kay$DATE, "%m"))

tm <- aggregate(
  mean_temperature ~ Anio + Mes,
  data = kay,
  FUN = mean
)

names(tm)[3] <- "Temp_mensual"

tm <- tm[
  order(tm$Anio,
        tm$Mes),
]

head(tm)

dim(tm)

tabla_meses <- aggregate(
  Temp_mensual ~ Mes,
  data = tm,
  FUN = function(x) c(Promedio = mean(x), Desv_est = sd(x))
)

tabla_meses <- do.call(data.frame, tabla_meses)
names(tabla_meses) <- c("Mes", "Promedio", "Desv_est")

tabla_meses$Mes <- factor(
  tabla_meses$Mes,
  levels = 1:12,
  labels = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
             "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
)

kayseri_z <- monthly_z_score(tm, tabla_meses)
kayseri_z