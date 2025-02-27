# Automatización de actualización de información estadística

**Automatización de actualización de información estadística** es un proyecto que implementa técnicas para **automatizar la obtención y actualización de datos estadísticos** (por ejemplo, indicadores publicados por INEGI) en plataformas de información. Los scripts incluidos permiten descargar series de indicadores automáticamente y mantener bases de datos o informes siempre actualizados con la información más reciente.

## Descripción del Proyecto

Este repositorio contiene código en R diseñado para **actualizar de forma automatizada indicadores estadísticos** provenientes de fuentes oficiales. En particular, se enfoca en la extracción de datos del Instituto Nacional de Estadística y Geografía (INEGI) de México. El proyecto implementa técnicas de conexión a servicios web y procesamiento de datos para evitar labores manuales repetitivas. Al ejecutar estos scripts, se pueden obtener las últimas cifras disponibles y actualizar plataformas de información estadística (dashboards, bases de datos, reportes) de manera eficiente y confiable.

## Planteamiento del Problema

Frecuentemente existe la necesidad de **obtener indicadores del INEGI** (como datos económicos, demográficos, etc.) de forma regular. Sin una automatización, actualizar estos datos implica ingresar manualmente a portales web, descargar archivos o copiar información, lo cual es **tedioso, propenso a errores y consume mucho tiempo**. Además, aunque INEGI ofrece **servicios de datos en línea** (como APIs o el Catálogo Nacional de Indicadores), acceder a ellos puede presentar dificultades: requiere conocer las URLs o endpoints correctos, manejar autenticación (por ejemplo, claves de API) y transformar las respuestas (JSON, XML, etc.) a formatos utilizables. Este proyecto surge de esa problemática: la necesidad de contar con un mecanismo automatizado que obtenga indicadores oficiales fácilmente y supere las barreras de acceso manual a los datos.

## Propuesta de Solución

La solución propuesta es una serie de **scripts en R organizados en dos módulos** (`_api` y `_cni`) que extraen y actualizan los indicadores del INEGI de forma automatizada:

- **Módulo `_api`**: Contiene scripts que se conectan a la **API de datos de INEGI** para descargar indicadores de manera programática. Usando solicitudes HTTP a los endpoints oficiales del INEGI (con una clave de API cuando es necesaria), estos scripts obtienen las series de datos en formato JSON/XML y las transforman en tablas de R listas para su análisis o almacenamiento. Este enfoque aprovecha la infraestructura del INEGI para obtener datos actualizados al instante en que se publican.

- **Módulo `_cni`**: Contiene scripts que interactúan con el **Catálogo Nacional de Indicadores (CNI)** del Sistema Nacional de Información Estadística y Geográfica. En caso de que algunos indicadores no estén disponibles mediante la API tradicional, estos scripts acceden a la fuente alternativa del CNI (ya sea mediante endpoints especiales, descargas de archivos de datos, o web scraping de las páginas del catálogo). El código organiza y formatea la información del CNI para integrarla con el resto de datos, asegurando que incluso indicadores clave provenientes de este catálogo se mantengan actualizados automáticamente.

En conjunto, ambos módulos resuelven el problema de mantener información estadística al día: el usuario puede ejecutar los scripts para **descargar, procesar y actualizar indicadores sin intervención manual**, garantizando eficiencia y exactitud en la actualización de datos.

## Posibles Aplicaciones

Este proyecto tiene múltiples aplicaciones prácticas en distintos ámbitos, tanto en el **sector público** como en el **sector privado**:

- **Sector público**: Dependencias gubernamentales, oficinas de planeación y observatorios de datos pueden utilizar estos scripts para alimentar sus sistemas internos o tableros de control con las últimas cifras socioeconómicas. Por ejemplo, una oficina estatal de información podría automatizar la actualización mensual de indicadores de empleo, inflación o población directamente desde INEGI, reduciendo retrasos y errores en reportes oficiales.

- **Sector privado**: Empresas y consultoras pueden beneficiarse al integrar estos mecanismos en sus flujos de trabajo de business intelligence. Por ejemplo, una empresa financiera podría actualizar diariamente sus análisis de mercado con indicadores macroeconómicos (tipo de cambio, IPC, PIB, etc.) obtenidos automáticamente, mejorando la toma de decisiones con datos actualizados al día. Asimismo, analistas y académicos que requieran series de tiempo oficiales pueden incorporar este código en sus proyectos para asegurarse de trabajar siempre con información vigente.

- **Organismos y ONGs**: Instituciones educativas, organismos internacionales u ONGs enfocadas en datos abiertos pueden emplear este repositorio para nutrir sus portales de datos o investigaciones con información confiable de INEGI sin invertir tiempo en descargas manuales.

En resumen, cualquier escenario que requiera **datos oficiales actualizados constantemente** puede aprovechar esta automatización, liberando tiempo y recursos que antes se gastaban en obtener y formatear datos.

## Ejemplos de Uso

A continuación se muestran ejemplos de cómo utilizar los scripts en R y los pasos para ejecutarlos. Antes de comenzar, asegúrate de tener instalado R (y opcionalmente RStudio) y contar con las **librerías necesarias** instaladas. Los principales paquetes de R utilizados (ya sea cargados explícitamente con `library()` o invocados con `paquete::función`) son: **`httr`**, **`jsonlite`**, **`dplyr`**, **`tidyr`**, **`readr`**, **`readxl`** (u **`openxlsx`**), **`rvest`** (para scraping web si es necesario) y **`lubridate`**. Puedes instalar cualquiera que te falte mediante `install.packages("nombre_del_paquete")`.

