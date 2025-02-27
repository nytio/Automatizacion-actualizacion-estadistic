#
# Obtener archivos de datos directamente del CNI
#
library(rvest)
library(chromote)

Sys.setenv(CHROMOTE_CHROME = "/usr/bin/google-chrome")

# Función auxiliar para extraer parámetros de la URL
extract_param <- function(url, param) {
  pattern <- paste0(param, "=")
  start_pos <- regexpr(pattern, url)
  if(start_pos == -1) stop(paste("Parámetro", sQuote(param), "no encontrado en la URL"))
  sub_str <- substr(url, start_pos + nchar(pattern), nchar(url))
  amp_pos <- regexpr("&", sub_str)
  if(amp_pos == -1) stop(paste("Formato inesperado en el parámetro", sQuote(param)))
  substr(sub_str, 1, amp_pos - 1)
}

# Esperar a que el documento esté completamente cargado
wait_for_complete <- function(live_html, timeout = 60, max_inactive = 10, poll_interval = 2) {
  start <- Sys.time()
  last_state <- ""
  last_change <- Sys.time()
  
  repeat {
    state <- tryCatch(
      live_html$session$Runtime$evaluate("document.readyState")$result$value,
      error = function(e) NA
    )
    if (!is.na(state) && state == "complete") break
    
    if (identical(state, last_state)) {
      if(difftime(Sys.time(), last_change, units = "secs") > max_inactive) break
    } else {
      last_state <- state
      last_change <- Sys.time()
    }
    
    if(difftime(Sys.time(), start, units = "secs") > timeout)
      stop("Timeout: la página no se cargó completamente")
    
    Sys.sleep(poll_interval)
  }
  invisible(TRUE)
}

# Función para esperar a que aparezca un nuevo archivo
wait_for_new_file <- function(existing_files, path = "~/Downloads/", timeout = 60, poll_interval = 2) {
  start_time <- Sys.time()
  
  repeat {
    Sys.sleep(poll_interval)
    current_files <- list.files(path = path)
    new_files <- setdiff(current_files, existing_files)
    if (length(new_files) > 0) return(new_files[1])
    
    if(difftime(Sys.time(), start_time, units = "secs") > timeout) {
      stop("Timeout: No se encontró un nuevo archivo en el directorio")
    }
  }
}

# Función para dar un clic a un botón específico
try_click <- function(page, selector, max_attempts = 60, poll_interval = 2) {
  for(attempt in seq_len(max_attempts)) {
    Sys.sleep(poll_interval)
    page$scroll_into_view(selector)
    res <- try(page$click(selector), silent = TRUE)
    if(!inherits(res, "try-error")) return(TRUE)
  }
  return(FALSE)
}

# Función para intentar hacer clic en varios selectores
try_click_multiple <- function(page, selectors, max_attempts = 60, poll_interval = 2) {
  for(selector in selectors) {
    if(try_click(page, selector, max_attempts, poll_interval)) return(TRUE)
  }
  return(FALSE)
}

# Función principal para gestionar la descarga
downloads_live <- function(url, max_attempts = 60, poll_interval = 2, downloads_dir = "~/Downloads/") {
  if(url == "") stop("La URL no puede estar vacía")
  
  # Extraer parámetros
  x <- as.numeric(extract_param(url, "gen"))
  tipo3 <- (x >= 9000) & (x < 10000)
  
  # Abrir la página y asegurar el cierre de la sesión
  page <- read_html_live(url)
  on.exit(page$session$close())
  
  page$session$Page$setDeviceMetricsOverride(
    width = 1280,
    height = 720,
    deviceScaleFactor = 1,
    mobile = FALSE
  )
  
  wait_for_complete(page, poll_interval = poll_interval)
  
  # Verificar que la URL actual es la esperada
  current_url <- page$session$Runtime$evaluate("document.location.href")$result$value
  if(current_url != url)
    stop("La URL actual no coincide con la esperada")
  
  # Intentar hacer clic en el botón de descarga
  if(!try_click_multiple(page,
                         c("#wuc_barraherramientas_ImageDescarga",
                           "img[src='img/barraSup/btn_descargar_on.png']"),
                         max_attempts, poll_interval)) {
    stop("No se pudo hacer clic en ExportarSeries")
  }
  wait_for_complete(page, poll_interval = poll_interval)
  
  # Para tipo3, hacer clic en el elemento Combo
  if(tipo3) {
    if(!try_click(page, "#CBox_all", max_attempts, poll_interval))
      stop("No se pudo hacer clic en el elemento #CBox_all para tipo3")
    wait_for_complete(page, poll_interval = poll_interval)
  }
  
  # Registrar archivos existentes
  downloads_path <- path.expand(downloads_dir)
  existing_files <- list.files(path = downloads_path)
  wait_for_complete(page, poll_interval = poll_interval)
  
  # Hacer clic para descargar el XLS
  if(tipo3) {
    if(!try_click(page, "#inputExportarMU", max_attempts, poll_interval))
      stop("Error al hacer clic en #inputExportarMU")
  } else {
    if(!try_click_multiple(page,
                           c("#Image1", "img[src='img/btn_descargaXLS.png']"),
                           max_attempts, poll_interval)) {
      stop("Error al hacer clic en el botón de descarga XLS")
    }
  }
  
  # Esperar a que aparezca el nuevo archivo
  new_file <- wait_for_new_file(existing_files, path = downloads_path,
                                timeout = 60, poll_interval = poll_interval)
  
  if(is.null(new_file) || new_file == "")
    stop("No se pudo identificar el nuevo archivo descargado")

  # Renombrar el archivo descargado
  downloads_path <- sub("/+$", "", downloads_path)
  newname <- extract_param(url, "ind")
  filename <- file.path(downloads_path, paste0(newname, ".xls"))

  if(!file.rename(from = file.path(downloads_path, new_file), to = filename))
    stop("Error al renombrar el archivo descargado")

  return(filename)
}

# Otra carpeta usada para almacenar "cni/"
archivo_procesa <- function(url = NULL, path = "~/Downloads/") {
  if(is.null(url)) {
    return(NULL)
  }
  paste0(path, extract_param(url, "ind"), ".xls")
}

## Testeo
#url <- "https://www.snieg.mx/cni/escenario.aspx?idOrden=1.2&ind=6200104753&gen=2889&d=s"
#res <- downloads_live(url)

#url <- "https://www.snieg.mx/cni/escenario.aspx?idOrden=1.1&ind=6200011952&gen=15576&d=s"
#res <- downloads_live(url)

# Entra a cada página y descarga sus datos
descargartodos_sel <- function(data = "CNI_1.csv") {
  inegi <- t(read.csv(data, header = FALSE))
  for(url in inegi) {
    filename <- archivo_procesa(url)
    if(file.exists(filename))
      next
    print(">>------------->>")
    print(url)
    res <- downloads_live(url) 
    print(res)
    Sys.sleep(1)
  }
}

## Testeo
# descargartodos_sel("~/Downloads/CNI_0.csv")
