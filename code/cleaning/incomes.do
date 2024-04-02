use "$XWALKS/consistent_1990", clear
keep if year == 1940
keep weight nhgisst_1990 nhgiscty_1990 icpsrst icpsrcty
ren icpsrst stateicp
ren icpsrcty countyicp

tempfile consistent_xwalk
save `consistent_xwalk'

use city perwt stateicp countyicp incwage using "$RAWDATA/census/usa_00055.dta", clear

ren city citycode
// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
merge m:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta",  keep(1 3) keepusing(citycode)
ren citycode city

g incwagec = incwage if _merge==3
drop _merge


joinby  icpsrst icpsrcty using `consistent_xwalk', keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = nhgisst_1990*100+nhgiscty_1990/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen

collapse (median) incwage incwagec [w=weight], by(czone)

ren valueh med_income_1940
ren valueh med_urban_income_1940

save "$INTDATA/census/incomes", replace
