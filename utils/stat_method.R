detectar_estadistico <- function(z, k = 2) {
  
  media <- mean(z, na.rm = TRUE)
  desviacion <- sd(z, na.rm = TRUE)
  
  limite_inferior <- media - k * desviacion
  limite_superior <- media + k * desviacion
  
  anomalias <- z < limite_inferior | z > limite_superior
  
  return(anomalias)
}
