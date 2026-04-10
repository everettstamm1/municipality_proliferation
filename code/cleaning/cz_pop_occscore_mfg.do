
foreach d in 108 109 110 111 114{
	if "`d'" == "98" use "$RAWDATA/census/usa_000`d'.dta/usa_000`d'.dta", clear
	if "`d'" != "98" use "$RAWDATA/census/usa_00`d'.dta/usa_00`d'.dta", clear

	keep perwt stateicp countyicp race city occscore year ind1950
	
	ren city citycode
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
	
	merge m:1 stateicp countyicp using "$RAWDATA/dcourt/county1940_crosswalks", keep(3) nogen keepusing(cz)
	
	
	collapse (sum) lforce mfg pop popc bpop bpopc (mean) occscore occscorec, by(cz year)
	g mfg_lfshare = mfg / lforce
	drop mfg lforce
	save "$INTDATA/census/cz_pop_occscore_mfg_`d'", replace

}




clear 
foreach d in 108 109 110 111 114{
	append using "$INTDATA/census/cz_pop_occscore_mfg_`d'"
}

save "$INTDATA/census/cz_pop_occscore_mfg.dta", replace
