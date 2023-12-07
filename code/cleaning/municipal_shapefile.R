library(tidyverse)
library(sf)
library(haven)
library(tigris)
library(stringr)
library(readxl)
library(terra)

RAWDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/raw/"
INTDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/interim/"
CLEANDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/clean/"

XWALKS <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/xwalks/"

#### Geographies ----
county_cz_xwalk <- read_dta(paste0(XWALKS,"cw_cty_czone.dta"))
sample_czs <- read_dta(paste0(INTDATA,"dcourt/original_130_czs.dta")) %>% 
  mutate(sample_130_czs = TRUE)

fips_place_xwalk <- read_dta(paste0(XWALKS,"cog_ID_fips_place_xwalk_02.dta")) %>% 
  select(fips_state, fips_county_2002, fips_place_2002) %>% 
  rename(STATEFP = fips_state, COUNTYFP = fips_county_2002, PLACEFP = fips_place_2002)

munis <- read_stata(paste0(RAWDATA,'/cbgoodman/muni_incorporation_date.dta')) %>% 
  select(muniname,statefips,placefips,countyfips,yr_incorp) %>% 
  rename(STATEFP = statefips, PLACEFP = placefips, COUNTYFP = countyfips) 
  
WRLURI <- read_stata(paste0(RAWDATA,"other/WHARTONLANDREGULATIONDATA_1_15_2020/WRLURI_01_15_2020.dta")) %>% 
  filter(str_length(GEOID)==7) %>% # Keeping only census designated places
  mutate(PLACEFP = fipsplacecode18, STATEFP = statecode) %>% 
  select(PLACEFP, STATEFP,LPPI18,SPII18,LPAI18,LZAI18,SRI18,DRI18,
       EI18,AHI18,ADI18,WRLURI18,weight_full,weight_metro,
       totinitiatives18,appr_rate18, communityname18) %>% 
  mutate(PLACEFP = case_when((PLACEFP == 11390) ~ 11397, # Butte-Silver Bow to Butte-Silver Bow (balance)
                             (PLACEFP == 60915 ~ 60900), # Princeton to Princeton
                             TRUE ~ PLACEFP)) 

places <- data.frame()

for(s in unique(munis$STATEFP)){
  place_s <- places(state = s, year = 2018) %>% 
    left_join(munis, by = c('STATEFP', 'PLACEFP'))
  places <- rbind(places,place_s)
}

places <- places %>% 
  mutate(cty_fips = as.numeric(str_c(STATEFP,COUNTYFP)),
         STATEFP = as.numeric(STATEFP),
         PLACEFP = as.numeric(PLACEFP)) %>% 
  merge(county_cz_xwalk, by = 'cty_fips', all.x = TRUE) %>% 
  rename(cz = czone) %>% 
  left_join(sample_czs, by = 'cz') %>% 
  mutate(sample_130_czs = if_else(is.na(sample_130_czs),  FALSE, TRUE)) %>% 
  left_join(WRLURI, by = c('STATEFP', 'PLACEFP')) %>% 
  mutate(ALAND = ALAND/1000,AWATER = AWATER/1000,
         south = STATEFP %in% c(01,05,12,13,21,22,28,37,40,45,47,48,51,54),
         ak_hi = STATEFP %in% c(2,15))
  


st_write(places,paste0(CLEANDATA,"other/municipal_shapefile.shp"), layer = "munis")

# Also save attributes without shapefile for ease of use
places %>% 
  st_drop_geometry() %>% 
  write_dta(paste0(CLEANDATA,"other/municipal_shapefile_attributes.dta"))

# TROUBLESHOOTING THE MERGE
# test <- places %>% 
#   st_drop_geometry() %>% 
#   select(cty_fips,PLACEFP,STATEFP,NAME,muniname, yr_incorp,LSAD) %>% 
#   full_join(WRLURI, by = c('STATEFP','PLACEFP')) %>% 
#   mutate(merge = if_else(!is.na(LSAD),
#                          if_else(!is.na(WRLURI18),
#                                  3,1),2))
# 
# test <- test[c(22,21,1:20)]
# test <- test[order(test$STATEFP,test$PLACEFP),]
# flags <- test %>% 
#   filter(merge==2 & STATEFP %in% unique(places$STATEFP)) %>% 
#   select(c(STATEFP,PLACEFP))
# 
# 
# check3 <- read_excel("C:/Users/Everett Stamm/Downloads/all-geocodes-v2018.xlsx",skip=4)
# check3 <- check3[str_detect(check3$`Area Name (including legal/statistical area description)`,"Cheshire") == TRUE,]
# %>% 
#   filter(str_detect(`Ar`)


