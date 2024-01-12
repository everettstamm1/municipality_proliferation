
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
    } else{
      stop(paste0("could not install ", pkg))
    }
  }
}

# Get paths
paths <- read.csv("../paths.csv")
RAWDATA <- paths[paths$global == "RAWDATA",2]
INTDATA <- paths[paths$global == "INTDATA",2]
XWALKS <- paths[paths$global == "XWALKS",2]

#### Geographies ----
county_cz_xwalk <- read_dta(paste0(XWALKS,"/cw_cty_czone.dta"))

counties <- counties()  %>% 
  select(ALAND, AWATER, STATEFP, COUNTYFP, geometry) %>% 
  rename(county_land = ALAND, county_water = AWATER) %>% 
  mutate(county_total = county_land+county_water,
         cty_fips = as.numeric(paste0(STATEFP,COUNTYFP))) %>% 
  merge(county_cz_xwalk, by="cty_fips") 

crs <- st_crs(counties)


#### Ports ----


ports <- read_sf(paste0(RAWDATA,"/covariates/ports/ports_x010g.shp")) %>% 
  st_set_crs(crs) %>% 
  mutate(has_port = 1) 

county_ports <- counties %>% 
  st_intersects(ports) %>% 
  data.frame() %>% 
  rename(cty_row = row.id) %>% 
  select(cty_row) %>% 
  mutate(has_port = 1)



#### Railroads ----
railroads <- read_sf(paste0(RAWDATA,"/covariates/historical_railroads/Historical_Railroads___Vanderbilt.shp")) %>%
  st_transform(crs) %>% 
  filter(InOpBy <=1940)

# Writing this function because my computer crashes if I try the
# intersection all at once, plus I want to keep tabs on the 
# progress with the print statement.

county_km <- function(fips){
  print(paste0("Starting FIPS: ",fips))
  county <- counties %>% 
    filter(cty_fips == fips) 
  int <- st_intersection(railroads, county) %>% 
    st_length() %>% 
    sum()
  return(int)
  
}

km_railroads_1940 <- aggregate(counties$cty_fips,list(counties$cty_fips),county_km) %>% 
  rename(cty_fips = Group.1,
         km_railroad = x)


#### Network costs ----
cost_id_county <-  read_excel(paste0(RAWDATA,"/covariates/RR_NetworkDatabase_DH_Oct2015/Data/Transportation_Costs_AllDecades/Cost_ID_county.xlsx")) %>% 
  select(`gis id`, ICPSRFIP) %>% 
  rename(cty_fips = ICPSRFIP, gisid= `gis id`)

cost_matrix <- read_dta(paste0(RAWDATA,"/covariates/RR_NetworkDatabase_DH_Oct2015/Data/Transportation_Costs_AllDecades/NSFtranspCost.dta")) %>%
  merge(cost_id_county, by.x = 'gisid_origin', by.y = 'gisid', all = T) %>%
  rename(cty_fips_origin = cty_fips) %>% 
  merge(county_cz_xwalk, by.x = 'cty_fips_origin', by.y = 'cty_fips', all.x = T) %>% 
  rename(cz_origin = czone) %>% 
  merge(cost_id_county, by.x = 'gisid_destination', by.y = 'gisid', all = T) %>%
  rename(cty_fips_destination = cty_fips) %>% 
  merge(county_cz_xwalk, by.x = 'cty_fips_destination', by.y = 'cty_fips', all.x = T) %>%
  rename(cz_destination = czone) %>% 
  filter(cz_origin != cz_destination) %>%  # Not including within cz costs in average
  group_by(cz_origin) %>% 
  summarise(transpo_cost_1920 = mean(cost1920))

#### Coastal Counties ----
coastline_counties <- read_excel(paste0(RAWDATA,"/covariates/coastline-counties-list.xlsx"), skip = 3) %>% 
  mutate(cty_fips = as.numeric(`STATE/\r\nCOUNTY\r\nFIPS`)) %>% 
  select(cty_fips) %>% 
  mutate(coastal = 1)

### Climate ----
headers <- c("JAN","FEB","MAR","APR","MAY","JUN","JUL","AUG","SEP","OCT","NOV","DEC","cty_fips","year")

precip <- read.table(paste0(RAWDATA,"/covariates/climate/ncei.noaa.gov_data_nclimdiv-monthly_access_climdiv-pcpncy-v1.0.0-20230606.txt")) %>% 
  mutate(cty_fips = if_else(nchar(V1)==11,str_sub(V1,1,5),str_sub(V1,1,4)), 
         year = if_else(nchar(V1)==11,str_sub(V1,8,11),str_sub(V1,7,10))) %>% 
  select(-c(V1)) %>% 
  filter(year==1940)

max_temp <- read.table(paste0(RAWDATA,"/covariates/climate/ncei.noaa.gov_data_nclimdiv-monthly_access_climdiv-tmaxcy-v1.0.0-20230606.txt")) %>% 
  mutate(cty_fips = if_else(nchar(V1)==11,str_sub(V1,1,5),str_sub(V1,1,4)), 
         year = if_else(nchar(V1)==11,str_sub(V1,8,11),str_sub(V1,7,10))) %>% 
  select(-c(V1)) %>% 
  filter(year==1940)

