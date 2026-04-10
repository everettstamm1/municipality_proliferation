

foreach d in 84 85 86 87 88 89{
	use "$RAWDATA/census/usa_000`d'.dta/usa_000`d'.dta", clear
	keep perwt stateicp countyicp race city occscore year
	
	ren city citycode
	merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset_split.dta",  keep(1 3) keepusing(citycode)
ren citycode city
	
	g popc = perwt if _merge == 3
	g bpop = perwt if race == 2
	replace occscore = . if occscore == 0
	g bpopc = bpop if _merge == 3
	g occscorec = occscore if _merge == 3
	ren perwt pop
	
	if `d'==81{
		replace occscorec = occscorec * popc
		replace occscore = occscore * pop

	}
	
	collapse (sum) pop popc bpop bpopc occscore occscorec, by(stateicp countyicp year)
	
	ren stateicp icpsrst
	ren countyicp icpsrcty
	merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen
		
	foreach var of varlist pop popc bpop bpopc occscore occscorec{
		replace `var' = `var'*weight
	}
	collapse (sum) pop popc bpop bpopc occscore occscorec, by(year nhgisst_1990 nhgiscty_1990)
	
	ren nhgisst_1990 statefip
	ren nhgiscty_1990 countyfip
		
	g cty_fips = statefip*100+countyfip/10

	merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
	ren cty_fips fips
	ren czone cz
	
	collapse (sum) pop popc bpop bpopc occscore occscorec, by(year cz)
	
	// Convert from aggregates to averages
	replace occscore = occscore/pop
	replace occscorec = occscorec/popc
	g full_count = `d' != 81
	tempfile r`d'
	save `r`d''

}




clear 
foreach d in 84 85 86 87 88 89{
	append using `r`d''
}

save "$INTDATA/census/cz_pop_occscore.dta", replace


// 1960

import delimited using "$RAWDATA/census/county_race_1950_2020/nhgis0017_ds91_1960_county.csv", clear
g statefip = statea/10
g countyfip = countya/10
drop if mod(statefip,1)>0 | statefip==2 | statefip==15
drop if mod(countyfip,1)>0

egen pop = rowtotal(b5*)
egen bpop = rowtotal(b5s002 b5s009)
g fips = (1000*statefip) + countyfip
keep year state county fips stateicp countyicp pop bpop

merge 1:1 fips using "$RAWDATA/dcourt/county1940_crosswalks", keepusing(cz) keep(1 3) nogen
collapse (sum) bpop pop, by(year cz)

tempfile r1960
save `r1960'


import delimited using "$RAWDATA/census/county_race_1950_2020/nhgis0017_ts_nominal_county.csv", clear
ren statefp statefip
ren countyfp countyfip

egen pop = rowtotal(b18*)
g bpop = b18ab

g fips = (1000*statefip) + countyfip

keep year state county fips pop bpop
merge m:1 fips using "$RAWDATA/dcourt/county1940_crosswalks", keepusing(cz) keep(1 3) nogen
collapse (sum) bpop pop, by(year cz)

tempfile r1970
save `r1970'

/*

import delimited using "$RAWDATA/census/county_race_1950_1980/nhgis0016_ds94_1970_county.csv", clear
g statefip = statea
g countyfip = countya
drop if mod(statefip,1)>0 | statefip==2 | statefip==15
replace countyfip = 780 if countyfip == 780.5 // virginia cities 1950s
drop if mod(countyfip,1)>0

egen pop = rowtotal(cbw*)
g black = cbw002

g fips = (1000*statefip) + countyfip
keep year state county fips pop black

merge 1:1 fips using "$DCOURT/data/crosswalks/county1940_crosswalks", keepusing(smsa  cz) keep(1 3) nogen
tempfile r1970
save `r1970'

import delimited using "$RAWDATA/census/county_race_1950_1980/nhgis0016_ds116_1980_county.csv", clear
g statefip = statea
g countyfip = countya
drop if mod(statefip,1)>0 | statefip==2 | statefip==15

egen pop = rowtotal(c6x*)
g black = c6x002
g fips = (1000*statefip) + countyfip
keep year state county fips pop black

merge 1:1 fips using "$DCOURT/data/crosswalks/county1940_crosswalks", keepusing(smsa cz) keep(1 3) nogen
tempfile r1980
save `r1980'
*/

clear 
use "$INTDATA/census/cz_pop_occscore.dta", clear
keep year cz pop bpop
foreach d in 1960 1970 {
	append using `r`d''
}

rename bpop black

g black_share = black/pop
bys cz (year) : g change_black_share  = black/pop - black[_n-1]/pop[_n-1] if year-10 == year[_n-1]
keep cz year black pop 
rename black black_new
rename pop pop_new
sort cz year
tempfile x
save `x'

use "$INTDATA/census/cz_race_data.dta", clear
keep cz year black pop 

merge 1:1 cz year using `x'
ren _merge first_merge
merge m:1 cz using "$CLEANDATA/cz_pooled", keepusing(cz cz_name)



cf _all using `x', verbose

save "$INTDATA/census/cz_race_data.dta", replace


