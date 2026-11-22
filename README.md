## Requisitos previos antes de ejecutar el proyecto
 
 - [Rtools](https://cran.r-project.org/bin/windows/Rtools/rtools40.html) | La que corresponda a tu versión de R | **Solo Windows.** Obligatorio: `dbscan 1.1-5` es una versión antigua y se compila desde código fuente 

> Después de instalar Rtools, **reinicia RStudio** para que se actualice el PATH.

## Cómo levantar el proyecto
 
### 1. Clonar el repositorio
 
```bash
git clone <URL-DEL-REPOSITORIO>
cd anomaly-detection-kayeri-turkey
```
 
### 2. Abrir el proyecto
 
Haz doble clic en `anomaly-detection-kayeri-turkey.Rproj` (o en RStudio: *File > Open Project*).
 
La primera vez, `renv` se activará automáticamente a través del archivo `.Rprofile`. Si te pregunta o te avisa que no está instalado, déjalo instalarse.
 
### 3. Restaurar los paquetes
 
En la consola de R:
 
```r
renv::restore()
```
 
Responde `y` cuando pregunte. Esto instala en una biblioteca privada del proyecto las versiones exactas que indica `renv.lock`.
 
> La primera vez puede tardar varios minutos: `dbscan 1.1-5` se compila desde código fuente (~2 min).
 
### 4. Verificar que todo quedó bien
 
```r
renv::status()
```
 
Debe responder: `No issues found -- the project is in a consistent state.`
 
Para confirmar la versión de dbscan:
 
```r
packageVersion("dbscan")   # debe devolver ‘1.1.5’
```


---
 
## Estructura del proyecto
 
```
.
├── main.R                    # Script principal del análisis
├── utils/                    # Funciones auxiliares (limpieza, desestacionalización, gráficas, métodos)
├── exploracion/              # Scripts de exploración (promedios mensuales)
├── equivalencia/             # Scripts de equivalencia Develi vs. otras estaciones
│   ├── candidatas/           # Temperatura y precipitación de las candidatas (GHCN-M v4)
│   ├── filtro_ghcnm_v4/      # Búsqueda exploratoria de estaciones equivalentes (ver nota)
│   └── descartados/          # Alternativas probadas que no se usaron
├── docs/
│   └── fuentes.md            # Citas y enlaces de descarga de los datos
├── data/
│   ├── AereopuertoKayseri_1975-2007.csv
│   └── equivalencia/
│       ├── fuentes/          # Datos originales descargados (los pesados no se suben)
│       ├── procesados/       # Salidas de los scripts de equivalencia
│       └── privado/          # Datos de uso restringido (ignorado por git)
├── renv/                     # Configuración de renv (la biblioteca no se sube a Git)
├── renv.lock                 # Versiones exactas de los paquetes
└── .Rprofile                 # Activa renv al abrir el proyecto
```
 
---

## Equivalencia de estaciones

El paper usa la estación de Develi; nosotros usamos el Aeropuerto de Kayseri (Erkilet). Estos scripts comparan
las dos estaciones (media y desviación estándar) en temperatura, humedad relativa y precipitación, en periodos comparables.
Las fuentes y enlaces de descarga están en [`docs/fuentes.md`](docs/fuentes.md).

Se corren desde la raíz del proyecto, en este orden:

| # | Script | Entrada | Salida (en `data/equivalencia/`) |
|---|---|---|---|
| 1 | `equivalencia/01_descarga_ghcnh_erkilet.R` | Descarga de GHCNh | `procesados/AereopuertoKayseri_GHCNh_1975-2007.csv` |
| 2 | `equivalencia/02_humedad_kayseri_ghcnh.R` | `fuentes/ghcnh_raw/` (del paso 1) | `procesados/kayseri-erkilet-relative-humidity[-diario\|-mensual].csv` y `procesados/kayseri-erkilet-temperature[-diario\|-mensual].csv`: por día, por mes y por año (método MGM: 07, 14 y 21 h) |
| 3 | `equivalencia/03_humedad_develi.R` | `privado/17836_RelHum.csv` | `privado/develi-data-relative-humidity.csv` |
| 7 | `equivalencia/07_precipitacion_gpcc.R` | Descarga de GPCC 0.25° (DWD) | `procesados/precip_gpcc025_develi_kayseri_1975-2007.csv` (solo para rellenar los meses que faltan en el paso 8) |
| 8 | `equivalencia/08_precipitacion_kayseri_ghcnm_v4.R` | `fuentes/ghcnm_v4_prcp_TUMLP017196.csv` | `procesados/kayseri_precip_ghcnm_v4_1975-2007.csv` |
| 9 | `equivalencia/09_referencia_develi.R` | `privado/` (datos MGM de Develi: T y P de la Prof. Altın, HR de la Prof. Dadaşer-Çelik) | `privado/develi_referencia_[mensual\|anual].csv` |
| 10 | `equivalencia/10_filtro_temperatura_mundo.R` | `fuentes/ghcnm_v4/` (GHCN-M v4 qcu) | `privado/candidatas_temp_*.csv` y `privado/resumen_temp_*.csv` |
| 11 | `equivalencia/11_candidatas_ghcnh_mgm.R` | `fuentes/ghcnh_raw/` | `procesados/candidatas_mgm_mensual.csv` (T y HR con el método MGM) |
| 12 | `equivalencia/12_erzincan_isd_mgm.R` | `fuentes/isd/`, `fuentes/ghcnm_v4/prcp/` | `procesados/erzincan_mensual.csv` |
| 13 | `equivalencia/13_candidatas_latitud_altitud.R` | `fuentes/ghcnh-station-list.txt` | `privado/candidatas_latitud_altitud.csv` (provisional) |
| 14 | `equivalencia/14_candidatas_ghcnh_lat_alt.R` | `fuentes/ghcnh_raw/` | `procesados/candidatas_lat_alt_mgm_mensual.csv` |
| 15 | `equivalencia/15_develi_ghcnm_v4_qcu.R` | `fuentes/ghcnm_v4/` | `procesados/develi_tavg_ghcnm_v4_qcu.csv` (Develi cruda en NOAA, para validar los datos de Develi) |
| 16 | `equivalencia/16_meses_anios_sobre_10pct.R` | `privado/develi_referencia_mensual.csv`, `procesados/`, `fuentes/ghcnm_v4/` | `procesados/resumen_meses_anios_10pct.csv` y `privado/comparacion_10pct/` (tabla mes a mes por estación y variable, con outliers A/B) |
| 17 | `equivalencia/17_grafica_meses_10pct.R` | `privado/comparacion_10pct/` (paso 16) | `storage/equivalencia/meses_10pct_<estacion>.png` |

Los pasos 16 y 17 aplican el criterio del docente (`|Develi − estación| × 100 / Develi ≤ 10 %`) mes por mes y año por año
contra todas las estaciones disponibles: Erkilet, Tomarza, Pınarbaşı y Sarız (provincia de Kayseri, hasta 1990),
Niğde, Kırşehir, Konya, Afyon, Ankara Etimesgut y Çorum. Outliers (se marcan, no se rellenan datos):
**A** = Develi casi en 0 (lluvia < 1 mm o temperatura entre −1 y 1 °C), donde el porcentaje no tiene sentido;
**B** = diferencia en unidades fuera de Q1 − 1.5·IQR o Q3 + 1.5·IQR (Tukey), a investigar contra estaciones vecinas.

> Los pasos 3, 9, 10, 13, 16 y 17 necesitan datos de uso restringido (`privado/`) que no están en el repo: se usan con permiso, pero no se publican.
> `candidatas/` extrae temperatura y precipitación de Niğde, Kırşehir, Konya y Afyon de GHCN-M v4. `filtro_ghcnm_v4/` es la búsqueda
> exploratoria que usó la versión ajustada de NOAA (qfe, con valores estimados), GPCC, kriging y Open-Meteo; se conserva como
> registro, pero esos datos modelados o estimados **no** se usan como dataset.
> Los pasos 1 y 7 descargan solos sus datos (ver `docs/fuentes.md`); el 8 usa el CSV que ya está en `fuentes/`.
> Los pasos 4, 5 y 6 se descartaron; sus scripts están en `equivalencia/descartados/` (el motivo, en `docs/fuentes.md`).
> Las funciones del método de MGM que usa el paso 2 están en `equivalencia/funciones_mgm.R`.

---

## Trabajo en equipo con renv
 
### Al instalar un paquete
 
1. Instálalo **dentro del proyecto**:
```r
   renv::install("nombre_paquete")            # última versión
   renv::install("nombre_paquete@x.y-z")      # versión específica
```
2. Úsalo en algún script **guardado** dentro del proyecto (por ejemplo `library(nombre_paquete)`), porque `renv` detecta dependencias escaneando los archivos `.R`.
3. Actualiza el lockfile:
```r
   renv::snapshot()
```
4. Haz commit y push de `renv.lock` junto con tu código:
```bash
   git add renv.lock
   git commit -m "Agrega <paquete> al renv.lock"
   git push
```
 
### Si haces `git pull` y cambió `renv.lock`
 
Sincroniza tus paquetes con los del equipo:
 
```r
renv::restore()
```

 
### Comandos útiles
 
| Comando | Para qué sirve |
|---|---|
| `renv::status()` | Ver si tus paquetes coinciden con el lockfile |
| `renv::restore()` | Instalar lo que dice el lockfile |
| `renv::snapshot()` | Guardar en el lockfile lo que usa el código |
| `renv::dependencies()` | Ver qué paquetes detecta `renv` en los scripts |
 
---

