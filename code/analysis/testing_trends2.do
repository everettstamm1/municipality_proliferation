

local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 use "$CLEANDATA/cz_pooled", clear


ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"

forv i=1/11{
	local y = 1900+10*`i'
	local y1 = `y' - 10
	g growth`y' = (pop`y' - pop`y1')/pop`y1'
}
		
		
keep cz growth* decomp* pop* popc1940 GM_raw_pp `b_controls' `extra_controls' n18* n19*_cgoodman_cz_pc n20*_cgoodman_cz_pc above_x_med np18* np19*_cgoodman_cz_pc np20*_cgoodman_cz_pc shift_share_base
/*
rename n*_cgoodman_cz_pc y*
reshape long y, i(cz) j(year)

gen g = 1950 if above_x_med == 1

g event_time = (year - g)/10

forv k = -4/6 {
	local ak = abs(`k')
	if `k' < 0 local lab = "n`ak'"
	if `k' >= 0 local lab  "`k'"
	di "`lab'"
    gen evt_`lab' = event_time == `k'
}

drop evt_n1
reghdfe y evt_* `b_controls' `extra_controls', absorb(cz year) cluster(cz)
coefplot, keep(evt_*) vertical xline(0)
*/


g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		ivreg2 n`y'_cgoodman_cz_pc shift_share_base `b_controls' `extra_controls' [aw=popc1940], r
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.")

				
keep cz growth19* growth20* decomp19* decomp20* popc1940 GM_raw_pp `b_controls' `extra_controls'  n19*_cgoodman_cz_pc n20*_cgoodman_cz_pc  np19*_cgoodman_cz_pc np20*_cgoodman_cz_pc 

foreach var of varlist *{
	di "`var'"
	drop if mi(`var')
}

ssaggregate growth* decomp*_cgoodman_cz_pc n*_cgoodman_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' `extra_controls'") s(share)

merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
replace shift = 0 if mi(shift)
lab var shift "`xlab'"

				
g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		ivreg2 n`y'_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.")
				
				
graph export "$FIGS/RR2/es_by_year.png", as(png) replace



				drop b ci_lo ci_hi year yearlab

g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		reg np`y'_cgoodman_cz_pc shift [aw=s_n]
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.")
graph export "$FIGS/RR2/es_by_year_pct.png", as(png) replace


drop b ci_lo ci_hi year yearlab

		
g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		ivreg2 decomp`y'_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.")
				
				
graph export "$FIGS/RR2/es_by_year_decomp.png", as(png) replace
drop b ci_lo ci_hi year yearlab


g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		ivreg2 growth`y' (GM_raw_pp = shift) [aw=s_n]
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Population Growth")
				
				
graph export "$FIGS/RR2/es_by_year_popgrowth.png", as(png) replace
asdf

// No imbalanced controls

use "$CLEANDATA/cz_pooled", clear
ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"

keep cz popc1940 GM_raw_pp `b_controls' `extra_controls' n18* n19*_cgoodman_cz_pc n20*_cgoodman_cz_pc above_x_med np18* np19*_cgoodman_cz_pc np20*_cgoodman_cz_pc




ssaggregate n*_cgoodman_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'") s(share)

merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
replace shift = 0 if mi(shift)
lab var shift "`xlab'"

				
g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		ivreg2 n`y'_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.")
				
				
graph export "$FIGS/RR/event_study_pp_noctrl.png", as(png) replace

drop b ci_lo ci_hi year yearlab

		
g b = .
g ci_lo = .
g ci_hi = .
g year = .
g yearlab = ""
forv i=6/16{
	if `i'!=4{
		local y = 1850+10*`i'
		local y1 = `y' - 10
		local ystub = mod(`y',100)
		local ylab = cond(`ystub' == 0, "`y1'-00","`y1'-`ystub'")
		local ylab = cond(`y' == 1900, "1880-00","`ylab'")

		ivreg2 np`y'_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]
		local b = e(b)[1,1]
		local sd = e(V)[1,1]^(0.5)
		replace b = `b' if _n == `i'
		replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
		replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
		replace year = `y' if _n == `i'
		replace yearlab = "`ylab'" if _n == `i'
	}
}
lab var b "Change in Municipalities P.C."
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.")
				
				
graph export "$FIGS/RR/event_study_pct_noctrl.png", as(png) replace