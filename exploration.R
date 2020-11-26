library(reticulate)
library(ggplot2)
library(jsonlite)
library(dplyr)
library(tidyr)

source_python('download.py')
source_python('transform.py')
staff_all <- import_eurostat_dataset('data/staff_all.gz')

# Import Spain NUTS2 codes
spain_nuts <- fromJSON('data/spain_nuts2.json')

# Filter Spanish data
spain_index = c()
for (location in staff_all$geo){
  is_from_spain <- location %in% names(spain_nuts)
  spain_index <- append(spain_index, is_from_spain)
}
spain_staff <- staff_all[spain_index, ]

# Aggregate all type of professionals per region.
# Use inhabitants per professional as unit.
spain_staff %>%
  filter(unit == 'HAB_P') %>% select(-c(unit, isco08)) %>%
  group_by(geo) %>% summarize_all(sum) -> spain_staff_agg

spain_staff_agg <-select(spain_staff_agg, -c(2019, 2018, 2016, 2016, 2005, 2004))

# Transform for better compatibility with ggplot
# Also remove years with NaN values because the aggregation metric, sum,
# would be heavily affected by lack of data.
spain_trans <- spain_staff_agg %>%
                    select(c(geo, names(spain_staff_agg)[6:15]))%>%
                    gather("year", "hab_per_prof", -geo)
spain_trans$year <- as.numeric(spain_trans$year)

ggplot(spain_trans, aes(year, hab_per_prof, color=geo))+geom_line()

