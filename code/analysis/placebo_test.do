
local use_sumshare = 1
local use_pct_inst = 1


// Controls
if `use_sumshare' == 0 local b_controls reg2 reg3 reg4 blackmig3539_share 
if `use_sumshare' == 1 local b_controls reg2 reg3 reg4 v2_sumshares_urban 


if `use_sumshare' == 0 & `use_pct_inst' == 0 local extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local extra_controls coastal transpo_cost_1920
if `use_sumshare' == 1 & `use_pct_inst' == 1 local extra_controls coastal transpo_cost_1920

// Inst
if `use_pct_inst' == 0 local inst GM_hat_raw_pp
if `use_pct_inst' == 1 local inst GM_hat_raw

foreach outcome in cgoodman schdist_ind spdist gen_town gen_muni totfrac{
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
	qui parmby "reg n_`outcome'_cz_pc GM_hat_raw_r`i' `b_controls' [aw=popc1940], r", lab saving(`"vr`i'`outcome'"', replace) idn(`i') ids(vr) ylabel rename(idn vrsn) level(95 99)
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
	
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	g significant99=((min99<0 & max99<0) | (min99>0 & max99>0))
	qui sum significant95
	local psig95 : di %4.2f r(mean)*100
	qui sum significant99
	local psig99 : di %4.2f r(mean)*100	
	twoway scatter estimate vrsn if ids=="vr", msymbol(Dh) mcolor(jmpgreen) legend(label(1 "Placebos")) ///
			|| rcap min95 max95 vrsn if ids=="vr", lcolor(jmpgreen%20) ///
			graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(on order(1 2 3) rows(1) ring(0) position(5) ) /// 
			yline(0, lcolor(black)) xsc(range(1(100)1000)) ///
			 ytitle("") title("`outlab'") ///
			caption( "% significant at the 5% level = `psig95'" "% significant at the 1% level = `psig99'")
			
	
	
	graph export "$FIGS/exogeneity_tests/D17_placebo_`outcome'.pdf", replace as(pdf)	
}


foreach outcome in cgoodman schdist_ind spdist gen_town gen_muni totfrac{
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
	qui parmby "reg n_`outcome'_cz_pc GM_hat_raw_r`i' `b_controls' `extra_controls' [aw=popc1940], r", lab saving(`"vr`i'`outcome'"', replace) idn(`i') ids(vr) ylabel rename(idn vrsn) level(95 99)
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
	
	g significant95=((min95<0 & max95<0) | (min95>0 & max95>0))
	g significant99=((min99<0 & max99<0) | (min99>0 & max99>0))
	qui sum significant95
	local psig95 : di %4.2f r(mean)*100
	qui sum significant99
	local psig99 : di %4.2f r(mean)*100	
	twoway scatter estimate vrsn if ids=="vr", msymbol(Dh) mcolor(jmpgreen) legend(label(1 "Placebos")) ///
			|| rcap min95 max95 vrsn if ids=="vr", lcolor(jmpgreen%20) ///
			graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(on order(1 2 3) rows(1) ring(0) position(5) ) /// 
			yline(0, lcolor(black)) xsc(range(1(100)1000)) ///
			 ytitle("") title("`outlab'") ///
			caption( "% significant at the 5% level = `psig95'" "% significant at the 1% level = `psig99'")
			
	
	
	graph export "$FIGS/exogeneity_tests/D17_placebo_`outcome'_new_ctrls.pdf", replace as(pdf)
}