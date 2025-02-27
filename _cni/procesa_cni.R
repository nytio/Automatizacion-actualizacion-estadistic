#
# Someter los insumos CNI a procesos de normalización y transformación
#
require(dplyr) # 1.1.4
require(tidyr) # 1.3.1
require(stringr) # 1.5.1
source("consulta_cni.R")

data_procesa <- function(archivo = NULL) {
  if(is.null(archivo)) {
    return(NULL)
  }
  return(switch(tools::file_ext(archivo),
    xlsx = openxlsx2::read_xlsx(archivo, 1, col_names = FALSE),
    xls = readxl::read_xls(archivo, 1, col_names = FALSE),
    csv = read.csv(archivo, header = FALSE)))
}

tabla_procesa <- function(fichas = data.frame()) {
  for(i in 1:dim(fichas)[1]){
    if(!is.na(fichas[i,2])){
      break;
    }
  }
  
  B <- fichas[i:dim(fichas)[1],]
  
  for(i in 1:dim(B)[1]){
    if(is.na(B[i,2])){
      break;
    }
  }
  # Si no tienen notas al pie de tabla, evita dejar el último fuera
  if(dim(B)[1] != i) {
    B <- B[1:(i-1),]
  }

  # Establecer los nombres de las columnas en base a la primera fila
  names(B) <- as.character(B[1, ])
  B <- B[-1, ]
  
  return(B)
}

transforma_procesa <- function(datos = data.frame()) {
  if ("Ciudad Autorepresentada" %in% names(datos)) {
    lookup <- c(
      "Aguascalientes"      = 10010001,
      "Mexicali"            = 20020001,
      "Tijuana"             = 20040001,
      "La Paz"              = 30030001,
      "Campeche"            = 40020001,
      "Torreón"             = 50350001,
      "Saltillo"            = 50300001,
      "Colima"              = 60020001,
      "Tuxtla Gutiérrez"    = 71010001,
      "Chihuahua"           = 80190001,
      "Ciudad Juárez"       = 80370001,
      "Ciudad de México"    = 90010001,
      "Durango"             = 100050001,
      "León"                = 110200001,
      "Acapulco"            = 120010001,
      "Pachuca"             = 130480001,
      "Guadalajara"         = 140390001,
      "Toluca"              = 151060001,
      "Morelia"             = 160530001,
      "Cuernavaca"          = 170070001,
      "Tepic"               = 180170001,
      "Monterrey"           = 190390001,
      "Oaxaca"              = 200670001,
      "Puebla"              = 211140001,
      "Querétaro"           = 220140001,
      "Cancún"              = 230050001,
      "San Luis Potosí"     = 240280001,
      "Culiacán"            = 250060001,
      "Hermosillo"          = 260300001,
      "Villahermosa"        = 270040001,
      "Tampico"             = 280380001,
      "Reynosa"             = 280320001,
      "Tlaxcala"            = 290260001,
      "Veracruz"            = 301930001,
      "Mérida"              = 310500001,
      "Zacatecas"           = 320560001
    )
    
    datos <- datos |>
      rename(`Entidad federativa` = `Ciudad Autorepresentada`) |>
      mutate(`Entidad federativa` = lookup[as.character(`Entidad federativa`)])
    
  } else {
    lookup <- c(
      "Nacional"                     = 0,
      "Aguascalientes"               = 1,
      "Baja California"              = 2,
      "Baja California Sur"          = 3,
      "Campeche"                     = 4,
      "Coahuila de Zaragoza"         = 5,
      "Colima"                       = 6,
      "Chiapas"                      = 7,
      "Chihuahua"                    = 8,
      "Ciudad de México"             = 9,
      "Durango"                      = 10,
      "Guanajuato"                   = 11,
      "Guerrero"                     = 12,
      "Hidalgo"                      = 13,
      "Jalisco"                      = 14,
      "México"                       = 15,
      "Michoacán de Ocampo"          = 16,
      "Morelos"                      = 17,
      "Nayarit"                      = 18,
      "Nuevo León"                   = 19,
      "Oaxaca"                       = 20,
      "Puebla"                       = 21,
      "Querétaro"                    = 22,
      "Quintana Roo"                 = 23,
      "San Luis Potosí"              = 24,
      "Sinaloa"                      = 25,
      "Sonora"                       = 26,
      "Tabasco"                      = 27,
      "Tamaulipas"                   = 28,
      "Tlaxcala"                     = 29,
      "Veracruz de Ignacio de la Llave" = 30,
      "Yucatán"                      = 31,
      "Zacatecas"                    = 32
    )
    
    datos <- datos |>
      mutate(`Entidad federativa` = lookup[as.character(`Entidad federativa`)])
  }
  
  # Identificar las columnas que tienen nombres con formato "YYYY" o "YYYY/MM"
  date_cols <- grep("^\\d{4}(?:/\\d{2})?$", names(datos), value = TRUE)
  
  # Convertir de formato ancho a largo
  datos_long <- datos |>
    pivot_longer(
      cols = all_of(date_cols), 
      names_to = "anio", 
      values_to = "valor"
    )
  
  # Procesar la columna 'valor' de forma vectorizada
  datos_long <- datos_long |>
    rowwise() |>
    mutate(
      valor_char = format(valor, scientific = FALSE, trim = TRUE),
      es_numerico = str_detect(valor_char, "^-?[0-9]+(\\.[0-9]+)?([eE][-+]?[0-9]+)?$"),
      numero = if (isTRUE(es_numerico)) as.numeric(valor) else NA_real_,
      excepcion = if (isFALSE(es_numerico)) as.character(valor) else NA_character_
    ) |>
    ungroup() |>
    select(-valor_char, -es_numerico, -valor) |>
    rename(valor = numero) |>
    rename(identidad = `Entidad federativa`) |>
    mutate(anio = as.character(anio))
  
  return(datos_long)
}

