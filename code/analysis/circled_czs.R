
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

czs <- st_read(paste0(RAWDATA,"/shapefiles/cz1990_shapefile/cz1990.shp")) %>% 
  st_transform(crs)

maxcity <- read_dta(paste0(INTDATA,"/census/maxcitypop.dta")) %>% 
  rename(GEOID_max = GEOID) %>% 
  dplyr::select(c(cz,maxcitypop,totfrac_in_main_city,GEOID_max))

lakes <- st_read(paste0(RAWDATA,"/shapefiles/Lakes_and_Rivers_Shapefile_NA_Lakes_and_Rivers_data_hydrography_p_lakes_v2/Lakes_and_Rivers_Shapefile/NA_Lakes_and_Rivers/data/hydrography_p_lakes_v2.shp")) %>% 
  st_transform(crs)
land <- st_read(paste0(RAWDATA,"/shapefiles/USA_Federal_Lands/USA_Federal_Lands.shp")) %>% 
  st_transform(crs)

water <- st_read(paste0(RAWDATA,"/shapefiles/USA_Detailed_Water_Bodies/USA_Detailed_Water_Bodies.shp")) %>% 
  st_transform(crs) %>% 
  filter(!(FTYPE %in% c('Canal/Ditch','Stream/River')))

df <- munis %>% 
  inner_join(maxcity, by = 'cz') %>%
  mutate(GEOID_max = as.numeric(GEOID_max)) %>% 
  mutate(Legend =  case_when((GEOID == GEOID_max) ~ "Principal City", # Butte-Silver Bow to Butte-Silver Bow (balance)
                             (yr_ncrp <= 1940 ~ "Incorporated Pre-1940"), # Princeton to Princeton
                             TRUE ~ "Incorporated Post-1940 or Unincorporated")) %>% 
  filter(!is.na(cz))
    
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

x <- df[df$GEOID == df$GEOID_max,]

y <- df[!(df$cz %in% x$cz),] 
df[df$GEOID == df$GEOID_max,] %>% 
  st_cast(to = 'MULTILINESTRING') %>% 
  st_write(paste0(CLEANDATA,"/other/main_munis.shp"), append = FALSE)

df[df$GEOID != df$GEOID_max,] %>% 
  st_cast(to = 'MULTILINESTRING') %>% 
  filter(yr_ncrp <= 1940) %>% 
  st_write(paste0(CLEANDATA,"/other/other_munis.shp"), append = FALSE)



get_border <- function(cz){
  print(paste0("Starting cz: ",cz))
  m <- df[df$cz == cz,]
  border <- st_intersection(m$geometry[m$GEOID == m$GEOID_max],
                            m$geometry[(m$GEOID != m$GEOID_max) & (m$yr_ncrp<1940)],
                            model = 'closed')
  return(border)
}
  

get_land <- function(cz){
  print(paste0("Starting cz: ",cz))
  main_muni <- main_munis[main_munis$cz==cz,]
  main_muni_buff <- main_muni %>% 
    st_buffer(dist = 10)
  int <- land %>% 
    st_make_valid() %>% 
    st_intersection(main_muni_buff)
  if(nrow(int)>0){
    border <- main_muni %>% 
      st_crop(int)
  }
  else{
    border <- NA
  }
  return(border)
}

get_water <- function(cz){
  print(paste0("Starting cz: ",cz))
  main_muni <- main_munis[main_munis$cz==cz,]
  main_muni_buff <- main_muni %>% 
    st_buffer(dist = 10)
  int <- water %>% 
    st_make_valid() %>% 
    st_intersection(main_muni_buff)
  if(nrow(int)>0){
    border <- main_muni %>% 
      st_crop(int)
  }
  else{
    border <- NA
  }
  return(border)
}

muni_borders <- sapply(unique(df$cz), get_border)
land_borders <- sapply(unique(df$cz), get_land)
water_borders <- sapply(unique(df$cz), get_water)

x <- unique(df$cz)
plot(df$geometry[df$cz==35001])
plot(main_munis$geometry[main_munis$cz == 35001])
plot(muni_borders[[2]], add = T, col = 'red')
plot(land_borders[[2]], add = T, col = 'green')
plot(water_borders[[2]], add = T, col = 'blue')
plot(land$geometry, add = T, col = 'green')

order
1: cast principal city to multilinestring
2: buffer (1) by 10 or so
3: intersect (2) with land
4: crop (1) by (3)
5: measure (4)