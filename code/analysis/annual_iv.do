

local b_controls reg2 reg3 reg4 sumshare_base



forv y=1910(10)2010{
	use "$CLEANDATA/cz_pooled", clear

	local depvar diff`y'_cgoodman_exact_cz_pc
	local path "$FIGS/event_studies/es_ssaggregate_`spec'.png"
	local ylab "Change in Municipalities P.C."

	local y1 = `y' - 10
	local ystub = mod(`y',100)

	ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'  ") s(share)
	
	
	merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
	replace shift = 0 if mi(shift)
	lab var shift "`xlab'"
							
	g b = .
	g ci_lo = .
	g ci_hi = .
	g year = .
	g yearlab = ""
	
	ivreg2 `depvar' (GM_raw_pp = shift) [aw=s_n]

	local b = e(b)[1,1]
	local sd = e(V)[1,1]^(0.5)
	replace b = `b' if _n == 1
	replace ci_hi  = `b' + 1.96 * `sd' if _n == 1
	replace ci_lo  = `b' - 1.96 * `sd' if _n == 1
	replace year = `y' if _n == 1
	replace yearlab = "`y'" if _n == 1
	keep b ci_hi ci_lo year yearlab
	keep if _n == 1
	tempfile y`y'
	save `y`y''
	
}

clear
forv y = 1910(10)2010{
	append using `y`y''
}
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.") xtitle("Year")


graph export "$FIGS/event_studies/es_ssaggregate_2.png", as(png) replace

use "$CLEANDATA/cz_pooled", clear


forv y=1910(10)2010{
	
	use "$CLEANDATA/cz_pooled", clear

	local y1 = `y' - 10
	local ystub = mod(`y',100)
	local depvar diff`y'_cgoodman_exact_cz_pc


	ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'  mfg_lfshare`y1' mean_income_1940 cz_popdens`y1' ") s(share)
			
	merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
	replace shift = 0 if mi(shift)
	lab var shift "`xlab'"
							
	g b = .
	g ci_lo = .
	g ci_hi = .
	g year = .
	g yearlab = ""
	
ivreg2 `depvar' (GM_raw_pp = shift) [aw=s_n]

	local b = e(b)[1,1]
	local sd = e(V)[1,1]^(0.5)
	replace b = `b' if _n == 1
	replace ci_hi  = `b' + 1.96 * `sd' if _n == 1
	replace ci_lo  = `b' - 1.96 * `sd' if _n == 1
	replace year = `y' if _n == 1
	replace yearlab = "`y'" if _n == 1
	keep b ci_hi ci_lo year yearlab
	keep if _n == 1
	tempfile y`y'
	save `y`y''
	
}

		

clear
forv y = 1910(10)2010{
	append using `y`y''
}
labmask year, val(yearlab)
sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, val angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) ytitle("Change in Municipalities P.C.") xtitle("Year")


graph export "$FIGS/event_studies/es_ssaggregate_4.png", as(png) replace


