

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
paths <- read.csv("paths.csv")
RAWDATA <- paths[paths$global == "RAWDATA",2]
INTDATA <- paths[paths$global == "INTDATA",2]
CLEANDATA <- paths[paths$global == "CLEANDATA",2]
FIGS <- paths[paths$global == "FIGS",2]
XWALKS <- paths[paths$global == "XWALKS",2]

districts <- st_read(paste0(RAWDATA,"/nces/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp")) %>% 
  select(GEOID, ALAND) %>% 
  st_drop_geometry() %>% 
  rename(leaid = GEOID,
         area = ALAND)

write_dta(districts,path=paste0(INTDATA,"/nces/leaid_areas.dta"))

