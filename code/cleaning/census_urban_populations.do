
// Census Urban Populations
local working_directory : pwd
cd "$RAWDATA/census/urban_1900_1930"
do usa_00045.do
cd "`working_directory'"


// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
ren city citycode
merge m:1 citycode using "$DCOURT/data/city_sample/GM_city_final_dataset_split.dta",  keep(3) nogen keepusing(citycode)
ren citycode city
g pop = hhwt
g pop_urban = hhwt*(urban-1)
g pop_city = cond(city==0,0,hhwt)
g pop_urbarea = cond(urbarea==0,0,hhwt)
g pop_urbpop = cond(urbpop==0,0,hhwt)
drop statefip

collapse (sum) pop*, by(stateicp countyicp year)

ren stateicp icpsrst
ren countyicp icpsrcty
merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen

foreach var of varlist pop pop_urban pop_city pop_urbarea pop_urbpop{
	replace `var' = `var'*weight
}

collapse (sum) pop pop_urban pop_city pop_urbarea pop_urbpop, by(year nhgisst_1990 nhgiscty_1990)

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
ren cty_fips fips
ren czone cz
ren year decade

preserve 
	collapse (sum) pop pop_urban pop_city pop_urbarea pop_urbpop, by(cz decade)

	save "$INTDATA/census/cz_urbanization_1900_1930.dta", replace
restore

save "$INTDATA/census/county_urbanization_1900_1930.dta", replace