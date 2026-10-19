library(dbscan)

source("utils/deseason.R")
source("utils/plots.R")

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

kayseri_z <- monthly_z_score(tm)

plot_original_vs_deseason(kayseri_z)

# Exporta el png a storage/
png("storage/original-vs-deseason.png", width = 1000, height = 600, res = 120)
plot_original_vs_deseason(kayseri_z)
dev.off()





