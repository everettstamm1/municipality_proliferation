
foreach level in county{
	
	eststo clear

	foreach ds in all_local {

		use "$CLEANDATA/`level'_`ds'_stacked.dta", clear
		ren fips cty_fips
		merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk", keep(3) nogen
		keep if msapmsa2000 == 4480 | msapmsa2000 == 1600
		keep if decade==1940 | decade == 1950 | decade == 1960
		keep if GM_hat2 <.
		
		
		
		g decade_end = decade+10
		g decade_str = string(decade)+"-"+string(decade_end)
		labmask decade, values(decade_str)
		
		twoway  (connected GM_hat2 decade if cty_fips == 6037, col(red)) ///
						(connected GM_hat2 decade if cty_fips == 17031, col(blue)) ///
						(connected GM_hat2 decade if cty_fips == 17089, col(blue)) ///
						(connected GM_hat2 decade if cty_fips == 17097, col(blue)) ///
						(connected GM_hat2 decade if cty_fips == 17197, col(blue)) , /// 
						legend(order(1 2) label(2 "Chicago, IL PMSA") label(1 "Los Angeles-Long Beach, CA PMSA")) ///
						xlabel(1940 1950 1960,valuelabel angle(45)) title("Predicted values of Chicago vs. LA Counties")
						
						graph export "$FIGS/descriptive/la_chicago_gm_hat2.png", as(png) replace

	}
	
	
}


import delimited using "$RAWDATA/census/national_county.txt",clear
g county_name = v4 + ", " + v1
g fips = 1000*v2 + v3

keep county_name fips
tempfile countynames
save `countynames'

use "$CLEANDATA/county_all_local_stacked.dta", clear
ren fips cty_fips
merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk", keep(3) nogen
keep if msapmsa2000 == 4480 | msapmsa2000 == 1600
keep if decade==1940 | decade == 1950 | decade == 1960
keep if GM_hat2 <.

ren cty_fips fips

merge m:1 fips using `countynames'