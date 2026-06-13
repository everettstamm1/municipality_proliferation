// First for 1900-1950 from full count
foreach d in 108 109 110 111 116 118{
	
	use perwt stateicp countyicp race city occscore year ind1950 using "$RAWDATA/census/usa_00`d'.dta/usa_00`d'.dta", clear
 	ren city citycode

	replace citycode = 3540 if citycode == 3521 // Lebanon, PA rename

	merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset.dta",  keep(1 3) keepusing(citycode)
ren citycode city
	
	g popc = perwt if _merge == 3
	g bpop = perwt if race == 2
	replace occscore = . if occscore == 0
	g bpopc = bpop if _merge == 3
	g occscorec = occscore if _merge == 3
	ren perwt pop
	
	g lforce = cond(!mi(ind1950),pop,0)
	g mfg = (ind1950 >= 300 & ind1950 < 500) * lforce
	
	merge m:1 stateicp countyicp using "$RAWDATA/dcourt/replication_AER/data/crosswalks/county1940_crosswalks", keep(3) nogen keepusing(cz)
	
	
	collapse (sum) lforce mfg pop popc bpop bpopc (mean) occscore occscorec, by(cz year)
	g mfg_lfshare = mfg / lforce
	drop mfg lforce
	save "$INTDATA/census/cz_pop_occscore_mfg_`d'", replace

}

clear 
foreach d in 108 109 110 111 116 118{
	append using "$INTDATA/census/cz_pop_occscore_mfg_`d'"
}

save "$INTDATA/census/cz_pop_occscore_mfg.dta", replace

// 1960 and 1970 taken from dcourt CCDB, previously ran.

// Then from 1980-2000 from nhgis:

import delimited using "$RAWDATA/census/nhgis0048_csv/nhgis0048_csv/nhgis0048_ds107_1980_county.csv", clear

replace gisjoin = "G3200250" if gisjoin == "G3205100"
merge 1:1 gisjoin using  "$RAWDATA/dcourt/replication_AER/data/crosswalks/county1940_crosswalks", keepusing(cz) keep(3) nogen

g mfg = dia003 + dia004
egen lforce = rowtotal(dia*)

collapse (sum) mfg lforce, by(cz)
g mfg_lfshare1980 = mfg/lforce
drop mfg lforce
tempfile mfg1980
save `mfg1980'

import delimited using "$RAWDATA/census/nhgis0048_csv/nhgis0048_csv/nhgis0048_ds123_1990_county.csv", clear

replace gisjoin = "G3200250" if gisjoin == "G3205100"
merge 1:1 gisjoin using  "$RAWDATA/dcourt/replication_AER/data/crosswalks/county1940_crosswalks", keepusing(cz) keep(3) nogen


g mfg = e4p004 + e4p005
egen lforce = rowtotal(e4p*)

collapse (sum) mfg lforce, by(cz)
g mfg_lfshare1990 = mfg/lforce
drop mfg lforce
tempfile mfg1990
save `mfg1990'
import delimited using "$RAWDATA/census/nhgis0048_csv/nhgis0048_csv/nhgis0048_ds151_2000_county.csv", clear

replace gisjoin = "G3200250" if gisjoin == "G3205100"
merge 1:1 gisjoin using  "$RAWDATA/dcourt/replication_AER/data/crosswalks/county1940_crosswalks", keepusing(cz) keep(3) nogen

g mfg = gmh003 + gmh016
egen lforce = rowtotal(gmh*)

collapse (sum) mfg lforce, by(cz)
g mfg_lfshare2000 = mfg/lforce
drop mfg lforce

merge 1:1 cz using `mfg1980', nogen
merge 1:1 cz using `mfg1990', nogen

save "$INTDATA/census/cz_mfg_1980_2000.dta", replace


// 2010 Urban Populations
local working_directory : pwd
cd "$RAWDATA/census/nhgis0020_fixed/nhgis0020_fixed"
do nhgis0020_ds172_2010_county.do
cd "`working_directory'"

ren h7v001 pop2010
ren h7w002 popc2010

destring statea countya, replace
g cty_fips = statea*1000 + countya
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren czone cz

collapse (sum) pop2010 popc2010, by(cz)

save "$INTDATA/census/urb_pop_2010.dta", replace

