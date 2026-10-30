CENTINELAS <- c(-9999.9, 9999.9, -9999, 9999)

limpiar_datos <- function(df) {
  
  n_inicial <- nrow(df)
  
  # 1. Centinelas -> NA (temperatura y punto de rocío)
  df$mean_temperature[df$mean_temperature %in% CENTINELAS] <- NA
  df$mean_dew_point_temperature[df$mean_dew_point_temperature %in% CENTINELAS] <- NA
  
  # 2. Eliminar filas sin fecha o sin temperatura
  df <- df[!is.na(df$DATE) & !is.na(df$mean_temperature), ]
  
  # 3. Eliminar fechas duplicadas
  df <- df[!duplicated(df$DATE), ]
  
  cat("Registros eliminados en la limpieza:", n_inicial - nrow(df), "\n")
  
  return(df)
}