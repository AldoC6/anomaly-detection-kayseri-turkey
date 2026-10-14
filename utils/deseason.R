monthly_z_score <- function(tm) {
  
  tabla_meses <- aggregate(
    Temp_mensual ~ Mes,
    data = tm,
    FUN = function(x) c(Promedio = mean(x), Desv_est = sd(x))
  )
  
  tabla_meses <- do.call(data.frame, tabla_meses)
  names(tabla_meses) <- c("Mes", "Promedio", "Desv_est")
  
  tabla_meses$Mes <- factor(
    tabla_meses$Mes,
    levels = 1:12,
    labels = c("Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio",
               "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre")
  )
  
  stats <- tabla_meses
  stats$Mes <- as.integer(stats$Mes)
  
  res <- merge(tm, stats, by = "Mes", all.x = TRUE)
  
  res$Z <- (res$Temp_mensual - res$Promedio) / res$Desv_est
  
  res <- res[order(res$Anio, res$Mes), c("Anio", "Mes", "Z", "Temp_mensual")]
  rownames(res) <- NULL
  
  return(res)
}