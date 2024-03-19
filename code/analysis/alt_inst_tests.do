// Alt Inst tests
local b_controls reg2 reg3 reg4 v2_sumshares_urban
local extra_controls transpo_cost_1920 coastal

use "$CLEANDATA/cz_pooled", clear

foreach outcome in cgoodman schdist_ind spdist gen_town gen_muni totfrac{
    if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	preserve
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_1940_hat_raw GM_7r_hat_raw GM_r_hat_raw GM_hat_raw) `b_controls' [aw = popc1940], r
		local hansenj : di %4.2f e(jp)
		
		global spec1 (GM_raw_pp = GM_hat_raw)  `b_controls'
		global spec2 (GM_raw_pp = GM_7r_hat_raw)  `b_controls'
		global spec3 (GM_raw_pp = GM_r_hat_raw) `b_controls'
		global spec4 (GM_raw_pp = GM_1940_hat_raw)  `b_controls'
		
		forval spec=1(1)4{
			tempfile spec`spec'
			parmby "ivreg2 n_`outcome'_cz_pc ${spec`spec'} [aw = popc1940]", lab saving(`"spec`spec'"', replace) idn(`l') ids(spec) ylabel 
		}
			
		drop _all
		forval spec=1(1)4{
			capture append using "spec`spec'"
			rm "spec`spec'.dta"
		}
		
		tempfile overid_coefplot
		save `overid_coefplot'
		
		use `overid_coefplot', clear 
		keep if regexm(parm,"GM")==1
		g x=_n
		twoway scatter estimate x , mcolor(jmpgreen) ///
		|| rcap min95 max95 x, lcolor(jmpgreen%20)  ///
		title("`outlab'")  ///
		xsc(range(1(1)4)) xla(none, value angle(45))  ///
		xla(1 "Baseline" 2 "Resid State FEs" 3 "Top Urban Dropped" 4 "1940 Southern State of Birth" , add custom labcolor(jmpblue)) ///
		caption("Hansen J Statistic: `hansenj'", ring(0) pos(8)) ///
		xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(off)
		
		graph export "$FIGS/exogeneity_tests/D16_alt_inst_pooled_`outcome'.pdf", replace as(pdf)
	restore
}


use "$CLEANDATA/cz_pooled", clear

foreach outcome in cgoodman schdist_ind spdist gen_town gen_muni totfrac{
    if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	preserve
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_1940_hat_raw GM_7r_hat_raw GM_r_hat_raw GM_hat_raw) `b_controls' `extra_controls' [aw = popc1940], r
		local hansenj : di %4.2f e(jp)
		
		global spec1 (GM_raw_pp = GM_hat_raw)  `b_controls'  `extra_controls'
		global spec2 (GM_raw_pp = GM_7r_hat_raw)  `b_controls' `extra_controls'
		global spec3 (GM_raw_pp = GM_r_hat_raw) `b_controls' `extra_controls'
		global spec4 (GM_raw_pp = GM_1940_hat_raw)  `b_controls' `extra_controls'
		
		forval spec=1(1)4{
			tempfile spec`spec'
			parmby "ivreg2 n_`outcome'_cz_pc ${spec`spec'} [aw = popc1940]", lab saving(`"spec`spec'"', replace) idn(`l') ids(spec) ylabel 
		}
			
		drop _all
		forval spec=1(1)4{
			capture append using "spec`spec'"
			rm "spec`spec'.dta"
		}
		
		tempfile overid_coefplot
		save `overid_coefplot'
		
		use `overid_coefplot', clear 
		keep if regexm(parm,"GM")==1
		g x=_n
		twoway scatter estimate x , mcolor(jmpgreen) ///
		|| rcap min95 max95 x, lcolor(jmpgreen%20)  ///
		title("`outlab'")  ///
		xsc(range(1(1)4)) xla(none, value angle(45))  ///
		xla(1 "Baseline" 2 "Resid State FEs" 3 "Top Urban Dropped" 4 "1940 Southern State of Birth" , add custom labcolor(jmpblue)) ///
		caption("Hansen J Statistic: `hansenj'", ring(0) pos(8)) ///
		xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(off)
		
		graph export "$FIGS/exogeneity_tests/D16_alt_inst_pooled_`outcome'_new_ctrls.pdf", replace as(pdf)
	restore
}

