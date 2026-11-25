# Paso 17 - ¿Los meses que pasan el 10 % son esporádicos o seguidos?
# Pregunta del inge (18/11/2026). Para cada variable dibuja una cuadrícula
# año (filas) x mes (columnas): rojo = el mes pasa el 10 %, gris = no pasa,
# azul = outlier A (Develi casi en 0, el % no aplica), blanco = sin dato,
# punto negro = outlier B (diferencia anómala en unidades; ver paso 16). Si las fallas fueran seguidas (un cambio de instrumento o de
# lugar), se verían como un bloque de años en rojo; si son esporádicas o de
# temporada, se ven repartidas o en columnas de ciertos meses.
# Además cuenta las rachas de meses seguidos que pasan el 10 %.
# Entradas: privado/comparacion_10pct/<variable>_<estacion>.csv (paso 16)
# Salida:   storage/equivalencia/meses_10pct_<estacion>.png, una por estación
#           (solo pasa/no pasa; las variables que no tenga la estación se omiten)
# ============================================================

anios    <- 1975:2007
umbral   <- 10

dir_tablas <- "data/equivalencia/privado/comparacion_10pct"
dir_salida <- "storage/equivalencia"
dir.create(dir_salida, showWarnings = FALSE, recursive = TRUE)

variables <- c(temperatura_C    = "Temperatura (% en grados C)",
               humedad_relativa = "Humedad relativa",
               precipitacion    = "Precipitacion")
meses_txt <- c("Ene", "Feb", "Mar", "Abr", "May", "Jun",
               "Jul", "Ago", "Sep", "Oct", "Nov", "Dic")

# Rachas: largo de cada tramo de meses seguidos que pasan el 10 %
rachas <- function(pasa) {
  r <- rle(pasa)
  r$lengths[!is.na(r$values) & r$values]
}

# Estaciones: todas las que tengan al menos una tabla del paso 16
archivos   <- list.files(dir_tablas, pattern = "\\.csv$")
prefijos   <- paste0("^(", paste(names(variables), collapse = "|"), ")_")
estaciones <- unique(sub("\\.csv$", "", sub(prefijos, "", archivos[grepl(prefijos, archivos)])))

for (estacion in estaciones) {
vars_est <- names(variables)[file.exists(
  file.path(dir_tablas, paste0(names(variables), "_", estacion, ".csv")))]
cat("\n==", estacion, "==\n")

png(file.path(dir_salida, paste0("meses_10pct_", estacion, ".png")),
    width = 500 * length(vars_est) + 100, height = 1100, res = 130)
par(mfrow = c(1, length(vars_est)), mar = c(4, 4, 5, 1), oma = c(0, 0, 3, 0))

for (v in vars_est) {
  tabla <- read.csv(file.path(dir_tablas, paste0(v, "_", estacion, ".csv")))

  # Cuadrícula completa 1975-2007 x 12 meses (NA = sin dato)
  todos <- expand.grid(Mes = 1:12, Anio = anios)
  todos <- merge(todos, tabla, by = c("Anio", "Mes"), all.x = TRUE)
  todos <- todos[order(todos$Anio, todos$Mes), ]
  out   <- ifelse(is.na(todos$Outlier), "", todos$Outlier)
  pasa  <- ifelse(out == "A", NA, todos$Diferencia_pct > umbral)

  # Matriz meses x años: 1 = no pasa, 2 = pasa, 3 = outlier A, NA = sin dato
  m <- matrix(ifelse(out == "A", 3, ifelse(pasa, 2, 1)), nrow = 12, ncol = length(anios))

  image(1:12, anios, m, col = c("grey85", "firebrick", "steelblue2"), zlim = c(1, 3),
        xaxt = "n", yaxt = "n", xlab = "", ylab = "",
        ylim = rev(range(anios) + c(-0.5, 0.5)))
  axis(1, at = 1:12, labels = meses_txt, las = 2, cex.axis = 0.8)
  axis(2, at = seq(1975, 2005, 5), las = 1, cex.axis = 0.8)
  abline(h = anios + 0.5, col = "white", lwd = 0.5)
  abline(v = 1:11 + 0.5,  col = "white", lwd = 0.5)
  b <- out == "B"
  points(todos$Mes[b], todos$Anio[b], pch = 19, cex = 0.6)

  r <- rachas(pasa)
  title(main = variables[[v]], line = 3)
  mtext(sprintf("%d de %d meses (%.0f %%) sin outliers A | A: %d | B: %d | racha max: %d",
                sum(pasa, na.rm = TRUE), sum(!is.na(pasa)),
                100 * mean(pasa, na.rm = TRUE), sum(out == "A"), sum(out == "B"),
                max(c(0, r))),
        side = 3, line = 1.2, cex = 0.7)

  cat(variables[[v]], ": pasan", sum(pasa, na.rm = TRUE), "de", sum(!is.na(pasa)),
      "| rachas:", length(r), "| máx:", max(c(0, r)), "\n  por mes:",
      tapply(pasa, todos$Mes, sum, na.rm = TRUE), "\n")
}

mtext(paste0("Develi vs ", gsub("_", " ", estacion),
             " (1975-2007)\nrojo = pasa el 10 %, gris = no pasa, azul = outlier A, punto = outlier B, blanco = sin dato"),
      outer = TRUE, cex = 0.8, font = 2, line = 0.5)
dev.off()
cat("Gráfica:", file.path(dir_salida, paste0("meses_10pct_", estacion, ".png")), "\n")
}
