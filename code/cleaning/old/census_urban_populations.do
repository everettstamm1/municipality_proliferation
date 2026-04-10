
use "$RAWDATA/census/urban_1900_1930/usa_00067.dta/usa_00067", clear


// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
ren city citycode
merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset_split.dta",  keep(1 3) keepusing(citycode)
ren citycode city

replace age = . if age == 000
replace lit = . if lit == 0
g literate = lit == 4 if lit < .
replace labforce = . if inlist(labforce,0,9)
replace labforce = labforce - 1
replace occscore = . if occscore == 0
g black = race == 2

g agec = age if _merge == 3
g blackc = race == 2 & _merge == 3
g literatec = literate if _merge == 3
g occscorec = occscore if _merge == 3
g labforcec = labforce if _merge == 3

g pop = perwt
g popc = perwt if _merge == 3

foreach var of varlist age black  literate labforce occscore  agec blackc  literatec labforcec occscorec{
	replace `var' = `var'*perwt
}

collapse (sum) pop popc age black  literate labforce occscore   agec blackc  literatec labforcec occscorec, by(stateicp countyicp year)

ren stateicp icpsrst
ren countyicp icpsrcty
merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen

foreach var of varlist pop age black  literate labforce occscore  popc agec blackc  literatec labforcec occscorec{
	replace `var' = `var'*weight
}
keep pop age black  literate labforce occscore  popc agec blackc  literatec labforcec occscorec year nhgisst_1990 nhgiscty_1990
collapse (sum) pop age black  literate labforce occscore  popc agec blackc  literatec labforcec occscorec, by(year nhgisst_1990 nhgiscty_1990)

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren cty_fips fips
ren czone cz
ren year decade


preserve 
	collapse (sum) pop popc age black  literate labforce occscore  agec blackc  literatec labforcec occscorec, by(cz decade)
	// Convert from aggregates to averages
	foreach var in age black  literate labforce occscore   {
			replace `var' = `var'/pop
			replace `var'c = `var'c/popc
	}
	save "$INTDATA/census/cz_urbanization_1900_1930.dta", replace
restore

	// Convert from aggregates to averages

foreach var in age black  literate labforce occscore   {
		replace `var' = `var'/pop
		replace `var'c = `var'c/popc
}
save "$INTDATA/census/county_urbanization_1900_1930.dta", replace



// Census Urban Populations
local working_directory : pwd
cd "$RAWDATA/census/urban_1900_1930"
do usa_00045.do
cd "`working_directory'"

duplicates drop
// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
ren city citycode
merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset_split.dta",  keep(1 3) keepusing(citycode)
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


use city perwt stateicp countyicp using "$RAWDATA/census/usa_00055.dta", clear

ren city citycode
// 1900-30 include way more cities than 1940, so crosswalk to the cities we actually use
merge m:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta",  keep(1 3) keepusing(citycode)
ren citycode city

g perwtc = perwt if _merge==3

drop _merge

bys city : egen citypop = sum(perwtc)
bys stateicp countyicp : egen maxcitypop = max(citypop)
g maxcity = city if maxcitypop == citypop
bys stateicp countyicp (maxcity) : replace maxcity = maxcity[1]

drop city citypop 

bys stateicp countyicp : egen pop = sum(perwt)
drop perwt
bys stateicp countyicp : egen popc = sum(perwtc)
drop perwtc

duplicates drop

ren stateicp icpsrst
ren countyicp icpsrcty
g year = 1940
merge 1:m year icpsrst icpsrcty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(3) nogen


foreach var of varlist maxcitypop popc pop {
	replace `var' = `var'*weight
}

ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
ren cty_fips fips
ren czone cz
ren year decade


bys cz : egen temp = max(maxcitypop)
g temp_name = maxcity if maxcitypop == temp
bys cz (temp_name) : replace temp_name = temp_name[1]
drop maxcity maxcitypop
ren temp maxcitypop
ren temp_name maxcity 

bys cz : egen temp = total(pop)
drop pop
ren temp pop
bys cz : egen temp = total(popc)
drop popc
ren temp popc

keep cz maxcity maxcitypop popc pop 
duplicates drop

g totfrac_in_main_city = maxcitypop/pop
replace totfrac_in_main_city = 0 if pop==0
drop popc pop 

merge 1:1 cz using "$INTDATA/dcourt/original_130_czs", keep(3) nogen
label values maxcity CITY

ren maxcity city
cityfix_census
drop city_original
merge 1:1 city using "$XWALKS/US_place_point_2010_crosswalks", keepusing(gisjoin) keep(3) nogen
g GEOID = substr(gisjoin,2,2) + substr(gisjoin,5,.)
drop city city_original citycode gisjoin
save "$INTDATA/census/maxcitypop", replace



import delimited "$RAWDATA/census/nhgis0038_csv/nhgis0038_ds172_2010_place.csv", clear
ren placea PLACEFP
ren statea STATEFP
merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(1 3) nogen
// Some spot fixes
replace cz = 18000 if gisjoin == "G36074183"
replace cz = 12701 if gisjoin == "G09074260"
replace cz = 12701 if gisjoin == "G09077270"
replace cz = 16400 if gisjoin == "G39007454"
replace cz = 11302 if gisjoin == "G24070530"

merge m:1 cz using "$INTDATA/dcourt/original_130_czs", keep(3) nogen

bys cz : egen maxcitypop2010 = max(h7v001)
keep if maxcitypop2010 == h7v001
ren name maxcity_name
keep cz maxcity_name PLACEFP STATEFP maxcitypop2010
save "$INTDATA/census/maxcitypop_2010.dta", replace


