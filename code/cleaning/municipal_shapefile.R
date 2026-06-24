
.locked_package_helper <- c(
  "code/dependencies/locked_packages.R",
  "dependencies/locked_packages.R",
  "../dependencies/locked_packages.R",
  "../../dependencies/locked_packages.R"
)
.locked_package_helper <- .locked_package_helper[file.exists(.locked_package_helper)][1]
if (is.na(.locked_package_helper)) {
  stop("Could not find code/dependencies/locked_packages.R.")
}
source(.locked_package_helper)
enforce_locked_packages()

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
  rename(STATEFP = statefips, PLACEFP = placefips, COUNTYFP = countyfips) %>%
  ### Louisville and Butte-Silver Bow are consolidated cities, match to central city
  mutate(PLACEFP = case_when(PLACEFP == "11390" & STATEFP == "30" ~ "11397", TRUE ~ PLACEFP),
         PLACEFP = case_when(PLACEFP == "48003" & STATEFP == "21" ~ "48000", TRUE ~ PLACEFP)) 

    

corelogic <- read.csv(paste0(INTDATA,"/corelogic/censusplace_clogic_chars.csv")) %>% 
  rename(NAME_corelogic = NAME)

population <- read.csv(paste0(RAWDATA,"/census/nhgis0025_csv/nhgis0025_csv/nhgis0025_ds258_2020_place.csv")) %>% 
  select(STATEA, PLACEA, U7H001) %>% 
  rename(STATEFP = STATEA, PLACEFP = PLACEA, population = U7H001)

places <- data.frame()

for(s in unique(munis$STATEFP)){
  place_s <- st_read(paste0(RAWDATA,"/census/tiger/states/tl_2022_",s,"_place.shp")) %>% 
    left_join(munis %>% filter(STATEFP == s), by = c('STATEFP', 'PLACEFP'))
  places <- rbind(places,place_s)
}


places <- places 
  

out <- places %>%  
  filter(GEOID != "2148006") %>% 
  mutate(STATEFP = as.numeric(STATEFP),
         PLACEFP = as.numeric(PLACEFP),
         COUNTYFP = as.numeric(COUNTYFP)) %>% 
  mutate(ALAND = ALAND/1000,AWATER = AWATER/1000,
         south = STATEFP %in% c(01,05,12,13,21,22,28,37,40,45,47,48,51,54),
         ak_hi = STATEFP %in% c(2,15),
         GEOID = as.numeric(GEOID)) %>% 
  left_join(corelogic, by = 'GEOID')  %>% 
  mutate(STATEFP = if_else(is.na(STATEFP),floor(GEOID/100000),STATEFP)) %>% 
  left_join(cz_place_xwalk, by = c('STATEFP','PLACEFP')) %>% 
  left_join(sample_czs[c('cz','sample_130_czs')], by = 'cz') %>% 
  mutate(sample_130_czs = if_else(is.na(sample_130_czs),  FALSE, TRUE)) %>% 
  left_join(population, by = c('STATEFP','PLACEFP')) %>% 
  # Recode Louisville city back to consildated to be consistent with other data
  mutate(PLACEFP = case_when(PLACEFP == 48000 & STATEFP == 21 ~ 48006, 
                           TRUE ~ PLACEFP),
         cz = case_when(PLACEFP == 48006 & STATEFP == 21 ~ 13101,
                        PLACEFP == 11397 & STATEFP == 30 ~ 34404,
                             TRUE ~ cz),
         sample_130_czs = case_when(PLACEFP == 48006 & STATEFP == 21 ~ 1,
                        PLACEFP == 11397 & STATEFP == 30 ~ 1,
                        TRUE ~ sample_130_czs),
       GEOID = case_when(PLACEFP == 48006 & STATEFP == 21 ~ 2148006,
                         TRUE ~ GEOID)) 

out %>% 
  st_write(paste0(INTDATA,"/other/municipal_shapefile_v2.shp"), append = FALSE)

# Also save attributes without shapefile for ease of use
out %>% 
  st_drop_geometry() %>% 
  write_dta(paste0(INTDATA,"/other/municipal_shapefile_attributes.dta"))