metadatos_ficha <- function(fichas = data.frame(), ind, url) {
  for(i in 1:dim(fichas)[1]){
    if(!is.na(fichas[i,2])){
      break;
    }
  }
  
  A <- fichas[1:(i-1),1]
  B <- fichas[i:dim(fichas)[1],]
  
  for(i in 1:dim(B)[1]){
    if(is.na(B[i,2])){
      break;
    }
  }
  # 6204483017 y 6204483013 no tienen notas al pie de tabla, dejando a Zacatecas fuera de la extracción.
  if(dim(B)[1] == i) {
    C <- B
    D <- NULL
  } else {
    C <- B[1:(i-1),]
    D <- B[i:dim(B)[1],1]    
  }
  
  metadatos <- rbind(A,D)
  metadatos <- metadatos[!is.na(metadatos),]
  
  columnas <- grep("^\\d{4}(?:/\\d{2})?$", as.character(C[1,]), value = TRUE)
  
  largo <- length(as.character(columnas))
  metadatos <- rbind(metadatos, paste0("Periodo inicial: ", columnas[1]))
  metadatos <- rbind(metadatos, paste0("Periodo final: ", columnas[largo]))
  metadatos <- rbind(metadatos, paste0("Total serie histórica: ", largo))
  
  metadatos <- rbind(metadatos, paste0("ind: ", ind))
  metadatos <- rbind(metadatos, paste0("web_consulta: ", url))
  
  return(t(metadatos))
}

organiza_metadatos <- function(metadatos_list) {
  # Procesamos cada registro de metadatos
  registros <- lapply(metadatos_list, function(registro) {
    # Convertir a vector (en caso de que sea una matriz)
    registro <- as.vector(registro)
    
    # Para cada cadena del registro, separamos la clave y el valor
    key_values <- lapply(registro, function(x) {
      # Separamos usando ":" como delimitador; en caso de que haya más de uno, unimos el resto
      partes <- unlist(strsplit(x, ":", fixed = TRUE))
      key <- trimws(partes[1])
      value <- if(length(partes) > 1) trimws(paste(partes[-1], collapse = ":")) else NA
      # Retornamos una lista con nombre
      setNames(list(value), key)
    })
    
    # Unificamos las listas de cada cadena en una única lista con nombres
    do.call(c, key_values)
  })
  
  # Vector de nombres de columnas a eliminar
  campos_a_quitar <- c(
    "Sistema Nacional de Información Estadística y Geográfica",
    "Catálogo Nacional de Indicadores",
    "ND",
    "MB",
    "NA",
    "en un momento en el tiempo, respecto al total de mujeres en edad fértil unidas en ese mismo momento.",
    "Por método moderno se entiende cualquier anticonceptivo, con la excepción de los métodos tradicionales, tales como el ritmo, retiro y Billings.",
    "NC",
    "NEDR"
  )
  
  # Combinamos todos los registros en un data frame
  # Los campos que no existen en algún registro se rellenan con NA
  # Quita columnas y organiza
  df_metadatos <- bind_rows(registros) |>
    select(-any_of(campos_a_quitar)) |>
    select(ind, web_consulta, everything())
  
  return(df_metadatos)
}

organiza_sel <- function(data = "CNI_0.csv") {
  # Leer y transponer el archivo CSV
  inegi <- t(read.csv(data, header = FALSE))
  
  # Inicializar listas locales para los resultados y metadatos
  resultados_list <- list()
  metadatos_list <- list()
  
  #url <- obtenerUrlCalendario.db(seleccion_reactiva())
  i <- 1
  for(url in inegi) {
    ind <- extract_param(url, "ind")
    filename <- archivo_procesa(url)
    
    if(file.exists(filename)) {
      message(">>------------->>")
      message(url)
      
      cuadro <- data_procesa(filename)
      data_proc <- transforma_procesa(tabla_procesa(cuadro))
      metadato <- metadatos_ficha(cuadro, ind, url)
      
      # Si existe la columna "Indicador", se crea una nueva variable "no"
      if ("Indicador" %in% names(data_proc)) {
        data_proc <- data_proc |>
          mutate(no = paste(ind, Indicador, sep = "_")) |>
          select(-Indicador)
      } else {
        data_proc <- data_proc |>
          mutate(no = ind)
      }
      
      data_proc <- data_proc |>
        mutate(identidad = as.integer(identidad)) |>
        select(all_of(c("no", "anio", "identidad", "excepcion", "valor"))) |>
        arrange(no, anio, identidad)
      
      resultados_list[[i]] <- data_proc
      metadatos_list[[i]] <- metadato
      
      i <- i + 1
    }
  }
  
  # Combinar los data frames de resultados y metadatos
  df_indicadores <- if(length(resultados_list) > 0) do.call(rbind, resultados_list) else NULL
  md_indicadores <- if(length(metadatos_list) > 0) organiza_metadatos(metadatos_list) else NULL

  # Retornar ambos resultados en una lista
  list(df_indicadores = df_indicadores, md_indicadores = md_indicadores)
}
