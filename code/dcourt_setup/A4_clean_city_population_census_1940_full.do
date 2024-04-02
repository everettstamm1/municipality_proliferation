/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
SUMMARY: 
	This do-file constructs a dataset of population at the city-level in 1940. 

STEPS:
	*1. Standardize city names.
	*2. Merge with state crosswalks.
	*4. Save city-level dataset.

*first created: 07/09/2018
*last updated:  07/16/2018 
*/

	gz7, filepath("$RAWDATA/census") filename("usa_00055.dta.gz")
	
	g popc = perwt
	g bpopc = perwt if race==2
	g wpopc = perwt if race==1
	// Fixing texarkana, TX/AR
	replace city = 69510 if city==6951 & stateicp == 49
	replace city = 69511 if city==6951 & stateicp == 42

	collapse (sum) popc bpopc wpopc (mean) citypop, by(city statefip)
	drop if city==0
	
	// Dropping some errors, La Grange, IL that is in Louisiana and La Grange, GA that is in Florida
	drop if city==3391 & statefip == 22
	drop if city==3392 & statefip == 12

	cityfix_census
	
	
	*Merge with State Crosswalks
	merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
	replace cz = 19600 if city=="Belleville, NJ"
	replace cz_name = "Newark, NJ" if city=="Belleville, NJ"
	drop if _merge==2
	drop _merge
	ren *popc *popc1940 
	
	//  spot changes to match dcourt versions
	replace city = "Grosse Pointe Woods, MI" if city=="Grosse Pointe Park, MI" 
	replace citycode = 7092 if citycode == 7110
	replace citycode = 3540 if citycode == 3521

	save "$INTDATA/dcourt/clean_city_population_census_1940_full.dta", replace
	
