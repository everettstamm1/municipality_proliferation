## Load dependencies, install if not already.
packages <-
  c('tidyverse',
    'sf',
    'haven',
    'tigris',
    'stringr',
    'readxl')

for (pkg in packages) {
  if (require(pkg, character.only = TRUE) == FALSE) {
    print(paste0("Trying to install ", pkg))
    install.packages(pkg)
    if (require(pkg, character.only = TRUE)) {
      print(paste0(pkg, " installed and loaded"))
    } else {
      stop(paste0("could not install ", pkg))
    }
  }
}

# ----------------------------
# Get paths
# ----------------------------

paths <- read.csv("../../paths.csv")

RAWDATA <- paths[paths$global == "RAWDATA", 2]
INTDATA <- paths[paths$global == "INTDATA", 2]
XWALKS  <- paths[paths$global == "XWALKS", 2]

# ----------------------------
# Set tigris download/cache folder
# ----------------------------

TIGRIS_DIR <- file.path(RAWDATA, "census", "tiger", "CB")

dir.create(TIGRIS_DIR, recursive = TRUE, showWarnings = FALSE)

# Normalize path for Windows/R compatibility
TIGRIS_DIR <- normalizePath(TIGRIS_DIR, winslash = "/", mustWork = TRUE)

options(tigris_use_cache = TRUE)
options(timeout = 600)

# Current R session cache location
Sys.setenv(TIGRIS_CACHE_DIR = TIGRIS_DIR)

# Optional: uncomment this if you want tigris to remember this folder
# across future R sessions by writing to .Renviron.
# tigris::tigris_cache_dir(TIGRIS_DIR)

message("Tigris files will be saved/cached in: ", TIGRIS_DIR)

# Use 2022 TIGER/Line files
TIGRIS_YEAR <- 2022

county_cz_xwalk <- read_dta(paste0(XWALKS, "/cw_cty_czone.dta"))

cbgoodman <- read_dta(paste0(RAWDATA, "/cbgoodman/muni_incorporation_date.dta")) %>% 
  select(placefips, statefips, countyfips, yr_incorp) %>% 
  rename(
    PLACEFP  = placefips,
    STATEFP  = statefips,
    COUNTYFP = countyfips
  ) %>%
  mutate(
    PLACEFP  = str_pad(as.character(PLACEFP),  5, side = "left", pad = "0"),
    STATEFP  = str_pad(as.character(STATEFP),  2, side = "left", pad = "0"),
    COUNTYFP = str_pad(as.character(COUNTYFP), 3, side = "left", pad = "0")
  ) %>% 
  ### Louisville and Butte-Silver Bow are consolidated cities, match to central city
  mutate(PLACEFP = case_when(PLACEFP == "11390" & STATEFP == "30" ~ "11397", TRUE ~ PLACEFP),
         PLACEFP = case_when(PLACEFP == "48003" & STATEFP == "21" ~ "48000", TRUE ~ PLACEFP)) 


# Manual edits: Need to break New York City into its distinct counties

## County FIPS 005, 047, 061, 081, and 085 correspond to
## Bronx, Kings, New York, Queens, and Richmond Counties.

ny_incorp <- cbgoodman$yr_incorp[
  cbgoodman$STATEFP == "36" & cbgoodman$PLACEFP == "51000"
]

ny <- data.frame(
  PLACEFP  = rep("51000", 5), 
  STATEFP  = rep("36", 5),
  COUNTYFP = c("005", "047", "061", "081", "085"),
  yr_incorp = rep(ny_incorp, 5)
)

cbgoodman <- cbgoodman %>% 
  filter(STATEFP != "36" | PLACEFP != "51000") %>% 
  bind_rows(ny)

# ----------------------------
# Download/read national county file from tigris cache
# ----------------------------

counties_raw <- tigris::counties(
  year = TIGRIS_YEAR, # NEED 2010 COUNTIES 
  cb = TRUE,
  class = "sf"
)

counties <- counties_raw %>% 
  st_drop_geometry() %>% 
  select(ALAND, AWATER, STATEFP, COUNTYFP) %>% 
  rename(
    county_land  = ALAND,
    county_water = AWATER
  ) %>% 
  mutate(
    #STATEFP = str_pad(as.character(STATEFP), 2, side = "left", pad = "0"),
    #COUNTYFP = str_pad(as.character(COUNTYFP), 3, side = "left", pad = "0"),
    county_total = county_land + county_water,
    cty_fips = as.numeric(paste0(STATEFP, COUNTYFP))
  ) %>% 
  left_join(county_cz_xwalk, by = "cty_fips") %>% 
  mutate(czone = if_else(STATEFP == "09",20901,czone)) %>% # Spot fix for change in CT counties. Actual crosswalk doesn't matter since state has only one CZone
  filter(!is.na(czone))

# ----------------------------
# Download/read national places file from tigris cache
# ----------------------------

places_raw <- tigris::places(
  year = TIGRIS_YEAR,
  cb = TRUE,
  class = "sf"
)

places <- places_raw %>% 
  st_drop_geometry() %>% 
  select(ALAND, AWATER, STATEFP, PLACEFP) %>% 
  rename(
    place_land  = ALAND,
    place_water = AWATER
  ) %>% 
  mutate(
    STATEFP = str_pad(as.character(STATEFP), 2, side = "left", pad = "0"),
    PLACEFP = str_pad(as.character(PLACEFP), 5, side = "left", pad = "0"),
    place_total = place_land + place_water
  ) %>% 
  merge(cbgoodman, by = c("PLACEFP", "STATEFP")) %>% 
  mutate(
    COUNTYFP = str_pad(as.character(COUNTYFP), 3, side = "left", pad = "0")
  ) %>% 
  full_join(counties, by = c("COUNTYFP", "STATEFP")) %>% 
  mutate(
    frac_land  = place_land / county_land,
    frac_total = place_total / county_total
  ) %>% 
  mutate(PLACEFP = case_when(PLACEFP == "48000" & STATEFP == "21" ~ "48006", 
                                     TRUE ~ PLACEFP))


write_dta(
  places,
  path = paste0(INTDATA, "/cgoodman/cgoodman_place_county_geog.dta")
)
