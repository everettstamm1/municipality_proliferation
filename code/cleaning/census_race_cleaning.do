
// 1910-1940

forv d=49/52{
	gz7, filepath("$RAWDATA/census") filename("usa_000`d'.dta.gz")
	
	g pop = perwt 
	g bpop = perwt if race == 2
	g popc = perwt if city!=0
	g bpopc = perwt if city!=0 & race == 2

	collapse (sum) popc pop bpop bpopc, by(stateicp countyicp)
	g year = `d'
	merge 1:1 stateicp countyicp using "$DCOURT/data/crosswalks/county1940_crosswalks", keepusing(statefip countyfip cz smsa state_name county_name) keep(1 3) nogen
	ren county_name county
	ren state_name state
	tempfile r`d'
	save `r`d''
}

// 1950
import delimited using "$RAWDATA/census/county_race_1950_2020/nhgis0017_ds84_1950_county.csv", clear
g statefip = statea/10
g countyfip = countya/10
drop if mod(statefip,1)>0
drop if mod(countyfip,1)>0

egen pop = rowtotal(b3*)
egen black = rowtotal(b3p003 b3p007)

g fips = (1000*statefip) + countyfip
keep year state county fips stateicp countyicp pop black

merge 1:1 fips using "$DCOURT/data/crosswalks/county1940_crosswalks", keepusing(smsa cz) keep(1 3) nogen

tempfile r1950
save `r1950'

import delimited using "$RAWDATA/census/county_race_1950_2020/nhgis0017_ds91_1960_county.csv", clear
g statefip = statea/10
g countyfip = countya/10
drop if mod(statefip,1)>0 | statefip==2 | statefip==15
drop if mod(countyfip,1)>0

egen pop = rowtotal(b5*)
egen black = rowtotal(b5s002 b5s009)
g fips = (1000*statefip) + countyfip
keep year state county fips stateicp countyicp pop black

merge 1:1 fips using "$DCOURT/data/crosswalks/county1940_crosswalks", keepusing(smsa cz) keep(1 3) nogen
tempfile r1960
save `r1960'


import delimited using "$RAWDATA/census/county_race_1950_2020/nhgis0017_ts_nominal_county.csv", clear
ren statefp statefip
ren countyfp countyfip

egen pop = rowtotal(b18*)
g black = b18ab

g fips = (1000*statefip) + countyfip

keep year state county fips pop black
merge m:1 fips using "$DCOURT/data/crosswalks/county1940_crosswalks", keepusing(smsa cz) keep(1 3) nogen

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
forv d=1900(10)1970{
	append using `r`d''
}

replace statefip = string(floor(fips/1000)) if statefip==""
replace countyfip = string(mod(fips,1000)) if countyfip==""

preserve 
	collapse (sum) black pop, by(year statefip countyfip)

	g black_share = black/pop
	bys statefip countyfip (year) : g change_black_share  = black/pop - black[_n-1]/pop[_n-1] if year-10 == year[_n-1]
	keep statefip countyfip year black pop black_share change_black_share
	
	save "$INTDATA/census/county_race_data.dta", replace
restore

preserve 
	collapse (sum) black pop, by(year cz)
	
	g black_share = black/pop
	bys cz (year) : g change_black_share  = black/pop - black[_n-1]/pop[_n-1] if year-10 == year[_n-1]
	keep cz year black pop black_share change_black_share
	
	save "$INTDATA/census/cz_race_data.dta", replace
restore

preserve
	collapse (sum) black pop, by (year smsa)

	g black_share = black/pop
	bys smsa (year) : g change_black_share  = black/pop - black[_n-1]/pop[_n-1] if year-10 == year[_n-1]
	keep smsa year black pop black_share change_black_share

	save "$INTDATA/census/msa_race_data.dta", replace
restore

collapse (sum) black pop, by(statefip year)
g black_share = black/pop
bys statefip (year) : g change_black_share  = black/pop - black[_n-1]/pop[_n-1] if year-10 == year[_n-1]
	
keep statefip  year black pop black_share change_black_share

save "$INTDATA/census/state_race_data.dta", replace

