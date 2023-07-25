
gz7, filepath("$RAWDATA/dcourt") filename("usa_00047.dta.gz")

rename perwt pop
g bpop = pop if race == 2
g nwhtpop = pop if race != 1
drop if city==0
collapse (sum) pop bpop nwhtpop, by(sample city statefip region)

g south = floor(region/10)==3
drop region

reshape wide pop bpop nwhtpop, i(statefip city south) j(sample)

rename city citycode
decode citycode, gen(city)

*Standardize City Names
//A - fix spelling and formatting variations
split city, p(,) g(part)
replace city = proper(part1) + "," + upper(part2) 
drop part1 part2

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
replace city = "Lafayette, IN" if city == "Lafayette, IL"

//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
//B1 - the following cities overlap with their subsitutes
*	replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
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

// New york new jersey
replace city = "New York, NJ" if city == "New York, NY" & statefip==34

ren *195001 *1950
ren *196002 *1960


preserve
	*Merge with State Crosswalks
	merge m:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
	replace cz = 19600 if city=="Belleville, NJ"
	replace cz_name = "Newark, NJ" if city=="Belleville, NJ"
	*Resolve Unmerged Cities
	tab _merge

	*Save
	drop if _merge==2
	drop _merge

	save "$INTDATA/dcourt/census_1950_1960_racepop_cz", replace
restore

preserve
	*Merge with State Crosswalks
	merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(countyfip state_fips)

	drop if _merge==2
	drop _merge

	save "$INTDATA/dcourt/census_1950_1960_racepop_county", replace
restore

merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(smsa) keep(1 3) nogen

save "$INTDATA/dcourt/census_1950_1960_racepop_msa", replace



