// Only 296 cities
use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear

collapse (mean) yr_incorp (sum) place_land place_total, by(STATEFP PLACEFP)

g gisjoin = "G" + STATEFP + "0" + PLACEFP
merge 1:1 gisjoin using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keep(3) nogen

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
foreach level in county cz{
	if "`level'"=="county" local levelvar "fips"
	if "`level'"=="cz" local levelvar "cz"
	preserve
		foreach geog in land total{
			forv d=1940(10)1970{
				bys `levelvar' : egen `geog'`d' = total(place_`geog') if yr_incorp<=`d'
				replace `geog'`d' = 0 if `geog'`d' == .
				g frac_`geog'`d' = `geog'`d' / `level'_`geog'
				replace frac_`geog'`d' = min(frac_`geog'`d',1)
			}
		}


		keep `levelvar' frac_land19* frac_total19* `level'_land `level'_total land* total*

		collapse (max) land* total* frac_land19* frac_total19* `level'_land `level'_total, by(`levelvar')

		reshape long frac_land frac_total land total, i(`levelvar') j(decade) 
		ren `level'_land `level'_land2010
		ren `level'_total `level'_total2010
		ren land land_incorp
		ren total total_incorp
		
		save "$INTDATA/cgoodman/`level'_geogs.dta", replace
	restore
}

// Incorp + Rugged land split
local files : dir "$INTDATA/land_cover/states/" files *
foreach f in `files'{
	use "$INTDATA/land_cover/states/`f'", clear
	local state = substr(`"`f'"',-6,2)
	tempfile s`state'
	save `s`state''
}
clear

foreach f in `files'{
	local state = substr(`"`f'"',-6,2)
	append using `s`state''
}

g frac_unusable = (area_unusable + area_incorporated -area_both)/area_total

ren county_fips fips
keep fips decade frac_unusable
save "$INTDATA/land_cover/frac_unusable", replace
