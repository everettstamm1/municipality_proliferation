

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
		
		
keep cz above_x_med shift_share_base GM_raw_pp popc1940 b18*_cgoodman_cz_pc b19*_cgoodman_cz_pc b20*_cgoodman_cz_pc region b_cgoodman_cz????
rename b*_cgoodman_cz_pc munis_pc*
rename b_cgoodman_cz* munis*
drop munis17* munis18* munis_pc18*
reshape long munis_pc munis, i(cz) j(year)

reghdfe munis_pc c.above_x_med#year, absorb(cz year) vce(cluster cz)

g x_above_10_below_1 = GM_raw_pp > 10
replace x_above_10_below_1 = . if GM_raw_pp > 1 & GM_raw_pp < 10


forv y = 1900(10)2010{
	g y`y' = year == `y'
	g above_x_medX`y' = above_x_med * y`y'
	g x_above_10_below_1X`y' = x_above_10_below_1 * y`y'
	g GM_raw_ppX`y' = GM_raw_pp * y`y'
	g shift_share_baseX`y' = shift_share_base * y`y'
	lab var above_x_medX`y' "`y'"
	lab var GM_raw_ppX`y' "`y'"
	lab var shift_share_baseX`y' "`y'"
}
/*
preserve
	collapse (mean) munis_pc, by(year above_x_med)
	twoway 	(scatter munis_pc year if above_x_med == 0, color(blue)) ///
			(scatter munis_pc year if above_x_med == 1, color(red)) 
restore


preserve
	collapse (mean) munis, by(year above_x_med)
	bys year (above_x_med) : g diff = munis - munis[_n - 1] if year == year[_n-1]
	bys year (above_x_med) : g diff2 = (munis - munis[_n - 1])/munis[_n - 1] if year == year[_n-1]

	twoway 	(scatter munis year if above_x_med == 0, color(blue)) ///
			(scatter munis year if above_x_med == 1, color(red)) 
	twoway 	(scatter diff year, color(blue)) 
		twoway 	(scatter diff2 year if year > 1880, color(blue)) 

restore
*/
drop GM_raw_ppX1930 above_x_medX1930 shift_share_baseX1930 x_above_10_below_1X1930
g coef = .
g ci_hi = .
g ci_lo = .
// Basic
reghdfe munis_pc above_x_medX*  if year > 1890, absorb(year cz region region#year) cl(cz)
forv y=1900(10)2010{
	if `y'==1930{
		replace coef = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
	}
	else{
		replace coef = _b[above_x_medX`y'] if year == `y'
		replace ci_hi = _b[above_x_medX`y'] + 1.96*_se[above_x_medX`y'] if year == `y'
		replace ci_lo = _b[above_x_medX`y'] - 1.96*_se[above_x_medX`y'] if year == `y'
	}
}

twoway ///
	(scatter coef year, color(black)) ///
	(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
	yline(0, lc(red) lp(dash)) ///
	xlabel(1900(10)2010, val angle(45)) ///
	legend(off) ytitle("Event Study Coefficients")
				
graph export "$FIGS/RR/did_es_uw.png", as(png) replace

replace coef = .
replace ci_hi = .
replace ci_lo = .

// Weighted
reghdfe munis_pc above_x_medX* [aw=popc1940] if year > 1890, absorb(year cz) cl(cz)
forv y=1900(10)2010{
	if `y'==1930{
		replace coef = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
	}
	else{
		replace coef = _b[above_x_medX`y'] if year == `y'
		replace ci_hi = _b[above_x_medX`y'] + 1.96*_se[above_x_medX`y'] if year == `y'
		replace ci_lo = _b[above_x_medX`y'] - 1.96*_se[above_x_medX`y'] if year == `y'
	}
}

twoway ///
	(scatter coef year, color(black)) ///
	(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
	yline(0, lc(red) lp(dash)) ///
	xlabel(1900(10)2010, val angle(45)) ///
	legend(off) ytitle("Event Study Coefficients")
				
graph export "$FIGS/RR/did_es_w.png", as(png) replace


replace coef = .
replace ci_hi = .
replace ci_lo = .

// Basic, region FEs
reghdfe munis_pc above_x_medX*  if year > 1890, absorb(year cz region) cl(cz)
forv y=1900(10)2010{
	if `y'==1930{
		replace coef = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
	}
	else{
		replace coef = _b[above_x_medX`y'] if year == `y'
		replace ci_hi = _b[above_x_medX`y'] + 1.96*_se[above_x_medX`y'] if year == `y'
		replace ci_lo = _b[above_x_medX`y'] - 1.96*_se[above_x_medX`y'] if year == `y'
	}
}

twoway ///
	(scatter coef year, color(black)) ///
	(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
	yline(0, lc(red) lp(dash)) ///
	xlabel(1900(10)2010, val angle(45)) ///
	legend(off) ytitle("Event Study Coefficients")
				
graph export "$FIGS/RR/did_es_uw_reg.png", as(png) replace

replace coef = .
replace ci_hi = .
replace ci_lo = .

// Weighted, region FEs
reghdfe munis_pc above_x_medX* [aw=popc1940] if year > 1890, absorb(year cz region) cl(cz)
forv y=1900(10)2010{
	if `y'==1930{
		replace coef = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
	}
	else{
		replace coef = _b[above_x_medX`y'] if year == `y'
		replace ci_hi = _b[above_x_medX`y'] + 1.96*_se[above_x_medX`y'] if year == `y'
		replace ci_lo = _b[above_x_medX`y'] - 1.96*_se[above_x_medX`y'] if year == `y'
	}
}

twoway ///
	(scatter coef year, color(black)) ///
	(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
	yline(0, lc(red) lp(dash)) ///
	xlabel(1900(10)2010, val angle(45)) ///
	legend(off) ytitle("Event Study Coefficients")
				
graph export "$FIGS/RR/did_es_w_reg.png", as(png) replace

