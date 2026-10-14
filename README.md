## Requisitos previos antes de ejecutar el proyecto
 
 - [Rtools](https://cran.r-project.org/bin/windows/Rtools/) | La que corresponda a tu versión de R | **Solo Windows.** Obligatorio: `dbscan 1.1-5` es una versión antigua y se compila desde código fuente 

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
├── 01_promedios_mensuales.R  # Paso 1: promedios mensuales
├── 02_tabla_de_promedios.R   # Paso 2: tabla de promedios por mes
├── utils/
│   └── deseason.R            # Funciones auxiliares (p. ej. monthly_z_score)
├── data/
│   └── AereopuertoKayseri_1975-2008.csv
├── renv/                     # Configuración de renv (la biblioteca no se sube a Git)
├── renv.lock                 # Versiones exactas de los paquetes
└── .Rprofile                 # Activa renv al abrir el proyecto
```
 
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

