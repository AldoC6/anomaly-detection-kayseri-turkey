# Filtro Monthly v4 - Paso 4: humedad relativa de las que pasaron precipitacion (paso 2)
# Compara la humedad relativa anual de Develi (MGM, medida) con la de cada
# candidata, calculada con el metodo de MGM (07-14-21 hora local): Etimesgut con
# GHCNh (paso 11) y Nigde con ISD (paso 3). Con los dos criterios del docente:
#   - anio por anio: |Develi - estacion| * 100 / Develi <= 10 % en cada anio
#   - media y DE de los valores anuales del periodo, con el mismo %
#   - Un anio cuenta si tiene los 12 meses (cada mes con >= 15 dias validos).
# La humedad de Develi es de uso restringido: la salida va en privado/.
# Entradas: privado/develi_referencia_anual.csv (paso 9)
#           procesados/candidatas_mgm_mensual.csv         (paso 11: Etimesgut)
#           procesados/filtro_ghcnm_v4/nigde_isd_mgm_mensual.csv (paso 3: Nigde)
# Salida:   privado/filtro_ghcnm_v4_humedad_<inicio>-<fin>.csv
# ============================================================

inicio <- 1975
fin    <- 2007
umbral <- 10
candidatas <- c("TUI0000LTAD", "TUM00017250")    # Etimesgut, Nigde (pasaron media y DE en el paso 2)
salida <- sprintf("data/equivalencia/privado/filtro_ghcnm_v4_humedad_%d-%d.csv", inicio, fin)

# ---- 1. Humedad mensual de las candidatas (metodo MGM) ----
mensual <- rbind(
  read.csv("data/equivalencia/procesados/candidatas_mgm_mensual.csv"),
  read.csv("data/equivalencia/procesados/filtro_ghcnm_v4/nigde_isd_mgm_mensual.csv")
)
mensual <- mensual[mensual$estacion %in% candidatas & mensual$anio >= inicio & mensual$anio <= fin, ]
mensual <- unique(mensual[!is.na(mensual$hr) & mensual$dias_hr >= 15, c("estacion", "nombre", "anio", "mes", "hr")])

# ---- 2. Promedio anual (solo anios con los 12 meses) ----
anual <- aggregate(hr ~ estacion + nombre + anio, data = mensual,
                   FUN = function(x) if (length(x) == 12) mean(x) else NA)
anual <- anual[!is.na(anual$hr), ]

develi <- read.csv("data/equivalencia/privado/develi_referencia_anual.csv")
develi <- develi[develi$anio >= inicio & develi$anio <= fin & !is.na(develi$hr), c("anio", "hr")]
names(develi)[2] <- "hr_develi"

# ---- 3. Comparar contra Develi ----
comp <- merge(anual, develi, by = "anio")
comp$dif_pct <- abs(comp$hr_develi - comp$hr) * 100 / comp$hr_develi

resumen <- do.call(rbind, lapply(split(comp, comp$estacion), function(d) {
  data.frame(
    estacion      = d$estacion[1],
    nombre        = d$nombre[1],
    anios         = nrow(d),
    anios_sobre   = sum(d$dif_pct > umbral),
    dif_max_pct   = max(d$dif_pct),
    dif_media_pct = abs(mean(d$hr_develi) - mean(d$hr)) * 100 / mean(d$hr_develi),
    dif_de_pct    = abs(sd(d$hr_develi) - sd(d$hr)) * 100 / sd(d$hr_develi)
  )
}))
resumen$pasa_media_de <- resumen$dif_media_pct <= umbral & resumen$dif_de_pct <= umbral

write.csv(resumen, salida, row.names = FALSE)
print(resumen, row.names = FALSE, digits = 3)
