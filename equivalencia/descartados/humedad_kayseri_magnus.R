# Descartado: alternativa con fórmula de Magnus (la HR oficial es la de GHCNh)
df_humity <- read.csv("data/equivalencia/procesados/AereopuertoKayseri_GHCNh_1975-2007.csv", header = TRUE)
df_humity$DATE <- as.Date(df_humity$DATE, format = "%d/%m/%Y")   # <- cambio 1

sum(is.na(df_humity$DATE))

kay <- df_humity[, c("DATE", "mean_temperature", "mean_dew_point_temperature")]  # <- cambio 2

# ---- Humedad relativa diaria (fórmula de Magnus) ----        # <- cambio 3
Td <- kay$mean_dew_point_temperature
T  <- kay$mean_temperature
kay$humedad_relativa <- 100 * exp(17.625 * Td / (243.04 + Td)) / exp(17.625 * T / (243.04 + T))

sum(kay$humedad_relativa > 100, na.rm = TRUE)   # días imposibles (más de 100 %)
kay$humedad_relativa[kay$humedad_relativa > 100] <- NA

kay$Anio <- as.integer(format(kay$DATE, "%Y"))
kay$Mes  <- as.integer(format(kay$DATE, "%m"))

humedad_relativa_mes <- aggregate(humedad_relativa ~ Anio + Mes, data = kay, FUN = mean)
humedad_relativa_mes <- humedad_relativa_mes[order(humedad_relativa_mes$Anio, humedad_relativa_mes$Mes), ]
dim(humedad_relativa_mes)        # 396 3

humedad_relativa_anual <- aggregate(humedad_relativa ~ Anio, data = humedad_relativa_mes, FUN = mean)
head(humedad_relativa_anual)
dim(humedad_relativa_anual)      # 33 2

write.csv(humedad_relativa_anual, "data/equivalencia/procesados/kayseri-erkilet-data-relative-humidity-calculated.csv", row.names = FALSE)

