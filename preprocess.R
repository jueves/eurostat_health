library(reticulate)
library(plotly)
library(jsonlite)
library(tidyverse)

source_python('prepare_metadata.py', envir=NULL)
source_python('download_data.py', envir=NULL)
source_python('transform_eurostat_data.py')

## Code-label dictionaries --------------------
# Spain regions
spain_nuts <- fromJSON('data/spain_nuts2.json')

# Professional categories
isco08 <- fromJSON('data/health_professionals_metadata.json')
for (i in 1:length(names(isco08))) {
  isco08[[i]] <- isco08[[i]][[1]]
}

# Health problems
icd10_list <- fromJSON('data/icd10_v2007.json')


## Health professionals --------------------
# Import all professionals data
# 
# Get also all NaN data, so the aggregation only returns valid values
# when there are measurements for every type of professionals in a specific
# year and region.

print("Loading staff_all...")
staff_all <- transform_eurostat_data('data/staff_all.gz', na_rm=FALSE)
staff_all <- mutate(staff_all, geo = as.factor(staff_all$geo),
                    isco08 = as.factor(staff_all$isco08),
                    unit = as.factor(staff_all$unit))

# Create profession name attribute
staff_all <- mutate(staff_all, prof = recode_factor(staff_all$isco08, !!!unlist(isco08)))

## Standardized deaths -------------------
print("Loading deaths...")
deaths <- transform_eurostat_data('data/deaths_stand.gz')

# Create factors
factor_cols <- c('unit', 'sex', 'age', 'icd10')
deaths[,factor_cols] <- lapply(deaths[,factor_cols], factor)
age_order = c("Y_LT65", "Y_GE65", "TOTAL")
deaths$age <- ordered(deaths$age, levels=age_order)

# Create death cause name and level
deaths <- mutate(deaths, cause = recode_factor(deaths$icd10, !!!unlist(icd10_list$names)))
deaths <- mutate(deaths, icd10_level = recode_factor(deaths$icd10, !!!unlist(icd10_list$levels)))

## Length of stay ---------------------------
print("Loading length_stay...")
length_stay <- transform_eurostat_data('data/length_of_stay.gz')
factor_cols <- c( "age", "indic_he", "unit", "sex", "icd10", "geo")
length_stay[,factor_cols] <- lapply(length_stay[,factor_cols], factor)

age_order <- c("Y_LT1", "Y1-4", "Y5-9", "Y10-14", "Y15-19", "Y20-24", "Y25-29",
               "Y30-34", "Y35-39", "Y40-44", "Y45-49", "Y50-54", "Y55-59",
               "Y60-64", "Y65-69", "Y70-74", "Y75-79", "Y80-84", "Y85-89",
               "Y90-94", "Y_GE90", "Y_GE95", "TOTAL", "UNK")

length_stay$age <- ordered(length_stay$age, levels=age_order)

## Hospital discharges ---------------------
print("Loading hospital_discharges...")
hospital_discharges <- transform_eurostat_data('data/hosp_discharges.gz')
factor_cols <- c( "age", "indic_he", "unit", "sex", "icd10", "geo")
hospital_discharges[,factor_cols] <- lapply(hospital_discharges[,factor_cols], factor)

hospital_discharges <- mutate(hospital_discharges, cause = recode_factor(hospital_discharges$icd10, !!!unlist(icd10_list$names)))
hospital_discharges <- mutate(hospital_discharges, icd10_level = recode_factor(hospital_discharges$icd10, !!!unlist(icd10_list$levels)))

#- Hospital discharges and length of stay -#
print("Loading discharge_stay...")
discharge_stay <- transform_eurostat_data('data/hosp_discharges_and_length_of_stay.gz')
factor_cols <- c( "icha_hc", "indic_he", "unit", "geo")
discharge_stay[,factor_cols] <- lapply(discharge_stay[,factor_cols], factor)

print("Data preprocessing completed.")