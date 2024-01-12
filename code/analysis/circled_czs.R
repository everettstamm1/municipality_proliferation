
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
czs <- st_read(paste0(RAWDATA,"/shapefiles/cz1990_shapefile/cz1990.shp"))
munis <- st_read(paste0(CLEANDATA,"/other/municipal_shapefile.shp"))
maxcity <- read_dta(paste0(INTDATA,"/census/maxcitypop.dta")) %>% 
  rename(GEOID_max = GEOID) %>% 
  select(-cz_name)

df <- munis %>% 
  inner_join(maxcity, by = 'cz') %>% 
  mutate(Legend =  case_when((GEOID == GEOID_max) ~ "Principal City", # Butte-Silver Bow to Butte-Silver Bow (balance)
                             (yr_ncrp <= 1940 ~ "Incorporated Pre-1940"), # Princeton to Princeton
                             TRUE ~ "Incorporated Post-1940 or Unincorporated"))
    
for (cz in unique(df$cz)){
  cz_name <- df$cz_name[df$cz == cz]
  path_name <- cz_name %>% 
    str_replace_all(",","") %>% 
    str_replace_all("\\.","") %>% 
    str_replace_all(" ","_") %>% 
    str_replace_all("-","_") %>% 
    str_to_lower()
  
  cz_plot <- ggplot() + 
    geom_sf(data = czs[czs$cz==cz,],fill=alpha("white",0.2)) +
    geom_sf(data = df[df$cz==cz,], mapping = aes(fill = Legend)) +
    ggtitle(cz_name)
    
  ggsave(paste0(FIGS,"/circled_czs/",path_name,".png"), scale = 4, plot = cz_plot)
}
ggplot() + 
  geom_sf(data = czs[czs$cz==35100,],fill=alpha("white",0.2)) +
  geom_sf(data = df[df$cz==35100,], mapping = aes(fill = Legend))+
  ggtitle("test")
unique(df$cz_name) 

