

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


districts <- st_read(paste0(RAWDATA,"/nces/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp"))
dist_cz_xwalk <- read_dta(paste0(XWALKS,"/leaid_cz_xwalk.dta")) %>% 
  rename(cz = czone)
sample_czs <- read_dta(paste0(CLEANDATA,"/cz_pooled.dta")) %>% 
  select(cz)

df <- districts %>% 
  mutate(leaid = as.numeric(GEOID)) %>% 
  left_join(dist_cz_xwalk, by = 'leaid') %>% 
  inner_join(sample_czs, by = 'cz') %>% 
  st_make_valid()

check <- df %>% 
  st_drop_geometry()

for(c in unique(df$cz)){
  print(paste0("Starting cz: ",c))
  cz_df <- df %>% filter(cz == c)
  len <- nrow(cz_df)
  touchgrid = data.frame(matrix(NA, nrow = len, ncol = len))
  colnames(touchgrid) <- cz_df$leaid
  rownames(touchgrid) <- cz_df$leaid
  distgrid = data.frame(matrix(NA, nrow = len, ncol = len))
  colnames(distgrid) <- cz_df$leaid
  rownames(distgrid) <- cz_df$leaid
  for(i in 1:len){
    sf_i <- cz_df[i,]
    sf_i_cent <- st_centroid(sf_i)
    print(paste0("Starting i: ",i))
    for(j in 1:len){
      if (i<j){
        sf_j <- cz_df[j,]
        touch <- st_touches(sf_i,sf_j,sparse = FALSE)
        touchgrid[i,j] <- touch[1]
        touchgrid[j,i] <- touch[1]
        dist <- st_distance(sf_i_cent,st_centroid(sf_j))
        distgrid[i,j] <- dist[1]
        distgrid[j,i] <- dist[1]
      }
    }
  }
  write.csv(touchgrid,paste0(INTDATA,'/nces/school_touching_distance/school_touching_',c,".csv"))
  write.csv(distgrid,paste0(INTDATA,'/nces/school_touching_distance/school_centroid_dist_',c,".csv"))
}
