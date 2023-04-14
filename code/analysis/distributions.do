use "$CLEANDATA/county_all_local_stacked_og.dta", clear
keep GM GM_hat GM_raw GM_hat_raw  fips decade
keep if decade==1940 | decade == 1950 | decade == 1960
ren GM* GM*_og
tempfile og 
save `og'

use "$CLEANDATA/county_all_local_stacked_full.dta", clear
keep GM GM_hat GM_raw GM_hat_raw fips decade
keep if decade==1940 | decade == 1950 | decade == 1960

ren GM* GM*_full
merge 1:1 fips decade using `og', nogen
drop if GM_full==. & GM_og ==. | fips==.
label define sample 1 "Derenoncourt and Full"  2 "Added in Full"
g sample = .
replace sample = 1 if GM_full<. & GM_og<.
replace sample = 2 if GM_full<. & GM_og ==.


lab values sample sample

foreach var of varlist GM_full GM_hat_full GM_raw_full GM_hat_raw_full{
	if "`var'" == "GM_full" local lab "Rank GM"
	if "`var'" == "GM_hat_full" local lab "Rank GM Hat"
	if "`var'" == "GM_raw_full" local lab "Raw GM"
	if "`var'" == "GM_hat_raw_full" local lab "Raw GM Hat"

	su `var',d
	local all_mean : di %3.2f `r(mean)'
	local all_median : di %2.0f `r(p50)'

	su `var' if sample == 2,d
	local d_mean : di %3.2f `r(mean)'
	local d_median : di %2.0f `r(p50)'

	twoway__histogram_gen `var',  gen(h x, replace)
	twoway (hist `var' if sample == 2, freq start(`r(start)') width(`r(width)') color(blue%30)) ///
				(hist `var', freq start(`r(start)') width(`r(width)') color(green%30)), ///
				legend(cols(1) order(1 "Added in Full, mean: `all_mean' median: `all_median'" 2 "Derenoncourt and Full, mean: `d_mean' median: `d_median'")) ///
				title("Full-Sample `lab' Distribution") 
	graph export "$FIGS/distributions/`var'.png", as(png) replace
}

use "$CLEANDATA/county_cgoodman_stacked_og.dta", clear
keep if decade==1940 | decade == 1950 | decade == 1960
keep n_muni_county_L0 fips decade

label define decades 1940 "1940-50" 1950 "1950-60" 1960 "1960-70"
lab values decade decades
foreach d in 1940 1950 1960{
	if "`d'" == "1940" local col "red"
	if "`d'" == "1950" local col "blue"
	if "`d'" == "1960" local col "green"
	if "`d'" == "1940" local yr "1940-50"
	if "`d'" == "1950" local yr "1950-60"
	if "`d'" == "1960" local yr "1960-70"

	twoway 	(hist n_muni_county_L0 if decade == `d', color("`col'") freq), ///
			title("Municipal Incorporations `yr', CGoodman Data")
	graph export "$FIGS/distributions/cgoodman_`d'.png", as(png) replace

				
}
