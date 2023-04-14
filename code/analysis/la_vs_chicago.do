


foreach level in county{
	

	foreach ds in schdist_ind {

		use "$CLEANDATA/`level'_`ds'_stacked_full.dta", clear
		
		ren fips cty_fips
		//merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk", keep(3) nogen
		//keep if msapmsa2000 == 4480 | msapmsa2000 == 1600
		keep if decade==1940 | decade == 1950 | decade == 1960
		keep if GM_hat <.
		bys decade : egen mean_base_muni = mean(base_muni_county_L0)
		bys decade : egen mean_GM_raw = mean(GM_raw)
		bys decade : egen mean_GM_hat_raw = mean(GM_hat_raw)
		
		g decade_end = decade+10
		g decade_str = string(decade)+"-"+string(decade_end)
		labmask decade, values(decade_str)
		
		g decade_down = decade - 1
		g decade_up = decade + 1.5
		twoway  (bar base_muni_county_L0 decade if cty_fips == 29097, yaxis(2) barwidth(1) lcol(black%50) fcol(red%50)) ///
						(bar base_muni_county_L0 decade_down if cty_fips == 18089, yaxis(2) barwidth(1) lcol(black%50) fcol(blue%50)) ///
						(bar mean_base_muni decade_up, yaxis(2) barwidth(1) lcol(black%50) fcol(yellow%50)) ///
						(connected GM_hat_raw decade if cty_fips == 29097, yaxis(1) col(red%50)) ///
						(connected GM_hat_raw decade if cty_fips == 18089, yaxis(1)  col(blue%50)) ///
						(connected mean_GM_hat_raw decade, yaxis(1)  col(yellow%50)) ///
						, ///
						legend(order(1 2 3) label(3 "National Average") label(2 "Lake County, IN") label(1 "Jasper County, MO")) ///
						xlabel(1940 1950 1960,valuelabel angle(45))  ///
						title("Change in black population of Jasper vs. Lake Counties (predicted)") ///
						ytitle("Number of Independent School Districts (Bar)", axis(2)) ///
						ytitle("Change in Percent Black Population (Line)", axis(1)) ///
						yscale(range(0 150) axis(2)) ylabel(0(25)150, axis(2)) ///
						
						graph export "$FIGS/descriptive/comparison_hat.png", as(png) replace
						
		twoway  (bar base_muni_county_L0 decade if cty_fips == 29097, yaxis(2) barwidth(1) lcol(black%50) fcol(red%50)) ///
						(bar base_muni_county_L0 decade_down if cty_fips == 18089, yaxis(2) barwidth(1) lcol(black%50) fcol(blue%50)) ///
						(bar mean_base_muni decade_up, yaxis(2) barwidth(1) lcol(black%50) fcol(yellow%50)) ///
						(connected GM_raw decade if cty_fips == 29097, yaxis(1) col(red%50)) ///
						(connected GM_raw decade if cty_fips == 18089, yaxis(1) col(blue%50)) ///
						(connected mean_GM_raw decade, yaxis(1)  col(yellow%50)) ///
						, ///
						legend(order(1 2 3) label(3 "National Average")  label(2 "Lake County, IN") label(1 "Jasper County, MO")) ///
						xlabel(1940 1950 1960,valuelabel angle(45)) ///
						title("Change in black population of Jasper vs. Lake Counties (actual)") ///
						ytitle("Number of Independent School Districts (Bar)", axis(2)) ///
						ytitle("Change in Percent Black Population (Line)", axis(1)) ///
						yscale(range(0 150) axis(2)) ylabel(0(25)150, axis(2))
						
						graph export "$FIGS/descriptive/comparison.png", as(png) replace

	}
	
	
}
/*

import delimited using "$RAWDATA/census/national_county.txt",clear
g county_name = v4 + ", " + v1
g fips = 1000*v2 + v3

keep county_name fips
tempfile countynames
save `countynames'

use "$CLEANDATA/county_schdist_ind_stacked_full.dta", clear
merge m:1 fips using `countynames'
keep if inlist(decade, 1940, 1950, 1960)
ren fips cty_fips
merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk", keep(3) nogen
ren cty_fips fips
bys fips : egen GM_avg = mean(GM)
bys fips : egen n_muni_avg = mean(n_muni_county_L0)

keep if fips == 42107 | 

import delimited using "$RAWDATA/census/national_county.txt",clear
g county_name = v4 + ", " + v1
g fips = 1000*v2 + v3

keep county_name fips
tempfile countynames
save `countynames'

use "$CLEANDATA/county_all_local_stacked_og.dta", clear
ren fips cty_fips
merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk", keep(3) nogen
keep if msapmsa2000 == 4480 | msapmsa2000 == 1600
keep if decade==1940 | decade == 1950 | decade == 1960
keep if GM_hat2 <.

ren cty_fips fips

merge m:1 fips using `countynames'