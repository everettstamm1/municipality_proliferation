
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

munis <- st_read(paste0(CLEANDATA,"/other/municipal_shapefile/municipal_shapefile_v2.shp")) 

df <- munis %>% 
  filter(sm_130_ == 1)

for(c in unique(df$cz)){
  print(paste0("Starting cz: ",c))
  cz_df <- df %>% filter(cz == c)
  len <- nrow(cz_df)
  touchgrid = data.frame(matrix(NA, nrow = len, ncol = len))
  colnames(touchgrid) <- cz_df$GEOID
  rownames(touchgrid) <- cz_df$GEOID
  distgrid = data.frame(matrix(NA, nrow = len, ncol = len))
  colnames(distgrid) <- cz_df$GEOID
  rownames(distgrid) <- cz_df$GEOID
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
  write.csv(touchgrid,paste0(CLEANDATA,'/other/full_touching/full_touching_',c,".csv"))
  write.csv(distgrid,paste0(CLEANDATA,'/other/full_touching/full_centroid_dist_',c,".csv"))
}
