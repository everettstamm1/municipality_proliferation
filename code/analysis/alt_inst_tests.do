// Alt Inst tests
local b_controls reg2 reg3 reg4 
local extra_controls mfg_lfshare1940 mean_income_1940 cz_popdens1940


use "$CLEANDATA/cz_pooled", clear

foreach outcome in cgoodman schdist_ind spdist gen_town gen_muni totfrac{
    if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	preserve
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift_share_black_sob shift_share_base_stres shift_share_base_rur shift_share_base) `b_controls' `extra_controls' sumshare_base sumshare_base_stres sumshare_black_sob sumshare_base_rur [aw = popc1940], r partial(reg2 reg3 reg4)
		local hansenj : di %4.2f e(jp)
		
		global spec1 (GM_raw_pp = shift_share_base)  `b_controls'  `extra_controls' sumshare_base 
		global spec2 (GM_raw_pp = shift_share_base_stres)  `b_controls' `extra_controls' sumshare_base_stres 
		global spec3 (GM_raw_pp = shift_share_base_rur) `b_controls' `extra_controls'   sumshare_base_rur
		global spec4 (GM_raw_pp = shift_share_black_sob)  `b_controls' `extra_controls' sumshare_black_sob
		
		forval spec=1(1)4{
			tempfile spec`spec'
			parmby "ivreg2 n_`outcome'_cz_pc ${spec`spec'} [aw = popc1940], r partial(reg2 reg3 reg4)", lab saving(`"spec`spec'"', replace) idn(`l') ids(spec) ylabel 
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
		
		graph export "$FIGS/FA3_`outcome'.pdf", replace as(pdf)
	restore
}

