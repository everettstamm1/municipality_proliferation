
// 1940-170 changes
use "$CLEANDATA/cz_pooled.dta", clear 

gen share_1940=bpopc1940/popc1940 
gen share_1970=bpopc1970/popc1970 

keep if inlist(cz_name,"San Jose, CA", "San Francisco, CA", "Kansas City, MO", "St. Louis, MO") | ///
		inlist(cz_name,	"Columbus, OH", "Cleveland, OH", "Madison, WI", "Milwaukee, WI")

gen order=1 if cz_name =="Columbus, OH"
replace order=2 if cz_name =="Cleveland, OH"
replace order=3 if cz_name =="Madison, WI"
replace order=4 if cz_name =="Milwaukee, WI"
replace order=5 if cz_name =="Kansas City, MO"
replace order=6 if cz_name =="St. Louis, MO"
replace order=7 if cz_name =="San Jose, CA"
replace order=8 if cz_name =="San Francisco, CA"

foreach var in b_cgoodman_cz b_schdist_ind_cz b_gen_subcounty_cz b_gen_town_cz b_spdist_cz{
  foreach y in 1940 1970{
	ren `var'`y'_pcc `var'_pcc_`y'
	lab var `var'_pcc_`y' "Number `var'"
  }
}
keep share_* b_cgoodman_cz_pcc* b_schdist_ind_cz_pcc* b_gen_subcounty_cz_pcc* b_gen_town_cz_pcc* b_spdist_cz_pcc* cz_name order

reshape long share_ b_cgoodman_cz_pcc_ b_schdist_ind_cz_pcc_ b_gen_subcounty_cz_pcc_ b_gen_town_cz_pcc_ b_spdist_cz_pcc_, i(cz_name) j(decade) 
label variable share "Black Population Share"

g order2 = cond(decade==1940,order-0.2,order+0.2)


foreach var of varlist share_ b_cgoodman_cz_pcc_ b_schdist_ind_cz_pcc_ b_gen_subcounty_cz_pcc_ b_gen_town_cz_pcc_ b_spdist_cz_pcc_{
    graph twoway 	(bar `var' order2 if decade == 1940, barw(0.4) col(blue)) ///
					(bar `var' order2 if decade == 1970, barw(0.4) col(red)), ///
					xlabel(1 "Columbus, OH" 2 "Cleveland, OH" 3 "Madison, WI" 4 "Milwaukee, WI" ///
						5 "Kansas City, MO" 6 "St. Louis, MO" 7 "San Jose, CA" 8 "San Francisco, CA", angle(45)) ///
					legend(order(1 "1940" 2 "1970")) scheme(s1color) xtitle("")
					
	graph export "$FIGS/motivation/`var'1940_1970.png", as(png) replace
}

// TS split
use "$CLEANDATA/cz_stacked.dta", clear 
keep if dcourt == 1 & inlist(decade,1940,1950,1960, 1970)
su GM_raw_pp if decade == 1940, d
g above = GM_raw_pp>`r(p50)' & decade == 1940
bys cz (decade) : replace above = above[1]

collapse (mean) b_cgoodman_cz_L0 b_schdist_ind_cz_L0 b_gen_subcounty_cz_L0 b_gen_town_cz_L0 b_spdist_cz_L0, by(above decade)

foreach var in cgoodman schdist_ind gen_subcounty gen_town spdist{
    graph twoway (connected b_`var'_cz_L0 decade if above == 1, lpattern(dash)) ///
				 (connected b_`var'_cz_L0 decade if above == 0), ///
				legend(order(1 "Above median exposure" 2 "Below median exposure")) ytitle("Mean number `var' per 10,000 urban residents") xtitle("Decade")
	graph export "$FIGS/motivation/`var'_ts.png", as(png) replace

}

// TS not split
use "$CLEANDATA/cz_stacked.dta", clear 
keep if dcourt == 1 & inlist(decade,1940,1950,1960,1970)

collapse (mean) b_cgoodman_cz_L0 b_schdist_ind_cz_L0 b_gen_subcounty_cz_L0 b_gen_town_cz_L0 b_spdist_cz_L0, by(decade)

foreach var in cgoodman schdist_ind  gen_town spdist{
    graph twoway (connected b_`var'_cz_L0 decade) ///
				 , ///
				 ytitle("Mean number `var' per 10,000 Urban Residents") xtitle("Decade")
	graph export "$FIGS/motivation/`var'_ts_pooled.png", as(png) replace

}

graph twoway (connected b_cgoodman_cz_L0 decade) ///
			(connected b_schdist_ind_cz_L0 decade) ///
			(connected b_gen_town_cz_L0 decade) ///
			(connected b_spdist_cz_L0 decade), ///
			legend(order(1 "Municipalities" 2 "School districts" 3 "Townships" 4 "Special districts")) ///
			ytitle("Mean local gov'ts per 10,000 urban residents")
	graph export "$FIGS/motivation/ts_pooled.png", as(png) replace
	

// TS not split, normalized
use "$CLEANDATA/cz_stacked.dta", clear 
keep if dcourt == 1 & inlist(decade,1940,1950,1960,1970)

collapse (mean) b_cgoodman_cz_L0 b_schdist_ind_cz_L0 b_gen_subcounty_cz_L0 b_gen_town_cz_L0 b_spdist_cz_L0, by(decade)
foreach var in cgoodman schdist_ind  gen_town spdist{
    su b_`var'_cz_L0 if decade == 1940
	bys decade : replace b_`var'_cz_L0 = 100*b_`var'_cz_L0/`r(mean)'
	
    graph twoway (connected b_`var'_cz_L0 decade) ///
				 , ///
				 ytitle("Mean number `var' per 10,000 Urban Residents") xtitle("Decade")
	graph export "$FIGS/motivation/`var'_ts_pooled_norm.png", as(png) replace

}

graph twoway (connected b_cgoodman_cz_L0 decade) ///
			(connected b_schdist_ind_cz_L0 decade) ///
			(connected b_gen_town_cz_L0 decade) ///
			(connected b_spdist_cz_L0 decade), ///
			legend(order(1 "Municipalities" 2 "School districts" 3 "Townships" 4 "Special districts")) ///
			ytitle("Mean local gov'ts per 10,000 urban residents")
graph export "$FIGS/motivation/ts_pooled_norm.png", as(png) replace
