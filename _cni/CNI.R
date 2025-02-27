require(dplyr) # 1.1.4
library(openxlsx2)
source("procesa_cni.R")

# Descarga todos los archivos
descargartodos_sel("~/Downloads/CNI_0.csv")

# Organiza arhivos descargados
resultado_final <- organiza_sel("~/Downloads/CNI_0.csv")

# Guarda los resultados en Excel
wb <- wb_workbook(creator = "Mario Hernández M.")
wb$add_worksheet("Catálogo")
wb$add_data("Catálogo", read.csv("~/Downloads/CNI_0.csv", header = FALSE))

wb$add_worksheet("Datos")
wb$add_data("Datos", resultado_final$df_indicadores, na.strings = "")

wb$add_worksheet("Metadatos")
wb$add_data("Metadatos", resultado_final$md_indicadores, na.strings = "")

df_notas <- data.frame(
  Notas = c(
    "ND: No disponible",
    "MB: Muy bajo  B: Bajo  A: Alto  M: Medio  MA: Muy alto",
    "NA: No aplica  NP: La variable denominador es igual a cero NC: No calculable",
    "NEDR: No existe distrito de riego"
  )
)

wb$add_worksheet("Notas")
wb$add_data("Notas", x = df_notas, colNames = TRUE)

# Guardar el archivo de Excel
wb$save("CNI_20250228.xlsx")
