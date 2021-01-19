source("preprocess.R")

icd10_es <- c(Other="Otros",
              Neoplasms="Neoplasias",
              "Mental and behavioural disorders (F00-F99)"="Desórdenes mentales y del comportamiento",
              "Diseases of the nervous system and the sense organs (G00-H95)"="Enfermedades del sistema nervioso y órganos de los sentidos",
              "Diseases of the circulatory system (I00-I99)"="Enfermedades del sistema circulatorio",
              "Diseases of the respiratory system (J00-J99)"="Enfermedades del sistema respiratorio",
              "Diseases of the digestive system (K00-K93)"="Enfermedades del sistema digestivo",
              "External causes of morbidity and mortality (V01-Y89)"="Causas externas de morbilidad y mortalidad",
              "Diseases of the musculoskeletal system and connective tissue (M00-M99)"="Enfermedades del sistema musculoesquelético\n y los tejidos conectivos",
              "Diseases of the genitourinary system (N00-N99)"="Enfermedades del aparato genitourinario",
              "Pregnancy, childbirth and the puerperium (O00-O99)"="Embarazo, parto y puerperio")


age_groups <- c("Y_LT1"="0 a 1",
                "Y1-4"="1 a 15",
                "Y5-9"="1 a 15",
                "Y10-14"="1 a 15",
                "Y_LT15"="1 a 15",
                "Y15-19"="15 a 50",
                "Y20-24"="15 a 50",
                "Y25-29"="15 a 50",
                "Y30-34"="15 a 50",
                "Y35-39"="15 a 50",
                "Y40-44"="15 a 50",
                "Y45-49"="15 a 50",
                "Y50-54"="50 a 65",
                "Y55-59"="15 a 50",
                "Y60-64"="15 a 50",
                "Y65-69"="Más de 65",
                "Y70-74"="Más de 65",
                "Y75-79"="Más de 65",
                "Y80-84"="Más de 65",
                "Y85-89"="Más de 65",
                "Y90-94"="Más de 65",
                "Y_GE65"="Más de 65",
                "Y_GE85"="Más de 65",
                "Y_GE90"="Más de 65",
                "Y_GE95"="Más de 65",
                "TOTAL"="Total",
                "UNK"="Otros",
                "Y_LT25"="Otros")


get_examples <- function(data, n_rows=2, m_rows=3) {
  n_rows_index <- sample(nrow(data), n_rows)
  metadata_index <- which("" != data$metadata)
  m_rows_index <- metadata_index[sample(length(metadata_index), m_rows)]
  data_sample <- data[append(n_rows_index, m_rows_index),]
  return(data_sample)
}

# Get data ---------------------------------------------------------------------
# Deaths
get_deaths() %>%
  filter(sex == 'T', age == 'TOTAL', geo == 'EU28', icd10_level == 1) %>%
  select(c(icd10, value, cause, icd10_level)) %>%
  group_by(cause) %>%
  summarise(deaths=mean(value, na.rm = TRUE)) %>%
  arrange(desc(deaths)) -> deaths_agg
save(deaths_agg, file="data/deaths_agg.RData")


# Discharges
get_hospital_discharges() %>%
  filter(age == 'TOTAL', icd10_level == 1) %>%
  select(c(icd10, value, cause, icd10_level)) %>%
  group_by(cause) %>%
  summarise(value=mean(value, na.rm = TRUE)) %>%
  arrange(desc(value)) -> discharges_agg
save(discharges_agg, file="data/discharges_agg.RData")


# Visualizations ---------------------------------------------------------------
get_staff_all() %>%
  filter(geo %in% names(spain_nuts)) %>%
  mutate(region = recode_factor(geo, !!!unlist(spain_nuts))) %>%
  filter(unit == 'P_HTHAB') %>% select(c(year, prof, value)) %>%
  group_by(year, prof) %>% summarize_all(mean, na.rm=TRUE) -> staff
  
names(staff)[2] <- "Tipo"
ggplot(staff, aes(year, value, color=Tipo))+geom_line()+
          labs(y='Profesionales por cada 100.000hab', x='Año')

# Deaths
load("data/deaths_agg.RData")

others_deaths <- as.character(deaths_agg$cause[5:nrow(deaths_agg)])

deaths_agg %>%
  mutate(cause = fct_collapse(cause, Other=others_deaths)) %>%
  group_by(cause) %>%
  summarise(deaths=sum(deaths)) %>%
  mutate(cause, cause = fct_reorder(cause, deaths)) %>%
  mutate(cause, cause = fct_relevel(cause, 'Other')) %>%
  mutate(cause, cause = recode_factor(cause, !!!unlist(icd10_es))) %>%
  ggplot(aes(cause, deaths))+geom_col(fill="#000078")+coord_flip()+
  theme(axis.text=element_text(size=20), axis.title.y=element_text(size=20))+
  labs(x="",y="Muertes anuales por cada 100.000hab")


# ALOS
get_length_stay() %>%
  group_by(age) %>%
  filter(value < quantile(value, probs=0.97)) -> length_stay

save(length_stay, file="data/lengh_stay_diaps.RData")

length_stay %>%
  mutate(edad= sapply(age, function(x) age_groups[[as.character(x)]])) %>%
  filter(edad != "Otros") %>%
  select(edad, sex, icd10, geo, year, value) %>%
  group_by(edad, sex, icd10, geo, year) %>%
  summarise(value=mean(value)) -> len_plot


save(len_plot, file="data/len_pot.RData")
len_plot %>%
  ggplot(aes(edad, value))+geom_boxplot(fill="#000078", color="#657183")+coord_flip()+
          labs(y="Días")+theme(axis.text=element_text(size=20),
                               axis.title.y=element_text(size=20))

# Models
load("data/models_df.RData")

names(models_df) <- c("country", "término independiente", "edad", "mujeres",
                      "hombres", "año", "altas", "médicos", "enfermeras y matronas",
                      "dentistas", "farmacéuticos", "fisioterapeutas", "mortalidad")
models_df %>%
  pivot_longer(!country, names_to="name", values_to="value", values_drop_na=TRUE) %>%
  mutate(value = as.numeric(as.character(value))) %>%
  ggplot(aes(name, value)) + geom_boxplot() + coord_flip() +
  labs(x=NULL, y="Peso")+theme(axis.text=element_text(size=20),
                               axis.title.y=element_text(size=20))

# Discharges
others_discharge <- as.character(hospital_discharges$cause[8:nrow(hospital_discharges)])
discharges_agg %>%
  mutate(cause = fct_collapse(cause, Other=others_discharge)) %>%
  group_by(cause) %>%
  summarise(value=sum(value)) %>%
  mutate(cause, cause = fct_reorder(cause, value)) %>%
  mutate(cause, cause = fct_relevel(cause, 'Other')) %>%
  mutate(cause, cause = recode_factor(cause, !!!unlist(icd10_es))) %>%
  ggplot(aes(cause, value))+geom_col(fill="#000078")+coord_flip()+
  labs(x="",y="Diagnósticos al alta")+theme(axis.text=element_text(size=20),
                                            axis.title.y=element_text(size=20))
