
// mfg_lfshare for non CCDB years (1900-40, 1980-2010)
foreach d in 108 109 110 111 114{
	local  d = 114
	use if ind1950 != 0 using "$RAWDATA/census/usa_00`d'.dta/usa_00`d'.dta", clear

	keep ind1950 stateicp countyicp  perwt ind1950 year
	drop if ind1950 == 0 | mi(ind1950)
	
	g mfg = (ind1950 >= 300 & ind1950 < 500) * perwt
	g lforce = perwt

	
	merge m:1 stateicp countyicp using "$RAWDATA/dcourt/county1940_crosswalks", keep(3) nogen keepusing(cz)
	
	
	collapse (sum) lforce mfg, by(cz year)
	g mfg_lfshare = mfg / lforce
	keep cz year mfg_lfshare
	save "$INTDATA/census/cz_mfg_`d'", replace

}




clear 
foreach d in 108 109 110 111 114{
	append using "$INTDATA/census/cz_mfg_`d'"
}

reshape wide mfg_lfshare, i(cz) j(year)
save "$INTDATA/census/cz_mfg.dta", replace

rename 