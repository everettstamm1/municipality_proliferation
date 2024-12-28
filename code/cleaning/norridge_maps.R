
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

# Subset to get only the shared municipalities
shared_munis <- munis[munis$GEOID %in% c(1753377,1733435), ]

# Find the corresponding school district(s)
shared_districts <- districts[districts$GEOID == '1733720', ]

# Calculate the intersection (overlap) between municipalities and school districts
overlap <- st_intersection(shared_munis, shared_districts)

grid_size <- 0.001
bbox_overlap <- st_bbox(overlap)
x_seq <- seq(bbox_overlap["xmin"], bbox_overlap["xmax"], by = grid_size)
y_seq <- seq(bbox_overlap["ymin"], bbox_overlap["ymax"], by = grid_size)

grid <- st_make_grid(overlap, cellsize = c(grid_size, grid_size), what = "polygons")
hatch_grid <- grid[seq(1, length(grid), by = 2)]
hatch_grid <- hatch_grid %>% 
  st_make_valid() %>% 
  st_intersection(st_make_valid(shared_districts))
bbox_shared <- st_bbox(shared_munis)
shift <- 0.0001
ggplot() + 
  geom_sf(data = munis, aes(fill = shared), col = 'black') +
  scale_fill_manual(values = c("white", "#00BA38"), labels = c("Not shared", "Shared")) +
  geom_sf(data = hatch_grid, fill = '#F8766D', alpha = 0.4) +
  coord_sf(xlim = c(bbox_shared["xmin"]*(1+shift), bbox_shared["xmax"]*(1-shift)),
           ylim = c(bbox_shared["ymin"]*(1-shift), bbox_shared["ymax"]*(1+shift)))+
  theme_minimal()+
  labs(title = "Map with Simulated Hatch Pattern for Shared Areas")+ 
  theme(
    axis.text = element_blank(),      # Remove the text labels
    axis.ticks = element_blank(),     # Remove the tick marks
    axis.title = element_blank(),     # Remove axis titles
    panel.grid = element_blank()      # Remove the grid lines (optional)
  )

ggplot() +
  geom_sf(data = shared_districts, fill = "lightblue", color = NA, alpha = 0.4) +  # All school districts
  geom_sf(data = munis, fill = "white", color = "black", size = 0.5) +   # All municipalities
  geom_sf(data = overlap, fill = NA, color = "black", size = 0.5) +               # Outline for overlapping area
  geom_sf(data = hatch_grid, fill = "black", color = NA, alpha = 0.2) +           # Hatch grid for the overlapping area
  geom_sf(data = shared_munis, fill = "red", color = "black", size = 0.5) +       # Highlight shared municipalities
  coord_sf(xlim = c(bbox_shared["xmin"], bbox_shared["xmax"]),
           ylim = c(bbox_shared["ymin"], bbox_shared["ymax"])) +                 # Zoom to shared municipalities
  theme_minimal() +
  labs(title = "Map with Simulated Hatch Pattern for Shared Areas") + 
  theme(
    axis.text = element_blank(),      # Remove the text labels
    axis.ticks = element_blank(),     # Remove the tick marks
    axis.title = element_blank(),     # Remove axis titles
    panel.grid = element_blank()      # Remove the grid lines (optional)
  )
