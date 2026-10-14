monthly_z_score <- function(tm, tabla_meses) {
  
  stats <- tabla_meses
  stats$Mes <- as.integer(stats$Mes)
  
  res <- merge(tm, stats, by = "Mes", all.x = TRUE)
  
  res$Z <- (res$Temp_mensual - res$Promedio) / res$Desv_est
  
  res <- res[order(res$Anio, res$Mes), c("Anio", "Mes", "Z", "Temp_mensual")]
  rownames(res) <- NULL
  
  return(res)
}