
## Load dependencies, install if not already.
packages <-
  c('tidyverse',
    'sf',
    'haven',
    'tigris',
    'stringr',
    'readxl')

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
paths <- read.csv("../paths.csv")
RAWDATA <- paths[paths$global == "RAWDATA",2]
INTDATA <- paths[paths$global == "INTDATA",2]
XWALKS <- paths[paths$global == "XWALKS",2]
county_cz_xwalk <- read_dta(paste0(XWALKS,"/cw_cty_czone.dta"))

cbgoodman <- read_dta(paste0(RAWDATA,"/cbgoodman/muni_incorporation_date.dta")) %>% 
  select(placefips,statefips,countyfips, yr_incorp) %>% 
  rename(PLACEFP = placefips,STATEFP = statefips, COUNTYFP = countyfips)

# Manual edits: Need to break New York City into it's distinct counties

## County FIPS 5,47,61,81, and 85 correspond to Bronx, Brooklyn, Manhattan, Queens, and Staten Island
# which correspond to Bronx, Kings, New York, Queens, and Richmond Counties
ny_incorp = cbgoodman$yr_incorp[cbgoodman$STATEFP == "36" & cbgoodman$PLACEFP == "51000"]
ny <- data.frame(PLACEFP = rep("51000",5), 
                 STATEFP = rep("36",5),
                 COUNTYFP = c("5","47","61","81","85"),
                 yr_incorp = rep(ny_incorp,5))
cbgoodman <- cbgoodman %>% 
  filter(STATEFP != "36" | PLACEFP != "51000") %>% 
  rbind(ny)

counties <- counties()  %>% 
  st_drop_geometry() %>% 
  select(ALAND, AWATER, STATEFP, COUNTYFP) %>% 
  rename(county_land = ALAND, county_water = AWATER) %>% 
  mutate(county_total = county_land+county_water,
         cty_fips = as.numeric(paste0(STATEFP,COUNTYFP))) %>% 
  merge(county_cz_xwalk, by="cty_fips")



places <- places(cb=TRUE)  %>% 
  st_drop_geometry() %>% 
  select(ALAND, AWATER, STATEFP, PLACEFP) %>% 
  rename(place_land = ALAND, place_water = AWATER) %>% 
  mutate(place_total = place_land+place_water) %>% 
  merge(cbgoodman, by = c("PLACEFP","STATEFP")) %>% 
  mutate(COUNTYFP = str_pad(COUNTYFP,3,side="left",pad = "0")) %>% 
  merge(counties, by = c("COUNTYFP","STATEFP")) %>% 
  mutate(frac_land = place_land/county_land, frac_total = place_total/county_total)

write_dta(places,path=paste0(INTDATA,"/cgoodman/cgoodman_place_county_geog.dta"))
