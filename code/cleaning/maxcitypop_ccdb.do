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