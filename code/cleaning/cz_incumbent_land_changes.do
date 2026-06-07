use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear

collapse (mean) yr_incorp (sum) land_area2010 = place_land, by(STATEFP PLACEFP)

g gisjoin = "G" + STATEFP + "0" + PLACEFP

merge 1:1 gisjoin using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keep(3) nogen

merge 1:1 city using "$INTDATA/dcourt/xwalk_296_city_cz.dta"


// Spot replcaements : https://www.census.gov/quickfacts/fact/table/uppermontclaircdpnewjersey,brookdalecdpnewjersey,bellevilletownshipessexcountynewjersey/PST045224
replace land_area2010 = 8546964.3 if city == "Belleville, NJ"


replace land_area2010 = 4143982.7  if city == "Brookdale, NJ"


replace land_area2010 = 6164174.2 if city == "Upper Montclair, NJ"


replace land_area2010 = 1853784800 if city == "Butte, MT"

g incumbent = _merge == 3 | inlist(city,"Butte, MT","Upper Montclair, NJ","Brookdale, NJ", "Belleville, NJ")

replace land_area2010 = land_area2010/2589988.11 // convert to sq miles

merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keep(1 3) nogen keepusing(land_area1940 land_area1970)
keep cz cz_name city STATEFP PLACEFP land_area1940 land_area1970 land_area2010 yr_incorp incumbent
order cz cz_name city STATEFP PLACEFP land_area1940 land_area1970 land_area2010 yr_incorp incumbent

sort cz
g incumbent_land1940 = land_area1940 if incumbent == 1
g incumbent_land1970 = land_area1970 if incumbent == 1
g incumbent_land2010 = land_area2010 if incumbent == 1


g incorp_land1940 = cond(!mi(land_area1940), land_area1940,land_area2010) if yr_incorp <= 1940
g incorp_land1970 = cond(!mi(land_area1970), land_area1970,land_area2010) if yr_incorp <= 1970
//g incorp_land1940 = land_area2010 if yr_incorp <= 1940
//g incorp_land1970 = land_area2010 if yr_incorp <= 1970
g incorp_land2010 = land_area2010 if yr_incorp <= 2010
merge m:1 cz using "$INTDATA/dcourt/original_130_czs", keep(3) nogen


collapse (sum) incumbent_land1940 incumbent_land1970 incumbent_land2010  incorp_land1940 incorp_land1970 incorp_land2010, by(cz)

g change_incorp_land_4070 = incorp_land1970 - incorp_land1940
g change_incorp_land_4010 = incorp_land2010 - incorp_land1940

g change_incumbent_land_4070 = incumbent_land1970 - incumbent_land1940
g change_incumbent_land_4010 = incumbent_land2010 - incumbent_land1940

g prop_incumbent_land_change4070 = 100*(change_incumbent_land_4070 / change_incorp_land_4070)
g prop_incumbent_land_change4010 = 100*(change_incumbent_land_4010 / change_incorp_land_4010)

g lchange_incumbent_land_4070 = log(incumbent_land1970) - log(incumbent_land1940)
g lchange_incumbent_land_4010 = log(incumbent_land2010) - log(incumbent_land1940)

g prop_incumbent_land_4070 = 100*((incumbent_land1970/incorp_land1970 ) - (incumbent_land1940/incorp_land1940 ))
g prop_incumbent_land_4010 = 100*((incumbent_land2010/incorp_land2010 ) - (incumbent_land1940/incorp_land1940 ))

keep cz lchange_incumbent_land_4070 lchange_incumbent_land_4010 prop_incumbent_land_change4010 prop_incumbent_land_change4070 prop_incumbent_land_4070 prop_incumbent_land_4010
duplicates drop
save "$INTDATA/cz_incumbent_land_changes.dta", replace