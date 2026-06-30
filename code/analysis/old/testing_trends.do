

local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 

use "$CLEANDATA/cz_pooled", clear
ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"

g b = .
g ci_lo = .
g ci_hi = .
g year = .
forv i=2/10{
	local y = 1900+10*`i'
	qui reg n`y'_cgoodman_cz_pc shift_share_base  `b_controls' `extra_controls' [aw=popc1940], r
	local b = e(b)[1,1]
	local sd = e(V)[1,1]^(0.5)
	replace b = `b' if _n == `i'
	replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
	replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
	replace year = `y' if _n == `i'
}


sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1920(10)2000, angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off)
				


ivreg2 n1940_cgoodman_cz_pc (GM_raw_pp = shift_share_base)  reg2 reg3 reg4 sumshare_base [aw=popc1940], r

ssaggregate n*_cgoodman_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' `extra_controls'") s(share)

merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
replace shift = 0 if mi(shift)
lab var shift "`xlab'"

g b = .
g ci_lo = .
g ci_hi = .
g year = .
forv i=2/10{
	local y = 1900+10*`i'
	//qui ivreg2 n`y'_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]
	reg n`y'_cgoodman_cz_pc shift [aw=s_n]
	local b = e(b)[1,1]
	local sd = e(V)[1,1]^(0.5)
	replace b = `b' if _n == `i'
	replace ci_hi  = `b' + 1.96 * `sd' if _n == `i'
	replace ci_lo  = `b' - 1.96 * `sd' if _n == `i'
	replace year = `y' if _n == `i'
}

sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1920(10)2000, angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off)
				
	ivreg2 n1940_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]
