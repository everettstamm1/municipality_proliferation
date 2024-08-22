
## Load dependencies, install if not already.
packages <-
  c('tidyverse',
    'sf',
    'haven',
    'tigris',
    'stringr',
    'readxl',
    'terra')

for (pkg in packages) {
  if (require(pkg, character.only = TRUE) == FALSE) {
    print(paste0("Trying to install ", pkg))
    install.packages(pkg)
    if (require(pkg, character.only = TRUE)) {
      print(paste0(pkg, " installed and loaded"))
    } else{
      stop(paste0("could not install ", pkg))
    }
  }
}

# Get paths
paths <- read.csv("../../paths.csv")
CLEANDATA <- paths[paths$global == "CLEANDATA",2]
RAWDATA <- paths[paths$global == "RAWDATA",2]
INTDATA <- paths[paths$global == "INTDATA",2]
XWALKS <- paths[paths$global == "XWALKS",2]



#### Geographies ----
county_cz_xwalk <- read_dta(paste0(XWALKS,"/cw_cty_czone.dta"))
sample_czs <- read_dta(paste0(INTDATA,"/dcourt/original_130_czs.dta")) %>% 
  mutate(sample_130_czs = TRUE)

fips_place_xwalk <- read_dta(paste0(XWALKS,"/place_county_xwalk.dta")) %>% 
  rename(STATEFP = statefp, PLACEFP = placefp, COUNTYFP_xwalk = countyfp) %>% 
  select(STATEFP, PLACEFP, COUNTYFP_xwalk)
cz_place_xwalk <- read_dta(paste0(XWALKS,"/cz_place_xwalk.dta"))

munis <- read_stata(paste0(RAWDATA,'/cbgoodman/muni_incorporation_date.dta')) %>% 
  select(muniname,statefips,placefips,countyfips,yr_incorp) %>% 
  rename(STATEFP = statefips, PLACEFP = placefips, COUNTYFP = countyfips) 
  
WRLURI <- read_stata(paste0(RAWDATA,"/other/WHARTONLANDREGULATIONDATA_1_15_2020/WRLURI_01_15_2020.dta")) %>% 
  filter(str_length(GEOID)==7) %>% # Keeping only census designated places
  mutate(PLACEFP = fipsplacecode18, STATEFP = statecode) %>% 
  select(PLACEFP, STATEFP,LPPI18,SPII18,LPAI18,LZAI18,SRI18,DRI18,
       EI18,AHI18,ADI18,WRLURI18,weight_full,weight_metro,
       totinitiatives18,appr_rate18, communityname18) %>% 
  mutate(PLACEFP = case_when((PLACEFP == 11390) ~ 11397, # Butte-Silver Bow to Butte-Silver Bow (balance)
                             (PLACEFP == 60915 ~ 60900), # Princeton to Princeton
                             TRUE ~ PLACEFP))


corelogic <- read.csv(paste0(CLEANDATA,"/corelogic/censusplace_clogic_chars.csv")) %>% 
  rename(NAME_corelogic = NAME)

population <- read.csv(paste0(RAWDATA,"/census/nhgis0025_csv/nhgis0025_csv/nhgis0025_ds258_2020_place.csv")) %>% 
  select(STATEA, PLACEA, U7H001) %>% 
  rename(STATEFP = STATEA, PLACEFP = PLACEA, population = U7H001)

places <- data.frame()

for(s in unique(munis$STATEFP)){
  place_s <- places(state = s) %>% 
    left_join(munis, by = c('STATEFP', 'PLACEFP'))
  places <- rbind(places,place_s)
}

places <- data.frame()

for(s in unique(munis$STATEFP)){
  place_s <- places(state = s) %>% 
    full_join(munis[munis$STATEFP == s,], by = c('STATEFP', 'PLACEFP'))
  places <- rbind(places,place_s)
}

out <- places %>% 
  mutate(STATEFP = as.numeric(STATEFP),
         PLACEFP = as.numeric(PLACEFP),
         COUNTYFP = as.numeric(COUNTYFP)) %>% 
  left_join(WRLURI, by = c('STATEFP', 'PLACEFP')) %>% 
  mutate(ALAND = ALAND/1000,AWATER = AWATER/1000,
         south = STATEFP %in% c(01,05,12,13,21,22,28,37,40,45,47,48,51,54),
         ak_hi = STATEFP %in% c(2,15),
         GEOID = as.numeric(GEOID)) %>% 
  left_join(corelogic, by = 'GEOID')  %>% 
  mutate(STATEFP = if_else(is.na(STATEFP),floor(GEOID/100000),STATEFP)) %>% 
  left_join(cz_place_xwalk, by = c('STATEFP','PLACEFP')) %>% 
  left_join(sample_czs[c('cz','sample_130_czs')], by = 'cz') %>% 
  mutate(sample_130_czs = if_else(is.na(sample_130_czs),  FALSE, TRUE)) %>% 
  left_join(population, by = c('STATEFP','PLACEFP'))

out %>% 
  st_write(paste0(CLEANDATA,"/other/municipal_shapefile/municipal_shapefile_v2.shp"), append = FALSE)

# Also save attributes without shapefile for ease of use
out %>% 
  st_drop_geometry() %>% 
  write_dta(paste0(CLEANDATA,"/other/municipal_shapefile_attributes.dta"))

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
