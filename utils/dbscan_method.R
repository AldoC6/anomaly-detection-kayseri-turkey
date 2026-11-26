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
  D <- as.matrix(z)
  m <- nrow(D)

  # Imprime en consola solo si imprimir = TRUE
  imprime <- function(...) if (imprimir) cat(...)

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

  imprime(sprintf("\n========== DBSCAN | Eps = %s | Minpts = %d | [L1] m = %d ==========\n",
              eps, minpts, m))

  # 2. for i = 1 to m
  for (i in seq_len(m)) {
    imprime(sprintf("\n--- [L2] Iteración %d de %d | punto i = %d | valor = %.4f ---\n", i, m, i, D[i, 1]))

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
    imprime(sprintf("  [L4] neighbors (Dist <= %s): %s\n", eps,
                paste(sprintf("%d [Dist = %.4f]", neighbors, Dist[neighbors]), collapse = ", ")))
    imprime(sprintf("       puntos que exceden Eps (Dist > %s): %d\n", eps, m - length(neighbors)))

    # 5. neighbor_count = count(neighbors)
    neighbor_count <- length(neighbors)
    imprime(sprintf("  [L5] neighbor_count = %d\n", neighbor_count))

    # 6. core_neig = check_core_neighbor(neighbors)
    cn <- check_core_neighbor(neighbors)
    core_neig <- cn$hay_nucleo
    imprime(sprintf("  [L6] conteo de cada vecino: %s\n",
                paste(sprintf("%d -> %d", neighbors, cn$conteos), collapse = ", ")))
    imprime(sprintf("  [L6] core_neig = %s%s\n", core_neig,
                if (core_neig) paste0(" (vecinos núcleo: ", paste(cn$nucleos, collapse = ", "), ")") else ""))

    # 7. if (neighbor_count >= minpts)
    if (neighbor_count >= minpts) {
      imprime(sprintf("  [L7] neighbor_count (%d) >= minpts (%d) -> punto núcleo\n", neighbor_count, minpts))
      class_vec[i] <- class_no                               # 8. class(i) = class_no
      clase_iteracion[i] <- class_no
      tipo[i] <- "núcleo"
      for (point in neighbors) {                             # 9. while (more points near i)
        class_vec[point] <- class_no                         # 10. class(point) = class_no
      }
      imprime(sprintf("  [L8-12] class(%d) = %d y class(point) = %d para los puntos: %s\n",
                  i, class_no, class_no, paste(neighbors, collapse = ", ")))
      class_no <- class_no + 1                               # 12. class_no += 1

    } else if (neighbor_count < minpts && core_neig == TRUE) {   # 13.
      class_vec[i] <- 0                                      # 14. border point
      clase_iteracion[i] <- 0
      tipo[i] <- "frontera"
      imprime(sprintf("  [L13-14] neighbor_count (%d) < minpts (%d) y core_neig = TRUE -> class(%d) = 0 (punto frontera)\n",
                  neighbor_count, minpts, i))

    } else if (neighbor_count < minpts) {                    # 15.
      class_vec[i] <- -1                                     # 16. outlier point
      clase_iteracion[i] <- -1
      tipo[i] <- "atípico"
      imprime(sprintf("  [L15-16] neighbor_count (%d) < minpts (%d) y core_neig = FALSE -> class(%d) = -1 (punto atípico, ANOMALÍA)\n",
                  neighbor_count, minpts, i))
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

  # 19. return class
  return(class_vec)
}
