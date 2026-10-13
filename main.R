df_kayseri<- read.csv(file.choose(), header = TRUE)

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
