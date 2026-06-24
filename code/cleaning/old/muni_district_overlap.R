
.locked_package_helper <- c(
  "code/dependencies/locked_packages.R",
  "dependencies/locked_packages.R",
  "../dependencies/locked_packages.R",
  "../../dependencies/locked_packages.R"
)
.locked_package_helper <- .locked_package_helper[file.exists(.locked_package_helper)][1]
if (is.na(.locked_package_helper)) {
  stop("Could not find code/dependencies/locked_packages.R.")
}
source(.locked_package_helper)
enforce_locked_packages()

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

munis <- st_read(paste0(INTDATA,"/other/municipal_shapefile_v2.shp")) 
districts <- st_read(paste0(RAWDATA,"/nces/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp")) 


munis <- munis %>% 
  filter(sm_130_ == 1) %>% 
  mutate(land_area = st_area(geometry))

districts <- districts %>% 
  mutate(STATEFP = as.numeric(STATEFP)) %>% 
  filter(STATEFP %in% unique(munis$STATEFP)) %>% 
  st_make_valid() %>% 
  mutate(land_area = st_area(geometry))



for(s in unique(munis$STATEFP)){
  print(paste0("Starting state: ",s))
  state_munis <- munis %>% filter(STATEFP == s)
  state_districts <- districts %>% filter(STATEFP == s)
  
  nr <- nrow(state_munis)
  nc <- nrow(state_districts)
  
  distgrid = data.frame(matrix(NA, nrow = nr, ncol = nc))

  colnames(distgrid) <- state_districts$GEOID
  rownames(distgrid) <- state_munis$GEOID
  
  for(i in 1:nr){
    muni <- state_munis[i,]
    print(paste0("Starting i: ",i))
    for(j in 1:nc){
        dist <- state_districts[j,]
        int <- st_intersection(muni,dist,dimension = "polygon")
        if(nrow(int) > 0){
          int_area <- st_area(st_make_valid(int))
          distgrid[i,j] <- int_area/ state_districts$land_area[j]
        }
        else{
          distgrid[i,j] <- 0
        }
      }
  }
  write.csv(distgrid,paste0(INTDATA,'/other/muni_district_overlaps/distgrid_',s,".csv"))
}
