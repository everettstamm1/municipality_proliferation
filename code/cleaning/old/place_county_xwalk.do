

import delimited using "$RAWDATA/census/national_county.txt",clear
drop v1
rename v2 statefp
rename v3 countyfp
rename v4 county
drop v5
tempfile counties
save `counties'

import delimited using "$RAWDATA/census/national_places.txt",clear
drop if placefp==0

//drop if type == "County Subdivision"
// National places have spanish accents, national county does not.
replace county = subinstr(county, "Á", "A", .)
replace county = subinstr(county, "É", "E", .)
replace county = subinstr(county, "Í", "I", .)
replace county = subinstr(county, "Ó", "O", .)
replace county = subinstr(county, "Ú", "U", .)
replace county = subinstr(county, "Ü ", "U", .)
replace county = subinstr(county, "Ñ", "N", .)
replace county = subinstr(county, "á", "a", .)
replace county = subinstr(county, "é", "e", .)
replace county = subinstr(county, "í", "i", .)
replace county = subinstr(county, "ó", "o", .)
replace county = subinstr(county, "ú", "u", .)
replace county = subinstr(county, "ü", "u", .)
replace county = subinstr(county, "ñ", "n", .)
replace county = subinstr(county, "ü", "u", .)

// Some obs are in multiple counties, reshaping to long
split county, gen(county) parse(", ")
drop county
reshape long county, i(statefp placefp placename type funcstat state) j(n) string
drop if county==""

merge m:1 statefp county using `counties', keep(3) assert(2 3) nogen
keep statefp placefp countyfp placename county state
duplicates drop

save "$XWALKS/place_county_xwalk.dta", replace


// Build cz-place xwalk for relevant places
use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear
destring statefips countyfips placefips, replace
drop if statefips == 02 | statefips==15
g cty_fips = 1000*statefips+countyfips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
ren statefips STATEFP
ren placefips PLACEFP
ren czone cz
keep cz STATEFP PLACEFP
save "$XWALKS/cz_place_xwalk", replace



use  "$XWALKS/place_county_xwalk.dta", clear
g cty_fips = 1000*statefp + countyfp 

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
sort statefp placefp countyfp 

ren statefp STATEFP
ren placefp PLACEFP 


keep STATEFP PLACEFP placename cz countyfp 
duplicates drop
merge m:1 STATEFP PLACEFP using "F:/municipality_proliferation/data/xwalks/cz_place_xwalk.dta", keep(2 3) 
keep STATEFP PLACEFP placename cz czone _merge countyfp
duplicates drop
g x= cz == czone
tab x
ren _merge m0


merge m:1 cz using "$INTDATA/dcourt/original_130_czs"
ren _merge m_old
ren cz_name cz_name_old
ren cz cz_old
ren czone cz

merge m:1 cz using "$INTDATA/dcourt/original_130_czs"
ren _merge m_new
ren cz_name cz_name_new
ren cz cz_new

g both = m_new


