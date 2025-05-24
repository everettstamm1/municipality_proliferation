// Getting 1940 black and total urban populations, the long way to get the sample of 296 cities in 130 CZs right

use "$RAWDATA/dcourt/clean_city_population_census_1940.dta", clear // 711 cities in non-South
merge 1:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta", keepusing(wpopc1940)  // add in white urban pop

keep if _merge==3 | citycode == 910 /*butte, MT, correction later */ | citycode == 170 /* Amsterdam, NY,  correction later */
drop _merge

merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keepusing(bpop1970 bpop1960 nwhtpop1950 nwhtpop1960 pop1960 whtpop1970 pop1950 pop1940 pop1970)
ren whtpop1970 wpopc1970
foreach var of varlist bpop1960 nwhtpop1950 nwhtpop1960  pop1960{
ren `var' `var'_ccdb
}
	ren _merge ccdb_merge


/* Keep cities large enough (25k+) to appear in CCDB in 1940 and 1970. Results are 
robust to changing this criterion.*/
rename bpop1970 bpopc1970 // rename so it is clear these numbers correspond to city populations
rename pop1970 popc1970 // rename so it is clear these numbers correspond to city populations
rename pop1950 popc1950 // rename so it is clear these numbers correspond to city populations
rename pop1960 popc1960 // rename so it is clear these numbers correspond to city populations
rename bpop1960 bpopc1960 // rename so it is clear these numbers correspond to city populations
/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
Keep them in sample by retrieving 1970 black pop info from Census for these cities */
replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace wpopc1970= 23013 if city=="Butte, MT"

replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
replace wpopc1970= 25346 if city=="Amsterdam, NY"
keep if  bpopc1970!=. & pop1940!=.
/* The following non-southern cities are missing Black population data in 1970 though they have total population data for that year
city
Bolingbrook, IL
Burbank, IL
Burton, MI
Farmington Hills, MI
Grosse Pointe Woods, MI
Irvine, CA
Rancho Palos Verdes, CA
Romulus, MI
*/	

drop if ccdb_merge==2 // Dropping cities in CCDB that do not appear in the 1940 Census list of non-southern cities, see analysis of non-matches above. 

drop if popc1970 == .

bys cz : egen popc1940_cz = total(popc1940)
bys cz : egen bpopc1940_cz = total(bpopc1940)

bys cz : egen wpopc1940_cz = total(wpopc1940)
keep city citycode popc1940_cz wpopc1940_cz bpopc1940_cz
ren city city_name
ren citycode city
save "$INTDATA/dcourt/dest_city_sample_296", replace

		
gl group white
gl oldver  2w
gl newver  2wpp
global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta"

use "$INTDATA/dcourt/bartik/${oldver}_${group}origin_fips1940.dta", clear
merge 1:1 city using "$INTDATA/dcourt/dest_city_sample_296", keep(3) nogen

drop total_$blackcity* bpopc1940_cz
reshape long ${group}origin_fips, i(city) j(origin_fips) string
reshape wide ${group}origin_fips popc1940_cz wpopc1940_cz, i(origin_fips) j( city) 


merge 1:m origin_fips using  "$weights_data", keep(3) nogenerate

replace proutmig = -proutmig // outflows into inflows

