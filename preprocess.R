library(reticulate)
library(plotly)
library(jsonlite)
library(tidyverse)

source_python('prepare_metadata.py', envir=NULL)
source_python('download_data.py', envir=NULL)
source_python('transform_eurostat_data.py')

# Code-label dictionaries --------------------
# Spain regions
spain_nuts <- fromJSON('data/spain_nuts2.json')

# Professional categories
isco08 <- fromJSON('data/health_professionals_metadata.json')
for (i in 1:length(names(isco08))) {
  isco08[[i]] <- isco08[[i]][[1]]
}

# Health problems
icd10_list <- fromJSON('data/icd10_v2007.json')

# Age order, group ages in the end.
age_order <- c("Y_LT1", "Y1-4", "Y5-9", "Y10-14", "Y15-19", "Y20-24", "Y25-29",
               "Y30-34", "Y35-39", "Y40-44", "Y45-49", "Y50-54", "Y55-59",
               "Y60-64", "Y65-69", "Y70-74", "Y75-79", "Y80-84", "Y85-89",
               "Y90-94", "Y_LT15", "Y_LT25", "Y_GE65", "Y_GE85", "Y_GE90",
               "Y_GE95", "TOTAL", "UNK")

# >> Dimensions ----------------------------------------------------------------
# All health professionals --------------------
# Import all professionals data
# 
# Get also all NaN data, so the aggregation only returns valid values
# when there are measurements for every type of professionals in a specific
# year and region.

get_staff_all <- function() {
  print("Loading staff_all...")

  staff_all <- transform_eurostat_data('data/staff_all.gz', na_rm=FALSE)
  staff_all <- mutate(staff_all, geo = as.factor(staff_all$geo),
                      isco08 = as.factor(staff_all$isco08),
                      unit = as.factor(staff_all$unit))
  
  # Create profession name attribute
  staff_all <- mutate(staff_all, prof = recode_factor(staff_all$isco08, !!!unlist(isco08)))
  
  return(staff_all)
}

# Hospital professionals -------------------------------------------------------
get_staff_hosp <- function() {
  print("Loading staff_hosp....")

  staff_hosp <- transform_eurostat_data('data/staff_hospital.gz')
  factor_cols <- c("isco08", "unit", "geo")
  staff_hosp[,factor_cols] <- lapply(staff_hosp[,factor_cols], factor)
  
  staff_hosp <- mutate(staff_hosp, prof = (recode_factor(staff_hosp$isco08, !!!unlist(isco08))))
  
  # Select only FTE_HTHAB unit (Full Time Equivalent professionals per 100.000hab)
  staff_hosp %<>% filter(unit == "FTE_HTHAB") %>% select(-unit)
  
  return(staff_hosp)
}


# >> Facts ---------------------------------------------------------------------
# Crude deaths -----------------------------------------------------------------
get_deaths <- function() {
  print("Loading deaths...")

  deaths <- transform_eurostat_data('data/deaths_crude.gz')
  
  # Create factors
  factor_cols <- c('unit', 'sex', 'age', 'icd10')
  deaths[,factor_cols] <- lapply(deaths[,factor_cols], factor)
  deaths$age <- ordered(deaths$age, levels=age_order)
  
  # Create death cause name and level
  deaths <- mutate(deaths, cause = recode_factor(deaths$icd10,
                                                 !!!unlist(icd10_list$names)))
  deaths <- mutate(deaths, icd10_level = recode_factor(deaths$icd10,
                                                       !!!unlist(icd10_list$levels)))
  return(deaths)
}

# Hospital discharges ----------------------------------------------------------
get_hospital_discharges <- function(sex=FALSE) {
  print("Loading hospital_discharges...")
  
  files_names <- c("data/hosp_discharges_t.gz", "data/hosp_discharges_f.gz",
                  "data/hosp_discharges_m.gz")
  
  factor_cols <- c( "age", "indic_he", "unit", "sex", "icd10", "geo")
  
  
  if (sex) {
    datasets_list <- lapply(files_names, transform_eurostat_data)
    hospital_discharges <- bind_rows(datasets_list)
  } else {
    hospital_discharges <- transform_eurostat_data(files_names[1])
  }
  
  
  hospital_discharges[,factor_cols] <- lapply(hospital_discharges[,factor_cols], factor)
  
  hospital_discharges$age <- ordered(hospital_discharges$age, levels=age_order)
  
  hospital_discharges <- mutate(hospital_discharges,
                                cause = recode_factor(hospital_discharges$icd10,
                                                      !!!unlist(icd10_list$names)))
  hospital_discharges <- mutate(hospital_discharges,
                                icd10_level = recode_factor(hospital_discharges$icd10,
                                                            !!!unlist(icd10_list$levels)))
  
  return(hospital_discharges)
}

# Hospital discharges and length of stay ---------------------------------------
get_discharge_stay <- function() {
  print("Loading discharge_stay...")
  discharge_stay <- transform_eurostat_data('data/hosp_discharges_and_length_of_stay.gz')
  factor_cols <- c( "icha_hc", "indic_he", "unit", "geo")
  discharge_stay[,factor_cols] <- lapply(discharge_stay[,factor_cols], factor)
  
  return(discharge_stay)
}

# Length of stay ---------------------------
get_length_stay <- function(sex=FALSE) {
  print("Loading length_stay...")
  
  files_names <- c('data/length_of_stay_t.gz', 'data/length_of_stay_f.gz',
                   'data/length_of_stay_m.gz')
  
  factor_cols <- c( "age", "indic_he", "unit", "sex", "icd10", "geo")
  
  
  if (sex) {
    datasets_list <- lapply(files_names, transform_eurostat_data)
    length_stay <- bind_rows(datasets_list)
  } else {
    length_stay <- transform_eurostat_data(files_names[1])
  }
  
  length_stay[,factor_cols] <- lapply(length_stay[,factor_cols], factor)
  length_stay$age <- ordered(length_stay$age, levels=age_order)
  
  return(length_stay)
}