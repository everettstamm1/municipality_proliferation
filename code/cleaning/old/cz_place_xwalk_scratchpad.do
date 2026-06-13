// Move CZ crosswalk from raw to xwalk folder, no modifications necessary

copy "$RAWDATA/david_dorn/cw_cty_czone/cw_cty_czone.dta" "$XWALKS/cw_cty_czone.dta", replace


use "$XWALKS/cz_place_xwalk", clear


import excel using "$RAWDATA/cog/govt_units_2021/Govt_Units_2021_Final.xlsx", describe
return list
local n_worksheet = `r(N_worksheet)'

* loop through all sheets, list data, then save
forvalues i=1/`n_worksheet' {
	import excel using "$RAWDATA/cog/govt_units_2021/Govt_Units_2021_Final.xlsx" ,sheet(`"`r(worksheet_`i')'"') firstrow clear
	keep 	CENSUS_ID_PID6	CENSUS_ID_GIDID	UNIT_NAME	UNIT_TYPE	ADDRESS1 ADDRESS2 ///
				CITY STATE ZIP ZIP4	WEB_ADDRESS	FIPS_STATE FIPS_COUNTY FIPS_PLACE ///
				COUNTY_AREA_NAME IS_ACTIVE
				
	ren CENSUS_ID_PID6 PID
	ren CENSUS_ID_GIDID GID
	ren UNIT_NAME name
	ren UNIT_TYPE subtype
	ren FIPS_STATE fips_state
	ren FIPS_COUNTY fips_county_2020
	ren FIPS_PLACE fips_place_2020
	ren COUNTY_AREA_NAME county_name
	ren IS_ACTIVE active
	
	g type = `i'
	
	tempfile sheet_`i'
	save `sheet_`i''
}
clear
forv i=1/`n_worksheet'{
	append using `sheet_`i''
}


label define type 1 "General Purpose" ///
									2 "Special District" ///
									3 "School District" ///
									4 "Dependent School District"
									
label define subtype 	1 "County" ///
											2 "Municipal" ///
											3 "Township"

replace subtype = substr(subtype,1,1)
destring subtype, replace

label values type type
label values subtype subtype

save "$INTDATA/cog/master_2021.dta", replace


import excel using "$RAWDATA/cog/govt_units_2021/Govt_Units_2021_Final.xlsx" ,sheet("General Purpose") firstrow clear

g cty_fips = FIPS_STATE + FIPS_COUNTY
destring cty_fips, replace

merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen

ren czone cz_new
//keep cz_new FIPS_STATE FIPS_PLACE
destring FIPS_STATE FIPS_PLACE, replace
ren FIPS_STATE STATEFP
ren FIPS_PLACE PLACEFP
merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk"


import excel using "$RAWDATA/cog/govt_units_2012/Govt_Units_2012_Final.xlsx" ,sheet("GeneralPurp") firstrow clear

g cty_fips = FIPS_STATE + FIPS_COUNTY
destring cty_fips, replace

merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen

ren czone cz_new
//keep cz_new FIPS_STATE FIPS_PLACE
destring FIPS_STATE FIPS_PLACE, replace
ren FIPS_STATE STATEFP
ren FIPS_PLACE PLACEFP
drop if PLACEFP == .
merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk"





use "$XWALKS/cz_place_xwalk", clear


// Incorp Split
use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear
 
destring *FP, replace


//g cty_fips = STATEFP*1000 + COUNTYFP
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen



use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear





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
drop if funcstat == "F"
//drop if (funcstat=="S" | /// "Statistical entities"
//		 funcstat=="F" | /// Fictitious entity created to fill the Census Bureau geographic hierarch
//		 funcstat=="N" | /// Nonfunctioning legal entity
//		 funcstat=="I" ) // Inactive governmental unit that has the power to provide primary special-purpose functions
		 
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
keep statefp placefp countyfp placename county state funcstat n
duplicates drop
save "$XWALKS/place_county_xwalk.dta", replace

//keep statefp placefp countyfp
ren statefp STATEFP
ren countyfp COUNTYFP 
ren placefp PLACEFP

g cty_fips = 1000*STATEFP + COUNTYFP
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
ren czone cz
keep STATEFP PLACEFP cz placename
duplicates drop


merge m:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk"




import delimited "$RAWDATA/census/census_place_fips_xwalk.txt", clear


import delimited "$RAWDATA/census/nhgis0038_csv/nhgis0038_ds172_2010_place.csv", clear
ren placea PLACEFP
ren countya COUNTYFP
ren statea STATEFP

g cty_fips = 1000*STATEFP + COUNTYFP

merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen
ren czone cz_new




// Historical Finance
clear
odbc query "City_Gov_Fin"
odbc load, table("City_Govt_Finances")

keep General_Expenditure Direct_General_Expend Total_Current_Expend Direct_Expenditure Total_Expenditure Total_IG_Expenditure Total_Prop_Sale var41 Total_IG_Revenue var28 Total_Taxes General_Revenue Total_Revenue Population Year_of_Data Name County_Code Type_Code State_Code GID_Compatible_ID ID Year4 Survey_Year Sort_Code


rename State_Code ID_state
rename Type_Code ID_type
rename County_Code ID_county
g ID_unit = substr(ID,7,9)

merge m:1 ID using "$XWALKS/cog_ID_fips_place_xwalk_02.dta", keep(1 3) nogen


g cty_fips = fips_state+fips_county_2002
destring cty_fips, replace
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
drop cty_fips

// Destringing everything
foreach var of varlist General_Expenditure Direct_General_Expend Total_Current_Expend Direct_Expenditure Total_Expenditure Total_IG_Expenditure Total_Prop_Sale var41 Total_IG_Revenue var28 Total_Taxes General_Revenue Total_Revenue Population{
	replace `var' = . if `var' == -11111
}


keep fips_state fips_place_2002 czone
ren fips_state STATEFP 
ren fips_place_2002 PLACEFP 

merge m:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk"


use "$XWALKS/cog_ID_fips_place_xwalk_02.dta", clear

ren fips_state STATEFP
ren fips_county_2002 COUNTYFP 
ren fips_place_2002 PLACEFP 

g cty_fips = STATEFP + COUNTYFP

destring cty_fips STATEFP COUNTYFP PLACEFP, replace

merge m:1 cty_fips using "$XWALKS/cw_cty_czone"
ren _merge merge1

ren czone cz_new 

merge m:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk"

import delimited "$RAWDATA/census/nhgis0025_csv\nhgis0025_csv/nhgis0025_ds258_2020_place.csv", clear

