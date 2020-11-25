# Esto no lo he comprobado, pero debería de funcionar
# Con reticulate Link: https://www.r-bloggers.com/2018/03/reticulate-r-interface-to-python/
source_python('ETL.py')
(data1, metadata1) <- import_eurostat_dataset(file_name)

data.expen.hc <- read.csv('data/hlth_sha11_hc.tsv', sep = '\t', na.strings=': ')
data.beds <- read.csv('data/hlth_sha11_hc.tsv', sep = '\t', na.strings=': ')
# Creo que es un cubo, y la primera columna un comma separated time. Es decir, 
# es como un csv, en el que la casilla de los años para cada observación es un
# vector de valores para cada año.

data.deaths <- read.csv('data/estand_deaths_per_region.csv', na.strings=': ')
