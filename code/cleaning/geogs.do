// Only 296 cities
use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear

collapse (mean) yr_incorp (sum) place_land place_total, by(STATEFP PLACEFP)

g gisjoin = "G" + STATEFP + "0" + PLACEFP
merge 1:1 gisjoin using "$RAWDATA/dcourt//replication_AER/data/crosswalks/US_place_point_2010_crosswalks.dta", keep(3) nogen

merge 1:1 city using "$INTDATA/dcourt/xwalk_296_city_cz.dta", keep(2 3) nogen


// Spot replcaements : https://www.census.gov/quickfacts/fact/table/uppermontclaircdpnewjersey,brookdalecdpnewjersey,bellevilletownshipessexcountynewjersey/PST045224
replace place_land = 8546964.3 if city == "Belleville, NJ"
replace place_total = 8650563.8 if city == "Belleville, NJ"


replace place_land = 4143982.7  if city == "Brookdale, NJ"
replace place_total = 4143982.7 if city == "Brookdale, NJ"


replace place_land = 6164174.2 if city == "Upper Montclair, NJ"
replace place_total = 6578572.5 if city == "Upper Montclair, NJ"


replace place_land = 1853784800 if city == "Butte, MT"
replace place_total = 1855079700 if city == "Butte, MT"

collapse (sum) place_land place_total, by(cz)
ren place_land orig_land
ren place_total orig_total
ren orig* new_orig*

save "$INTDATA/cgoodman/orig_geogs.dta", replace

// Incorp Split
use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear

destring *FP, replace
//g cty_fips = STATEFP*1000 + COUNTYFP
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen
ren cty_fips fips
ren czone cz


preserve
	keep cz fips county_land county_total
	duplicates drop
	collapse (sum) county_land county_total, by(cz)
	ren county* cz*
	tempfile cz_land
	save `cz_land'
restore

merge m:1 cz using `cz_land', assert(3) nogen

// Stacked


foreach geog in land total{
	forv d=1940(10)1970{
		bys cz : egen `geog'`d' = total(place_`geog') if yr_incorp<=`d'
		replace `geog'`d' = 0 if `geog'`d' == .
		g frac_`geog'`d' = `geog'`d' / cz_`geog'
		replace frac_`geog'`d' = min(frac_`geog'`d',1)
	}
}


keep cz frac_land19* frac_total19* cz_land cz_total land* total*

collapse (max) land* total* frac_land19* frac_total19* cz_land cz_total, by(cz)

reshape long frac_land frac_total land total, i(cz) j(decade) 
ren cz_land cz_land2010
ren cz_total cz_total2010
ren land land_incorp
ren total total_incorp

save "$INTDATA/cgoodman/cz_geogs.dta", replace

