use "$RAWDATA/census/usa_00072.dta/usa_00072.dta", clear
	// keep people who lived in south in 1930
	decode stateicp, gen(origin_state)

	g origin_sample=(origin_state=="alabama" | origin_state=="arkansas" | origin_state=="florida" | origin_state=="georgia" | origin_state=="kentucky"| origin_state=="louisiana" | origin_state=="mississippi" | origin_state=="north carolina" | origin_state=="oklahoma" | origin_state=="south carolina" | origin_state=="tennessee" | origin_state=="texas" | origin_state=="virginia" | origin_state=="west virginia") & year == 1930
	bys hik (origin_sample) : replace origin_sample = origin_sample[_N]
	keep if origin_sample == 1
	
	// Keep people who lived in northern cities in 1940
	g citycode = city if year == 1940
	bys hik (citycode) : replace citycode = citycode[1]
	keep if year == 1930

	replace citycode = 3540 if citycode == 3521 // Lebanon, PA rename
	merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset.dta",  keep(3) keepusing(citycode cz_name cz) nogen
	
	// Clean vars
	replace occscore = . if occscore == 0
	replace rent30 = . if inlist(rent,0,9998,9999)
	replace valueh = . if inlist(valueh,0,  9999998, 9999999)
	
	replace empstat = . if empstat == 0
	g unemp_rate = empstat - 1 if inlist(empstat,1,2) // 1 if unemployed, 0 if employed, missing if not in labor force
	replace farm = farm - 1

	collapse (mean)  occscore, by(cz)
	
	rename occscore occscore_black_3040_linked
	
	save "$INTDATA/census/black_linked_chars.dta", replace