library(reticulate)
library(ggplot2)
library(plotly)
library(jsonlite)
library(dplyr)
library(tidyr)

source_python('metadata_ETL.py')
source_python('download_data.py')
source_python('transform_eurostat_data.py')

###########################
## Spanish professionals ##
###########################
# Import all professionals data
staff_all <- transform_eurostat_data('data/staff_all.gz', na_rm=TRUE)

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
# Use professionals per 100.000hab as unit.
spain_staff %>%
  filter(unit == 'P_HTHAB') %>% select(-c(unit, isco08, metadata)) %>%
  group_by(geo, year) %>% summarize_all(sum) -> spain_staff_agg

# Create labeled region
spain_staff_agg$region <- ''
for (i in 1:nrow(spain_staff_agg)) {
  this_geo <- spain_staff_agg[[i, 'geo']]
  spain_staff_agg[i,'region'] <- spain_nuts[this_geo]
}

# Plot professionals per region
p <- ggplot(spain_staff_agg, aes(year, value, color=region))+geom_line()+
  labs(y='Professionals per 100.000hab', x='Year')
ggplotly(p)

##############################
# Most frequent death causes #
##############################
deaths <- import_eurostat_dataset('data/deaths_stand.gz')
deaths_sample <- deaths[sample(nrow(deaths), 500),]

# Filter all ages, all Europe, both sexes.
deaths %>%
  filter(sex == 'T', age == 'TOTAL', geo == 'EU28') %>%
  select(-c(unit, sex, age, geo)) %>%
  gather("year", "deaths", -icd10) %>%
  group_by(icd10) %>%
  summarise(deaths=mean(deaths, na.rm = TRUE)) %>%
  arrange(desc(deaths)) -> deaths_agg

print("10 most frequent causes of death:")
print(deaths_agg[1:10,1])

