source("preprocess.R")

export_countries <- function(dataset, path) {
  # Export dataset to files as separate countries
  # This allows working with smaller data
  country_codes <- names(nuts_dic[["0"]])
  for (country in country_codes) {
    pattern <- paste0("^", country)
    country_data <- filter(dataset, str_detect(geo, pattern))
    file_name <- paste0(path, "/", country, ".Rdata")
    save(country_data, file=file_name)
  }
}

print(date())
length_stay <- get_length_stay(sex="all")
print("Importado")
export_countries(length_stay, "data/length_stay_subdata")
print(date())

print(date())
deaths <- get_deaths()
print("Importado")
export_countries(deaths, "data/deaths_subdata")
print(date())

print(date())
discharges <- get_hospital_discharges(sex="all")
print("Importado")
export_countries(discharges, "data/discharges_subdata")
print(date())

