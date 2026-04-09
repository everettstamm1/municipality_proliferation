
foreach d in 108 109 110 111 98{
	if "`d'" == "98" use "$RAWDATA/census/usa_000`d'.dta/usa_000`d'.dta", clear
	if "`d'" != "98" use "$RAWDATA/census/usa_00`d'.dta/usa_00`d'.dta", clear

	keep perwt stateicp countyicp race city occscore year
	
	ren city citycode
	merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset.dta",  keep(1 3) keepusing(citycode)
ren citycode city
	
	g popc = perwt if _merge == 3
	g bpop = perwt if race == 2
	replace occscore = . if occscore == 0
	g bpopc = bpop if _merge == 3
	g occscorec = occscore if _merge == 3
	ren perwt pop
	
	merge m:1 stateicp countyicp using "$RAWDATA/dcourt/county1940_crosswalks", keep(3) nogen keepusing(cz)
	
	
	collapse (sum) pop popc bpop bpopc (mean) occscore occscorec, by(cz year)
	
	save "$INTDATA/census/cz_pop_occscore_`d'", replace

}




clear 
foreach d in 108 109 110 111 98{
	append using "$INTDATA/census/cz_pop_occscore_`d'"
}

save "$INTDATA/census/cz_pop_occscore.dta", replace
