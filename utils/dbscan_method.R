detectar_dbscan <- function(z, eps, minpts) {
  if (!is.numeric(z)) stop("z debe ser un vector numérico")
  if (anyNA(z)) stop("z no debe contener NA")
  if (!is.numeric(eps) || length(eps) != 1 || eps <= 0) {
    stop("eps debe ser un número positivo")
  }
  if (!is.numeric(minpts) || length(minpts) != 1 || minpts < 1) {
    stop("minpts debe ser un entero positivo")
  }
  
  # DBSCAN solo sobre Z (una dimensión); dbscan() espera una matriz
  resultado <- dbscan(as.matrix(z), eps = eps, minPts = minpts)
  
  # El ruido es el cluster 0
  return(resultado$cluster == 0)
}
