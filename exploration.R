library(reticulate)
library(ggplot2)

source_python('download.py')
source_python('transform.py')
staff.all <- import_eurostat_dataset('data/staff_all.gz')

