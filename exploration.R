source("preprocess.R")

# Health professionals ------------------
head(staff_all)
summary(staff_all)

ggplot(staff_all, aes(value))+geom_histogram()+labs(title="Num of professionals, all values")
staff_all %>%
  filter(value > 10000) %>%
  ggplot(aes(value))+geom_histogram()+labs(title="Num of professionals, only values over 10.000")

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

# Aggregate by type of professional, Spain totals.
spain_staff %>%
  filter(unit == 'P_HTHAB') %>% select(c(year, prof, value)) %>%
  group_by(year, prof) %>% summarize_all(sum) -> spain_staff_prof

# Plot professionals per category
p <- ggplot(spain_staff_prof, aes(year, value, color=prof))+geom_line()+
  labs(y='Professionals per 100.000hab', x='Year')
ggplotly(p)

# Aggregate by type of professionals, Europe totals.
staff_regions <- filter(staff_all, unit == 'P_HTHAB', geo != 'EU28', year>2008)

my_colors = c("#698caf", "#b6191d")
ggplot(staff_regions, aes(prof, value))+geom_boxplot(fill=my_colors[1])+
  labs(title="Health professionals in european regions from 2009 to 2019",
       x="", y="Profesionals per 100.000 hab")

# Standardized causes of death -------------------------
head(deaths)
summary(deaths)

ggplot(deaths, aes(value))+geom_histogram()+labs(title="Num of standarized deaths per observation",
                                                 x="Num of deaths in observation",
                                                 y="Num of observations")

# Aggregate all level 1 causes of death
deaths %>%
  filter(sex == 'T', age == 'TOTAL', geo == 'EU28', icd10_level == 1) %>%
  select(c(icd10, value, cause, icd10_level)) %>%
  group_by(cause) %>%
  summarise(deaths=mean(value, na.rm = TRUE)) %>%
  arrange(desc(deaths)) -> deaths_agg

# Create "Other" category
others_list <- as.character(deaths_agg$cause[8:nrow(deaths_agg)])

deaths_agg %>%
  mutate(cause = fct_collapse(cause, Other=others_list)) %>%
  group_by(cause) %>%
  summarise(deaths=sum(deaths)) %>%
  mutate(cause, cause = fct_reorder(cause, deaths)) %>%
  mutate(cause, cause = fct_relevel(cause, 'Other')) -> deaths_agg_other

# Show barplot
ggplot(deaths_agg_other, aes(cause, deaths))+geom_col(fill=my_colors[1])+coord_flip()+
  labs(x="",y="Anual deaths per 100.000hab", title="Most common causes of death in Europe")


# Average hospitalization length -------------------------
head(length_stay)
summary(length_stay)

length_stay %>%
  group_by(age) %>%
  filter(value < quantile(value, probs=0.97)) %>%
  ggplot(aes(age, value))+geom_boxplot(fill=my_colors[2])

# Hospital discharges -------------------------------
head(hospital_discharges)
summary(hospital_discharges)

ggplot(hospital_discharges, aes(value))+geom_histogram()+labs(title="Hospital discharges")
hospital_discharges %>%
  filter(value < quantile(value, prob=0.97)) %>%
  ggplot(aes(value))+geom_histogram()+labs(title="Hospital discharges under quantile 0.97")

# Aggregate all level 1 causes of death
hospital_discharges %>%
  filter(age == 'TOTAL', icd10_level == 1) %>%
  select(c(icd10, value, cause, icd10_level)) %>%
  group_by(cause) %>%
  summarise(value=mean(value, na.rm = TRUE)) %>%
  arrange(desc(value)) -> hospital_discharges_agg

others_list <- as.character(hospital_discharges_agg$cause[8:nrow(hospital_discharges_agg)])

hospital_discharges_agg %>%
  mutate(cause = fct_collapse(cause, Other=others_list)) %>%
  group_by(cause) %>%
  summarise(value=sum(value)) %>%
  mutate(cause, cause = fct_reorder(cause, value)) %>%
  mutate(cause, cause = fct_relevel(cause, 'Other')) -> hospital_discharges_agg_other

ggplot(hospital_discharges_agg_other, aes(cause, value))+geom_col(fill=my_colors[2])+coord_flip()+
  labs(x="",y="Discharges", title="Most common causes of discharge in Europe")

# Hospital discharges and average hospitalization length ------------------------
head(discharge_stay)
summary(discharge_stay)

# Geo values are only NUTS0
levels(discharge_stay$geo)