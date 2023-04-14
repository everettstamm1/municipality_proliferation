cap prog drop cityfix_ccdb
prog def cityfix_ccdb
	syntax, codevar(varname)
	

	if "`codevar'" == "" local codevar "citycode"
	rename city `codevar'
	decode `codevar', gen(city)

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
	
	end