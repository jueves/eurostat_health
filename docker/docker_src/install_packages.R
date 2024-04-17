# Script de instalación para el Dockerfile
install.packages("plotly")
library(reticulate)
py_install(c("pandas", "requests", "openpyxl"))
