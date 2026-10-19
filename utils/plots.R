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