min_temp <- read.table(paste0(RAWDATA,"/covariates/climate/ncei.noaa.gov_data_nclimdiv-monthly_access_climdiv-tmincy-v1.0.0-20230606.txt")) %>% 
  mutate(cty_fips = if_else(nchar(V1)==11,str_sub(V1,1,5),str_sub(V1,1,4)), 
         year = if_else(nchar(V1)==11,str_sub(V1,8,11),str_sub(V1,7,10))) %>% 
  select(-c(V1) )%>% 
  filter(year==1940)

avg_temp <- read.table(paste0(RAWDATA,"/covariates/climate/ncei.noaa.gov_data_nclimdiv-monthly_access_climdiv-tmpccy-v1.0.0-20230606.txt")) %>% 
  mutate(cty_fips = if_else(nchar(V1)==11,str_sub(V1,1,5),str_sub(V1,1,4)), 
         year = if_else(nchar(V1)==11,str_sub(V1,8,11),str_sub(V1,7,10))) %>% 
  select(-c(V1)) %>% 
  filter(year==1940)

colnames(precip) <- headers
colnames(max_temp) <- headers
colnames(min_temp) <- headers
colnames(avg_temp) <- headers

# Adjust for number of days in months before averaging (1940 was a leap year)
ndays <- c(31,29,31,30,31,30,31,31,30,31,30,31)
precip[1:12] <- mapply(`*`,precip[1:12],ndays)
avg_temp[1:12] <- mapply(`*`,avg_temp[1:12],ndays)

precip <- precip %>% 
  mutate(avg_precip = rowSums(.[1:12])/366) %>% 
  select(cty_fips, avg_precip)

avg_temp <- avg_temp %>% 
  mutate(avg_temp = rowSums(.[1:12])/366) %>% 
  select(cty_fips, avg_temp)

max_temp$max_temp <- apply(max_temp[1:12],1,function(x) max(x))
max_temp <-  max_temp %>% 
  select(cty_fips, max_temp)

min_temp$min_temp <- apply(min_temp[1:12],1,function(x) min(x))
min_temp <-  min_temp %>% 
  select(cty_fips, min_temp)

#### Saiz housing elasticity ----
# pklist <- c("dtplyr", "curl", "foreign")
# library(dtplyr)
# library(curl)
# library(foreign)
# source("https://raw.githubusercontent.com/fgeerolf/R/master/load-packages.R")
# 
# url.Saiz2010 <- "http://web.archive.org/web/20100619052721/http://real.wharton.upenn.edu/~saiz/"
# filename.zip <- "SUPPLYDATA.zip"
# filename.dta <- "HOUSING_SUPPLY.dta"
# 
# curl_download(paste(url.Saiz2010, filename.zip, sep = ""), destfile = filename.zip, quiet = FALSE)
# unzip(filename.zip)
# housing.supply <- read.dta(filename.dta)
# unlink(filename.dta)
# unlink(filename.zip)
# rm(filename.dta, filename.zip, url.Saiz2010)

#### Natural Resources ----
oil_nat_gas <- read.csv(paste0(RAWDATA,"/covariates/Oil__and__Natural__Gas__Wells.csv")) %>% 
  mutate(year = as.numeric(substr(COMPDATE,1,4)),
         n = 1,
         cty_fips = as.numeric(COUNTYFIPS)) %>% 
  filter(year<=1940) %>% 
  group_by(cty_fips) %>% 
  summarise(n_wells = sum(n))

#### Combining data ----
output <- counties %>% 
  # Ports
  mutate(cty_row = row_number()) %>% 
  merge(county_ports, by = "cty_row", all.x = T) %>% 
  mutate(has_port = if_else(is.na(has_port),0,has_port)) %>% 
  # Coastal counties
  merge(coastline_counties, by = "cty_fips", all.x=T) %>% 
  mutate(coastal = if_else(is.na(coastal),0,coastal)) %>% 
  # Climate
  merge(precip, by = 'cty_fips', all.x = T) %>% 
  merge(avg_temp, by = 'cty_fips', all.x = T) %>% 
  merge(max_temp, by = 'cty_fips', all.x = T) %>% 
  merge(min_temp, by = 'cty_fips', all.x = T) %>% 
  # Oil
  merge(oil_nat_gas, by = 'cty_fips', all.x = T) %>% 
  # Railroad lines
  merge(km_railroads_1940, by = 'cty_fips', all.x = T) %>% 
  group_by(czone) %>% 
  summarize(n_wells = sum(n_wells, na.rm = T),
            max_temp = max(max_temp, na.rm = T),
            min_temp = min(min_temp, na.rm = T),
            avg_temp = mean(avg_temp, na.rm = T),
            avg_precip = sum(avg_precip, na.rm = T),
            has_port = max(has_port, na.rm = T),
            coastal = max(coastal, na.rm = T),
            m_rr = sum(km_railroad, na.rm = T),
            m_rr_sqm_total = sum(km_railroad, na.rm = T)/(sum(county_total,na.rm = T)),
            m_rr_sqm_land = sum(km_railroad, na.rm = T)/(sum(county_land,na.rm = T))) %>%
  merge(cost_matrix,by.x = 'czone', by.y = 'cz_origin', all.x=T) %>% 
  st_drop_geometry() %>% 
  rename(cz = czone)


write_dta(output,path=paste0(INTDATA,"/covariates/covariates.dta"))


