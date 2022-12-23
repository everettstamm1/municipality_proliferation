// Cleans settlement_infobox2, crosswalks it to commuting zones, and creates the n_muni_cz variable

// Started as an attempt to clean settlement_infobox2 but I found a whole bunch more data to go through, commented out at bottom for later use

clear all



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

// Municipal incorporation data

import delimited using "$RAWDATA/wiki/settlement_infobox2.tsv", clear

// Cleaning FIPS codes
replace fips = strtrim(fips)
// Spot fixes
replace fips = "55-53750" if fips == "55â53750"
replace fips = "51061" if fips=="061"
replace fips = "20-08425" if fips =="20-8425"
replace fips = "40-28700" if fips =="40-2870"
replace fips = "23-65725" if wid==259370
replace fips = "02-17740" if wid==105601
replace fips = "53-51515" if wid==138264
replace fips = "06-73290" if wid==107687
replace fips = "26-14300" if wid==117429
replace fips = "48-26232" if wid==151167

split fips, gen(fips) parse(", ")
drop fips
reshape long fips, i(wid incorporated_date qid page_title unincorporated incorp_year_text text) j(n) 
drop if fips==""

// Correct format is SS-PPPPP where SS is the two digit state code and PPPPP is the five digit place code
g fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")
// Dropping leading zeros
replace fips = substr(fips,2,.) if substr(fips,1,1)=="0" & fips_form!=1 & strlen(fips)==9
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")
// Replacing / with -
replace fips = subinstr(fips,"/","-",1) if regexm(fips,"^[0-9][0-9][/][0-9][0-9][0-9][0-9][0-9]$")
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")

// Form for townships seems to be SS-TTT-PPPPP or SS-TT-PPPPP or SS-PPPPP-TTT
g township_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$") 
// Dropping leading zeros
replace fips = substr(fips,2,.) if substr(fips,1,1)=="0" & township_form!=1 & strlen(fips) == 13 
replace township_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")
// Dropping TTT
replace fips = substr(fips,1,2)+"-"+substr(fips,8,5) if township_form==1
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")
sort fips_form

// Fixing SS-TT-PPPPP
g two_township_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$") 
replace fips = substr(fips,1,2)+"-"+substr(fips,7,5) if two_township_form==1
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")

// Fixing SS-PPPPP-TTT
g tail_township_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9][-][0-9][0-9][0-9]$")
// Dropping leading zeros
replace fips = substr(fips,1,8) if tail_township_form==1
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")

// Some codes are 5 digits, either they're in the proper 5 digit county format or are place codes missing their state code prefix
g state = substr(page_title,strrpos(page_title,",_")+2,.) if strrpos(page_title,",_") >0
replace state = subinstr(state,"_"," ",.)

// Some spot fixes
replace state="New York" if state=="New York (town)"
replace state="New York" if state=="Queens"
replace state="Alaska" if state=="Wrangell"
replace state="Alabama" if state=="Vestavia Hills"
replace state="Alaska" if state=="Juneau"
// Freedom seems to legitimately be in both idaho and wyoming, randomly choosing one
g rand = runiform()
replace state="Idaho" if state=="Idaho and Wyoming" & rand>=0.5
replace state="Wyoming" if state=="Idaho and Wyoming" & rand<0.5
drop rand
replace state="Connecticut" if state=="Bridgeport"
drop if state=="Bolivia" // Not sure why this is here
replace state="Alabama" if state=="Boaz"
replace state="Washington" if state=="Bellevue"
replace state="Kansas" if state=="Kansas and Nebraska" & n==1
replace state="Nebraska" if state=="Kansas and Nebraska" & n==2
replace state="Texas" if state=="Houston"

preserve
	import delimited using "$RAWDATA/census/state.txt",clear
	keep state state_name
	rename state statefp
	rename state_name state
	tempfile statefps
	save `statefps'
restore

merge m:1 state using `statefps', keep(1 3) nogen

g fips_state = real(substr(fips,1,2))

// These are explicitly counties
g county_form1 = fips_state==statefp & regexm(fips,"^[0-9][0-9][0-9][0-9][0-9]$") 
g county_form2 = fips_state==statefp & regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9]$") 
replace fips = substr(fips,1,2)+"-"+substr(fips,4,3) if county_form2==1
g county_form = county_form1 | county_form2


g missdash_form = regexm(fips,"^[0-9][0-9][0-9][0-9][0-9][0-9][0-9]$") & fips_state==statefp
replace fips = substr(fips,1,2)+"-"+substr(fips,3,5) if missdash_form==1
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")


g missstate = regexm(fips,"^[0-9][0-9][0-9][0-9][0-9]$") & fips_state!=statefp
tostring statefp, gen(statestr)
replace statestr = "0"+statestr if statefp<10
replace fips = statestr+"-"+fips if missstate==1
replace fips_form = regexm(fips,"^[0-9][0-9][-][0-9][0-9][0-9][0-9][0-9]$")
keep fips fips_form county_form incorp_year_text incorporated_date unincorporated text page_title wid qid 
duplicates drop

