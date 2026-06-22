use "$population/clean_city_population_census_1940.dta", clear // 711 cities in non-South
merge 1:1 citycode using "$population/clean_city_population_census_1940_full.dta", keepusing(wpopc1940) // add in white urban pop
keep if _merge==3 | citycode == 910 /*butte, MT, correction later */ | citycode == 170 /* Amsterdam, NY,  correction later */

keep city citycode popc1940 bpopc1940 wpopc1940 cz cz_name south

merge 1:1 city using "$population/clean_city_population_ccdb_1944_1977.dta", keepusing(pop1940 bpop1970 pop1970 whtpop1970) keep(3) nogen

rename bpop1970  bpopc1970
rename pop1970 popc1970
rename whtpop1970 wpopc1970

/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
Keep them in sample by retrieving 1970 black pop info from Census for these cities */
replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
//keep if bpopc1970!=. & pop1940!=.
keep if bpopc1970!=. & pop1940 != .
keep if popc1940 >=25000 | popc1970>=25000

preserve
	keep city citycode cz cz_name popc*
	bys cz : egen cz_popc1940 = total(popc1940)
	save "$INTDATA/dcourt/xwalk_296_city_cz.dta", replace
	keep cz cz_name
	duplicates drop
	save "$INTDATA/dcourt/original_130_czs", replace
restore
save "$INTDATA/dcourt/GM_city_final_dataset.dta", replace

