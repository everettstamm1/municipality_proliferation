
// Census Urban Populations
local working_directory : pwd
cd "$RAWDATA/census/urban_1900_1930"
do usa_00045.do
cd "`working_directory'"


// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
ren city citycode
merge m:1 citycode using "$DCOURT/data/city_sample/GM_city_final_dataset_split.dta",  keep(1 3) keepusing(citycode)
ren citycode city

g pop = hhwt
g popc = hhwt if _merge==3

drop statefip

collapse (sum) popc pop, by(stateicp countyicp year)

ren stateicp icpsrst
ren countyicp icpsrcty
merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen

foreach var of varlist popc pop{
	replace `var' = `var'*weight
}

collapse (sum) popc pop weight, by(year nhgisst_1990 nhgiscty_1990)

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren cty_fips fips
ren czone cz
ren year decade

preserve 
	collapse (sum) popc pop, by(cz decade)

	save "$INTDATA/census/cz_urbanization_1900_1930.dta", replace
restore

save "$INTDATA/census/county_urbanization_1900_1930.dta", replace





forv d=49/52{
	gz7, filepath("$RAWDATA/census") filename("usa_000`d'.dta.gz")
	
	g pop = perwt 
	g bpop = perwt if race == 2
	g popc = perwt if city!=0
	g bpopc = perwt if city!=0 & race == 2

	ren city citycode
	merge m:1 citycode using "$DCOURT/data/city_sample/GM_city_final_dataset_split.dta",  keep(1 3) keepusing(citycode)
	
	collapse (sum) popc pop bpop bpopc, by(stateicp countyicp year)

	ren stateicp icpsrst
	ren countyicp icpsrcty
	merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen
	
	
	foreach var of varlist popc pop bpop bpopc{
		replace `var' = `var'*weight
	}
	
		
	ren nhgisst_1990 statefip
	ren nhgiscty_1990 countyfip

	g cty_fips = statefip*100+countyfip/10

	merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
	ren cty_fips fips
	ren czone cz
	ren year decade
	
	collapse (sum) popc pop bpop bpopc, by(cz decade)

	tempfile r`d'
	save `r`d''
}

clear
forv d=49/52{
	append using `r`d''
}

save "$INTDATA/census/cz_urbanization_1900_1930", replace


gz7, filepath("$RAWDATA/census") filename("usa_00048.dta.gz")


// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
ren city citycode
merge m:1 citycode using "$DCOURT/data/city_sample/GM_city_final_dataset_split.dta",  keep(1 3) keepusing(citycode)
ren citycode city

g pop = perwt
g popc = perwt if _merge==3

drop citypop
bys city : egen maxcitypop = sum(popc)

collapse (max) maxcitypop (sum) popc pop, by(stateicp countyicp)

ren stateicp icpsrst
ren countyicp icpsrcty
g year = 1940
merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen


foreach var of varlist popc pop {
	replace `var' = `var'*weight
}

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren cty_fips fips
ren czone cz
ren year decade

collapse (sum) popc pop (max) maxcitypop, by(cz )
g totfrac_in_main_city = maxcitypop/pop
replace totfrac_in_main_city = 0 if pop==0

g urbfrac_in_main_city = maxcitypop/popc
replace urbfrac_in_main_city = 0 if popc==0
drop popc pop 

save "$INTDATA/census/maxcitypop", replace
