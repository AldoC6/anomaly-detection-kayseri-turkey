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
├── equivalencia/             # Scripts de equivalencia Develi vs. Kayseri
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

> El paso 3 necesita datos de uso restringido que no están en el repo; sin ellos, ese paso se salta.
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

