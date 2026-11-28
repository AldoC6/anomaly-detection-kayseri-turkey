# Detección de anomalías en temperatura con DBSCAN — Kayseri, Turquía

Replicación del artículo de Çelik, Dadaşer-Çelik y Dokuz (2011), *Anomaly Detection in Temperature Data Using DBSCAN Algorithm*, con datos de la estación del Aeropuerto de Kayseri (Erkilet): 33 años, de enero de 1975 a diciembre de 2007 (el artículo indica "33 años, de 1975 a 2008").

El programa:

1. Lee la temperatura media diaria de `data/AereopuertoKayseri_1975-2008.csv`.
2. Limpia los datos y calcula la temperatura media mensual.
3. Quita la estacionalidad con el *monthly z-score*.
4. Detecta anomalías con el método estadístico (μ ± kσ) y con DBSCAN, programado a partir del pseudocódigo del artículo (Algoritmo 1). El paquete `dbscan` se usa solo para verificar que los resultados sean iguales.
5. Genera las figuras 3, 4, 5 y 6 del artículo en `storage/`.
6. Analiza la sensibilidad de DBSCAN a `eps` y `minPts`: valores límite y tablas cruzadas de grupos, anomalías, fronteras y núcleos, con sus gráficas (mapas de calor, líneas y superficies 3D).

Las fuentes de los datos y de los métodos están en [`docs/fuentes.md`](docs/fuentes.md).

---

## Requisitos

- **R 4.6.1** (versión registrada en `renv.lock`) y RStudio.
- **[Rtools](https://cran.r-project.org/bin/windows/Rtools/)**, la versión que corresponda a tu R. **Solo en Windows.** Es obligatorio: `dbscan 1.1-5` es una versión antigua y se compila desde código fuente.

> Después de instalar Rtools, **reinicia RStudio** para que se actualice el PATH.

## Instalación

### 1. Clonar el repositorio

```bash
git clone https://github.com/AldoC6/anomaly-detection-kayseri-turkey.git
cd anomaly-detection-kayseri-turkey
```

### 2. Abrir el proyecto

Haz doble clic en `anomaly-detection-kayeri-turkey.Rproj` (o en RStudio: *File > Open Project*).

La primera vez, `renv` se activa automáticamente a través del archivo `.Rprofile`. Si avisa que no está instalado, déjalo instalarse.

### 3. Restaurar los paquetes

En la consola de R:

```r
renv::restore()
```

Responde `y` cuando pregunte. Esto instala las versiones exactas que indica `renv.lock`.

> La primera vez puede tardar varios minutos: `dbscan 1.1-5` se compila desde código fuente.

### 4. Verificar

```r
renv::status()             # debe responder: No issues found
packageVersion("dbscan")   # debe devolver '1.1.5'
```

## Ejecución

Con el proyecto abierto, ejecuta `main.R` completo (en RStudio: *Source*, o `Ctrl + Shift + S`).

Las figuras se guardan en `storage/`:

| Figura del artículo | Archivo | Contenido |
|---|---|---|
| 3 | `storage/original-vs-deseason.png` | Temperatura mensual original y desestacionalizada |
| 4 | `storage/fig4/a.png`, `b.png` | Método estadístico, μ ± 2σ y μ ± 3σ |
| 5 | `storage/fig5/a.png`, `b.png`, `c.png` | DBSCAN, minPts = 4 y eps = 0.05, 0.1, 0.15 |
| 6 | `storage/fig6/a.png`, `b.png`, `c.png` | DBSCAN, eps = 0.1 y minPts = 2, 4, 6 |

En la consola debe aparecer `Coincide dbscan library == dbscan pseudocodigo =  TRUE`: la implementación propia marca los mismos meses que el paquete `dbscan`.

Además se guardan:

| Carpeta | Archivos | Contenido |
|---|---|---|
| `storage/dbscan/` | `eps{eps}_minpts{minpts}_distancias.csv` | Para cada configuración del artículo: distancia de cada par de puntos (i, j), si es vecino, conteo de vecinos, clase y decisión (núcleo, frontera o atípico) |
| `storage/sensibilidad/` | `limites_eps_minpts.csv` | Valores mínimo y máximo de eps y minPts, y por qué |
| | `grupos_`, `anomalias_`, `frontera_`, `nucleo_eps_x_minpts.csv` | Tablas cruzadas eps × minPts en la zona donde cambian los resultados (eps 0.02–0.3, minPts 2–12) |
| | `*_completa_eps_x_minpts.csv` | Las mismas tablas hasta los valores límite (eps 0.0000347–5.72, minPts 1–396) |
| | `tabla_cruzada_eps_minpts.csv` | Todas las combinaciones de la zona principal en formato largo |
| | `mapa_*.png`, `anomalias_vs_*.png`, `*_3d.png` | Mapas de calor, gráficas de líneas y superficies 3D |

> Si algún `.csv` de `storage/` está abierto en Excel, ciérralo antes de ejecutar; si no, R no puede reemplazarlo.

### Corrida paso a paso con otros parámetros

Después de ejecutar `main.R`, para ver cómo DBSCAN clasifica cada mes con cualquier `eps` y `minPts`:

```r
dbscan_pseudocodigo(z, 0.05, 3, archivo_csv = "storage/dbscan/prueba.csv", imprimir = TRUE)
```

Imprime el resumen en la consola, guarda las distancias en el CSV y escribe cada iteración (vecinos, conteos y decisión) en `storage/dbscan/iteraciones_eps0.05_minpts3.txt`, que RStudio abre automáticamente.

---

## Estructura del proyecto

```
.
├── main.R                    # Script principal: ejecuta todo el análisis
├── utils/
│   ├── clean.R               # Limpieza de datos (centinelas, NA, fechas duplicadas)
│   ├── deseason.R            # Monthly z-score (desestacionalización)
│   ├── stat_method.R         # Método estadístico μ ± kσ
│   ├── dbscan_method.R       # DBSCAN según el pseudocódigo del artículo y verificación con el paquete
│   ├── sensibilidad.R        # Límites y tablas cruzadas de eps × minPts, gráficas
│   └── plots.R               # Gráficas y exportación de figuras
├── data/
│   └── AereopuertoKayseri_1975-2008.csv   # Temperatura media diaria, 01/1975–12/2007 (NOAA SSOD)
├── storage/                  # Salidas de main.R: fig4/, fig5/, fig6/, dbscan/, sensibilidad/
├── docs/
│   └── fuentes.md            # Referencias de los datos y los métodos
├── renv/                     # Configuración de renv
├── renv.lock                 # Versiones exactas de los paquetes
└── .Rprofile                 # Activa renv al abrir el proyecto
```
