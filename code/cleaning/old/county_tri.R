library(tidyverse)
library(sf)
library(haven)
library(tigris)
library(stringr)
library(terra)
library(readr)
library(spatialEco)
library(raster)

RAWDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/raw/"
INTDATA <- "C:/Users/Everett Stamm/Dropbox/municipality_proliferation/data/interim/"



unusable_area <- function(county, countymap, stateplaces, elevmap, yearcut){
  c <- countymap %>% 
    filter(county_fips == county)
  
  c_elev <- raster::crop(x = elevmap, y = c, snap = "near") 
  
  countyplaces <- stateplaces %>% 
    filter(county_fips == county & yr_incorp <= yearcut)
  
  
  c_raster <-  raster::rasterToPolygons(c_elev) %>%  
    st_as_sf() %>% 
    st_set_crs(st_crs(c))
  if (nrow(countyplaces)>0){  
    c_incorporated <- st_crop(c_raster, countyplaces)
    
    area_incorporated <- sum(st_area(c_incorporated)) %>% 
      as.numeric()
  }
  else{
    area_incorporated <- 0
  }
  
  area_total <- sum(st_area(c_raster)) %>% 
    as.numeric()
  

  c_unusable <- c_elev %>% 
    raster::terrain(opt = "TRI") 
  
  if (max(c_unusable@data@values, na.rm = T) < 117){
    area_unusable <- 0
    area_both <- 0
  }
  else{
    c_unusable <- c_unusable %>% 
      raster::rasterToPolygons(fun = function(x){x>=117}) %>% # cutoff of 117 for an "rugged surface" https://www.arcgis.com/home/item.html?id=9194405568f04c5ea664bee17c08c607#:~:text=0%2D80m%20is%20considered%20to,represents%20an%20intermediately%20rugged%20surface
      st_as_sf() %>% 
      st_crop(y = c)
    area_unusable <- sum(st_area(c_unusable)) %>% 
      as.numeric()
        
    if (area_incorporated>0) {
      c_both <- st_crop(c_unusable,c_incorporated)
      area_both <- sum(st_area(c_both))%>% 
         as.numeric()
    }
    else{
      area_both <- 0
    }
  }
  
  return(c(area_total, area_unusable, area_incorporated, area_both)) 
}


cbgoodman <- read_dta(paste0(RAWDATA,"cbgoodman/muni_incorporation_date.dta")) %>% 
  dplyr::select(placefips,statefips,countyfips, yr_incorp) %>% 
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


counties <- counties() %>% 
  mutate(county_fips = as.numeric(paste0(STATEFP,COUNTYFP))) %>% 
  filter(STATEFP != "02" | STATEFP != "15")

elev <- elevatr::get_elev_raster(counties, z = 5)

ncounty <- length(unique(counties$county_fips))
df <- data.frame(county_fips = rep(unique(counties$county_fips),3), 
                 decade = c(rep(1940,ncounty),rep(1950,ncounty),rep(1960,ncounty)), 
                 area_total = rep(NA,3*ncounty),
                 area_unusable = rep(NA,3*ncounty),
                 area_incorporated = rep(NA,3*ncounty),
                 area_both = rep(NA,3*ncounty)) %>% 
  mutate(STATEFP = as.character(floor(county_fips/1000)))

for (s in unique(counties$STATEFP)){
  s_places <- places(state = s) %>%   
    merge(cbgoodman, by = c("PLACEFP","STATEFP"))  %>% 
    mutate(county_fips = as.numeric(paste0(STATEFP,COUNTYFP)))

  if ((s %in% c("04", "05", "06","08","09"))){ # for some reason Alaska (02) and Virginia (51) crash this loop. Specifically, county 51685 in virginia. Don't know why, but thankfully they aren't used in our analysis so we'll call it luck.
    for (c in unique(counties$county_fips[counties$STATEFP == s])){
      for (d in c(1940,1950,1960)){
        print(paste0("county ",c," decade ",d))
        x <- unusable_area(c,counties,s_places,elev,d)
        df$area_total[df$county_fips == c & df$decade == d] <- x[1]
        df$area_unusable[df$county_fips == c & df$decade == d] <- x[2]
        df$area_incorporated[df$county_fips == c & df$decade == d] <- x[3]
        df$area_both[df$county_fips == c & df$decade == d] <- x[4]
      }
    }
    write_dta(df %>% filter(STATEFP == as.numeric(s)), path = paste0(INTDATA,"land_cover/states/unusable_",s,".dta"))
  }
}


# 
# places <- places(cb=TRUE)  %>% 
#   st_drop_geometry() %>% 
#   select(ALAND, AWATER, STATEFP, PLACEFP) %>% 
#   rename(place_land = ALAND, place_water = AWATER) %>% 
#   mutate(place_total = place_land+place_water) %>% 
#   merge(cbgoodman, by = c("PLACEFP","STATEFP")) %>% 
#   mutate(COUNTYFP = str_pad(COUNTYFP,3,side="left",pad = "0")) %>% 
#   merge(counties, by = c("COUNTYFP","STATEFP")) %>% 
#   mutate(frac_land = place_land/county_land, frac_total = place_total/county_total)
# 
# 
# places <- places(state = "51") %>%   
#   merge(cbgoodman, by = c("PLACEFP","STATEFP"))  %>% 
#   mutate(county_fips = as.numeric(paste0(STATEFP,COUNTYFP)))
# t <- counties[counties$county_fips == 51685 ,]
# tt <- raster::crop(x = elev, y = t, snap = "near")
# ttt = raster::terrain(tt, opt = "TRI")
# t4 <- raster::rasterToPolygons(tt) %>%  st_as_sf() %>% st_set_crs(st_crs(t))
# tttt <- raster::rasterToPolygons(ttt, fun=function(x){x>=117}) # cutoff of 117 for an "rugged surface" https://www.arcgis.com/home/item.html?id=9194405568f04c5ea664bee17c08c607#:~:text=0%2D80m%20is%20considered%20to,represents%20an%20intermediately%20rugged%20surface
# ttttt <- st_as_sf(tttt) %>% st_set_crs(st_crs(t))
# tttttt <- st_crop(ttttt,t)
# p <- places %>% 
#   filter(county_fips == 8097 & yr_incorp <= 1940)
# pp <- st_crop(t4, p)
# ppp <- st_crop(tttttt,p)
# t7 <- st_union(tttttt,t)
# mycounties = unique(counties$county_fips)
# 
# countyshapes = lapply(mycounties,
#                       FUN = function(x){
#                         return(counties[counties$county_fips==x,])
#                       })
# countyshapes
# 
# countyTRIs = lapply(countyshapes,
#                     FUN = CountyTRI,
#                     myraster = elev)
# 
# df <- as.matrix(countyTRIs) %>% 
#   as.data.frame() %>% 
#   rename(mean_tri = V1) %>% 
#   mutate(fips = mycounties, mean_tri = as.numeric(mean_tri))
# 
# write_dta(df, paste0(INTDATA,"land_cover/county_tri.dta"))
