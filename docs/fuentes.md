# Fuentes de datos

Datos usados para comparar la estación de Develi (la del paper) con el Aeropuerto de Kayseri (Erkilet).
Los archivos pesados no están en el repo: se descargan con los enlaces de abajo y se guardan en la carpeta indicada.

## Temperatura diaria — Kayseri, análisis principal (NOAA SSOD v2)

- Cita: NOAA National Centers for Environmental Information. *Synoptic Summary of the Day (SSOD), Version 2*. https://www.ncei.noaa.gov/oa/synoptic-summary-of-the-day/index.html#v2/
- Estación: `TUI0000LTAU` (Kayseri/Erkilet).
- Archivo: `data/AereopuertoKayseri_1975-2007.csv` (es el que usa `main.R`).
- No se usa en la equivalencia: SSOD promedia todas las lecturas del día de 00 a 24 UTC, y MGM usa (T07 + T14 + 2 × T21) / 4 en hora solar local. Para comparar con Develi se usa GHCNh con el método de MGM (sección siguiente).

## Temperatura y humedad relativa — Kayseri (NOAA GHCN-Hourly, GHCNh)

- Cita: Menne, M. J., et al. (2023). *Global Historical Climatology Network – Hourly (GHCNh), Version 1*. NOAA National Centers for Environmental Information. https://doi.org/10.25921/jp3d-3v19
- Descarga (un archivo por año): `https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/access/by-year/<AÑO>/psv/GHCNh_TUI0000LTAU_<AÑO>.psv`
- Carpeta: `data/equivalencia/fuentes/ghcnh_raw/` (la llena `equivalencia/01_descarga_ghcnh_erkilet.R`, ~193 MB).
- Lista de estaciones (nombre, latitud, longitud y altitud; la usa el paso 13): `https://www.ncei.noaa.gov/oa/global-historical-climatology-network/hourly/doc/ghcnh-station-list.txt`, guardada en `data/equivalencia/fuentes/ghcnh-station-list.txt`.
- Método de cálculo (paso 2): la humedad y la temperatura de Kayseri se calculan con el método de MGM, para compararlas con Develi (MGM) con el mismo procedimiento:
  - MGM define la humedad media diaria como la suma de las lecturas de 07:00, 14:00 y 21:00 (hora local) dividida entre 3, y la temperatura media diaria como (T07 + T14 + 2 × T21) / 4; en ambos casos la mensual es el promedio de los días: Meteoroloji Genel Müdürlüğü, *Tanımlar* (definiciones de las estadísticas oficiales), https://mgm.gov.tr/files/resmi-istatistikler/tanimlar.pdf
  - Las observaciones climatológicas se hacen a las 07, 14 y 21 en hora solar media del lugar, calculada con la longitud de la estación: Meteoroloji Genel Müdürlüğü, *Klimatolojik Rasat El Kitabı*, https://www.mgm.gov.tr/FILES/genel/kitaplar/KlimatolojikRasatElKitabi.pdf
  - Para Kayseri (35.50 E) eso equivale a 04:38, 11:38 y 18:38 UTC. Si no hay observación a ±30 min, se interpola entre la anterior y la siguiente (máx. 3 h).

## Precipitación mensual — Kayseri (NOAA GHCN-Monthly v4)

- Cita del dataset: Applequist, S., Durre, I., & Vose, R. (2024). *Global Historical Climatology Network (GHCN) Monthly Precipitation, Version 4*. Estación TUMLP017196. NOAA National Centers for Environmental Information. https://doi.org/10.25921/67zp-5m03 [consultado el 10/11/2026].
- Artículo de referencia: Applequist, S., Durre, I., & Vose, R. (2024). The Global Historical Climatology Network Monthly Precipitation Dataset, Version 4. *Scientific Data, 11*, 633. https://doi.org/10.1038/s41597-024-03457-z
- Descarga: https://www.ncei.noaa.gov/data/ghcnm/v4/precipitation/ (formato y banderas en el readme: https://www.ncei.noaa.gov/data/ghcnm/v4/precipitation/doc/ghcn-m_v4_prcp_readme.txt).
- Estación: `TUMLP017196` (KAYSERI/ERKILET, 38.7 N, 35.5 E, 1070 m).
- Archivo: `data/equivalencia/fuentes/ghcnm_v4_prcp_TUMLP017196.csv` (lo procesa `equivalencia/08_precipitacion_kayseri_ghcnm_v4.R`).
- Validación: en los 21 años de 1975–2006 con los 12 meses, el total anual coincide con Barak (2009, Tabla 25) con una diferencia media de 0.17 %.
- En 1975–2007 faltan 20 meses (1985-09, 1986-07, 1987-09, 1988-08, 1991-01 a 04 y 06, 1993-05, 06, 09, 11 y 12, 1996-06, 1998-05, 1999-04 y 09, 2000-07, 2004-09).

## Precipitación mensual — relleno de meses faltantes de Kayseri (GPCC Full Data V2020, 0.25°)

