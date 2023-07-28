local b_controls reg2 reg3 reg4 blackmig3539_share


foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{
	use "$CLEANDATA/cz_pooled", clear
	labmask cz, values(cz_name)
	keep if dcourt == 1

	// Getting full sample values
	// RF
	reg n_`outcome'_cz_pcc GM_hat_raw_pp `b_controls' [aw=popc1940], r
	local b_rf = _b[GM_hat_raw_pp]
	local se_rf = _se[GM_hat_raw_pp]
	
	ivreg2 n_`outcome'_cz_pcc (GM_raw_pp = GM_hat_raw_pp) `b_controls' [aw=popc1940], r
	local b_iv = _b[GM_raw_pp]
	local se_iv = _se[GM_raw_pp]
	levelsof cz, local(czs)
	
	foreach cz in `czs'{
		qui parmby "reg n_`outcome'_cz_pcc GM_hat_raw_pp `b_controls' [aw=popc1940] if cz!=`cz', r", lab saving(`"rf`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(95 99)
		
		qui parmby "ivreg2 n_`outcome'_cz_pcc (GM_raw_pp = GM_hat_raw_pp) `b_controls' [aw=popc1940] if cz!=`cz', r", lab saving(`"iv`cz'`outcome'"', replace) idn(`cz') ids(vr) ylabel rename(idn vrsn) level(95 99)
		
	}
	clear
	
	foreach cz in `czs'{
		append using "rf`cz'`outcome'"
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
	yline(`b_rf', lcolor(red) lstyle(dash)) title("Reduced form LOO, outcome `outcome'") ///
		caption( "`n' out of 130 significant at the 0.05 level" "Red line indicates full sample point estimate")
		
	graph export "$FIGS/exogeneity_tests/loo_rf_`outcome'.png", replace 	

	clear
	foreach cz in `czs'{
		append using "iv`cz'`outcome'"
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
	yline(`b_iv', lcolor(red) lstyle(dash)) title("2SLS LOO, outcome `outcome'") ///
		caption( "`n' out of 130 significant at the 0.05 level" "Red line indicates full sample point estimate")
		graph export "$FIGS/exogeneity_tests/loo_iv_`outcome'.png", replace 	

}