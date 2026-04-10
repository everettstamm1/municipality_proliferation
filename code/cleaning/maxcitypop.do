use "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", clear

rename bpop1970 bpopc1970 // rename so it is clear these numbers correspond to city populations
rename pop1970 popc1970 // rename so it is clear these numbers correspond to city populations

/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
Keep them in sample by retrieving 1970 black pop info from Census for these cities */
replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
keep if  bpopc1970!=. & pop1940!=.

keep cz city popc1970 pop1940 pop1950 pop1960
collapse (max) popc1970 pop1940 pop1950 pop1960, by(cz)

ren popc1970 maxcitypop1970
ren pop1960 maxcitypop1960
ren pop1950 maxcitypop1950
ren pop1940 maxcitypop1940

save "$INTDATA/census/maxcitypop_ccdb", replace


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

