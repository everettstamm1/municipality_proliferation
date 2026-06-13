use "$RAWDATA/dcourt/replication_AER/data/mechanisms/population/clean_city_population_ccdb_1944_1977.dta", clear

/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
Keep them in sample by retrieving 1970 black pop info from Census for these cities */
replace pop1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace pop1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf

keep cz city pop1940 pop1950 pop1960 pop1970
reshape long pop, i(cz city) j(year)
bys cz year : egen maxcitypop = max(pop)

keep if maxcitypop == pop

merge m:1 city using "$RAWDATA/dcourt/replication_AER/data/crosswalks/US_place_point_2010_crosswalks", keepusing(gisjoin) keep(3) nogen 
g GEOID = substr(gisjoin,2,2) + substr(gisjoin,5,.)
merge m:1 cz using "$INTDATA/dcourt/original_130_czs", keep(3) nogen

keep cz GEOID maxcitypop year
reshape wide maxcitypop GEOID, i(cz) j(year)

save "$INTDATA/census/maxcitypop", replace



import delimited "$RAWDATA/census/nhgis0038_csv/nhgis0038_ds172_2010_place.csv", clear
ren placea PLACEFP
ren statea STATEFP
merge 1:1 STATEFP PLACEFP using "$XWALKS/cz_place_xwalk", keep(1 3) nogen
// Some spot fixes
replace cz = 18000 if gisjoin == "G36074183"
replace cz = 12701 if gisjoin == "G09074260"
replace cz = 12701 if gisjoin == "G09077270"
replace cz = 16400 if gisjoin == "G39007454"
replace cz = 11302 if gisjoin == "G24070530"

merge m:1 cz using "$INTDATA/dcourt/original_130_czs", keep(3) nogen

bys cz : egen maxcitypop2010 = max(h7v001)
keep if maxcitypop2010 == h7v001
ren name maxcity_name
keep cz maxcity_name PLACEFP STATEFP maxcitypop2010


save "$INTDATA/census/maxcitypop_2010.dta", replace