**Pasos para ejecutar los scripts:**

1. **Clonar el repositorio**: Descarga o clona este repositorio en tu máquina local para tener acceso a los scripts. Por ejemplo, usando Git:  
   ```
   git clone https://github.com/nytio/Automatizacion-actualizacion-estadistica.git
   ```
   Luego, abre R o RStudio en el directorio del repositorio.

2. **Configurar clave de AP** (si aplica): Si vas a utilizar los scripts del módulo `_api`, asegúrate de tener una clave de API de INEGI. Esta clave (token) se puede obtener registrándote en el portal de desarrolladores de INEGI. Una vez obtenida, puedes asignarla en R a una variable o incluirla en los scripts según las instrucciones del código (por ejemplo, algunos scripts podrían requerir definir `api_key <- "TU_CLAVE_AQUI"` antes de hacer las llamadas).

3. **Instalar paquetes requeridos**: Verifica que tienes instalados los paquetes mencionados (httr, jsonlite, etc.). Si no, instálalos con `install.packages()` como se indicó. Luego cárgalos en tu sesión R. (Nota: algunos scripts ya cargan internamente los paquetes usando la sintaxis library o llamadas explícitas con `::`, pero es buena práctica asegurarse de tenerlos disponibles.)
4. **Ejecutar un script de actualización**: Puedes correr los scripts directamente para obtener los datos. Por ejemplo, para actualizar indicadores vía API del INEGI, ejecuta en R:
   ```
   source("path/to/repo/_api/actualizar_indicadores_api.R")
   ```
Este script se conectará a la API de INEGI y descargará las series definidas en él. De forma similar, para actualizar usando datos del Catálogo Nacional de Indicadores:
   ```
   source("path/to/repo/_cni/actualizar_indicadores_cni.R")
   ```
Cada script está diseñado para conectarse a la fuente correspondiente, obtener los datos más recientes y procesarlos. Al finalizar, típicamente exportan los datos a un archivo (por ejemplo, CSV o Excel en alguna carpeta de salida) o actualizan una base de datos según la configuración.

5. **Verificar resultados**: Tras la ejecución, revisa la salida generada. Por ejemplo, si el script `_api` guarda un archivo `indicadores_api.csv` con los datos obtenidos, ábrelo para comprobar que contiene las columnas esperadas y las filas de datos actualizadas. Si el script devuelve un objeto en R (una tabla de datos), puedes inspeccionarlo directamente en la consola (ej. usando `head(nombre_objeto)` para ver las primeras filas).

**Ejemplo concreto**: Si quisieras obtener, digamos, la serie del Producto Interno Bruto (PIB) trimestral a través de la API, el script correspondiente (por ejemplo, `obtener_PIB_API.R` dentro de `_api`) podría usarse de la siguiente manera:
   ```
   # Cargar script de PIB
   source("scripts/_api/obtener_PIB_API.R")

   # Llamar a la función de obtención de PIB (supongamos que el script define una función obtener_PIB)
   serie_PIB <- obtener_PIB(api_key = "TU_CLAVE_API")

   # Revisar las primeras filas de la serie obtenida
   head(serie_PIB)
   ```
Este fragmento es ilustrativo; en general cada script .R de la carpeta adecuada cargará los datos de un conjunto de indicadores. Sigue una lógica similar para otros indicadores o grupos de datos: carga el script y luego ejecuta la función o código que extraiga el indicador deseado.

## Estructura de Archivos

El repositorio está organizado en archivos y carpetas para separar las funcionalidades. A continuación se describe la función de cada parte principal del proyecto:

- _api/ Carpeta que contiene los scripts relacionados con la **API del INEGI**. Dentro encontrarás uno o varios archivos `.R` que construyen las consultas a la API y manejan las respuestas. Por ejemplo, podría haber scripts dedicados a distintos conjuntos de indicadores (económicos, sociodemográficos, etc.) o funciones generales para hacer peticiones a la API y formatear los resultados. En general, cualquier código encargado de conectarse directamente a los endpoints de INEGI reside aquí.

- _cni/` Carpeta con los scripts para el **Catálogo Nacional de Indicadores (CNI)**. Aquí se incluyen archivos `.R` que obtienen datos de indicadores clave publicados en el CNI. Pueden conectarse a algún servicio web del catálogo, descargar archivos de datos (como Excel/CSV) o realizar web scraping de páginas HTML donde estén las series. Luego, transforman esos datos al formato requerido. Estos scripts complementan la información que no esté accesible mediante la API del INEGI.

- README.md Este archivo que estás leyendo. Proporciona la documentación del proyecto, incluyendo la descripción, instrucciones de uso, y otros detalles para que cualquier colaborador o usuario entienda el propósito y la forma de utilizar el código.

- LICENSE Archivo de licencia del proyecto, en el cual se establece que el código se distribuye bajo la licencia MIT. Esto permite a otros reutilizar el código libremente bajo las condiciones de dicha licencia.

(Nota: Si el repositorio incluye otros archivos o carpetas, como datos de ejemplo, configuraciones o scripts adicionales, se deberían describir aquí también. Asegúrate de documentar cualquier archivo relevante, por ejemplo, una carpeta `output/` donde se guarden los resultados, un script principal para correr todo el proceso de una vez, etc., si existieran.)

## Licencia

Este proyecto está disponible bajo **The MIT License (MIT)**. Esto significa que puedes usar, modificar y distribuir el código libremente, siempre que incluyas la nota de copyright y la licencia MIT en cualquier copia o derivación del código. Consulta el archivo **LICENSE** en este repositorio para ver el texto completo de la licencia.
