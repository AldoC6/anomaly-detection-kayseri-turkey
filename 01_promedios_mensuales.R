# PASO 1: Agrupar temperaturas por año y mes


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

write.csv(tm,"data/temp_men.csv",row.names = FALSE)
