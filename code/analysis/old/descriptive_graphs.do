use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear
destring statefips countyfips, replace
drop if statefips == 02 | statefips==15
g cty_fips = 1000*statefips+countyfips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
ren czone cz
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(cz above_x_med)
g n = 1

keep if yr_incorp > 1900
collapse (sum) n, by(yr_incorp above_x_med)

twoway (line n yr_incorp if above_x_med == 0,  lcolor(blue)) ///
		(line n yr_incorp if above_x_med == 1,  lcolor(red)), ///
		legend(order(1 "Below Median GM" 2 "Above Median GM")) ///
			xtitle("Year") ytitle("Count") xline(1940 1970, lpattern(dash) lcolor(red))

			
use "$CLEANDATA/cz_pooled", clear
keep cz cz_name b_*_cz1940_pc b_*_cz1950_pc b_*_cz1960_pc b_*_cz1970_pc pop1940 pop1950 pop1960 pop1970
drop *subcounty* *totfrac* *schdist_cz*
ren b_*_pc *
ren *schdist_ind* *schdist*
ren *cgoodman* *cg*
ren *gen_* **
drop all_local*

reshape long muni_cz cg_cz schdist_cz town_cz spdist_cz pop, i(cz cz_name) j(year)



twoway (scatter muni_cz pop if year == 1940,  mcolor(blue%50)) ///
		(scatter muni_cz pop if year == 1950,  mcolor(red%50)) ///
		(scatter muni_cz pop if year == 1960 ,  mcolor(black%50)) ///
		(scatter muni_cz pop if year == 1970,  mcolor(green%50)), ///
		legend(order(1 "1940" 2 "1950" 3 "1960" 4 "1970")) ///
			xtitle("Population") ytitle("Municipalities Per Capita") 

twoway (scatter schdist_cz pop if year == 1940,  mcolor(blue%50)) ///
		(scatter schdist_cz pop if year == 1950,  mcolor(red%50)) ///
		(scatter schdist_cz pop if year == 1960 ,  mcolor(black%50)) ///
		(scatter schdist_cz pop if year == 1970,  mcolor(green%50)), ///
		legend(order(1 "1940" 2 "1950" 3 "1960" 4 "1970")) ///
			xtitle("Population") ytitle("School Districts Per Capita") 


use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear
destring statefips countyfips, replace
drop if statefips == 02 | statefips==15
g cty_fips = 1000*statefips+countyfips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
ren czone cz
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(cz pop)
g n = 1




clear
set obs 100000
g y = runiform()
g x = runiform()
g pop = runiform()
g y_pc = y/pop
g x_pc = x/pop
reg y pop
reg y_pc pop
reg y x
reg y_pc x_pc