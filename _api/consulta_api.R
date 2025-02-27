source("conecta_api.R")

# ================================
# Ejemplo de uso:
# 1. Consultar el catálogo completo de indicadores del banco BISE
# 2. Obtener la serie de un indicador del banco BISE
# 3. Obtener los metadatos de un indicador del banco BISE

# ================================
# Un caso
cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = "6200240470")
df_indicadores <- Indicadores$obtener_df(indicadores = cat_indicadores$No)
md_indicadores <- Indicadores$consulta_metadatos()

cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = c("6200240470", "6207129648"))
df_indicadores <- Indicadores$obtener_df(indicadores = cat_indicadores$No)
md_indicadores <- Indicadores$consulta_metadatos()

# ================================
# Catálogo completo
cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = NULL, Fuente = "BIE")

# Definimos el tamaño del lote:
batch_size <- 1
total_indicadores <- length(cat_indicadores$No)
num_batches <- ceiling(total_indicadores / batch_size)

# Lista para acumular los resultados de cada lote
resultados_list <- list()
metadatos_list <- list()

# Bucle para procesar cada lote
for (i in seq_len(num_batches)) {
  start_idx <- (i - 1) * batch_size + 1
  end_idx <- min(i * batch_size, total_indicadores)
  batch <- cat_indicadores$No[start_idx:end_idx]
  
  cat(sprintf("Procesando lote %d de %d (indicadores %d a %d)...\n", 
              i, num_batches, start_idx, end_idx))
  
  # Consultar el lote actual (se asume que el método 'obtener_df' acepta un vector de indicadores)
  resultados_list[[i]] <- Indicadores$obtener_df(indicadores = batch)
  metadatos_list[[i]] <- Indicadores$consulta_metadatos()
  # Guardar resultados incrementalmente (opcionalmente se puede escribir en disco)
  #saveRDS(resultados_list, file = "resultados_incrementales.rds")
  
  # Pausa para evitar saturar el servicio (ajustar según necesidad)
  #Sys.sleep(1)
}

# Combinar todos los resultados en un solo data frame
df_indicadores <- do.call(rbind, resultados_list)
md_indicadores <- do.call(rbind, metadatos_list) 

# Guarda los resultados en Excel
library(openxlsx2)

wb <- wb_workbook()

wb$add_worksheet("Catálogo")
wb$add_data("Catálogo", cat_indicadores)

wb$add_worksheet("Datos")
wb$add_data("Datos", df_indicadores)

wb$add_worksheet("Metadatos")
wb$add_data("Metadatos", md_indicadores)

# Guardar el archivo de Excel
wb$save("BISE_202502T.xlsx")

# ================================
# Catálogo BIE

#https://www.inegi.org.mx/app/api/indicadores/desarrolladores/jsonxml/INDICATOR/741190/es/0700/true/BIE/2.0/[Aquí va tu Token]?type=json

cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = NULL, Fuente = "BIE")

#910472
cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = "441027", Fuente = "BIE")
df_indicadores <- Indicadores$obtener_df(indicadores = "441027")
md_indicadores <- Indicadores$consulta_metadatos()


PEDsnieg <- c("6300000108",
"6300000106",
"6300000085",
"6300000011",
"6300000101",
"6200093775",
"6300000122",
"6200002197",
"6207020182",
"6200027761",
"6200009519",
"6207095899",
"6204591959",
"6204591962",
"6200009554")

for (ind in PEDsnieg) {
  cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = ind, Fuente = "BIE")
}

df_indicadores <- Indicadores$obtener_df(indicadores = "441027", "BIE")
md_indicadores <- Indicadores$consulta_metadatos()


# ================================
# Para serie BIE
source("conecta.R")
Indicadores$def_geo(nivel = "GTO")

catalogo_list <- list()
j <- 1
for(i in seq_len(99999999999)) {
  cat_indicadores <- Indicadores$catalogo_indicadores(indicadores = i, Fuente = "BIE")
  if(is.null(cat_indicadores))
    next
  catalogo_list[[j]] <- cat_indicadores
  j <- j + 1
}

cat_indicadores <- do.call(rbind, catalogo_list)

# Definimos el tamaño del lote:
batch_size <- 1
total_indicadores <- length(cat_indicadores$No)
num_batches <- ceiling(total_indicadores / batch_size)

# Lista para acumular los resultados de cada lote
resultados_list <- list()
metadatos_list <- list()

# Bucle para procesar cada lote
for (i in seq_len(num_batches)) {
  start_idx <- (i - 1) * batch_size + 1
  end_idx <- min(i * batch_size, total_indicadores)
  batch <- cat_indicadores$No[start_idx:end_idx]
  
  cat(sprintf("Procesando lote %d de %d (indicadores %d a %d)...\n", 
              i, num_batches, start_idx, end_idx))
  
  # Consultar el lote actual (se asume que el método 'obtener_df' acepta un vector de indicadores)
  resultados_list[[i]] <- Indicadores$obtener_df(indicadores = batch, Fuente = "BIE")
  metadatos_list[[i]] <- Indicadores$consulta_metadatos()
}

# Combinar todos los resultados en un solo data frame
df_indicadores <- do.call(rbind, resultados_list)
md_indicadores <- do.call(rbind, metadatos_list) 

# Guarda los resultados en Excel
library(openxlsx2)

wb <- wb_workbook()

wb$add_worksheet("Catálogo")
wb$add_data("Catálogo", cat_indicadores)

wb$add_worksheet("Datos")
wb$add_data("Datos", df_indicadores)

wb$add_worksheet("Metadatos")
wb$add_data("Metadatos", md_indicadores)

# Guardar el archivo de Excel
wb$save("BIE_202502T.xlsx")
