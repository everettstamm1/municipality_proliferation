# install.packages(c("sf", "tigris", "dplyr", "purrr", "readr"))



## Load dependencies, install if not already.
packages <-
  c('tidyverse',
    'sf',
    'haven',
    'tigris')

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


options(tigris_use_cache = TRUE)
options(timeout = 600)

# Optional but helpful: avoid S2/GEOS issues during overlay
#sf::sf_use_s2(TRUE)

# Projection helper:
# Use CONUS Albers for most states, Alaska Albers for AK, Hawaii Albers for HI.
# This is just for computing areas/intersections within each state.
state_crs <- function(state_fips) {
  if (state_fips == "02") return(3338)  # Alaska Albers
  if (state_fips == "15") return(3759)  # Hawaii Albers
  return(5070)                          # NAD83 / Conus Albers
}



setup_tigris_folder <- function(shapefile_dir, persist = FALSE) {
  
  dir.create(shapefile_dir, recursive = TRUE, showWarnings = FALSE)
  shapefile_dir <- normalizePath(shapefile_dir, winslash = "/", mustWork = TRUE)
  
  options(tigris_use_cache = TRUE)
  options(timeout = 600)
  
  if (persist) {
    # This writes the cache location to .Renviron, so tigris remembers it
    # in future R sessions.
    tigris::tigris_cache_dir(shapefile_dir)
  } else {
    # This sets the cache location for the current R session only.
    Sys.setenv(TIGRIS_CACHE_DIR = shapefile_dir)
  }
  
  message("TIGER/Line shapefiles will be cached in: ", shapefile_dir)
  
  invisible(shapefile_dir)
}

make_place_county_xwalk_state <- function(state_fips, shapefile_dir) {
  
  setup_tigris_folder(shapefile_dir, persist = FALSE)
  
  state_fips <- sprintf("%02d", as.integer(state_fips))
  message("Processing state FIPS: ", state_fips)
  
  crs_use <- state_crs(state_fips)
  
  places <- tigris::places(
    state = state_fips,
    year = 2011,
    cb = FALSE,
    class = "sf"
  )
  
  counties <- tigris::counties(
    state = state_fips,
    year = 2011,
    cb = FALSE,
    class = "sf"
  )
  
  if (nrow(places) == 0 || nrow(counties) == 0) {
    return(tibble())
  }
  
  places <- places |>
    transmute(
      place_geoid    = GEOID,
      place_statefp  = STATEFP,
      placefp        = PLACEFP,
      place_name     = NAME,
      place_namelsad = NAMELSAD,
      place_classfp  = CLASSFP,
      place_funcstat = FUNCSTAT,
      geometry
    ) |>
    st_make_valid() |>
    st_transform(crs_use)
  
  counties <- counties |>
    transmute(
      county_geoid    = GEOID,
      county_statefp  = STATEFP,
      countyfp        = COUNTYFP,
      county_name     = NAME,
      county_namelsad = NAMELSAD,
      geometry
    ) |>
    st_make_valid() |>
    st_transform(crs_use)
  
  places <- places |>
    mutate(place_area_m2 = as.numeric(st_area(geometry)))
  
  counties <- counties |>
    mutate(county_area_m2 = as.numeric(st_area(geometry)))
  
  #sf::sf_use_s2(FALSE)
  
  inter <- suppressWarnings(
    st_intersection(places, counties)
  )
  
  if (nrow(inter) == 0) {
    return(tibble())
  }
  
  inter <- inter |>
    mutate(intersection_area_m2 = as.numeric(st_area(geometry)))
  
  xwalk <- inter |>
    st_drop_geometry() |>
    group_by(
      place_geoid,
      place_statefp,
      placefp,
      place_name,
      place_namelsad,
      place_classfp,
      place_funcstat,
      county_geoid,
      county_statefp,
      countyfp,
      county_name,
      county_namelsad
    ) |>
    summarise(
      intersection_area_m2 = sum(intersection_area_m2, na.rm = TRUE),
      place_area_m2 = first(place_area_m2),
      county_area_m2 = first(county_area_m2),
      .groups = "drop"
    ) |>
    mutate(
      place_area_share  = intersection_area_m2 / place_area_m2,
      county_area_share = intersection_area_m2 / county_area_m2
    ) |>
    filter(place_area_share > 1e-8)
  
  return(xwalk)
}

setup_tigris_folder(paste0(RAWDATA,"/census/tiger/states_2011/"), persist = FALSE)

state_fips <- unique(tigris::fips_codes$state_code)

# Drop territories unless you want them
state_fips <- setdiff(state_fips, c("60", "66", "69", "72","74", "78"))

place_county_xwalk <- map_dfr(
  state_fips,
  \(s) possibly(
    make_place_county_xwalk_state,
    otherwise = tibble()
  )(s, shapefile_dir = paste0(RAWDATA,"/census/tiger/states/"))
)
place_primary_county <- place_county_xwalk |>
  group_by(place_geoid) |>
  slice_max(place_area_share, n = 1, with_ties = FALSE) |>
  ungroup()

out <-place_primary_county %>% 
  mutate(cty_fips = as.numeric(county_geoid)) %>% 
  left_join(county_cz_xwalk, by = 'cty_fips') %>% 
  mutate(PLACEFP = as.numeric(placefp),
         STATEFP = as.numeric(place_statefp),
         cz = czone) %>% 
  select(PLACEFP,STATEFP,cz) %>% 
  distinct()

out %>% 
  write_dta(paste0(XWALKS,"/cz_place_xwalk.dta"))

out <- place_primary_county %>% 
  select(placefp, place_statefp, countyfp,place_name,county_name) %>% 
  rename(statefp = place_statefp) %>% 
  distinct()


out %>% 
  write_dta(paste0(XWALKS,"/place_county_xwalk.dta"))

