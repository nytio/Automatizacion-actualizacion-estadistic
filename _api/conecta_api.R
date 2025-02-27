library(dplyr)
library(httr)
library(jsonlite)

#' Clase Indicadores
#'
#' Esta clase permite consultar y manipular indicadores a través de la API de INEGI.
#'
#' @param token Token de acceso en formato de texto.
#' @export
Indicadores <- R6::R6Class("Indicadores",
  public = list(
    token = NULL,
    area_geo = "07000011",
    metadatos_list = list(),
    
    initialize = function(token) {
      if (missing(token) || !is.character(token)) {
        stop("Es necesario proporcionar un token válido en formato de texto.")
      }
      self$token <- token
    },
    
    def_geo = function(nivel = "GTO") {
      self$area_geo <- switch(EXPR = nivel,
        GTO = "07000011",
        NAL = "0700",
        EST = c("0700", sprintf("070000%02d", 1:32)),
        MUN = c("0700", sprintf("070000%02d", 1:32), sprintf("07000011%04d", 1:46)),
        "0700")
    },
    
    obtener_df = function(indicadores, Fuente = "BISE", Recientes = "true") {
      if (missing(indicadores) || is.null(indicadores)) {
        stop("Debes proporcionar al menos un indicador.")
      }
      indicadores <- as.character(indicadores)
      ind <- paste(indicadores, collapse = ",")
      
      resultados_list <- list()
      self$metadatos_list <- list()
      
      for (ent in self$area_geo) {
        url <- sprintf("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/%s/es/%s/%s/%s/2.0/%s?type=json",
                       ind, ent, Recientes, Fuente, self$token)
        
        respuesta <- tryCatch(
          GET(url),
          error = function(e) {
            warning(sprintf("Error en la consulta de la URL: %s", url))
            return(NULL)
          }
        )
        if (is.null(respuesta) || respuesta$status_code != 200) {
          cat(sprintf("Sin datos para indicador %s en área %s\n", ind, ent))
          next
        }
        
        flujoDatos <- fromJSON(content(respuesta, "text", encoding = "UTF-8"))
        if (!("Series" %in% names(flujoDatos)) || !("OBSERVATIONS" %in% names(flujoDatos$Series))) {
          next
        }
        
        dfs <- lapply(seq_along(indicadores), function(ii) {
          if (ii > length(flujoDatos$Series$OBSERVATIONS)) {
            return(NULL)
          }
          df <- flujoDatos$Series$OBSERVATIONS[[ii]]
          if (is.null(df) || (is.data.frame(df) && nrow(df) == 0)) {
            return(NULL)
          }
          df$indicador <- indicadores[ii]
          df
        })

        resultados_list <- c(resultados_list, Filter(Negate(is.null), dfs))

        if(ent == "07000011") {
          self$metadatos_list <- flujoDatos$Series[ , !names(flujoDatos$Series) %in% "OBSERVATIONS"] |>
            rename(No = INDICADOR)
        }
      }
      
      if(length(resultados_list) == 0) {
        return(data.frame())
      }
      
      resultados <- data.table::rbindlist(resultados_list, fill = TRUE)

      resultados <- resultados |>
        select(indicador, TIME_PERIOD, COBER_GEO, OBS_VALUE, everything()) |>
        rename(
          No = indicador,
          Descripcionperiodo = TIME_PERIOD,
          IDentidad = COBER_GEO,
          Valor = OBS_VALUE
        )
      
      return(resultados)
    },
    
    consulta_metadatos = function() {
      return(self$metadatos_list)
    },
    
    catalogo_indicadores = function(indicadores, Fuente = "BISE") {
      if (missing(indicadores)) {
        stop("Debes proporcionar al menos un indicador.")
      }
      if (!Fuente %in% c("BIE", "BISE")) {
        stop("El parámetro 'Fuente' debe ser 'BIE' o 'BISE'.")
      }
      
      if(is.null(indicadores)) {
        list_ind <- "null"
      } else {
        indicadores <- as.character(indicadores)
        list_ind <- paste(indicadores, collapse = ",")
      }
      url <- sprintf("https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/CL_INDICATOR/%s/es/%s/2.0/%s?type=json",
                     list_ind, Fuente, self$token)
      
      respuesta <- tryCatch(
        GET(url, timeout(100)),
        error = function(e) {
          warning(sprintf("Error en la consulta de la URL: %s. Detalle: %s", url, e$message))
          return(NULL)
        }
      )
      if (is.null(respuesta) || respuesta$status_code != 200) {
        cat(sprintf("Catálogo %s con %s", Fuente, url))
        return(NULL)
      }
      flujoDatos <- fromJSON(content(respuesta, "text", encoding = "UTF-8"))
      
      if (!("CODE" %in% names(flujoDatos))) {
        warning(sprintf("No se encontraron descripciones para el indicador %s",
                        paste(indicadores, collapse = ",")))
        return(NULL)
      }
      
      catalogo_df <- as.data.frame(flujoDatos$CODE) |>
        rename(No = value)
      
      return(catalogo_df)
    }
  )
)$new("TOKEN")

## Referencias:
# https://www.inegi.org.mx/servicios/api_indicadores.html#idMetodoIndicadoresInegi