- Uso: solo para los meses que faltan en GHCN-M v4 de Kayseri. En la celda de Kayseri hay 1 pluviómetro todos los meses (el de Erkilet) y su total anual difiere de Barak (2009) en 5.8 % en promedio.
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

## Temperatura media y precipitación mensuales — Develi

- Fuente: Servicio Meteorológico de Turquía (MGM), estación Develi 17836, 1975–2007. Datos proporcionados por la Prof. Dr. Türkan Bayer Altın (Niğde Ömer Halisdemir Üniversitesi), comunicación personal por correo, 10 de noviembre de 2026.
- Validación: la precipitación anual coincide con Barak (2009, Tabla 33) en los 32 años de 1975–2006, y la temperatura anual sigue la Figura 6 de Sönmez & Somuncu (2016, *Türk Coğrafya Dergisi, 66*).
- Los datos no se incluyen en el repo (permiso de uso, no de publicación). Van en `data/equivalencia/privado/` (ignorada por git).

## Humedad relativa — Develi

- Fuente: Servicio Meteorológico de Turquía (MGM), estación Develi 17836. Datos proporcionados por la Prof. Dr. Filiz Dadaşer-Çelik (Erciyes University, coautora del paper), comunicación personal por correo, 3 de noviembre de 2026.
- Los datos no se incluyen en el repo. Van en `data/equivalencia/privado/` (ignorada por git).

## Precipitación anual y temperatura máxima media anual medidas — Develi y Kayseri (Barak, 2009)

- Cita: Barak, B. (2009). *İç Anadolu Bölgesinde Küresel Isınma Sürecinde Yağış ve Sıcaklık Verilerinde Meydana Gelen Değişimler ve Eğilimler*. Tesis de maestría, Niğde Üniversitesi, Sosyal Bilimler Enstitüsü. Disponible en el Centro Nacional de Tesis de YÖK (https://tez.yok.gov.tr/UlusalTezMerkezi/).
- Tablas usadas: Tabla 33 (Develi, p. 39) y Tabla 25 (Kayseri Merkez, p. 31), "Yağış Etkinliği İndis Değerleri", 1975–2006. Columnas: P = precipitación anual total (mm), Tom = temperatura máxima media anual (°C), índice de Erinç = P / Tom. Los datos son de MGM.
- Archivo: `data/equivalencia/fuentes/barak2009_develi_kayseri_1975-2006.csv` (transcrito de la tesis; columnas `tabla` y `pagina` indican de dónde sale cada fila).
- Verificación: la precipitación anual de Develi coincide exactamente con NOAA GHCN-M v4 (`TUXLP331235`) en los años que este tiene completos (1976, 1982, 1983, 1985, 1988, 1989); en 1990 difiere (298.5 contra 306.0 mm). El índice de Erinç de cada fila es igual a P / Tom.
- La tesis no incluye la temperatura media anual ni la humedad relativa por año (la temperatura media solo aparece agrupada en clases de frecuencia).
- Los totales de Develi coinciden con los datos de la Prof. Dr. Türkan Bayer Altın en los 32 años; los de Kayseri, con NOAA GHCN-M v4 (`TUMLP017196`) en los años que este tiene completos.

## Fuentes descartadas

- NOAA GHCN-M v2 precipitación (`v2.prcp`, estaciones `64917195000` y `64917195006`): https://www.ncei.noaa.gov/pub/data/ghcn/v2/. Develi solo llega a 1990; se reemplazó por los datos de la Prof. Altın (Develi) y GHCN-M v4 (Kayseri). Scripts en `equivalencia/descartados/04_precipitacion_ghcnm_v2.R` y `05_precipitacion_anios_comunes.R`.
- Berkeley Earth, estación 24105 (Develi): Rohde, R. A., & Hausfather, Z. (2020). *Earth System Science Data, 12*, 3469–3479. https://doi.org/10.5194/essd-12-3469-2020. No coincide con el dato de MGM (enero de 1975: −5.3 °C contra −6.0 °C); se reemplazó por los datos de MGM. Archivo: `data/equivalencia/fuentes/24105-TAVG-Data.txt`.
- NOAA GHCN-M v4 temperatura, estación Develi `TUXLT848934` (Menne et al., 2018, *Journal of Climate, 31*(24), 9835–9854; https://doi.org/10.7289/V5XW4GTH). La variante `qfe` está homogeneizada y, desde 1991, sus valores para Develi son estimados. Script en `equivalencia/descartados/06_temperatura_develi_ghcnm_v4.R`.
- NOAA PREC/L 0.5° (Chen et al., 2002, *Journal of Hydrometeorology, 3*(3), 249–266; https://psl.noaa.gov/data/gridded/data.precl.html). No tiene pluviómetros en la celda de Develi después de 1990, así que en ese periodo su valor depende de las estaciones vecinas. Script en `equivalencia/descartados/precipitacion_precl.R`.
- Precipitación de GHCNh y SSOD para Kayseri: de 1975 a 1981 casi no hay reportes, y de 1982 a 1998 los totales anuales quedan, en la mayoría de los años, entre 25 % y 60 % de lo medido por MGM (Barak, 2009); después de 1998 la cobertura es irregular.
