local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls mfg_lfshare1940 mean_income_1940 cz_popdens1940

foreach outcome in spdist cgoodman gen_muni schdist_ind gen_town spdist totfrac{
	if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	
	
	use "$CLEANDATA/cz_pooled", clear
	labmask cz, values(cz_name)

	// Getting full sample values
	// RF
	reg n_`outcome'_cz_pc shift_share_base `b_controls' `extra_controls' [aw=popc1940], r
	local b_rf = _b[shift_share_base]
	local se_rf = _se[shift_share_base]
	
	preserve
		ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`b_controls' `extra_controls'") s(share)
			
		merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw=s_n]
		local b_iv = _b[GM_raw_pp]
		local se_iv = _se[GM_raw_pp]
	restore
	
	levelsof cz, local(czs)
	
	foreach cz in `czs'{
		
		qui parmby "reg n_`outcome'_cz_pc shift_share_base `b_controls' `extra_controls' [aw=popc1940] if cz!=`cz', r", lab saving(`"rf`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(90 95 99)
		
		local xlab : variable label shift_share_base

		preserve 
			drop if cz == `cz'
			ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`b_controls' `extra_controls'") s(share)
			
			merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
			replace shift = 0 if mi(shift)
			lab var shift "`xlab'"
			
			qui parmby "ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw=s_n]", lab saving(`"iv`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(90 95 99)
		restore
		
	}
	clear
	
	foreach cz in `czs'{
		append using "rf`cz'`outcome'"
		erase "rf`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	local n = _N
	g significant90=((min90<0 & max90<0) | (min90>0 & max90>0))
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	g significant99=((min99<0 & max99<0) | (min99>0 & max99>0))
	count if significant90==1
	local n90 = r(N)
	count if significant95==1
	local n95 = r(N)
	count if significant99==1
	local n99 = r(N)

	
	
	di "RF outcome `outcome' insig CZs: "
	twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min95 max95 x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_rf', lcolor(red) lstyle(dash)) title("`outlab'") ///
		caption("`n90' out of `n' significant at the 90% level" "`n95' out of `n' significant at the 95% level" "`n99' out of `n' significant at the 99% level" "Red line indicates full sample point estimate")
		
	graph export "$FIGS/exogeneity_tests/loo_rf_`outcome'_new_ctrls.pdf", replace as(pdf)	

	clear
	foreach cz in `czs'{
		append using "iv`cz'`outcome'"
		erase "iv`cz'`outcome'.dta"
	}
	g x = _n
	keep if parmseq==1
	local n = _N
	g significant90=((min90<0 & max90<0) | (min90>0 & max90>0))
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	g significant99=((min99<0 & max99<0) | (min99>0 & max99>0))
	count if significant90==1
	local n90 = r(N)
	count if significant95==1
	local n95 = r(N)
	count if significant99==1
	local n99 = r(N)

	
	di "2SLS outcome `outcome' insig CZs: "
		twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min95 max95 x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_iv', lcolor(red) lstyle(dash)) title("`outlab'") ///
		caption("`n90' out of `n' significant at the 90% level" "`n95' out of `n' significant at the 95% level" "`n99' out of `n' significant at the 99% level" "Red line indicates full sample point estimate")

		graph export "$FIGS/exogeneity_tests/loo_iv_`outcome'_new_ctrls.pdf", replace as(pdf)

}
