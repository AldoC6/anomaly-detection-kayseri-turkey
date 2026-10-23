detectar_estadistico <- function(z, k = 2) {
  
  if (!is.numeric(z)) stop("z debe ser un vector numérico")
  if (anyNA(z)) stop("z no debe contener NA")
  if (!is.numeric(k) || length(k) != 1 || k <= 0) {
    stop("k debe ser un número positivo")
  }
  
  media <- mean(z, na.rm = TRUE)
  desviacion <- sd(z, na.rm = TRUE)
  
  limite_inferior <- media - k * desviacion
  limite_superior <- media + k * desviacion
  
  anomalias <- z < limite_inferior | z > limite_superior
  
  return(anomalias)
}
