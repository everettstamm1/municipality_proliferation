library(tidyverse)
library(sf)
library(haven)
library(tigris)
library(stringr)

RAWDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/raw/"
INTDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/interim/"


cbgoodman <- read_dta(paste0(RAWDATA,"cbgoodman/muni_incorporation_date.dta")) %>% 
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
  mutate(county_total = county_land+county_water)


places <- places(cb=TRUE)  %>% 
  st_drop_geometry() %>% 
  select(ALAND, AWATER, STATEFP, PLACEFP) %>% 
  rename(place_land = ALAND, place_water = AWATER) %>% 
  mutate(place_total = place_land+place_water) %>% 
  merge(cbgoodman, by = c("PLACEFP","STATEFP")) %>% 
  mutate(COUNTYFP = str_pad(COUNTYFP,3,side="left",pad = "0")) %>% 
  merge(counties, by = c("COUNTYFP","STATEFP")) %>% 
  mutate(frac_land = place_land/county_land, frac_total = place_total/county_total)

write_dta(places,path=paste0(INTDATA,"cgoodman/cgoodman_place_county_geog.dta"))
