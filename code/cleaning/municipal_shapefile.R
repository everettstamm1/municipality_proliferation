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
  mutate(PLACEFP = as.character(fipsplacecode18), STATEFP = as.character(statecode)) %>% 
  select(PLACEFP, STATEFP,LPPI18,SPII18,LPAI18,LZAI18,SRI18,DRI18,
       EI18,AHI18,ADI18,WRLURI18,weight_full,weight_metro,
       totinitiatives18,appr_rate18)

places <- data.frame()

for(s in unique(munis$STATEFP)){
  place_s <- places(state = s) %>% 
    merge(munis, by = c('STATEFP', 'PLACEFP'), all.x = TRUE)
  places <- rbind(places,place_s)
}

places <- places %>% 
  mutate(cty_fips = as.numeric(str_c(STATEFP,COUNTYFP))) %>% 
  merge(county_cz_xwalk, by = 'cty_fips', all.x = TRUE) %>% 
  rename(cz = czone) %>% 
  left_join(sample_czs, by = 'cz') %>% 
  mutate(sample_130_czs = if_else(is.na(sample_130_czs),  FALSE, TRUE)) %>% 
  left_join(WRLURI, by = c('STATEFP', 'PLACEFP'))

st_write(places,paste0(CLEANDATA,"other/municipal_shapefile.shp"), layer = "munis")

