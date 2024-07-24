
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
RAWDATA <- paths[paths$global == "RAWDATA",2]
INTDATA <- paths[paths$global == "INTDATA",2]
CLEANDATA <- paths[paths$global == "CLEANDATA",2]
FIGS <- paths[paths$global == "FIGS",2]
XWALKS <- paths[paths$global == "XWALKS",2]


#### Geographies ----

munis <- st_read(paste0(CLEANDATA,"/other/municipal_shapefile/munis.shp")) 
crs <- st_crs(munis) # NAD 83

schools <- read.csv(paste0(RAWDATA,"/nces/school-districts_lea_directory.csv")) %>% 
  filter(!is.na(longitude) & !is.na(latitude) & year == 2017) %>% 
  st_as_sf(coords = c("longitude", "latitude"), crs = crs)

matched_data <- st_join(schools, munis, join = st_within)

output <- matched_data %>%  
  st_drop_geometry() %>% 
  select(PLACEFP, STATEFP,leaid) %>% 
  filter(!is.na(leaid) & !is.na(PLACEFP)) %>% 
  distinct()

write_dta(output,path=paste0(XWALKS,"/leaid_place_xwalk.dta"))
