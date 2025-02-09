use "$XWALKS/consistent_1990", clear
keep if year == 1940
keep weight nhgisst_1990 nhgiscty_1990 icpsrst icpsrcty


tempfile consistent_xwalk
save `consistent_xwalk'

use city valueh perwt stateicp countyicp incwage educd higrade using "$RAWDATA/census/usa_00064.dta", clear

ren city citycode
// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
merge m:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta",  keep(1 3) keepusing(citycode)
ren citycode city

g perwtc = perwt if _merge == 3
replace incwage = . if incwage > 5001
replace valueh = . if valueh >= 9999998 | valueh == 0
g incwagec = incwage if _merge==3
g incwage_pos = incwage if !mi(incwage) & incwage != 0
g incwagec_pos = incwagec if !mi(incwagec)

replace higrade = . if higrade == 0 | higrade == 99
replace higrade = higrade - 3
replace higrade = 0 if higrade < 0
replace higrade = 16 if higrade > 16

g hsgrad = educd > 61
g unigrad = educd > 100
drop educd 

g hsgradc = hsgrad if _merge == 3
g higradec = higrade if _merge == 3
g unigradc = unigrad if _merge == 3
g valuehc = valueh if _merge == 3
drop _merge

ren stateicp icpsrst
ren countyicp icpsrcty

collapse (sum) perwt perwtc (mean) hsgradc higradec unigradc valueh valuehc incwage incwagec incwage_pos incwagec_pos hsgrad unigrad higrade, by(icpsrst icpsrcty)

merge 1:m icpsrst icpsrcty using `consistent_xwalk', keep(3) nogen

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
g weightc = weight * perwtc

replace weight = weight * perwt
preserve
	collapse (mean) hsgrad unigrad higrade valueh mean_income_1940=incwage  mean_pos_income_1940=incwage_pos   [w=weight], by(czone)

	save "$INTDATA/census/incomes_and_education_1940", replace
restore


collapse (mean) hsgradc unigradc higradec valuehc mean_urban_income_1940 = incwagec mean_pos_urban_income_1940 = incwagec_pos [w=weightc], by(czone)

save "$INTDATA/census/urban_incomes_and_education_1940", replace


// 2010 Incomes

import delimited "$RAWDATA/census/nhgis0033_csv/nhgis0033_csv/nhgis0033_ds172_2010_place.csv", clear

g place_oo_rate = (iff002 + iff003) / iff001

ren statea STATEFP
ren placea PLACEFP

keep STATEFP PLACEFP place_oo_rate

merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(3) nogen

tempfile place_oo_rate
save `place_oo_rate'
/*
import delimited "$RAWDATA/census/nhgis0033_csv/nhgis0033_csv/nhgis0033_ds175_2010_place.csv", clear
g med_hh_inc_place = i25e001
g med_hv_place = jfje001


ren statea STATEFP
ren placea PLACEFP

keep STATEFP PLACEFP med_hh_inc_place med_hv_place

merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(3) nogen

tempfile place_hhinc_hv
save `place_hhinc_hv'
*/

