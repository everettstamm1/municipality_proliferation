use metarea race bpl perwt year stateicp countyicp using "$RAWDATA/dcourt/clean_IPUMS_1940_extract_to_construct_migration_weights.dta", clear

g southern = bpl == 1 | ///
			bpl == 5 | ///
			bpl == 12 | ///
			bpl == 13 | ///
			bpl == 21 | ///
			bpl == 22 | ///
			bpl == 28 | ///
			bpl == 37 | ///
			bpl == 40 | ///
			bpl == 45 | ///
			bpl == 47 | ///
			bpl == 48 | ///
			bpl == 51 | ///
			bpl == 54

keep if southern == 1

merge m:1 city using "$INTDATA/dcourt/GM_city_final_dataset.dta", keep(1 3) keepusing(city cz)


g totpop = 1

g urban = _merge == 3

g black = race == 2
g white = race == 1

g southern_urban = southern & urban

g southern_black = southern & black 
g southern_white = southern & white

g black_urban = black & urban
g white_urban = white & urban

g southern_black_urban = southern & black & urban
g southern_white_urban = southern & white & urban

collapse (sum)  southern southern_black southern_white southern_urban southern_black_urban southern_white_urban, by(cz)

save "$INTDATA/census/southernpops_1940", replace




// NHGIS ATTEMPT

import delimited "$RAWDATA/census/nhgis0042_csv/nhgis0042_csv/nhgis0042_ds99_1970_county.csv", clear

g southern = c14004
g southern_white = c14aa004
g southern_black =  c14ab004

keep year statea countya southern southern_white southern_black

replace statea = statea*10
replace countya = countya*10
ren statea nhgisst
ren countya nhgiscty

merge 1:m year nhgisst nhgiscty using "$XWALKS/consistent_1940_1970", keep(3) nogen
replace southern = southern*weight
replace southern_white = southern_white*weight
replace southern_black = southern_black*weight


collapse (sum) southern southern_white southern_black, by(year nhgisst_1990 nhgiscty_1990)

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
ren cty_fips fips
ren czone cz

collapse (sum) southern southern_black southern_white, by(cz)

tempfile southern
save `southern'


// Southern urban pop (by incorporated place)

// This crosswalking is painful
import delimited using "$RAWDATA/census/nhgis0041_csv/nhgis0041_csv/nhgis0041_ts_nominal_place.csv", clear
keep gjoin1970 gjoin2000 place
drop if gjoin1970 == "" 
duplicates drop
tempfile xwalk19702000
save `xwalk19702000'

import delimited "$RAWDATA/census/nhgis0042_csv/nhgis0042_csv/nhgis0042_ds99_1970_place.csv", clear
ren gisjoin gjoin1970

merge 1:1 gjoin1970 using `xwalk19702000', keep(1 3) nogen
rename gjoin2000 gisjoin
drop if gisjoin == "" &  gjoin1970 != "G1801145"

merge 1:1 gisjoin using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(city) keep(1 3) nogen
ren city city_name

replace city_name = "Belleville, NJ" if gjoin1970 == "G3401155"
replace city_name = "Brookdale, NJ" if gjoin1970 == "G3401235"
replace city_name = "Indianapolis, IN" if gjoin1970 == "G1801145"
replace city_name = "Upper Montclair, NJ" if gjoin1970 == "G3402780"
drop if city_name == ""
merge 1:1 city_name using "$INTDATA/dcourt/dest_city_sample_296", keep(3) nogen keepusing(city_name cz)

g southern_urban = c14004
g southern_white_urban = c14aa004
g southern_black_urban =  c14ab004


keep southern_urban southern_white_urban southern_black_urban cz

collapse (sum) southern_urban southern_black_urban southern_white_urban, by(cz)

merge 1:1 cz using `southern', keep(3) nogen
save "$INTDATA/census/southernpops_1970.dta", replace