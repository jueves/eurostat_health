# Script de instalación para el Dockerfile
library(reticulate)
version <- "3.9:latest"
env_name <- "rstudio_py_env"
install_python(version)
virtualenv_create(env_name)
use_virtualenv(env_name)
py_install("requests")
