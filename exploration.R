library(reticulate)
library(plotly)
library(jsonlite)
library(tidyverse)

source_python('metadata_ETL.py')
source_python('download_data.py')
source_python('transform_eurostat_data.py')

###########################
## Spanish professionals ##
###########################
# Import all professionals data
# 
# Get also all NaN data, so the aggregation only returns valid values
# when there are measurements for every type of professionals in a specific
# year and region.

staff_all <- transform_eurostat_data('data/staff_all.gz', na_rm=FALSE)
staff_all <- mutate(staff_all, geo = as.factor(staff_all$geo),
                               isco08 = as.factor(staff_all$isco08),
                               unit = as.factor(staff_all$unit))

# Get geo and isco08 names list
spain_nuts <- fromJSON('data/spain_nuts2.json')
isco08 <- fromJSON('data/health_professionals_metadata.json')
for (i in 1:length(names(isco08))) {
  isco08[[i]] <- isco08[[i]][[1]]
}

# Create profession name attribute
staff_all <- mutate(staff_all, prof = recode_factor(staff_all$isco08, !!!unlist(isco08)))

# Filter Spanish data
spain_staff <- filter(staff_all, geo %in% names(spain_nuts))

# Create region name atribute
spain_staff <- mutate(spain_staff, region = recode_factor(spain_staff$geo,
                                                          !!!unlist(spain_nuts)))

# Aggregate all type of professionals per region.
# Use professionals per 100.000hab as unit.
spain_staff %>%
  filter(unit == 'P_HTHAB') %>% select(c(region, year, value)) %>%
  group_by(region, year) %>% summarize_all(sum) -> spain_staff_region

# Plot professionals per region
p <- ggplot(spain_staff_region, aes(year, value, color=region))+geom_line()+
  labs(y='Professionals per 100.000hab', x='Year')+coord_cartesian(xlim=c(2005, 2016))
ggplotly(p)

# Aggregate by type of professional, all state.
spain_staff %>%
  filter(unit == 'P_HTHAB') %>% select(c(year, prof, value)) %>%
  group_by(year, prof) %>% summarize_all(sum) -> spain_staff_prof

# Plot professionals per category
p <- ggplot(spain_staff_prof, aes(year, value, color=prof))+geom_line()+
  labs(y='Professionals per 100.000hab', x='Year')
ggplotly(p)


##############################
# Most frequent death causes #
##############################
deaths <- transform_eurostat_data('data/deaths_stand.gz')
deaths_copy <- deaths
deaths <- deaths_copy
factor_cols <- c('unit', 'sex', 'age', 'icd10')
deaths[,factor_cols] <- lapply(deaths[,factor_cols], factor)

# Get death causes name and ICD-10 level
icd10_list <- fromJSON('data/icd10.json')

deaths <- mutate(deaths, cause = recode_factor(deaths$icd10, !!!unlist(icd10_list$names)))
deaths <- mutate(deaths, icd10_level = recode_factor(deaths$icd10, !!!unlist(icd10_list$levels)))

# Aggregate all level 1 causes of death
deaths %>%
  filter(sex == 'T', age == 'TOTAL', geo == 'EU28', icd10_level == 1) %>%
  select(c(icd10, value, cause, icd10_level)) %>%
  group_by(cause) %>%
  summarise(deaths=mean(value, na.rm = TRUE)) %>%
  arrange(desc(deaths)) -> deaths_agg

# Create "other" category
causes_order <- as.character(deaths_agg$cause)
others_list <- causes_order[8:length(causes_order)]
causes_order <- append(causes_order, 'Other')

deaths_agg %>%
  mutate(cause = fct_collapse(cause, Other=others_list)) %>%
  group_by(cause) %>%
  summarise(deaths=sum(deaths)) %>%
  mutate(cause, cause = fct_reorder(cause, deaths)) %>%
  mutate(cause, cause = fct_relevel(cause, 'Other')) -> deaths_agg_other

ggplot(deaths_agg_other, aes(cause, deaths))+geom_col(fill="#698caf")+coord_flip()+
  labs(x="",y="Anual deaths per 100.000hab", title="Most common causes of death in Europe")