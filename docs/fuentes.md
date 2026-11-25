# Fuentes

## Artículo replicado

- Çelik, M., Dadaşer-Çelik, F., & Dokuz, A. Ş. (2011). Anomaly detection in temperature data using DBSCAN algorithm. En *2011 International Symposium on Innovations in Intelligent Systems and Applications (INISTA)* (pp. 91–95). Estambul, Turquía. https://doi.org/10.1109/INISTA.2011.5946052

## Datos

- NOAA National Centers for Environmental Information. *Synoptic Summary of the Day (SSOD), Version 2*. https://www.ncei.noaa.gov/oa/synoptic-summary-of-the-day/index.html#v2/
  - Estación: `TUI0000LTAU`, Kayseri/Erkilet (Aeropuerto de Kayseri), 38.770 N, 35.495 E, 1,055.5 m.
  - Variable: temperatura media diaria (`mean_temperature`, °C), 1975–2007.
  - Archivo: `data/AereopuertoKayseri_1975-2007.csv`.

## Métodos

- **DBSCAN:** Ester, M., Kriegel, H.-P., Sander, J., & Xu, X. (1996). A density-based algorithm for discovering clusters in large spatial databases with noise. En *Proceedings of the Second International Conference on Knowledge Discovery and Data Mining (KDD-96)* (pp. 226–231). AAAI Press.
- **Paquete `dbscan` de R (versión 1.1-5):** Hahsler, M., Piekenbrock, M., & Doran, D. (2019). dbscan: Fast density-based clustering with R. *Journal of Statistical Software, 91*(1), 1–30. https://doi.org/10.18637/jss.v091.i01
  - Documentación: https://www.rdocumentation.org/packages/dbscan/versions/1.1-5/topics/dbscan
- **Monthly z-score (desestacionalización):** Tan, P.-N., Steinbach, M., Kumar, V., Potter, C., Klooster, S., & Torregrosa, A. (2001). Finding spatio-temporal patterns in earth science data. En *KDD 2001 Workshop on Temporal Data Mining*. San Francisco, EE. UU.
