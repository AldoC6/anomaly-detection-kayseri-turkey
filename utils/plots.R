plot_original_vs_deseason <- function(df) {
  
  texto_fecha <- paste(df$Anio, df$Mes, 1, sep = "-")
  fechas <- as.Date(texto_fecha)
  
  # Estilos (se reutilizan en las líneas y en la leyenda) 
  col_orig <- "grey45"
  col_des  <- "black"
  lty_orig <- 2     # punteada
  lty_des  <- 1     # sólida
  lwd_orig <- 1.5
  lwd_des  <- 2
  
  # Rango del eje Y
  # Se redondea a múltiplos de 5; el +5 deja espacio a la leyenda
  rango_y <- range(df$Temp_mensual, df$Z)
  rango_y <- c(floor(rango_y[1] / 5) * 5,
               ceiling(rango_y[2] / 5) * 5 + 5)
  
  # Lienzo + serie original
  plot(fechas, df$Temp_mensual,
       type = "l",
       lty  = lty_orig,
       lwd  = lwd_orig,
       col  = col_orig,
       ylim = rango_y,
       xaxt = "n",
       yaxt = "n",
       xlab = "Time (months)",
       ylab = "Temperature (°C)")
  
  # Eje Y 
  marcas_y <- seq(rango_y[1], rango_y[2], by = 5)
  axis(2, at = marcas_y, las = 1)
  
  # Serie desestacionalizada encima
  lines(fechas, df$Z,
        lty = lty_des,
        lwd = lwd_des,
        col = col_des)
  
  # Línea de referencia en 0
  abline(h = 0, col = "grey80")
  
  # Eje X
  marcas <- as.Date(c("1975-01-01", "1980-06-01", "1985-12-01", "1991-06-01",
                      "1996-12-01", "2002-05-01", "2007-11-01"))
  axis(1, at = marcas, labels = format(marcas, "%m/%Y"), cex.axis = 0.8)
  
  # Leyenda con los mismos estilos
  legend("top",
         legend = c("Original Data", "Deseasoned Data"),
         lty = c(lty_orig, lty_des),
         lwd = c(lwd_orig, lwd_des),
         col = c(col_orig, col_des),
         horiz = TRUE,
         bty = "n")
  
  
  
  invisible(NULL)
  
}

plot_anomalias <- function(df, anomalo, subtitulo = NULL) {
  
  stopifnot(length(anomalo) == nrow(df))
  
  texto_fecha <- paste(df$Anio, df$Mes, 1, sep = "-")
  fechas <- as.Date(texto_fecha)
  
  # Estilos (se reutilizan en plot() y en legend())
  tipo        <- "p"
  pch_normal  <- 4          # x
  pch_anomalo <- 3          # +
  col_normal  <- "grey40"
  col_anomalo <- "black"
  cex_normal  <- 0.8
  cex_anomalo <- 1.2
  
  pch_puntos <- ifelse(anomalo, pch_anomalo, pch_normal)
  col_puntos <- ifelse(anomalo, col_anomalo, col_normal)
  cex_puntos <- ifelse(anomalo, cex_anomalo, cex_normal)
  
  # Eje Y de 1 en 1; el +1 deja espacio a la leyenda
  y_min <- floor(min(df$Z, na.rm = TRUE))
  y_max <- ceiling(max(df$Z, na.rm = TRUE)) + 1
  # Para forzar -3 a 4 con este dataset:
  # y_min <- -3; y_max <- 4
  
  plot(fechas, df$Z,
       type = tipo,
       pch  = pch_puntos,
       col  = col_puntos,
       cex  = cex_puntos,
       ylim = c(y_min, y_max),
       xaxt = "n",
       yaxt = "n",
       xlab = "Time (months)",
       ylab = "Temperature (\u00B0C)")
  
  axis(2, at = seq(y_min, y_max, by = 1), las = 1)
  
  abline(h = 0, col = "grey80")
  
  marcas <- as.Date(c("1975-01-01", "1980-06-01", "1985-12-01", "1991-06-01",
                      "1996-12-01", "2002-05-01", "2007-11-01"))
  axis(1, at = marcas, labels = format(marcas, "%m/%Y"), cex.axis = 0.8)
  
  legend("top",
         legend = c("Normal Data", "Anomalous Data"),
         pch    = c(pch_normal, pch_anomalo),
         col    = c(col_normal, col_anomalo),
         pt.cex = c(cex_normal, cex_anomalo),
         horiz  = TRUE,
         bty    = "n")
  
  if (!is.null(subtitulo)) {
    title(sub = subtitulo)
  }
  
  invisible(NULL)
}



exportar <- function(archivo, df, anomalo, subtitulo) {
  png(archivo, width = 1000, height = 600, res = 120)
  on.exit(dev.off())
  plot_anomalias(df, anomalo, subtitulo)
}