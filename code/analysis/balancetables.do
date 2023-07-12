

foreach samp in  total urban  {
	if "`samp'"=="urban" local poptab ""
	if "`samp'"=="total" local poptab "_totpop"
	if "`samp'"=="total_dcourt" local poptab "_totpop"

	if "`samp'"=="urban" local popname "c"
	if "`samp'"=="total" local popname ""
	if "`samp'"=="total_dcourt" local popname ""

	if "`samp'"=="urban" local poplab "Urban Population"
	if "`samp'"=="total" local poplab "Total Population"		
	if "`samp'"=="total_dcourt" local poplab "Total Population"		

	use "$CLEANDATA/cz_pooled", clear
	// Deeply silly thing that must be done for formatting reasons
	forv i=1/9{
		g d`i'=1
	}
	ren mfg_lfshare1940`poptab' mfg_lfshare
	ren blackmig3539_share`poptab' blackmig3539

	local covars mfg_lfshare blackmig3539 frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2 
	
	local pooled_covars_`samp'  ""
	foreach covar in `covars' {
		
		g GM`covar' = GM_hat_raw_pp`poptab'
		label var GM`covar' "`covar' on GM_hat"

		eststo `covar': reg `covar' GM`covar' reg2 reg3 reg4 d1 d2 d3 d4 d5 d6 d7 d8 d9 [aw=pop`popname'1940], r
		local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
		if `p'<=0.05{
			if !inlist("`covar'","mfg_lfshare", "blackmig3539") local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar' `covar'_m"
			if inlist("`covar'","mfg_lfshare", "blackmig3539") local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
		}
	}

	eststo pooled_`samp' : appendmodels `covars'

	
	
	
	foreach decade in 1940 1950 1960{
		use "$CLEANDATA/cz_stacked", clear
		ren blackmig3539_share`poptab' blackmig3539

		// Deeply silly thing that must be done for formatting reasons
		forv i=1/9{
			g d`i'=1
		}
		local stacked_covars_`decade' ""
		
		foreach covar in `covars' {
			g GM`covar' = GM_hat_raw_pp`poptab'
			label var GM`covar' "`covar' on GM_hat"

			local label : variable label `covar'
			label var GM_hat_raw_pp`poptab' "`label' on GM_hat"
			eststo `covar': reg `covar' GM`covar' reg2 reg3 reg4 d1 d2 d3 d4 d5 d6 d7 d8 d9 [aw=pop`popname'] if decade==`decade', r
			local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
			if `p'<=0.05{
				if !inlist("`covar'","mfg_lfshare", "blackmig3539") local stacked_covars_`decade'_`samp' "`stacked_covars_`decade'_`samp''  `covar' `covar'_m"
				if inlist("`covar'","mfg_lfshare", "blackmig3539") local stacked_covars_`decade'_`samp' "`stacked_covars_`decade'_`samp''  `covar'"
			}
		}
		eststo stacked_`decade'_`samp' : appendmodels `covars'
		
	}
	
	use "$CLEANDATA/cz_stacked", clear
	ren blackmig3539_share`poptab' blackmig3539

	tab decade, gen(d)

	local stacked_covars ""
	
	foreach covar in `covars' {
				g GM`covar' = GM_hat_raw_pp`poptab'

		label var GM`covar' "`covar' on GM_hat"
		eststo `covar': reg `covar' GM`covar' reg2 reg3 reg4 d1 d2 d3 d4 d5 d6 d7 d8 d9 [aw=pop`popname'], r
		local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
		if `p'<=0.05{
			if !inlist("`covar'","mfg_lfshare", "blackmig3539") local stacked_covars_`samp' "`stacked_covars_`samp'' `covar' `covar'_m"
			if inlist("`covar'","mfg_lfshare", "blackmig3539") local stacked_covars_`samp' "`stacked_covars_`samp'' `covar'"
		}
	}
	eststo stacked_`samp'  : appendmodels `covars'
	
	esttab pooled_`samp' stacked_1940_`samp' stacked_1950_`samp' stacked_1960_`samp' stacked_`samp' ///
					using "$TABS/balancetables/cz_`samp'.tex", ///
					replace label se booktabs noconstant noobs compress nonumber ///
										b(%03.2f) se(%03.2f) //////
					keep(GM*) ///
					mtitles("1940-1970 Pooled" "1940-1950" "1950-1960" "1960-1970" "Stacked") ///
					coeflabel(mfg_lfshare blackmig3539_share frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2)
					
	
	foreach outcome in schdist_ind cgoodman{
		eststo clear

		local controls reg2 reg3 reg4

		use "$CLEANDATA/cz_pooled", clear
		ren blackmig3539_share`poptab' blackmig3539

		// FS
		eststo pooled_fs_nc_`samp' : reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
		local F : di %6.2f e(F)
		estadd local Fstat = `F'
		
		// OLS
		eststo pooled_ols_nc_`samp' : reg n_`outcome'_cz_pc`popname' GM_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
		
		// RF
		eststo pooled_rf_nc_`samp' : reg n_`outcome'_cz_pc`popname' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
		
		// IV
		eststo pooled_iv_nc_`samp' : ivreg2 n_`outcome'_cz_pc`popname' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' [aw=pop`popname'1940], r
		
		use "$CLEANDATA/cz_stacked", clear
		ren blackmig3539_share`poptab' blackmig3539

		foreach decade in 1940 1950 1960{
			// FS
			eststo stacked`decade'_fs_nc_`samp' : reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940] if decade==`decade', r
			local F : di %6.2f e(F)
			estadd local Fstat = `F'
			
			// OLS
			eststo stacked`decade'_ols_nc_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_raw_pp`poptab' `controls' [aw=pop`popname'1940] if decade==`decade', r
			
			// RF
			eststo stacked`decade'_rf_nc_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940] if decade==`decade', r
			
			// IV
			eststo stacked`decade'_iv_nc_`samp' : ivreg2 n_`outcome'_cz_L0_pc`popname' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' [aw=pop`popname'1940] if decade==`decade', r
		}
		
		// FS
		eststo stacked_fs_nc_`samp' : reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' i.decade [aw=pop`popname'1940], r
		local F : di %6.2f e(F)
		estadd local Fstat = `F'
		
		// OLS
		eststo stacked_ols_nc_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_raw_pp`poptab' `controls' i.decade [aw=pop`popname'1940], r
		
		// RF
		eststo stacked_rf_nc_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_hat_raw_pp`poptab' `controls' i.decade [aw=pop`popname'1940], r
		
		// IV
		eststo stacked_iv_nc_`samp' : ivreg2 n_`outcome'_cz_L0_pc`popname' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' i.decade [aw=pop`popname'1940], r
		
		// With controls
		local controls reg2 reg3 reg4 `pooled_covars_`samp''

		use "$CLEANDATA/cz_pooled", clear
		ren mfg_lfshare1940`poptab' mfg_lfshare
		ren blackmig3539_share`poptab' blackmig3539

		// FS
		eststo pooled_fs_c_`samp' : reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
		local F : di %6.2f e(F)
		estadd local Fstat = `F'
		
		// OLS
		eststo pooled_ols_c_`samp' : reg n_`outcome'_cz_pc`popname' GM_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
		
		// RF
		eststo pooled_rf_c_`samp' : reg n_`outcome'_cz_pc`popname' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
		
		// IV
		eststo pooled_iv_c_`samp' : ivreg2 n_`outcome'_cz_pc`popname' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' [aw=pop`popname'1940], r
		
		use "$CLEANDATA/cz_stacked", clear
		ren blackmig3539_share`poptab' blackmig3539

		foreach decade in 1940 1950 1960{
			local controls reg2 reg3 reg4 `stacked_covars_`decade'_`samp''

			// FS
			eststo stacked`decade'_fs_c_`samp' : reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940] if decade==`decade', r
			local F : di %6.2f e(F)
			estadd local Fstat = `F'
			
			// OLS
			eststo stacked`decade'_ols_c_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_raw_pp`poptab' `controls' [aw=pop`popname'1940] if decade==`decade', r
			
			// RF
			eststo stacked`decade'_rf_c_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940] if decade==`decade', r
			
			// IV
			eststo stacked`decade'_iv_c_`samp' : ivreg2 n_`outcome'_cz_L0_pc`popname' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' [aw=pop`popname'1940] if decade==`decade', r
		}
		
		local controls reg2 reg3 reg4 `stacked_covars_`samp''
		// FS
		eststo stacked_fs_c_`samp' : reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' i.decade [aw=pop`popname'1940], r
		local F : di %6.2f e(F)
		estadd local Fstat = `F'
		
		// OLS
		eststo stacked_ols_c_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_raw_pp`poptab' `controls' i.decade [aw=pop`popname'1940], r
		
		// RF
		eststo stacked_rf_c_`samp' : reg n_`outcome'_cz_L0_pc`popname' GM_hat_raw_pp`poptab' `controls' i.decade [aw=pop`popname'1940], r
		
		// IV
		eststo stacked_iv_c_`samp' : ivreg2 n_`outcome'_cz_L0_pc`popname' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' i.decade [aw=pop`popname'1940], r
		
		// Panel A: First stage
		esttab 	pooled_fs_nc_`samp' ///
						stacked1940_fs_nc_`samp' ///
						stacked1950_fs_nc_`samp' ///
						stacked1960_fs_nc_`samp' ///
						stacked_fs_nc_`samp' ///
						pooled_fs_c_`samp' ///
						stacked1940_fs_c_`samp' ///
						stacked1950_fs_c_`samp' ///
						stacked1960_fs_c_`samp' ///
						stacked_fs_c_`samp' ///
						using "$TABS/balancetables/reg_`outcome'_`samp'.tex", ///
						replace se booktabs noconstant noobs compress frag ///
						b(%03.2f) se(%03.2f) ///
						modelwidth(10) ///
						mtitles("1940-1970 Pooled" "1940-1950" "1950-1960" "1960-1970" "Stacked" ///
						"1940-1970 Pooled" "1940-1950" "1950-1960" "1960-1970" "Stacked") ///
						starlevels( * 0.10 ** 0.05 *** 0.01) ///
						posthead("\cmidrule(lr){1-11}" "\multicolumn{10}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-11}" ) ///
						mgroups("Basic controls" "Robust controls", pattern(1 0 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
						prehead( \begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}  \begin{threeparttable} \caption{Outcome variable `outcome'}  \begin{tabular}{l*{11}{c}} \toprule) ///
						stats(F N, labels("F-Stat" "Observations")) ///
						keep(GM_hat_raw_pp`poptab')
						
	// Panel B: OLS
	esttab 	pooled_ols_nc_`samp' ///
					stacked1940_ols_nc_`samp' ///
					stacked1950_ols_nc_`samp' ///
					stacked1960_ols_nc_`samp' ///
					stacked_ols_nc_`samp' ///
					pooled_ols_c_`samp' ///
					stacked1940_ols_c_`samp' ///
					stacked1950_ols_c_`samp' ///
					stacked1960_ols_c_`samp' ///
					stacked_ols_c_`samp' ///
					using "$TABS/balancetables/reg_`outcome'_`samp'.tex", ///
					append se booktabs noconstant noobs compress frag nonum nomtitles ///
					b(%03.2f) se(%03.2f) ///
					modelwidth(10) ///
					starlevels( * 0.10 ** 0.05 *** 0.01) ///
					posthead("\cmidrule[\heavyrulewidth](lr){1-11} \\ \cmidrule[\heavyrulewidth](lr){1-11}" "\multicolumn{10}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-11}" ) ///
					keep(GM_raw_pp`poptab') stats(N, labels("Observations")) 

	
	// Panel C: Reduced Form
	esttab 	pooled_rf_nc_`samp' ///
					stacked1940_rf_nc_`samp' ///
					stacked1950_rf_nc_`samp' ///
					stacked1960_rf_nc_`samp' ///
					stacked_rf_nc_`samp' ///
					pooled_rf_c_`samp' ///
					stacked1940_rf_c_`samp' ///
					stacked1950_rf_c_`samp' ///
					stacked1960_rf_c_`samp' ///
					stacked_rf_c_`samp' ///
					using "$TABS/balancetables/reg_`outcome'_`samp'.tex", ///
					append se booktabs noconstant noobs compress frag nonum nomtitles ///
					b(%03.2f) se(%03.2f) ///
					modelwidth(10) ///
					starlevels( * 0.10 ** 0.05 *** 0.01) ///
					posthead("\cmidrule[\heavyrulewidth](lr){1-11} \\ \cmidrule[\heavyrulewidth](lr){1-11}" "\multicolumn{10}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-11}" ) ///
					keep(GM_hat_raw_pp`poptab') stats(N, labels("Observations")) 
	// Panel D: IV
	esttab 	pooled_iv_nc_`samp' ///
					stacked1940_iv_nc_`samp' ///
					stacked1950_iv_nc_`samp' ///
					stacked1960_iv_nc_`samp' ///
					stacked_iv_nc_`samp' ///
					pooled_iv_c_`samp' ///
					stacked1940_iv_c_`samp' ///
					stacked1950_iv_c_`samp' ///
					stacked1960_iv_c_`samp' ///
					stacked_iv_c_`samp' ///
					using "$TABS/balancetables/reg_`outcome'_`samp'.tex", ///
					append se booktabs noconstant noobs compress frag nonum nomtitles ///
					b(%03.2f) se(%03.2f) ///
					modelwidth(10) ///
					starlevels( * 0.10 ** 0.05 *** 0.01) ///
					posthead("\cmidrule[\heavyrulewidth](lr){1-11} \\ \cmidrule[\heavyrulewidth](lr){1-11}" "\multicolumn{10}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-11}" ) ///
					keep(GM_raw_pp`poptab') ///
					postfoot(	\hline\hline \end{tabular}{\caption*{\begin{scriptsize} "Columns 1-4 include region fixed effects, column 5 includes region and decade fixed effects. Columns 6-7 include region fixed effects and all significant covariates from the corresponding balance table. Column 10 includes region and decade fixed effects and all significant covariates from the corresponding balance table. \(p<0.10\), ** \(p<0.05\), *** \(p<0.01\)"\end{scriptsize}}} \end{threeparttable} \end{table}) stats(N, labels("Observations")) 

	}
}
		
		
