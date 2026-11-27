detectar_dbscan <- function(z, eps, minpts) {
  if (!is.numeric(z)) stop("z debe ser un vector numérico")
  if (anyNA(z)) stop("z no debe contener NA")
  if (!is.numeric(eps) || length(eps) != 1 || eps <= 0) {
    stop("eps debe ser un número positivo")
  }
  if (!is.numeric(minpts) || length(minpts) != 1 || minpts < 1 ||
      minpts != round(minpts)) {
    stop("minpts debe ser un entero positivo")
  }
  
  # DBSCAN solo sobre Z (una dimensión); dbscan() espera una matriz
  resultado <- dbscan(as.matrix(z), eps = eps, minPts = minpts)
  
  # El ruido es el cluster 0
  return(resultado$cluster == 0)
}
dbscan_pseudocodigo <- function(z, eps, minpts,
                                archivo_csv = NULL,
                                imprimir = FALSE,
                                detalle_consola = FALSE) {
  if (!is.numeric(z)) stop("z debe ser un vector numérico")
  if (anyNA(z)) stop("z no debe contener NA")
  if (!is.numeric(eps) || length(eps) != 1 || eps <= 0) {
    stop("eps debe ser un número positivo")
  }
  if (!is.numeric(minpts) || length(minpts) != 1 || minpts < 1 ||
      minpts != round(minpts)) {
    stop("minpts debe ser un entero positivo")
  }

  # 1. import the data-set into D (m filas, n columnas)
  D <- as.matrix(unname(z))
  m <- nrow(D)

  if (imprimir) {
    archivo_txt <- sprintf("storage/dbscan/iteraciones_eps%s_minpts%d.txt", eps, minpts)
    dir.create(dirname(archivo_txt), recursive = TRUE, showWarnings = FALSE)
    con_txt <- file(archivo_txt, open = "w", encoding = "UTF-8")
    on.exit(close(con_txt), add = TRUE)
  }
  imprime <- function(...) if (imprimir) { cat(...); cat(..., file = con_txt) }

  # distance(i, D): distancia euclidiana del punto i a todos los puntos
  distance <- function(i, D) sqrt(rowSums((D - matrix(D[i, ], nrow(D), ncol(D), byrow = TRUE))^2))

  # check_core_neighbor(neighbors): ¿algún vecino es punto núcleo?
  check_core_neighbor <- function(neighbors) {
    conteos <- sapply(neighbors, function(j) sum(distance(j, D) <= eps))
    nucleos <- neighbors[conteos >= minpts]
    list(hay_nucleo = length(nucleos) > 0, nucleos = nucleos, conteos = conteos)
  }

  # Tabla de distancias para el CSV (una fila por comparación i, j)
  if (!is.null(archivo_csv)) {
    tabla_dist <- vector("list", m)
  }

  class_vec <- rep(NA_integer_, m)
  clase_iteracion <- rep(NA_integer_, m)   # clase que recibe i en su propia iteración
  tipo      <- character(m)
  class_no  <- 1

  # Etiqueta de cada punto: la fecha (names(z)) si existe; si no, el índice
  etiqueta <- if (!is.null(names(z))) names(z) else as.character(seq_len(m))

  imprime(sprintf("\n========== DBSCAN | Eps = %s | Minpts = %d | m = %d ==========\n",
                  eps, minpts, m))

  # 2. for i = 1 to m
  for (i in seq_len(m)) {

    # 3. Dist = distance(i, D)
    Dist <- distance(i, D)
    if (detalle_consola) {
      for (j in seq_len(m)) {
        imprime(sprintf("  [L3] Dist(%d, %d) = %.4f %s Eps = %s -> %s\n", i, j, Dist[j],
                    if (Dist[j] <= eps) "<=" else ">", eps,
                    if (Dist[j] <= eps) "vecino" else "excede"))
      }
    }
    if (!is.null(archivo_csv)) {
      tabla_dist[[i]] <- data.frame(
        i = i,
        j = seq_len(m),
        valor_i = round(D[i, 1], 6),
        valor_j = round(D[, 1], 6),
        Dist = round(Dist, 6),
        Eps = eps,
        resultado = ifelse(Dist <= eps, "vecino", "excede"),
        neighbor_count = cumsum(Dist <= eps)          # conteo de vecinos actualizado
      )
    }

    # 4. neighbors = find(Dist =< Eps)
    neighbors <- which(Dist <= eps)

    # 5. neighbor_count = count(neighbors)
    neighbor_count <- length(neighbors)

    # 6. core_neig = check_core_neighbor(neighbors)
    cn <- check_core_neighbor(neighbors)
    core_neig <- cn$hay_nucleo

    # 7. if (neighbor_count >= minpts)
    if (neighbor_count >= minpts) {
      class_vec[i] <- class_no                               # 8. class(i) = class_no
      clase_iteracion[i] <- class_no
      tipo[i] <- "núcleo"
      for (point in neighbors) {                             # 9. while (more points near i)
        class_vec[point] <- class_no                         # 10. class(point) = class_no
      }
      class_no <- class_no + 1                               # 12. class_no += 1

    } else if (neighbor_count < minpts && core_neig == TRUE) {   # 13.
      class_vec[i] <- 0                                      # 14. border point
      clase_iteracion[i] <- 0
      tipo[i] <- "frontera"

    } else if (neighbor_count < minpts) {                    # 15.
      class_vec[i] <- -1                                     # 16. outlier point
      clase_iteracion[i] <- -1
      tipo[i] <- "atípico"
    }

    # Impresión de la iteración i, paso por paso del pseudocódigo
    orden <- order(Dist[neighbors])                     # vecinos de más cercano a más lejano
    vec <- neighbors[orden]
    con <- cn$conteos[orden]
    imprime(sprintf("\nITERACION i = %d de %d\n", i, m))
    imprime(sprintf("Paso 2    punto i = %d | mes %s | valor = %.4f\n", i, etiqueta[i], D[i, 1]))
    imprime(sprintf("Paso 3    Dist = distancia del punto %d a los %d puntos: %d con Dist <= Eps (%s), %d exceden Eps\n",
                    i, m, neighbor_count, eps, m - neighbor_count))
    imprime(sprintf("Paso 4    neighbors = find(Dist =< Eps): %d vecinos\n", neighbor_count))
    for (k in seq_along(vec)) {
      imprime(sprintf("            j = %3d | mes %s | valor = %8.4f | Dist = %.4f <= %s | su conteo = %3d | nucleo = %s\n",
                      vec[k], etiqueta[vec[k]], D[vec[k], 1], Dist[vec[k]], eps, con[k],
                      if (con[k] >= minpts) "SI" else "NO"))
    }
    imprime(sprintf("Paso 5    neighbor_count = %d\n", neighbor_count))
    imprime(sprintf("Paso 6    core_neig (¿algún vecino es núcleo?) = %s (%d de %d vecinos son núcleo)\n",
                    core_neig, sum(con >= minpts), neighbor_count))
    imprime(sprintf("Paso 7    neighbor_count >= minpts ?  %d >= %d  ->  %s\n",
                    neighbor_count, minpts, if (neighbor_count >= minpts) "SI" else "NO"))
    if (tipo[i] == "núcleo") {
      imprime(sprintf("Pasos 8-12  class(%d) = %d y class(point) = %d para sus %d vecinos; class_no pasa a %d  ->  NUCLEO\n",
                      i, clase_iteracion[i], clase_iteracion[i], neighbor_count, clase_iteracion[i] + 1))
    } else if (tipo[i] == "frontera") {
      imprime(sprintf("Pasos 13-14 neighbor_count < minpts y core_neig = TRUE  ->  class(%d) = 0  ->  FRONTERA\n", i))
    } else {
      imprime(sprintf("Pasos 15-16 neighbor_count < minpts y core_neig = FALSE  ->  class(%d) = -1  ->  ANOMALIA\n", i))
    }
  }

  anomalias <- class_vec == -1
  cat(sprintf("\n========== [L19] Resumen | Eps = %s | Minpts = %d ==========\n", eps, minpts))
  cat(sprintf("Puntos núcleo: %d | Puntos frontera: %d | Puntos atípicos (anomalías): %d\n",
              sum(tipo == "núcleo"), sum(tipo == "frontera"), sum(anomalias)))
  cat(sprintf("Anomalías (i): %s\n", paste(which(anomalias), collapse = ", ")))
  if (!is.null(archivo_csv)) {
    dir.create(dirname(archivo_csv), recursive = TRUE, showWarnings = FALSE)
    tabla_dist <- do.call(rbind, tabla_dist)
    # Decisión final del punto i en cada una de sus filas
    tabla_dist$clase <- clase_iteracion[tabla_dist$i]
    tabla_dist$decision <- c("núcleo" = "nucleo", "frontera" = "frontera",
                             "atípico" = "atipico")[tipo[tabla_dist$i]]
    write.csv(tabla_dist, archivo_csv, row.names = FALSE)
    cat("Distancias de todas las iteraciones guardadas en:", archivo_csv, "\n")
  }

  if (imprimir) {
    cat("Iteraciones completas guardadas en:", archivo_txt, "\n")
    if (interactive()) file.edit(archivo_txt)
  }

  # 19. return class
  return(class_vec)
}
