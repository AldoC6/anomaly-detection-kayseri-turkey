# Descartado: Open-Meteo (reanálisis), se prefirió el dato medido de GHCNh.
# El CSV de Open-Meteo no está en el repo; se elige a mano.
df_humity <- read.csv(file.choose(), header = TRUE)

df_humity$time <- as.Date(df_humity$time, format = "%d/%m/%Y")

kay <- df_humity[, c("time", "relative_humidity")]

kay$Anio <- as.integer(format(kay$time, "%Y"))
kay$Mes <- as.integer(format(kay$time, "%m"))

rh <- aggregate(
  relative_humidity ~ Anio + Mes,
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

write.csv(rhanual, "open-meteo-data-relative-humidity.csv", row.names = FALSE)
