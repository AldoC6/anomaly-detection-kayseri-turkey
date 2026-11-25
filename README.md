# Detección de anomalías en temperatura con DBSCAN — Kayseri, Turquía

Replicación del artículo de Çelik, Dadaşer-Çelik y Dokuz (2011), *Anomaly Detection in Temperature Data Using DBSCAN Algorithm*, con datos de la estación del Aeropuerto de Kayseri (Erkilet), 1975–2007.

El programa:

1. Lee la temperatura media diaria de `data/AereopuertoKayseri_1975-2007.csv`.
2. Limpia los datos y calcula la temperatura media mensual.
3. Quita la estacionalidad con el *monthly z-score*.
4. Detecta anomalías con el método estadístico (μ ± kσ) y con DBSCAN.
5. Genera las figuras 3, 4, 5 y 6 del artículo en `storage/`.

Las fuentes de los datos y de los métodos están en [`docs/fuentes.md`](docs/fuentes.md).

---

## Requisitos

- **R 4.6.1** (versión registrada en `renv.lock`) y RStudio.
- **[Rtools](https://cran.r-project.org/bin/windows/Rtools/)**, la versión que corresponda a tu R. **Solo en Windows.** Es obligatorio: `dbscan 1.1-5` es una versión antigua y se compila desde código fuente.

> Después de instalar Rtools, **reinicia RStudio** para que se actualice el PATH.

## Instalación

### 1. Clonar el repositorio

```bash
git clone <URL-DEL-REPOSITORIO>
cd anomaly-detection-kayeri-turkey
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

---

## Estructura del proyecto

```
.
├── main.R                    # Script principal: ejecuta todo el análisis
├── utils/
│   ├── clean.R               # Limpieza de datos (centinelas, NA, fechas duplicadas)
│   ├── deseason.R            # Monthly z-score (desestacionalización)
│   ├── stat_method.R         # Método estadístico μ ± kσ
│   ├── dbscan_method.R       # Detección de anomalías con DBSCAN
│   └── plots.R               # Gráficas y exportación de figuras
├── data/
│   └── AereopuertoKayseri_1975-2007.csv   # Temperatura media diaria (NOAA SSOD)
├── storage/                  # Figuras generadas por main.R
├── docs/
│   └── fuentes.md            # Referencias de los datos y los métodos
├── renv/                     # Configuración de renv
├── renv.lock                 # Versiones exactas de los paquetes
└── .Rprofile                 # Activa renv al abrir el proyecto
```
