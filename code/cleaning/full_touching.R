
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

munis <- st_read(paste0(INTDATA,"/other//municipal_shapefile_v2.shp")) 
maxcitypops <- read_dta(paste0(INTDATA,"/census/maxcitypop.dta"))

df <- munis %>% 
  filter(sm_130_ == 1) %>% 
  left_join(maxcitypops, by = 'cz') %>% 
  mutate(main_GEOID = as.numeric(GEOID1940))
maincity <- df %>% 
  filter(GEOID == main_GEOID)


i <- 1
out <- list()
for(c in unique(df$cz)){
  print(paste0("Starting cz: ",c))
  
  
  maincity <- df %>% 
    filter(cz == c,GEOID == main_GEOID) %>% 
    select(cz,GEOID,geometry)
  
  maincity_c <- df %>% 
    filter(cz == c,GEOID == main_GEOID) %>% 
    st_centroid() %>% 
    select(cz,GEOID,geometry)
  
  othercities <- df %>% 
    filter(cz == c,GEOID != main_GEOID) %>% 
    select(cz,GEOID,geometry)
  
  touch <- st_touches(maincity,othercities)
  dist <- st_distance(maincity,othercities)
  dist_c <- st_distance(maincity_c,othercities)
  
  
  othercities$touching <- 0
  othercities$touching[touch[[1]]] <- 1
  othercities$dist <- t(dist)
  othercities$dist_c <- t(dist_c)
  
  out_c <- othercities %>% 
    st_drop_geometry() %>% 
    select(GEOID,cz,touching,dist,dist_c)
  out[[i]] <- out_c
  i <- i+1
  
}
outdf <- do.call(rbind, out)
write.csv(outdf,paste0(INTDATA,"/other/central_city_dists.csv"))