foreach var of varlist whiteorigin_fips* {
	
	local citynum = subinstr("`var'","${group}origin_fips","",.)

	g base = wpopc1940_cz`citynum'/popc1940_cz`citynum'
	
	// If prediction is that outmigration is greater than base pop, use percentage instead of percentage point
	g new = cond(popc1940_cz`citynum' + proutmig <0,   ///
				(proutmig +wpopc1940_cz`citynum')/popc1940_cz`citynum', ///
				(wpopc1940_cz`citynum' + proutmig)/(popc1940_cz`citynum' + proutmig))
	
	g shXpr_`var' = `var' * 100*(new - base) 
	drop if shXpr_`var'==.
	drop new base
}

local varlist origin_fips year shX* // Keep only necessary vars
keep `varlist'
quietly bysort origin_fips year: gen dup= cond(_N==1,0,_n)  
tab dup
drop if dup>0 

reshape long shXpr_${group}origin_fips, i(origin_fips year) j(city)
reshape wide shXpr_${group}origin_fips, i(city year) j(origin_fips) string

rename *${group}origin_fips* **

reshape wide shX*, i(city) j(year)	

/* Create total inmig var for cities. */
egen totshXpr=rowtotal(shXpr*) 
replace totshXpr=-1*totshXpr // Turn outflows into inflows


/* Create yearly inmig var for cities. */
local end_year = 1940 + 10*3
local lag_start_year=1940 + 10
forval year=`lag_start_year'(10)`end_year'{
	egen totshXpr`year'=rowtotal(shXpr*`year')
}


save "$INTDATA/dcourt/bartik/${newver}_${group}_proutmigorigin_fips19401970_all_wide.dta", replace
keep city totshXpr*
rename totshX* ${group}_proutmig*
save "$INTDATA/dcourt/bartik/${newver}_${group}_proutmigorigin_fips19401970_collapsed_wide.dta", replace



foreach v in "2pp" "2wpp"{
	
		local origincode origin_fips
		local dest_code city
		local wcode =cond("`v'"=="2pp","black","white")
		local sharecode = cond("`v'"=="2pp","2","2w")
		

		use "$INTDATA/dcourt/bartik/`sharecode'_`wcode'`origincode'1940.dta", clear
		
		order `wcode'* total*
		egen tot`wcode'mig`dest_code'3539=rowmean(total_`wcode'`dest_code'*)
		sum tot`wcode'mig`dest_code'3539
		egen sumshares = rowtotal(`wcode'`origincode'*)
		drop total_* `wcode'*
		save "$INTDATA/dcourt/instrument/`v'_`dest_code'_`wcode'migshare3539.dta", replace
		
		use "$INTDATA/dcourt/bartik/`v'_`wcode'_proutmig`origincode'19401970_collapsed_wide.dta", clear
		merge 1:1 `dest_code' using "$INTDATA/dcourt/instrument/`v'_`dest_code'_`wcode'migshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/instrument/`v'_`wcode'_prmig_1940_1970_wide.dta", replace
	
		use "$INTDATA/dcourt/instrument/`v'_`wcode'_prmig_1940_1970_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
		//A - fix spelling and formatting variations
		split city, p(,) g(part)
		replace city = proper(part1) + "," + upper(part2) 
		drop part1 part2
	
		
		*** Initial cleaning done. Save at this point.
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_`wcode'_prmig_1940_1970_wide_preprocessed.dta", replace
		
		use "$INTDATA/dcourt/instrument/city_crosswalked/`v'_`wcode'_prmig_1940_1970_wide_preprocessed.dta", clear
		g city_original=city
		
		replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
		replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
		replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
		replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
		replace city = "Norristown, PA" if city == "Norristown Borough, PA"
		replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
		replace city = "Jamestown, NY" if city == "Jamestown , NY"
		replace city = "Kensington, PA" if city == "Kensington,"
		replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
		replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
		replace city = "DuBois, PA" if city == "Du Bois, PA"
		replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
		replace city = "McKeesport, PA" if city == "Mckeesport, PA"
		replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
		replace city = "Lafayette, IN" if city == "La Fayette, IN"
		replace city = "Schenectady, NY" if city == "Schenectedy, NY"
		replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
		replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
		replace city = "New Kensington, PA" if city == "Kensington, PA"
	
		//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
		//B1 - the following cities overlap with their subsitutes
		*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
		replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
		replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
	
		//B2 - the following cities just share a border with their subsitutes but do not overlap
		replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
		replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
		replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
	
		//B3 - the following cities do not share a border with their substitutes but are within a few miles
		replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
		replace city = "Wallington, NJ" if city == "Nutley, NJ" 
		replace city = "Short Hills, NJ" if city == "South Orange, NJ"
		replace city = "Lafayette, IN" if city == "Lafayette, IL"
	   
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"
			*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		    
		
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_`wcode'_prmig_1940_1970_wide_xw.dta", replace
	}