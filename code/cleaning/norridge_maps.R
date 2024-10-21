
## Load dependencies, install if not already.
packages <-
  c('tidyverse',
    'sf',
    'haven',
    'tigris',
    'stringr',
    'readxl',
    'terra',
    'ggpattern')

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
districts <- st_read(paste0(RAWDATA,"/nces/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL23_SY2233/EDGE_SCHOOLDISTRICT_TL_23_SY2223.shp")) 

munis <- munis %>% 
  filter(GEOID %in% c(1714000,1753377,1733435,1757875,1768081,1765819,1727702,1764343,1723724))

districts <- districts %>% 
  mutate(STATEFP = as.numeric(STATEFP)) %>% 
  filter(STATEFP %in% unique(munis$STATEFP)) %>% 
  st_make_valid() %>% 
  mutate(land_area = st_area(geometry)) #%>% 
  #filter(GEOID %in% c("1733720"))

shared <- st_intersects(munis, districts, sparse = FALSE)
shared_municipalities <- apply(shared, 1, function(x) sum(x) > 1)
munis$shared <- munis$GEOID %in% c(1753377,1733435)
bbox_shared <- st_bbox(munis[munis$GEOID %in% c(1753377,1733435),])

ggplot() +
  geom_sf(data = munis, aes(fill = shared), color = "black", size = 0.5) +  # Municipalities with shared ones highlighted
  geom_sf_pattern(data = districts[districts$GEOID == '1733720',], aes(geometry = geometry), 
                  pattern = "stripe", pattern_fill = "black", pattern_angle = 45, 
                  pattern_density = 0.1, pattern_spacing = 0.05, fill = NA) +
  scale_fill_manual(values = c("white", "red"), labels = c("Not shared", "Shared")) +
  theme_minimal() +
  coord_sf(xlim = c(bbox_shared["xmin"], bbox_shared["xmax"]),
           ylim = c(bbox_shared["ymin"], bbox_shared["ymax"])) + 
  labs(
       fill = "Shared District")
