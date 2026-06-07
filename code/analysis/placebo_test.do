
local use_sumshare = 1
local use_pct_inst = 1


// Controls




local b_controls reg2 reg3 reg4 sumshare_base 


local extra_controls mfg_lfshare1940 mean_income_1940 cz_popdens1940

foreach outcome in cgoodman schdist_ind spdist gen_town gen_muni totfrac {
	if "`outcome'"=="cgoodman" local outlab "C. Goodman municipalities" 
	if "`outcome'"=="gen_muni" local outlab "CoG municipalities" 
	if "`outcome'"=="schdist_ind" local outlab "School districts" 
	if "`outcome'"=="gen_town" local outlab "Townships" 
	if "`outcome'"=="spdist" local outlab "Special districts" 
	if "`outcome'"=="totfrac" local outlab "Main City Share" 
	
	use "$CLEANDATA/cz_pooled", clear

	forval i = 1/1000{
	tempfile vr`i'
	capture confirm variable GM_hat_raw_r`i'
	if !_rc{
	 parmby "reg n_`outcome'_cz_pc GM_hat_raw_r`i' `b_controls' `extra_controls' [aw=popc1940], r", lab saving(`"vr`i'`outcome'"', replace) idn(`i') ids(vr) ylabel rename(idn vrsn) level(90 95 99)
	}
	}
	
	drop _all
	
	forval i=1/1000 {
	capture append using "vr`i'`outcome'"
	erase "vr`i'`outcome'.dta"
	}
	
	la var vrsn "Version"
	keep if parmseq==1
	
	tempfile `outcome'_versions
	save ``outcome'_versions'
		
	use ``outcome'_versions', clear 
	g significant90=((min90<0 & max90<0) | (min90>0 & max90>0))
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	g significant99=((min99<0 & max99<0) | (min99>0 & max99>0))
	qui sum significant90
	local psig90 : di %4.2f r(mean)*100
	qui sum significant95
	local psig95 : di %4.2f r(mean)*100
	qui sum significant99
	local psig99 : di %4.2f r(mean)*100	
	twoway scatter estimate vrsn if ids=="vr", msymbol(Dh) mcolor(jmpgreen) legend(label(1 "Placebos")) ///
			|| rcap min95 max95 vrsn if ids=="vr", lcolor(jmpgreen%20) ///
			graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(on order(1 2 3) rows(1) ring(0) position(5) ) /// 
			yline(0, lcolor(black)) xsc(range(1(100)1000)) ///
			 ytitle("") title("`outlab'") ///
			caption("% significant at the 10% level = `psig90'" "% significant at the 5% level = `psig95'" "% significant at the 1% level = `psig99'")
			
	
	
	graph export "$FIGS/exogeneity_tests/D17_placebo_`outcome'_new_ctrls.pdf", replace as(pdf)
}

