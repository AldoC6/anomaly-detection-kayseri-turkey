df_humity <- read.csv("data/equivalencia/procesados/AereopuertoKayseri_GHCNh_1975-2007.csv", header = TRUE)   # sale del script 01

df_humity$DATE <- as.Date(df_humity$DATE, format = "%d/%m/%Y")

kay <- df_humity[, c("DATE", "mean_relative_humidity")]

kay$Anio <- as.integer(format(kay$DATE, "%Y"))
kay$Mes <- as.integer(format(kay$DATE, "%m"))

rh <- aggregate(
  mean_relative_humidity ~ Anio + Mes,
  data = kay,
  FUN = mean
)

names(rh)[3] <- "relative_humidity"


rh <- rh[
  order(rh$Anio,
        rh$Mes),
]


head(rh)

dim(rh)


rhanual <- aggregate(
  relative_humidity ~ Anio,
  data = rh,
  FUN = mean
)

head(rhanual)
dim(rhanual)

write.csv(rhanual, "data/equivalencia/procesados/kayseri-erkilet-data-relative-humidity.csv", row.names = FALSE)
