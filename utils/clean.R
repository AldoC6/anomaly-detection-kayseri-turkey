CENTINELAS <- c(-9999, 9999)

limpiar_datos <- function(df) {
  
  n_inicial <- nrow(df)
  
  df$mean_temperature[df$mean_temperature %in% CENTINELAS] <- NA
  
  df <- df[!is.na(df$DATE) & !is.na(df$mean_temperature), ]
  
  df <- df[!duplicated(df$DATE), ]
  
  cat("Registros eliminados en la limpieza:", n_inicial - nrow(df), "\n")
  
  return(df)
}