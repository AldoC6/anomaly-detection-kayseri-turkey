# ---------------------------------------------------------------------------
# Sensibilidad de DBSCAN a eps y minpts (tablas cruzadas eps x minpts)
# Usa las mismas reglas que el pseudocódigo del artículo:
#   núcleo:   neighbor_count >= minpts   (el punto se cuenta a sí mismo)
#   frontera: no es núcleo y algún vecino es núcleo
#   anomalía: no es núcleo y ningún vecino es núcleo
# ---------------------------------------------------------------------------

# Valores límite de los parámetros según los datos
limites_parametros <- function(z) {
  z <- unname(z)
  d <- dist(as.matrix(z))                  # distancia entre cada par de puntos
  list(
    eps_min    = min(d[d > 0]),            # menor distancia entre dos meses distintos
    eps_max    = max(z) - min(z),          # rango de Z: todos son vecinos de todos
    minpts_min = 1,                        # cada punto se cuenta a sí mismo: todos son núcleo
    minpts_max = length(z)                 # el total de puntos
  )
}

# Núcleos, fronteras y anomalías para cada combinación de eps y minpts
tabla_cruzada <- function(z, eps_vals, minpts_vals) {
  z <- unname(z)
  Dist <- abs(outer(z, z, "-"))                    # Dist(i, j) para todos los pares
  filas <- list()
  for (eps in eps_vals) {
    vecino <- Dist <= eps                          # find(Dist =< Eps)
    neighbor_count <- rowSums(vecino)              # count(neighbors)
    for (minpts in minpts_vals) {
      nucleo    <- neighbor_count >= minpts
      core_neig <- as.vector(vecino %*% nucleo) > 0  # check_core_neighbor
      frontera  <- !nucleo & core_neig
      anomalia  <- !nucleo & !core_neig
      filas[[length(filas) + 1]] <- data.frame(eps = eps, minpts = minpts,
                                               nucleo = sum(nucleo), frontera = sum(frontera),
                                               anomalias = sum(anomalia))
    }
  }
  do.call(rbind, filas)
}

# Valores mínimo y máximo de cada parámetro, por qué, y cuántas anomalías da cada uno
# (el otro parámetro se deja fijo como en el artículo: eps 0.1, minpts 4)
tabla_limites <- function(z, lim, eps_ref = 0.1, minpts_ref = 4) {
  anom <- function(eps, minpts) tabla_cruzada(z, eps, minpts)$anomalias
  texto <- function(x) format(signif(x, 3), scientific = FALSE)
  data.frame(
    parametro            = c("eps", "minPts"),
    fijo                 = c(paste("minPts =", minpts_ref), paste("eps =", eps_ref)),
    minimo               = c(texto(lim$eps_min), lim$minpts_min),
    anomalias_min        = c(anom(lim$eps_min, minpts_ref), anom(eps_ref, lim$minpts_min)),
    por_que_min          = c("menor distancia mayor a 0 entre dos meses; con menos solo se juntan meses con Z idéntica",
                             "el punto se cuenta a sí mismo; con 1 todos son núcleo"),
    maximo               = c(texto(lim$eps_max), lim$minpts_max),
    anomalias_max        = c(anom(lim$eps_max, minpts_ref), anom(eps_ref, lim$minpts_max)),
    por_que_max          = c("rango de Z; todos son vecinos de todos y con más ya no cambia nada",
                             "total de meses; nadie puede tener más vecinos que esto")
  )
}

# Tabla en formato cruzado: filas = eps, columnas = minpts, celdas = variable
a_matriz <- function(tabla, variable) {
  mat <- xtabs(as.formula(paste(variable, "~ eps + minpts")), data = tabla)
  matrix(mat, nrow = nrow(mat),
         dimnames = list(eps = rownames(mat), minpts = colnames(mat)))
}

# Mapa de calor de la tabla cruzada, con el valor escrito en cada celda
grafica_mapa_calor <- function(mat, titulo, archivo) {
  png(archivo, width = 1200, height = 900, res = 120)
  on.exit(dev.off())
  par(mar = c(5, 5, 4, 2))
  ne <- nrow(mat); nm <- ncol(mat)
  colores <- colorRampPalette(c("white", "grey60", "black"))(100)
  image(1:nm, 1:ne, t(mat), col = colores, axes = FALSE,
        xlab = "minPts", ylab = "eps", main = titulo)
  axis(1, at = 1:nm, labels = colnames(mat))
  axis(2, at = 1:ne, labels = rownames(mat), las = 1)
  texto <- t(mat)
  col_txt <- ifelse(texto > max(mat) * 0.55, "white", "black")
  text(rep(1:nm, times = ne), rep(1:ne, each = nm), labels = texto, cex = 1.1, col = col_txt)
  box()
}

# Anomalías contra un parámetro, una línea por cada valor del otro
grafica_lineas <- function(tabla, x, grupo, archivo, xlab, titulo, log_x = FALSE) {
  png(archivo, width = 1200, height = 750, res = 120)
  on.exit(dev.off())
  par(mar = c(5, 5, 4, 9), xpd = FALSE)
  plot(NA, xlim = range(tabla[[x]]), ylim = c(0, max(tabla$anomalias)),
       log = if (log_x) "x" else "", xaxt = "n",
       xlab = xlab, ylab = "Número de anomalías", main = titulo)
  axis(1, at = sort(unique(tabla[[x]])))
  grupos <- sort(unique(tabla[[grupo]]))
  for (k in seq_along(grupos)) {
    s <- tabla[tabla[[grupo]] == grupos[k], ]
    s <- s[order(s[[x]]), ]
    lines(s[[x]], s$anomalias, type = "b", pch = k, lty = k)
  }
  par(xpd = TRUE)
  legend("topright", inset = c(-0.2, 0), legend = paste(grupo, "=", grupos),
         pch = seq_along(grupos), lty = seq_along(grupos), bty = "n")
}

# Superficie 3D: eps y minpts en la base, la variable (anomalías, fronteras...) en la altura
grafica_3d <- function(mat, titulo, zlab, archivo, theta = 40, phi = 25) {
  png(archivo, width = 1200, height = 1000, res = 120)
  on.exit(dev.off())
  par(mar = c(2, 2, 3, 2))
  eps    <- as.numeric(rownames(mat))
  minpts <- as.numeric(colnames(mat))
  # color de cada cara según su altura promedio
  alto  <- (mat[-1, -1] + mat[-1, -ncol(mat)] + mat[-nrow(mat), -1] + mat[-nrow(mat), -ncol(mat)]) / 4
  paleta <- colorRampPalette(c("white", "grey60", "grey20"))(100)
  colores <- paleta[cut(alto, 100, labels = FALSE)]
  persp(eps, minpts, mat, theta = theta, phi = phi, expand = 0.7,
        col = colores, border = "grey30", ticktype = "detailed", nticks = 6,
        xlab = "eps", ylab = "minPts", zlab = zlab, main = titulo, cex.axis = 0.8)
}