foreach f in mo_il in_ne nv_sc sd_wy{
	import delimited "$RAWDATA/census/geocorr/geocorr2014_`f'.csv", clear varnames(2)
	tempfile `f'
	save ``f''
}
clear
foreach f in mo_il in_ne nv_sc sd_wy{
	append using ``f''
}

save "$XWALKS/blockgroup_place_xwalk.dta", replace

// Places
import delimited "$RAWDATA/census/nhgis0035_csv/nhgis0035_csv/nhgis0035_ds176_20105_blck_grp.csv", clear
g countycode = 1000*statea + countya
g tract = tracta / 100
g blockgroup = blkgrpa

merge 1:m countycode tract blockgroup using "$XWALKS/blockgroup_place_xwalk", keep(3) nogen
//drop if placecode ==  99999 
// Aggregate -> mean
replace jose001 = jose001/jm5e001
replace jpee001 = jpee001/jm5e001

collapse (mean) joie001 jtie001 jpee001 jose001 [aw = bgtoplacefpallocationfactor], by(placecode statecode)

ren joie001 med_hh_inc_place
ren jtie001 med_hv_place
ren jpee001 mean_earnings_place
ren jose001 mean_hh_inc_place

ren placecode PLACEFP
ren statecode STATEFP

tempfile place_hhinc_hv
save `place_hhinc_hv'

import delimited "$RAWDATA/census/nhgis0035_csv/nhgis0035_csv/nhgis0035_ds176_20105_blck_grp.csv", clear
g cty_fips = 1000*statea + countya

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
ren  czone cz 
collapse (sum) jpee001 jose001 jm5e001, by(cz)

g mean_earnings_cz = jpee001/jm5e001
g mean_hh_inc_cz = jose001/jm5e001

merge 1:m cz using `place_oo_rate', keep(3) nogen
merge 1:1 PLACEFP STATEFP using `place_hhinc_hv', keep(1 3) nogen

save "$INTDATA/census/2010_hh_incomes", replace

// 1970 Incomes and home values

use "$XWALKS/consistent_1990", clear
keep if year == 1970
g statea = nhgisst/10
g countya = nhgiscty/10
keep weight nhgisst_1990 nhgiscty_1990 countya statea


tempfile consistent_xwalk
save `consistent_xwalk'

import delimited "$RAWDATA/census/nhgis0036_csv/nhgis0036_csv/nhgis0036_ds95_1970_county.csv", clear
egen housecount = rowtotal(cg7*)

merge 1:m statea countya using `consistent_xwalk', keep(3) nogen

collapse (sum) housecount cet001 [aw = weight], by(nhgisst_1990 nhgiscty_1990)
g cty_fips = nhgisst_1990*100+nhgiscty_1990/10
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren czone cz
collapse (sum) housecount cet001 , by(cz)
g agg_house_value_cz1970 = cet001/housecount
keep cz agg_house_value_cz1970

tempfile cz_hv
save `cz_hv'

import delimited "$RAWDATA/census/nhgis0036_csv/nhgis0036_csv/nhgis0036_ds99_1970_county.csv", clear
egen famcount = rowtotal(c3t*)

merge 1:m statea countya using `consistent_xwalk', keep(3) nogen

collapse (sum) famcount c1k001 [aw = weight], by(nhgisst_1990 nhgiscty_1990)
g cty_fips = nhgisst_1990*100+nhgiscty_1990/10
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren czone cz
collapse (sum) famcount c1k001 , by(cz)
g agg_fam_inc_cz1970 = c1k001/famcount
keep cz agg_fam_inc_cz1970
tempfile cz_inc
save `cz_inc'

import delimited "$RAWDATA/census/census_place_fips_xwalk.txt", clear varnames(1)
replace censusfipsname = strtrim(censusfipsname)
g state = real(substr(censusfipsname,1,2))
g census_place = real(substr(censusfipsname,3,4))
g fips_place = real(substr(censusfipsname,8,5))
g name = substr(censusfipsname,14,.)
drop censusfipsname v2

save "$XWALKS/census_place_fips_xwalk.dta", replace

import delimited "$RAWDATA/census/nhgis0036_csv/nhgis0036_csv/nhgis0036_ds95_1970_place.csv", clear

egen housecount = rowtotal(cg7*)
keep statea placea cet001 housecount
ren statea state
ren placea census_place

merge 1:1 state census_place using"$XWALKS/census_place_fips_xwalk.dta", keep(3) nogen

collapse (sum) cet001 housecount, by(state fips_place)
g agg_house_value_place1970 = cet001/housecount
drop cet001 housecount
ren state STATEFP
ren fips_place PLACEFP

tempfile place_hv
save `place_hv'


import delimited "$RAWDATA/census/nhgis0036_csv/nhgis0036_csv/nhgis0036_ds99_1970_place.csv", clear

egen famcount = rowtotal(c3t*)
keep statea placea c1k001 famcount
ren statea state
ren placea census_place

merge 1:1 state census_place using"$XWALKS/census_place_fips_xwalk.dta", keep(3) nogen

collapse (sum) c1k001 famcount, by(state fips_place)
g agg_fam_inc_place1970 = c1k001/famcount
drop c1k001 famcount
ren state STATEFP
ren fips_place PLACEFP


merge 1:1 STATEFP PLACEFP using `place_hv', nogen


merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(3) nogen

merge m:1 cz using `cz_inc', keep(3) nogen
merge m:1 cz using `cz_hv', keep(3) nogen

save "$INTDATA/census/1970_hh_incomes_hv", replace
