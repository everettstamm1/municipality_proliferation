


use city perwt stateicp countyicp incwage using "$RAWDATA/census/usa_00118.dta/usa_00118.dta" if incwage > 0 & incwage <=5000, clear

ren city citycode

replace citycode = 3540 if citycode == 3521 // Lebanon, PA rename

merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset.dta",  keep(3) keepusing(citycode cz_name cz) 
ren citycode city


collapse (mean)  mean_income_1940=incwage , by(cz)

save "$INTDATA/census/incomes_1940", replace


// 2010 place level Incomes


import delimited "$RAWDATA/census/census_place_fips_xwalk.txt", clear varnames(1)
replace censusfipsname = strtrim(censusfipsname)
g state = real(substr(censusfipsname,1,2))
g census_place = real(substr(censusfipsname,3,4))
g fips_place = real(substr(censusfipsname,8,5))
g name = substr(censusfipsname,14,.)
drop censusfipsname v2

save "$XWALKS/census_place_fips_xwalk.dta", replace

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

import delimited "$RAWDATA/census/nhgis0035_csv/nhgis0035_csv/nhgis0035_ds176_20105_blck_grp.csv", clear
g cty_fips = 1000*statea + countya

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
ren  czone cz 
collapse (sum) jose001 jm5e001, by(cz)

g mean_hh_inc_cz = jose001/jm5e001
drop jose001 jm5e001

tempfile cz_hhinc
save `cz_hhinc'

import delimited "$RAWDATA/census/nhgis0035_csv/nhgis0035_csv/nhgis0035_ds176_20105_blck_grp.csv", clear
g countycode = 1000*statea + countya
g tract = tracta / 100
g blockgroup = blkgrpa

merge 1:m countycode tract blockgroup using "$XWALKS/blockgroup_place_xwalk", keep(3) nogen


collapse (sum) jose001 jm5e001 [aw = bgtoplacefpallocationfactor], by(placecode statecode)
g mean_hh_inc_place = jose001/jm5e001

drop jose001 jm5e001

ren placecode PLACEFP
ren statecode STATEFP


merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(3) nogen

merge m:1 cz using `cz_hhinc', keep(1 3) nogen


save "$INTDATA/census/2010_hh_incomes", replace

// 1970 Incomes 



import delimited "$RAWDATA/census/nhgis0036_csv/nhgis0036_csv/nhgis0036_ds99_1970_county.csv", clear

merge 1:1 gisjoin using  "$RAWDATA/dcourt//replication_AER/data/crosswalks//county1940_crosswalks", keepusing(cz) keep(3) nogen
egen famcount = rowtotal(c3t*)
collapse (sum) famcount c1k001, by(cz)
g agg_fam_inc_cz1970 = c1k001/famcount
keep cz agg_fam_inc_cz1970
tempfile cz_inc
save `cz_inc'


import delimited "$RAWDATA/census/nhgis0036_csv/nhgis0036_csv/nhgis0036_ds99_1970_place.csv", clear

egen famcount = rowtotal(c3t*)
keep statea placea c1k001 famcount
ren statea state
ren placea census_place

merge 1:1 state census_place using"$XWALKS/census_place_fips_xwalk.dta", keep(3) nogen

collapse (sum) c1k001 famcount, by(state fips_place)
rename c1k001 agg_fam_inc_place1970 
ren state STATEFP
ren fips_place PLACEFP

merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(3) nogen

merge m:1 cz using `cz_inc', keep(3) nogen

save "$INTDATA/census/1970_hh_incomes_hv", replace
