local b_controls reg2 reg3 reg4 v2_sumshares_urban
local extra_controls transpo_cost_1920 coastal

foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	
	if "`outcome'"=="cgoodman" local siglevel 90
	if "`outcome'"!="cgoodman" local siglevel 95
	
	use "$CLEANDATA/cz_pooled", clear
	labmask cz, values(cz_name)
	keep if dcourt == 1

	// Getting full sample values
	// RF
	reg n_`outcome'_cz_pc GM_hat_raw `b_controls'  [aw=popc1940], r
	local b_rf = _b[GM_hat_raw]
	local se_rf = _se[GM_hat_raw]
	
	ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw) `b_controls'  [aw=popc1940], r
	local b_iv = _b[GM_raw_pp]
	local se_iv = _se[GM_raw_pp]
	levelsof cz, local(czs)
	
	foreach cz in `czs'{
		qui parmby "reg n_`outcome'_cz_pc GM_hat_raw `b_controls'  [aw=popc1940] if cz!=`cz', r", lab saving(`"rf`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(`siglevel')
		
		qui parmby "ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw) `b_controls'  [aw=popc1940] if cz!=`cz', r", lab saving(`"iv`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(`siglevel')
		
	}
	clear
	
	foreach cz in `czs'{
		append using "rf`cz'`outcome'"
		erase "rf`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant=((min`siglevel'<0 & max`siglevel'<0) | (min`siglevel'>0 & max`siglevel'>0))
	count if significant==1
	local n = r(N)
	di "RF outcome `outcome' insig CZs: "
	tab vrsn if  significant==0
	twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min`siglevel' max`siglevel' x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_rf', lcolor(red) lstyle(dash)) title("`outlab'") ///
		caption( "`n' out of 130 significant at the `siglevel'% level" "Red line indicates full sample point estimate")
		
	graph export "$FIGS/exogeneity_tests/loo_rf_`outcome'.pdf", replace as(pdf)	

	clear
	foreach cz in `czs'{
		append using "iv`cz'`outcome'"
		erase "iv`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant=((min`siglevel'<0 & max`siglevel'<0) | (min`siglevel'>0 & max`siglevel'>0))
	count if significant==1
	local n = r(N)
	
	di "2SLS outcome `outcome' insig CZs: "
	tab vrsn if  significant==0
		twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min`siglevel' max`siglevel' x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_iv', lcolor(red) lstyle(dash)) title("`outlab'") ///
		caption( "`n' out of 130 significant at the `siglevel'% level" "Red line indicates full sample point estimate")
		graph export "$FIGS/exogeneity_tests/loo_iv_`outcome'.pdf", replace as(pdf)

}



foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	
	if "`outcome'"=="cgoodman" local siglevel 90
	if "`outcome'"!="cgoodman" local siglevel 95
	
	use "$CLEANDATA/cz_pooled", clear
	labmask cz, values(cz_name)
	keep if dcourt == 1

	// Getting full sample values
	// RF
	reg n_`outcome'_cz_pc GM_hat_raw `b_controls' `extra_controls' [aw=popc1940], r
	local b_rf = _b[GM_hat_raw]
	local se_rf = _se[GM_hat_raw]
	
	ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw) `b_controls' `extra_controls' [aw=popc1940], r
	local b_iv = _b[GM_raw_pp]
	local se_iv = _se[GM_raw_pp]
	levelsof cz, local(czs)
	
	foreach cz in `czs'{
		qui parmby "reg n_`outcome'_cz_pc GM_hat_raw `b_controls' `extra_controls' [aw=popc1940] if cz!=`cz', r", lab saving(`"rf`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(`siglevel')
		
		qui parmby "ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw) `b_controls'  `extra_controls'[aw=popc1940] if cz!=`cz', r", lab saving(`"iv`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(`siglevel')
		
	}
	clear
	
	foreach cz in `czs'{
		append using "rf`cz'`outcome'"
		erase "rf`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant=((min`siglevel'<0 & max`siglevel'<0) | (min`siglevel'>0 & max`siglevel'>0))
	count if significant==1
	local n = r(N)
	di "RF outcome `outcome' insig CZs: "
	tab vrsn if  significant==0
	twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min`siglevel' max`siglevel' x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_rf', lcolor(red) lstyle(dash)) title("`outlab'") ///
		caption( "`n' out of 130 significant at the `siglevel'% level" "Red line indicates full sample point estimate")
		
	graph export "$FIGS/exogeneity_tests/loo_rf_`outcome'_new_ctrls.pdf", replace as(pdf)	

	clear
	foreach cz in `czs'{
		append using "iv`cz'`outcome'"
		erase "iv`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant=((min`siglevel'<0 & max`siglevel'<0) | (min`siglevel'>0 & max`siglevel'>0))
	count if significant==1
	local n = r(N)
	
	di "2SLS outcome `outcome' insig CZs: "
	tab vrsn if  significant==0
		twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min`siglevel' max`siglevel' x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_iv', lcolor(red) lstyle(dash)) title("`outlab'") ///
		caption( "`n' out of 130 significant at the `siglevel'% level" "Red line indicates full sample point estimate")
		graph export "$FIGS/exogeneity_tests/loo_iv_`outcome'_new_ctrls.pdf", replace as(pdf)

}