keep if fips_form==1
g statefp = real(substr(fips,1,2))
g placefp = real(substr(fips,4,5))
g n = 1

// Join on counties
joinby statefp placefp using "$XWALKS/place_county_xwalk"

// Clean before CZ merge
tostring countyfp, gen(cty_fips)
tostring statefp, gen(st_fips)
replace cty_fips = "00"+cty_fips if countyfp<10
replace cty_fips = "0"+cty_fips if countyfp>=10 & countyfp<100
replace cty_fips = st_fips+cty_fips
destring cty_fips, replace

// Gotta downcode some county codes back to the 90s
replace cty_fips = 2290 if cty_fips == 2068 // Yukon-Koyukuk Census Area
replace cty_fips = 2201 if cty_fips == 2198 // Prince of Wales-Outer Ketchikan Census Area
replace cty_fips = 2280 if cty_fips == 2195 // Wrangell-Petersburg Census Area
replace cty_fips = 2231 if cty_fips == 2105 // Skagway-Hoonah-Angoon Census Area
replace cty_fips = 2231 if cty_fips == 2230 // Skagway-Hoonah-Angoon Census Area
replace cty_fips = 12025 if cty_fips == 12086 // Miami-Dade County

// CZ Merge
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) assert(2 3) nogen

// Drop vars from county merge - keeping only commuting zones and info from settlement_infobox2
keep czone wid qid fips page_title unincorporated incorp_year_text incorporated_date text
duplicates drop 

g incorp_year = incorp_year_text
replace incorp_year = real(regexs(0)) if(regexm(incorporated_date,"[0-9][0-9][0-9][0-9]"))


g n = incorp_year>=1940 & incorp_year<=1970
g n1940 = incorp_year<1940
collapse (sum) n n1940, by(czone)
rename n n_muni_cz
rename n1940 n_muni_cz1940
rename czone cz
label var n_muni_cz "n_muni_cz"
label var n_muni_cz "n_muni_cz1940"

save "$INTDATA/n_muni_czone.dta", replace



//merge 1:1 cz using "$INTDATA/n_muni_czone.dta",keep(1 2)
//rename _merge muni_merge
//merge 1:1 cz using "$DCOURT/data/crosswalks/cz_names.dta"
//rename _merge name_merge

//order cz cz_name *_merge
//sort cz
//local inc_level "Lower Inc"	

/*
use "$DCOURT/data/GM_cz_final_dataset.dta", clear
merge 1:1 cz using "$INTDATA/n_muni_czone.dta"
rename czname czname1
keep cz n_muni_cz stateabbrv state_id _merge
rename _merge data_merge
merge 1:1 cz using "$DCOURT/data/crosswalks/cz_state_region_crosswalk.dta", keep(3) nogen
rename cz_name czname2
order data_merge cz czname* 
sort cz

*/

	
// other source
/*
import delimited using "$RAWDATA/gnis/NationalFedCodes_20210825.txt",clear
save "$RAWDATA/temp", replace

drop if census_code==""
keep feature_name feature_class census_code census_class_code state_numeric county_numeric
duplicates drop

keep if regexm(census_class_code,"^C[0-9]$") | /// Incorporated Places
				regexm(census_class_code,"^P[0-9]$") | /// Populated - Incorporated Place
				regexm(census_class_code,"^T[0-9]$") | /// Active minor civil divisions
				regexm(census_class_code,"^U[0-5]$")  // Populated (community) place

tempfile county_xwalk
save `county_xwalk'
import delimited using "$RAWDATA/gnis/NationalFile_20210825.txt",clear
keep if feature_class == "Civil" | ///
				feature_class == "Locale" | ///
				feature_class == "Populated Place" | ///
				feature_class == "Census"

// Seems like some observations from alaska got duplicated in arizona
duplicates tag feature_id, gen(tag)
drop if tag>0 & state_alpha=="AZ" & state_numeric==2
tempfile all_features
save `all_features'
				
import delimited using "$RAWDATA/gnis/Feature_Description_History_20210825.txt",clear bindquote(nobind)

merge 1:1 feature_id using `all_features', keep(3) nogen
import delimited using "$RAWDATA/gnis/HIST_FEATURES_20210825.txt",clear
keep if feature_class == "Civil" | ///
				feature_class == "Locale" | ///
				feature_class == "Populated Place" 
				
tempfile hist_features
save `hist_features'


import delimited using "$RAWDATA/gnis/POP_PLACES_20210825.txt",clear
tempfile pop_place
save `pop_place'


import delimited using "$RAWDATA/gnis/NationalFedCodes_20210825.txt",clear
tempfile fed_codes
save `fed_codes'

import delimited using "$RAWDATA/gnis/Feature_Description_History_20210825.txt",clear bindquote(nobind)


merge 1:1 feature_id using `hist_features', keep(3) nogen
g x = regexm(history, "ncorporated")
g y = regexm(description, "ncorporated")
keep if x==1 | y==1