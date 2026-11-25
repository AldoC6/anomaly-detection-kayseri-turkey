monthly_z_score <- function(tm) {
  
  tabla_meses <- aggregate(
    Temp_mensual ~ Mes,
    data = tm,
    FUN = function(x) c(Promedio = mean(x), Desv_est = sd(x))
  )
  
  tabla_meses <- do.call(data.frame, tabla_meses)
  names(tabla_meses) <- c("Mes", "Promedio", "Desv_est")
  
  res <- merge(tm, tabla_meses, by = "Mes", all.x = TRUE)
  
  res$Z <- (res$Temp_mensual - res$Promedio) / res$Desv_est
  
  res <- res[order(res$Anio, res$Mes), c("Anio", "Mes", "Z", "Temp_mensual")]
  rownames(res) <- NULL
  
  return(res)
}