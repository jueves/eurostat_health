# Script de instalación para el Dockerfile
install.packages("remotes")
library("remotes")
install_version("plotly", "4.10.4")
library(reticulate)
py_install(c("pandas==2.2.2", "requests==2.31.0", "openpyxl==3.1.2"))
