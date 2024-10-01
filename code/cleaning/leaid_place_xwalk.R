
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


#### Geographies ----
districts <- st_read(paste0(RAWDATA,"/nces/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp")) 

munis <- st_read(paste0(CLEANDATA,"/other/municipal_shapefile/municipal_shapefile_v2.shp")) 
crs <- st_crs(munis) # NAD 83

school_districts <- read.csv(paste0(RAWDATA,"/nces/school-districts_lea_directory.csv")) %>% 
  filter(!is.na(longitude) & !is.na(latitude) & year == 2017) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = crs)

schools <- read_dta(paste0(INTDATA,"/nces/school_ccd_directory.dta"))  %>% 
  filter(!is.na(longitude) & !is.na(latitude) & year == 2017) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = crs)

matched_districts <- st_join(school_districts, munis, join = st_within)
matched_schools <- st_join(schools, munis, join = st_within)

output_districts <- matched_districts %>%  
  st_drop_geometry() %>% 
  select(PLACEFP, STATEFP,leaid) %>% 
  filter(!is.na(leaid) & !is.na(PLACEFP)) %>% 
  distinct()


output_schools <- matched_schools %>%  
  st_drop_geometry() %>% 
  select(PLACEFP, STATEFP,leaid, ncessch) %>% 
  filter(!is.na(leaid) & !is.na(PLACEFP) & !is.na(ncessch)) %>% 
  distinct()

write_dta(output_districts,path=paste0(XWALKS,"/leaid_place_xwalk.dta"))
write_dta(output_schools,path=paste0(XWALKS,"/ncessch_place_xwalk.dta"))

