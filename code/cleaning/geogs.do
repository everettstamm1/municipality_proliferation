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


		keep `levelvar' frac_land19* frac_total19*

		collapse (max) frac_land19* frac_total19*, by(`levelvar')

		reshape long frac_land frac_total, i(`levelvar') j(decade) 

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
