cap prog drop cityfix_ccdb
prog def cityfix_ccdb
	syntax
	

	
*Standardize City Names
g city = proper(AREANAME) 

//A - fix spelling and formatting variations
replace city = stritrim(city)
replace city = subinstr(city, ",Mont", "", 1)
replace city = subinstr(city, "N Mex", "", 1)
replace city = subinstr(city, "W Va", "", 1)
replace city = subinstr(city, ",Nj", "", 1)
replace city = subinstr(city, ",Cal.", "", 1)
replace city = subinstr(city, "Cal.", "", 1)
replace city = subinstr(city, ", Mich", "", 1)
replace city = subinstr(city, "Nc.", "", 1)
replace city = subinstr(city, ", Ga.", "", 1)
replace city = subinstr(city, ", Miss", "", 1)
replace city = subinstr(city, "Pa.", "", 1)
replace city = subinstr(city, ",Tex", "", 1)
replace city = subinstr(city, " 5", "", 1 )

replace city = "Aliquippa" if city == "Aliquippa Pa"
replace city = "Arlington" if city == "Arlington County Va"
replace city = "Arlington" if city == "Arlington Town Mass"
replace city = "Belmont" if city == "Belmont Town Mass"
replace city = "Belvedere" if city == "Belvedere Twp Ca"
replace city = "Brookline" if city == "Brookline Town Mass"
replace city = "Central Falls" if city == "Central Falls Ri"
replace city = "East Bakersfield" if city == "East Bakersfield Cal"
replace city = "Haverford" if city == "Haverford Twp Pa"
replace city = "Lower Merion Twp" if city == "Lower Merion Twp Pa"
replace city = "Hagerstown" if city == "Magerstown" & state_name=="MARYLAND"
replace city = "Nashville" if city == "Nashville-Davidson"
replace city = "North Bergen" if city == "North Bergen Twp Nj"
replace city = "Sharon" if city == "Sharon Pa"
replace city = "Teaneck" if city == "Teaneck Twp Nj"
replace city = "Upper Darby" if city == "Upper Danby Twp Pa"
replace city = "Watertown" if city == "Watertown Town Mass"
replace city = "West Hartford" if city == "West Hartford Town Con"
replace city = "Woodbridge" if city == "Woodbridge Twp Nj"

replace city = "East St. Louis" if city == "East St Louis" 
replace city = "South St. Paul" if city == "South St Paul" 
replace city = "St. Charles" if city == "St Charles" 
replace city = "St. Clair Shores" if city == "St Clair Shores" 
replace city = "St. Cloud" if city == "St Cloud" 
replace city = "St. Joseph" if city == "St Joseph" 
replace city = "St. Louis Park" if city == "St Louis Park" 
replace city = "St. Louis" if city == "St Louis" 
replace city = "St. Paul" if city == "St Paul" 
replace city = "St. Petersburg" if city == "St Petersburg" 
replace city = "San Buenaventura (Ventura)" if city == "Ventura Nsan Buenaventur" 
replace city = "Wauwatosa" if city == "Wauwatusa" 
replace city = "McKeesport" if city == "Mc Keesport" 
replace city = "McAllen" if city == "Mc Allen" 
replace city = "Fond du Lac" if city == "Fond Du Lac" 
replace city = "DeKalb" if city == "De Kalb" 
replace city = "Northglenn" if city == "North Glenn" & state_name == "COLORADO"
replace city = "Milford city (balance)" if city == "Milford" & state_name == "CONNECTICUT"
replace city = "LaGrange" if city == "Lagrange" & state_name == "GEORGIA"
replace city = "Hallandale Beach" if city == "Hallandale" & state_name == "FLORIDA"
replace city = "Eastpointe" if city == "East Detroit" & state_name == "MICHIGAN"
replace city = "Elk Grove Village" if city == "Elk Grove" & state_name == "ILLINOIS"
replace city = "Winona" if city == "Minona" & state_name == "MINNESOTA"
replace city = "Lafayette, IN" if city == "Lafayette, IL"

replace city = city + ", " + state_abbrev
replace city = subinstr(city, " ,", ",", 1)

g city_original=city

//A - fix NYC name to match croswalk
replace city = "New York, NY" if city=="New York City, NY"

//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
//B1 - the following cities overlap with their subsitutes
*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
replace city = "Haverford College, PA" if city == "Haverford, PA"
replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
replace city = "Ardmore, PA" if city == "Lower Merion Twp, PA"
replace city = "Drexel Hill, PA" if city == "Upper Darby, PA" 

//B2 - the following cities just share a border with their subsitutes but do not overlap
replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
replace city = "Secaucus, NJ" if city == "North Bergen, NJ" 
replace city = "Bogota, NJ" if city == "Teaneck, NJ" 

//B3 - the following cities do not share a border with their substitutes but are within a few miles
replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
replace city = "Rutherford, NJ" if city == "Nutley, NJ" 
replace city = "Oildale, CA" if city == "East Bakersfield, CA"
	
*drop the last remaining unmatched city, which has no acceptable substitute in crosswalk
drop if city == "Honolulu, HI" 

*manually avoid duplicate names to facilitate merge with crosswalk
sort city STATE1
quietly by city STATE1: gen dup= cond(_N==1,0,_n)
tab dup
drop dup

*Drop individual boroughs of New York City, NY. Place1==2505 is for all of NYC.	
drop if regexm(AREANAME, "NEW YORK CITY")==1 & PLACE1!="2505"
* Drop Orange, TX which for some reason appears twice, but is not in the sample as it is in Texas.
drop if PLACE1 == "3140" | PLACE1 == "3130"

	end