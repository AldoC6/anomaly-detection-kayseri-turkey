library(dbscan)

source("utils/deseason.R")
source("utils/plots.R")
source("utils/stat_method.R")
source("utils/dbscan_method.R")

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

z <- kayseri_z$Z

# Figuras
## Figura 3
plot_original_vs_deseason(kayseri_z)

## Figura 4
anom_stad2 <- detectar_estadistico(z, 2)
anom_stad3 <- detectar_estadistico(z, 3)

plot_anomalias(kayseri_z, anom_stad2)
plot_anomalias(kayseri_z, anom_stad3)

## Figura 5

anom_eps005 <- detectar_dbscan(z, 0.05, 4)
anom_eps01 <- detectar_dbscan(z, 0.1, 4)
anom_eps015 <- detectar_dbscan(z, 0.15, 4)

plot_anomalias(kayseri_z, anom_eps005)
plot_anomalias(kayseri_z, anom_eps01)
plot_anomalias(kayseri_z, anom_eps015)

## Figura 6

anom_minpts2 <- detectar_dbscan(z, 0.1, 2)
anom_minpts4 <- detectar_dbscan(z, 0.1, 4)
anom_minpts6 <- detectar_dbscan(z, 0.1, 6)

plot_anomalias(kayseri_z, anom_minpts2)
plot_anomalias(kayseri_z, anom_minpts4)
plot_anomalias(kayseri_z, anom_minpts6)


# Exportaciones
## Figura 3
png("storage/original-vs-deseason.png", width = 1000, height = 600, res = 120)
plot_original_vs_deseason(kayseri_z)
dev.off()

## Figura 4
exportar('storage/fig4/a.png', kayseri_z, anom_stad2, "a) The results for μ ± 2σ")
exportar('storage/fig4/b.png', kayseri_z, anom_stad3, "b) The results for μ ± 3σ")

## Figura 5
exportar('storage/fig5/a.png', kayseri_z, anom_eps005, "a) The results for 4 minpts, 0.05 eps")
exportar('storage/fig5/b.png', kayseri_z, anom_eps01, "b) The results for 4 minpts, 0.1 eps")
exportar('storage/fig5/c.png', kayseri_z, anom_eps015, "c) The results for 4 minpts, 0.15 eps")

## Figura 6
exportar('storage/fig6/a.png', kayseri_z, anom_minpts2, "a) The results for 2 minpts, 0.1 eps")
exportar('storage/fig6/b.png', kayseri_z, anom_minpts4, "b) The results for 4 minpts, 0.1 eps")
exportar('storage/fig6/c.png', kayseri_z, anom_minpts6, "c) The results for 6 minpts, 0.1 eps")

