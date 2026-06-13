

foreach int in links diff{
	if "`int'"=="links" local intvar above_med_occscore_3040
	if "`int'"=="diff" local intvar above_med_occscore_diff
	if "`int'"=="links" local outlab "TA21"
	if "`int'"=="diff" local outlab "TA22"

	local controls reg2 reg3 reg4 mfg_lfshare1940 cz_popdens1940 mean_income_1940 sumshare_base sumshare_base_int `intvar'
	/* Now interacted with the chosen variable */
	// Generate interacted shares
	use "$INTDATA/ssaggregate_prep/shares_base.dta", clear
	merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(`intvar')

	gen share_int = share * `intvar'
	drop share `intvar'
	save "$INTDATA/ssaggregate_prep/shares_base_int.dta", replace

	// Run the interacted regression
	use "$CLEANDATA/cz_pooled", clear


	g x = GM_raw_pp
	g z = shift_share_base

	gen x_int = x * `intvar' 
	gen z_int = z * `intvar'
	gen sumshare_base_int = sumshare_base * `intvar'


	g y = .


	foreach outcome in cgoodman  spdist gen_muni totfrac schdist_ind{
		replace y = n_`outcome'_cz_pc
		su y if `intvar' == 0
		
		// First stage 1
		reg x z z_int `controls' [aw=popc1940] if !mi(n_`outcome'_cz_pc),r
		local b_fs1_x_`int'_`outcome' = e(b)[1,1]
		local se_fs1_x_`int'_`outcome' = e(V)[1,1]^0.5
		local b_fs1_x_int_`int'_`outcome' = e(b)[1,2]
		local se_fs1_x_int_`int'_`outcome' = e(V)[2,2]^0.5
		test z = 0
		local F1_`int'_`outcome' : di %6.2f r(F)

		// First stage 2
		reg x_int z z_int `controls' [aw=popc1940] if !mi(n_`outcome'_cz_pc),r
		local b_fs2_x_`int'_`outcome' = e(b)[1,1]
		local se_fs2_x_`int'_`outcome' = e(V)[1,1]^0.5
		local b_fs2_x_int_`int'_`outcome' = e(b)[1,2]
		local se_fs2_x_int_`int'_`outcome' = e(V)[2,2]^0.5
		test z_int = 0
		local F2_`int'_`outcome' : di %6.2f r(F)
		
		ivreg2 y (x x_int = z z_int) `controls' [aw = popc1940], r first
		local SWF1_`int'_`outcome' : di %6.2f e(first)[8,1]
		local SWF2_`int'_`outcome' : di %6.2f e(first)[8,2]
		local KPWF_`int'_`outcome' : di %04.2f e(widstat)
		
		// OLS 1940-70
		reg y x x_int `controls' [aw = popc1940], r
		local b_o70_x_`int'_`outcome' =  e(b)[1,1]
		local b_o70_x_int_`int'_`outcome' = e(b)[1,2]
		local se_o70_x_`int'_`outcome' = e(V)[1,1]^0.5
		local se_o70_x_int_`int'_`outcome' = e(V)[2,2]^0.5
		local nobs_`int'_`outcome' =  string(e(N),"%9.0f")
		su y if `intvar' == 0
		local mean70_`int'_`outcome' = string(r(mean),"%9.3f")
		
		// Long differences 
		replace y = ld_`outcome'_cz_pc
		// OLS 1940-70
		reg y x x_int `controls' [aw = popc1940], r
		local b_o10_x_`int'_`outcome' =  e(b)[1,1]
		local b_o10_x_int_`int'_`outcome' = e(b)[1,2]
		local se_o10_x_`int'_`outcome' = e(V)[1,1]^0.5
		local se_o10_x_int_`int'_`outcome' = e(V)[2,2]^0.5
		su y if `intvar' == 0
		local mean10_`int'_`outcome' = string(r(mean),"%9.3f")

	}
	
		
	foreach m in fs1 fs2 o70 o10 {
		foreach v in x x_int{
			foreach outcome in cgoodman spdist gen_muni totfrac schdist_ind{
				di "HERE"
				local z = abs(scalar(`b_`m'_`v'_`int'_`outcome'') / scalar(`se_`m'_`v'_`int'_`outcome''))
				di "`z'"
				local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
				di "`n_stars'"
				local b_`m'_`v'_`int'_`outcome' = string(`b_`m'_`v'_`int'_`outcome'',"%9.3f") + "`n_stars'"
				local se_`m'_`v'_`int'_`outcome' = string(`se_`m'_`v'_`int'_`outcome'',"%9.3f") 
			}
		}
	}





	capture file close fh
	file open fh using "$TABS/`outlab'.tex", write replace
	file write fh "\begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}" _n

	 
	file write fh "&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" _n

	file write fh "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" _n

	file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" _n
	file write fh "\cmidrule(lr){1-6}" _n

	file write fh "\multicolumn{5}{l}{Panel A: First Stage $\widehat{GM}$}\\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh  "GM  &    `b_fs1_x_`int'_cgoodman' &    `b_fs1_x_`int'_gen_muni' &    `b_fs1_x_`int'_schdist_ind' &    `b_fs1_x_`int'_spdist' &    `b_fs1_x_`int'_totfrac' \\" _n
	file write fh "                &  (`se_fs1_x_`int'_cgoodman')  &  (`se_fs1_x_`int'_gen_muni')  &  (`se_fs1_x_`int'_schdist_ind')  &  (`se_fs1_x_`int'_spdist')  &  (`se_fs1_x_`int'_totfrac')  \\" _n
	file write fh  "GM X Above Median  &    `b_fs1_x_int_`int'_cgoodman' &    `b_fs1_x_int_`int'_gen_muni' &    `b_fs1_x_int_`int'_schdist_ind' &    `b_fs1_x_int_`int'_spdist' &    `b_fs1_x_int_`int'_totfrac' \\" _n
	file write fh "                &  (`se_fs1_x_int_`int'_cgoodman')  &  (`se_fs1_x_int_`int'_gen_muni')  &  (`se_fs1_x_int_`int'_schdist_ind')  &  (`se_fs1_x_int_`int'_spdist')  &  (`se_fs1_x_int_`int'_totfrac')  \\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh "F-Stat & `F1_`int'_cgoodman' & `F1_`int'_gen_muni' & `F1_`int'_schdist_ind' & `F1_`int'_spdist' & `F1_`int'_totfrac' \\" _n
	file write fh "S.W. F-Stat & `SWF1_`int'_cgoodman' & `SWF1_`int'_gen_muni' & `SWF1_`int'_schdist_ind' & `SWF1_`int'_spdist' & `SWF1_`int'_totfrac' \\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh "\multicolumn{5}{l}{Panel B: First Stage $\widehat{GM}$ X Above Median}\\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh  "GM  &    `b_fs2_x_`int'_cgoodman' &    `b_fs2_x_`int'_gen_muni' &    `b_fs2_x_`int'_schdist_ind' &    `b_fs2_x_`int'_spdist' &    `b_fs2_x_`int'_totfrac' \\" _n
	file write fh "                &  (`se_fs2_x_`int'_cgoodman')  &  (`se_fs2_x_`int'_gen_muni')  &  (`se_fs2_x_`int'_schdist_ind')  &  (`se_fs2_x_`int'_spdist')  &  (`se_fs2_x_`int'_totfrac')  \\" _n
	file write fh  "GM X Above Median  &    `b_fs2_x_int_`int'_cgoodman' &    `b_fs2_x_int_`int'_gen_muni' &    `b_fs2_x_int_`int'_schdist_ind' &    `b_fs2_x_int_`int'_spdist' &    `b_fs2_x_int_`int'_totfrac' \\" _n
	file write fh "                &  (`se_fs2_x_int_`int'_cgoodman')  &  (`se_fs2_x_int_`int'_gen_muni')  &  (`se_fs2_x_int_`int'_schdist_ind')  &  (`se_fs2_x_int_`int'_spdist')  &  (`se_fs2_x_int_`int'_totfrac')  \\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh "F-Stat & `F2_`int'_cgoodman' & `F2_`int'_gen_muni' & `F2_`int'_schdist_ind' & `F2_`int'_spdist' & `F2_`int'_totfrac' \\" _n
	file write fh "S.W. F-Stat & `SWF2_`int'_cgoodman' & `SWF2_`int'_gen_muni' & `SWF2_`int'_schdist_ind' & `SWF2_`int'_spdist' & `SWF2_`int'_totfrac' \\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh "K.P. F-Stat & `KPWF_`int'_cgoodman' & `KPWF_`int'_gen_muni' & `KPWF_`int'_schdist_ind' & `KPWF_`int'_spdist' & `KPWF_`int'_totfrac' \\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh "\multicolumn{5}{l}{Panel C: OLS 1940-1970}\\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh  "GM  &    `b_o70_x_`int'_cgoodman' &    `b_o70_x_`int'_gen_muni' &    `b_o70_x_`int'_schdist_ind' &    `b_o70_x_`int'_spdist' &    `b_o70_x_`int'_totfrac' \\" _n
	file write fh "                &  (`se_o70_x_`int'_cgoodman')  &  (`se_o70_x_`int'_gen_muni')  &  (`se_o70_x_`int'_schdist_ind')  &  (`se_o70_x_`int'_spdist')  &  (`se_o70_x_`int'_totfrac')  \\" _n
	file write fh  "GM X Above Median  &    `b_o70_x_int_`int'_cgoodman' &    `b_o70_x_int_`int'_gen_muni' &    `b_o70_x_int_`int'_schdist_ind' &    `b_o70_x_int_`int'_spdist' &    `b_o70_x_int_`int'_totfrac' \\" _n
	file write fh "                &  (`se_o70_x_int_`int'_cgoodman')  &  (`se_o70_x_int_`int'_gen_muni')  &  (`se_o70_x_int_`int'_schdist_ind')  &  (`se_o70_x_int_`int'_spdist')  &  (`se_o70_x_int_`int'_totfrac')  \\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh "\multicolumn{5}{l}{Panel D: OLS 1940-2010}\\" _n
	file write fh "\cmidrule(lr){1-6}" _n
	file write fh  "GM  &    `b_o10_x_`int'_cgoodman' &    `b_o10_x_`int'_gen_muni' &    `b_o10_x_`int'_schdist_ind' &    `b_o10_x_`int'_spdist' &    `b_o10_x_`int'_totfrac' \\" _n
	file write fh "                &  (`se_o10_x_`int'_cgoodman')  &  (`se_o10_x_`int'_gen_muni')  &  (`se_o10_x_`int'_schdist_ind')  &  (`se_o10_x_`int'_spdist')  &  (`se_o10_x_`int'_totfrac')  \\" _n
	file write fh  "GM X Above Median  &    `b_o10_x_int_`int'_cgoodman' &    `b_o10_x_int_`int'_gen_muni' &    `b_o10_x_int_`int'_schdist_ind' &    `b_o10_x_int_`int'_spdist' &    `b_o10_x_int_`int'_totfrac' \\" _n
	file write fh "                &  (`se_o10_x_int_`int'_cgoodman')  &  (`se_o10_x_int_`int'_gen_muni')  &  (`se_o10_x_int_`int'_schdist_ind')  &  (`se_o10_x_int_`int'_spdist')  &  (`se_o10_x_int_`int'_totfrac')  \\" _n
	file write fh "\cmidrule(lr){1-6}" _n

	file write fh "Below Median 1940-70 Avg. &      `mean70_`int'_cgoodman'   &      `mean70_`int'_gen_muni'   &      `mean70_`int'_schdist_ind'   &      `mean70_`int'_spdist'   &      `mean70_`int'_totfrac'   \\" _n
	file write fh "Below Median 1940-2010 Avg. &      `mean10_`int'_cgoodman'   &      `mean10_`int'_gen_muni'   &      `mean10_`int'_schdist_ind'   &      `mean10_`int'_spdist'   &      `mean10_`int'_totfrac'   \\" _n
	file write fh "Observations    &      `nobs_`int'_cgoodman'   &      `nobs_`int'_gen_muni'   &      `nobs_`int'_schdist_ind'   &      `nobs_`int'_spdist'   &      `nobs_`int'_totfrac'   \\" _n

	file write fh "\bottomrule \end{tabularx}" _n


	file close fh
}