# Fuentes de datos

Datos usados para comparar la estación de Develi (la del paper) con el Aeropuerto de Kayseri (Erkilet).
Los archivos pesados no están en el repo: se descargan con los enlaces de abajo y se guardan en la carpeta indicada.

## Temperatura diaria — Aeropuerto de Kayseri (NOAA, SSOD v2)

- Estación: TUI0000LTAU (Kayseri/Erkilet).
- Archivo: `data/AereopuertoKayseri_1975-2007.csv` (es el que usa `main.R`).

## Humedad relativa horaria — NOAA GHCN-Hourly (GHCNh)

- Cita: Menne, M. J., et al. (2023). *Global Historical Climatology Network – Hourly (GHCNh), Version 1*. NOAA National Centers for Environmental Information. https://doi.org/10.25921/jp3d-3v19
- Descarga (un archivo por año): `https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/<AÑO>/psv/GHCNh_TUI0000LTAU_<AÑO>.psv`
- Carpeta: `data/equivalencia/fuentes/ghcnh_raw/` (la llena `equivalencia/01_descarga_ghcnh_erkilet.R`, ~193 MB).
- Método de cálculo (paso 2): la humedad de Kayseri se calcula con el método de MGM, para compararla con Develi (MGM) con el mismo procedimiento:
  - MGM define la humedad media diaria como la suma de las lecturas de 07:00, 14:00 y 21:00 (hora local) dividida entre 3, y la mensual como el promedio de los días: Meteoroloji Genel Müdürlüğü, *Tanımlar* (definiciones de las estadísticas oficiales), https://mgm.gov.tr/files/resmi-istatistikler/tanimlar.pdf
  - Las observaciones climatológicas se hacen a las 07, 14 y 21 en hora solar media del lugar, calculada con la longitud de la estación: Meteoroloji Genel Müdürlüğü, *Klimatolojik Rasat El Kitabı*, https://www.mgm.gov.tr/FILES/genel/kitaplar/KlimatolojikRasatElKitabi.pdf
  - Para Kayseri (35.50 E) eso equivale a 04:38, 11:38 y 18:38 UTC. Si no hay observación a ±30 min, se interpola entre la anterior y la siguiente (máx. 3 h).

## Precipitación mensual — NOAA GHCN-Monthly v2 (`v2.prcp`)

- Cita: Peterson, T. C., & Vose, R. S. (1997). An overview of the Global Historical Climatology Network temperature database. *Bulletin of the American Meteorological Society, 78*(12), 2837–2849. Conjunto de datos: https://doi.org/10.7289/V5X34VDR
- Descarga: https://www.ncei.noaa.gov/pub/data/ghcn/v2/ (`v2.prcp`, `v2.prcp.inv`, `v2.prcp.readme`).
- Estaciones: `64917195000` (Aeropuerto Kayseri) y `64917195006` (Develi).
- Carpeta: `data/equivalencia/fuentes/` (`v2.prcp` pesa ~84 MB y no se sube a git; el `.inv` y el `.readme` sí están).

## Temperatura mensual — Develi (Berkeley Earth, estación 24105)

- Cita: Rohde, R. A., & Hausfather, Z. (2020). The Berkeley Earth Land/Ocean Temperature Record. *Earth System Science Data, 12*, 3469–3479. https://doi.org/10.5194/essd-12-3469-2020
- Página de la estación: https://berkeleyearth.lbl.gov/stations/24105
- Archivo: `data/equivalencia/fuentes/24105-TAVG-Data.txt`.

## Temperatura mensual — Develi (NOAA GHCN-Monthly v4)

- Cita del dataset: Menne, M. J., et al. *Global Historical Climatology Network – Monthly Temperature, Version 4*. NOAA National Centers for Environmental Information. https://doi.org/10.7289/V5XW4GTH
- Artículo de referencia: Menne, M. J., Williams, C. N., Gleason, B. E., Rennie, J. J., & Lawrimore, J. H. (2018). The Global Historical Climatology Network Monthly Temperature Dataset, Version 4. *Journal of Climate, 31*(24), 9835–9854. https://doi.org/10.1175/JCLI-D-18-0094.1
- Descarga: https://www.ncei.noaa.gov/pub/data/ghcn/v4/ghcnm.tavg.latest.qfe.tar.gz (variante `qfe`; las variantes `qcu`/`qcf`/`qfe` se describen en el readme de NOAA, sección 2.2.1: https://www.ncei.noaa.gov/pub/data/ghcn/v4/readme.txt).
- Estación: `TUXLT848934` (DEVELI, 38.4 N, 35.5 E, 1180 m).
- Carpeta: `data/equivalencia/fuentes/ghcnm_v4/` (la llena `equivalencia/06_temperatura_develi_ghcnm_v4.R`; no se sube a git).

## Precipitación mensual — Develi y Kayseri (GPCC Full Data V2020, 0.25°)

- GPCC = *Global Precipitation Climatology Centre* (Servicio Meteorológico Alemán, DWD): malla mensual de precipitación interpolada a partir de pluviómetros. Incluye la variable `numgauge` (número de pluviómetros usados en cada celda).
- Cita: Schneider, U., Becker, A., Finger, P., Rustemeier, E., & Ziese, M. (2020). *GPCC Full Data Monthly Product Version 2020 at 0.25°: Monthly Land-Surface Precipitation from Rain-Gauges built on GTS-based and Historical Data*. DWD. https://doi.org/10.5676/DWD_GPCC/FD_M_V2020_025
- Descarga: archivos por década `full_data_monthly_v2020_<década>_025.nc.gz` (1971_1980, 1981_1990, 1991_2000, 2001_2010): https://opendata.dwd.de/climate_environment/GPCC/full_data_monthly_v2020/025/
- Unidades: mm/mes.
- Celdas (centro de la celda 0.25°):
  - Develi: 38.375 N, 35.625 E. Contiene la coordenada registrada de la estación (38.4 N, 35.5 E en GHCN-M), que es la que usa GPCC para ubicar el pluviómetro.
  - Develi (pueblo, solo referencia): 38.375 N, 35.375 E. Contiene la coordenada MGM del pueblo; no tiene pluviómetro.
  - Kayseri: 38.875 N, 35.375 E. Contiene el Aeropuerto de Kayseri (Erkilet).
- Validación: en 1975–1990 los meses sin pluviómetro de la celda de Develi coinciden con los meses faltantes de Develi en NOAA GHCN-M v4 (`TUXLP331235`).
- Carpeta: `data/equivalencia/fuentes/gpcc/` (la llena `equivalencia/07_precipitacion_gpcc.R`; pesada, no se sube a git).
- Fuente descartada: NOAA PREC/L 0.5° (Chen et al., 2002, *Journal of Hydrometeorology, 3*(3), 249–266; https://psl.noaa.gov/data/gridded/data.precl.html). No tiene pluviómetros en la celda de Develi después de 1990, así que en ese periodo su valor depende de las estaciones vecinas. Script en `equivalencia/descartados/precipitacion_precl.R`.

## Humedad relativa — Develi

- Fuente: Servicio Meteorológico de Turquía (MGM), estación Develi 17836. Datos proporcionados por la Prof. Dr. Filiz Dadaşer-Çelik (Erciyes University, coautora del paper), comunicación personal por correo, 3 de noviembre de 2026.
- Los datos no se incluyen en el repo. Van en `data/equivalencia/privado/` (ignorada por git).
