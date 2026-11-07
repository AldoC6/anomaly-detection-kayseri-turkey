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

## Humedad relativa — Develi

- Fuente: Servicio Meteorológico de Turquía (MGM), estación Develi 17836. Datos proporcionados por la Prof. Dr. Filiz Dadaşer-Çelik (Erciyes University, coautora del paper), comunicación personal por correo, 3 de noviembre de 2026.
- Los datos no se incluyen en el repo. Van en `data/equivalencia/privado/` (ignorada por git).
