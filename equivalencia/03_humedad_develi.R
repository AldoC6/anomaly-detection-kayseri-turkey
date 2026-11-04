# Datos de uso restringido: van en data/equivalencia/privado/ (no se suben a git).
# Entrada: la hoja de 17836_RelHum.xlsx exportada como CSV con el mismo nombre.
df_humity <- read.csv("data/equivalencia/privado/17836_RelHum.csv", header = TRUE)
names(df_humity) <- c("station", "year", "month", "relative_humidity")   # el encabezado original trae "relative _humidity"

kay <- df_humity[, c("year","month", "relative_humidity")]

names(kay)[3] <- "relative_humidity"


kay <- kay[
  order(kay$year,
        kay$month),
]


head(kay)

dim(kay)


rhanual <- aggregate(
  relative_humidity ~ year,
  data = kay,
  FUN = mean
)

head(rhanual)
dim(rhanual)

write.csv(rhanual, "data/equivalencia/privado/develi-data-relative-humidity.csv", row.names = FALSE)
