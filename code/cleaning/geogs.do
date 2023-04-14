// Incorp Split
use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear

destring *FP, replace
g fips = STATEFP*1000 + COUNTYFP

foreach geog in land total{
	forv d=1940(10)1970{
		bys fips : egen `geog'`d' = total(place_`geog') if yr_incorp<=`d'
		replace `geog'`d' = 0 if `geog'`d' == .
		g frac_`geog'`d' = `geog'`d' / county_`geog'
		replace frac_`geog'`d' = min(frac_`geog'`d',1)
	}
}

keep fips frac_land19* frac_total19*

collapse (max) frac_land19* frac_total19*, by(fips)

reshape long frac_land frac_total, i(fips) j(decade) 

save "$INTDATA/cgoodman/county_geogs.dta", replace

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
