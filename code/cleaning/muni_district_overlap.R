library(tidyverse)
library(sf)

munis <- st_read(paste0(INTDATA, "/other/municipal_shapefile_v2.shp")) %>% 
  filter(sm_130_ == 1) %>%
  mutate(STATEFP = as.integer(STATEFP)) %>%
  select(muni_geoid = GEOID, STATEFP, geometry) %>%
  st_make_valid() 

districts_full <- st_read(paste0(RAWDATA, "/nces/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp")) 

districts <- districts_full %>%
  mutate(STATEFP = as.integer(STATEFP)) %>%
  filter(STATEFP %in% unique(munis$STATEFP)) %>%
  select(dist_geoid = GEOID, STATEFP, geometry) %>%
  st_make_valid()

# Make sure CRS matches
districts <- st_transform(districts, st_crs(districts))

# Which munis cover which districts?
covered_list <- st_covered_by(districts, munis, sparse = TRUE)

covered_pairs <- tibble(
  dist_geoid = districts$dist_geoid,
  muni_index = covered_list
) %>%
  tidyr::unnest_longer(muni_index, values_to = "muni_index") %>%
  filter(!is.na(muni_index)) %>%
  mutate(
    muni_geoid = munis$muni_geoid[muni_index]
  )

out <- munis %>%
  st_drop_geometry() %>% 
  mutate(exclusive_school_district = muni_geoid %in% covered_pairs$muni_geoid) %>% 
  rename(GEOID = muni_geoid)

write_dta(out,paste0(INTDATA,"/other/covered_ex_dist.dta"))
