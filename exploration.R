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
staff_all <- transform_eurostat_data('data/staff_all.gz')

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
  filter(unit == 'P_HTHAB') %>% select(-c(unit, isco08)) %>%
  group_by(geo) %>% summarize_all(sum) -> spain_staff_agg

# Transform for better compatibility with ggplot
# Also remove years many NaN values.
spain_trans <- spain_staff_agg %>%
  select(c(geo, names(spain_staff_agg)[6:15]))

# Create labeled region
spain_trans$region <- ''
for (i in 1:nrow(spain_trans)) {
  this_geo <- spain_trans[[i, 'geo']]
  spain_trans[i,'region'] <- spain_nuts[this_geo]
}

# Create year attribute
spain_trans %>% gather("year", "professionals", -geo, -region) -> spain_trans
spain_trans$year <- as.numeric(spain_trans$year)

# Plot professionals per region
p <- ggplot(spain_trans, aes(year, professionals, color=region))+geom_line()+
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

