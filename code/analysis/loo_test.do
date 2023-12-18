local b_controls reg2 reg3 reg4 blackmig3539_share
local extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total


foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	use "$CLEANDATA/cz_pooled", clear
	labmask cz, values(cz_name)
	keep if dcourt == 1

	// Getting full sample values
	// RF
	reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls'  [aw=popc1940], r
	local b_rf = _b[GM_hat_raw_pp]
	local se_rf = _se[GM_hat_raw_pp]
	
	ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls'  [aw=popc1940], r
	local b_iv = _b[GM_raw_pp]
	local se_iv = _se[GM_raw_pp]
	levelsof cz, local(czs)
	
	foreach cz in `czs'{
		qui parmby "reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls'  [aw=popc1940] if cz!=`cz', r", lab saving(`"rf`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(95 99)
		
		qui parmby "ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls'  [aw=popc1940] if cz!=`cz', r", lab saving(`"iv`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(95 99)
		
	}
	clear
	
	foreach cz in `czs'{
		append using "rf`cz'`outcome'"
		erase "rf`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	count if significant95==1
	local n = r(N)
	di "RF outcome `outcome' insig CZs: "
	tab vrsn if  significant95==0
	twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min95 max95 x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_rf', lcolor(red) lstyle(dash))  ///
		caption( "`n' out of 130 significant at the 0.05 level" "Red line indicates full sample point estimate")
		
	graph export "$FIGS/exogeneity_tests/loo_rf_`outcome'.pdf", replace as(pdf)	

	clear
	foreach cz in `czs'{
		append using "iv`cz'`outcome'"
		erase "iv`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	count if significant95==1
	local n = r(N)
	
	di "2SLS outcome `outcome' insig CZs: "
	tab vrsn if  significant95==0
		twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min95 max95 x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_iv', lcolor(red) lstyle(dash)) ///
		caption( "`n' out of 130 significant at the 0.05 level" "Red line indicates full sample point estimate")
		graph export "$FIGS/exogeneity_tests/loo_iv_`outcome'.pdf", replace as(pdf)

}



foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	use "$CLEANDATA/cz_pooled", clear
	labmask cz, values(cz_name)
	keep if dcourt == 1

	// Getting full sample values
	// RF
	reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls' `extra_controls'  [aw=popc1940], r
	local b_rf = _b[GM_hat_raw_pp]
	local se_rf = _se[GM_hat_raw_pp]
	
	ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' `extra_controls'  [aw=popc1940], r
	local b_iv = _b[GM_raw_pp]
	local se_iv = _se[GM_raw_pp]
	levelsof cz, local(czs)
	
	foreach cz in `czs'{
		qui parmby "reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls' `extra_controls' [aw=popc1940] if cz!=`cz', r", lab saving(`"rf`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(95 99)
		
		qui parmby "ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' `extra_controls' [aw=popc1940] if cz!=`cz', r", lab saving(`"iv`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(95 99)
		
	}
	clear
	
	foreach cz in `czs'{
		append using "rf`cz'`outcome'"
		erase "rf`cz'`outcome'.dta"
	}
	keep if parmseq==1
	g x = _n
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	count if significant95==1
	local n = r(N)
	di "RF outcome `outcome' insig CZs: "
	tab vrsn if  significant95==0
	twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min95 max95 x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_rf', lcolor(red) lstyle(dash))  ///
		caption( "`n' out of 130 significant at the 0.05 level" "Red line indicates full sample point estimate")
		
	graph export "$FIGS/exogeneity_tests/loo_rf_`outcome'_new_ctrls.pdf", replace as(pdf)	

	clear
	foreach cz in `czs'{
		append using "iv`cz'`outcome'"
		erase "iv`cz'`outcome'.dta"	
	}
	keep if parmseq==1
	g x = _n
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	count if significant95==1
	local n = r(N)
	
	di "2SLS outcome `outcome' insig CZs: "
	tab vrsn if  significant95==0
		twoway scatter estimate x , mcolor(jmpgreen) ///
	|| rcap min95 max95 x, lcolor(jmpgreen%50)  ///
	 yline(0, lcolor(black)) ///
	xsc(range(1(10)131)) xla(none) xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(rows(2)) ///
	yline(`b_iv', lcolor(red) lstyle(dash)) ///
		caption( "`n' out of 130 significant at the 0.05 level" "Red line indicates full sample point estimate")
		graph export "$FIGS/exogeneity_tests/loo_iv_`outcome'_new_ctrls.pdf", replace as(pdf)	

}