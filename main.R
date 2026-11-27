library(dbscan)

source("utils/clean.R")
source("utils/deseason.R")
source("utils/plots.R")
source("utils/stat_method.R")
source("utils/dbscan_method.R")
source("utils/sensibilidad.R")

df_kayseri<- read.csv("data/AereopuertoKayseri_1975-2008.csv", header = TRUE)

df_kayseri$DATE <- as.Date(df_kayseri$DATE, format = "%d/%m/%Y")

df_kayseri <- limpiar_datos(df_kayseri)

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
names(z) <- sprintf("%d-%02d", kayseri_z$Anio, kayseri_z$Mes)   # fecha de cada punto

# Figuras
## Figura 3
plot_original_vs_deseason(kayseri_z)

## Figura 4
anom_stad2 <- detectar_estadistico(z, 2)
anom_stad3 <- detectar_estadistico(z, 3)

plot_anomalias(kayseri_z, anom_stad2)
plot_anomalias(kayseri_z, anom_stad3)

## Figura 5

anom_eps005 <- dbscan_pseudocodigo(z, 0.05, 4, archivo_csv = "storage/dbscan/eps0.05_minpts4_distancias.csv") == -1
anom_eps01  <- dbscan_pseudocodigo(z, 0.1, 4, archivo_csv = "storage/dbscan/eps0.1_minpts4_distancias.csv") == -1
anom_eps015 <- dbscan_pseudocodigo(z, 0.15, 4, archivo_csv = "storage/dbscan/eps0.15_minpts4_distancias.csv") == -1

plot_anomalias(kayseri_z, anom_eps005)
plot_anomalias(kayseri_z, anom_eps01)
plot_anomalias(kayseri_z, anom_eps015)

## Figura 6

anom_minpts2 <- dbscan_pseudocodigo(z, 0.1, 2, archivo_csv = "storage/dbscan/eps0.1_minpts2_distancias.csv") == -1
anom_minpts4 <- anom_eps01   # misma combinación que la figura 5b (eps = 0.1, minPts = 4)
anom_minpts6 <- dbscan_pseudocodigo(z, 0.1, 6, archivo_csv = "storage/dbscan/eps0.1_minpts6_distancias.csv") == -1

## Verificación: la implementación propia da las mismas anomalías que la libreria de dbscan
coincide <- c(
  identical(as.vector(anom_eps005),  detectar_dbscan(z, 0.05, 4)),
  identical(as.vector(anom_eps01),   detectar_dbscan(z, 0.1, 4)),
  identical(as.vector(anom_eps015),  detectar_dbscan(z, 0.15, 4)),
  identical(as.vector(anom_minpts2), detectar_dbscan(z, 0.1, 2)),
  identical(as.vector(anom_minpts6), detectar_dbscan(z, 0.1, 6))
)
cat("\nCoincide dbscan library == dbscan pseudocodigo = ", all(coincide), "\n")

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

# Sensibilidad: tablas cruzadas eps x minPts
lim <- limites_parametros(z)
dir.create("storage/sensibilidad", showWarnings = FALSE)

limites <- tabla_limites(z, lim)
cat("\nValores límite de eps y minPts:\n")
print(limites[, c("parametro", "fijo", "minimo", "anomalias_min", "maximo", "anomalias_max")],
      row.names = FALSE)
write.csv(limites, "storage/sensibilidad/limites_eps_minpts.csv", row.names = FALSE)

# Zona donde los resultados cambian (incluye los valores del artículo)
eps_vals    <- c(0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2, 0.3)
minpts_vals <- c(2, 3, 4, 5, 6, 8, 10, 12)
sens <- tabla_cruzada(z, eps_vals, minpts_vals)
write.csv(sens, "storage/sensibilidad/tabla_cruzada_eps_minpts.csv", row.names = FALSE)

for (v in c("anomalias", "frontera", "nucleo")) {
  mat <- a_matriz(sens, v)
  cat("\nTabla cruzada de", v, "(filas = eps, columnas = minPts):\n")
  print(mat)
  write.csv(mat, paste0("storage/sensibilidad/", v, "_eps_x_minpts.csv"))
}

# Tabla completa hasta los valores límite (los extremos dan 0 o 396 anomalías)
eps_ext    <- c(lim$eps_min, 0.001, 0.005, 0.01, 0.02, 0.03, 0.05, 0.075, 0.1, 0.15, 0.2,
                0.3, 0.5, 0.75, 1, 1.5, 2, 3, 4, lim$eps_max)
minpts_ext <- c(1, 2, 3, 4, 5, 6, 8, 10, 15, 20, 30, 50, 100, 200, lim$minpts_max)
sens_ext <- tabla_cruzada(z, eps_ext, minpts_ext)
sens_ext$eps <- sapply(signif(sens_ext$eps, 3), format, scientific = FALSE)
for (v in c("anomalias", "frontera", "nucleo")) {
  write.csv(a_matriz(sens_ext, v), paste0("storage/sensibilidad/", v, "_completa_eps_x_minpts.csv"))
}

grafica_mapa_calor(a_matriz(sens, "anomalias"), "Anomalías según eps y minPts",
                   "storage/sensibilidad/mapa_anomalias.png")
grafica_mapa_calor(a_matriz(sens, "frontera"), "Puntos frontera según eps y minPts",
                   "storage/sensibilidad/mapa_fronteras.png")
grafica_lineas(sens, "eps", "minpts", "storage/sensibilidad/anomalias_vs_eps.png",
               "eps", "Anomalías al variar eps (una línea por minPts)", log_x = TRUE)
grafica_lineas(sens, "minpts", "eps", "storage/sensibilidad/anomalias_vs_minpts.png",
               "minPts", "Anomalías al variar minPts (una línea por eps)")
grafica_3d(a_matriz(sens, "anomalias"), "Anomalías según eps y minPts", "Anomalías",
           "storage/sensibilidad/anomalias_3d.png")
grafica_3d(a_matriz(sens, "frontera"), "Puntos frontera según eps y minPts", "Fronteras",
           "storage/sensibilidad/fronteras_3d.png")
