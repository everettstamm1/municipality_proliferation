

local b_controls reg2 reg3 reg4 blackmig3539
local balance_cutoff = 0.05
local samp = "urban"
foreach geog in full{
	if "`geog'"=="full" local samplab ""
	if "`geog'"=="1" local samplab "Northeast Region"
	if "`geog'"=="2" local samplab "Midwest Region"
	if "`geog'"=="3" local samplab "South Region"
	if "`geog'"=="4" local samplab "West Region"

	if "`geog'"=="full" local geoglab ""
	if "`geog'"!="full" local geoglab "_reg`geog'"
		

	use "$CLEANDATA/cz_pooled", clear

	if "`geog'"!="full" keep if region==`geog'



	// Deeply silly thing that must be done for formatting reasons
	forv i=1/9{
		g d`i'=1
	}
	ren mfg_lfshare1940 mfg_lfshare
	ren blackmig3539_share blackmig3539

	local covars ln_pop_dens1940 urban_share1940 mfg_lfshare b_gen_muni_cz1940_pc b_schdist_ind_cz1940_pc  b_spdist_cz1940_pc b_gen_town_cz1940_pc b_cgoodman_cz1940_pc frac_land transpo_cost_1920 coastal avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2 popc1940 pop1940
	
	local pooled_covars_`samp'  ""
	foreach covar in `covars' {
		
		g GM`covar' = GM_hat_raw_pp
		label var GM`covar' "`covar' on GM_hat"

		eststo `covar': reg `covar' GM`covar' `b_controls' d1 d2 d3 d4 d5 d6 d7 d8 d9 [aw=popc1940], r
		local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
		if `p'<=`balance_cutoff'{
			if (!inlist("`covar'","mfg_lfshare", "blackmig3539", "popc1940","pop1940") & !regexm("`covar'","cz1940_pc")) local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar' `covar'_m"
			if (inlist("`covar'","mfg_lfshare", "blackmig3539", "popc1940","pop1940") | regexm("`covar'","cz1940_pc")) local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
		}
	}

	eststo pooled_`samp' : appendmodels `covars'

	
	
	
	foreach decade in 1940 1950 1960{
		use "$CLEANDATA/cz_stacked", clear
			if "`samp'"=="td" keep if dcourt==1
	if "`geog'"!="full" & "`geog'"!="1" keep if reg`geog'==1
	if "`geog'"=="1" drop if reg2==1 | reg3 == 1 | reg4 == 1

		ren blackmig3539_share blackmig3539

		// Deeply silly thing that must be done for formatting reasons
		forv i=1/9{
			g d`i'=1
		}
		local stacked_covars_`decade' ""
		
		foreach covar in `covars' {
			g GM`covar' = GM_hat_raw_pp
			label var GM`covar' "`covar' on GM_hat"

			local label : variable label `covar'
			label var GM_hat_raw_pp "`label' on GM_hat"
			eststo `covar': reg `covar' GM`covar' `b_controls' d1 d2 d3 d4 d5 d6 d7 d8 d9 [aw=popc] if decade==`decade', r
			local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
			if `p'<=`balance_cutoff'{
			if (!inlist("`covar'","mfg_lfshare", "blackmig3539", "popc1940","pop1940") & !regexm("`covar'","cz1940_pc")) local stacked_covars_`decade'  "`stacked_covars_`decade'' `covar' `covar'_m"
			if (inlist("`covar'","mfg_lfshare", "blackmig3539", "popc1940","pop1940") | regexm("`covar'","cz1940_pc")) local stacked_covars_`decade'  "`stacked_covars_`decade'' `covar'"
			}
		}
		eststo stacked_`decade'_`samp' : appendmodels `covars'
			
		}
		
		use "$CLEANDATA/cz_stacked", clear
			if "`samp'"=="td" keep if dcourt==1
if "`geog'"!="full" & "`geog'"!="1" keep if reg`geog'==1
		if "`geog'"=="1" drop if reg2==1 | reg3 == 1 | reg4 == 1
		
		ren blackmig3539_share blackmig3539

		tab decade, gen(d)

		local stacked_covars ""
		
		foreach covar in `covars' {
					g GM`covar' = GM_hat_raw_pp

			label var GM`covar' "`covar' on GM_hat"
			eststo `covar': reg `covar' GM`covar' `b_controls' d1 d2 d3 d4 d5 d6 d7 d8 d9 [aw=popc], r
			local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
			if `p'<=`balance_cutoff'{
				if (!inlist("`covar'","mfg_lfshare", "blackmig3539", "popc1940","pop1940") & !regexm("`covar'","cz1940_pc")) local stacked_covars  "`stacked_covars' `covar' `covar'_m"
				if (inlist("`covar'","mfg_lfshare", "blackmig3539", "popc1940","pop1940") | regexm("`covar'","cz1940_pc")) local stacked_covars  "`stacked_covars' `covar'"
			}
		}
		eststo stacked_`samp'  : appendmodels `covars'
		
		esttab pooled_`samp' stacked_1940_`samp' stacked_1950_`samp' stacked_1960_`samp' stacked_`samp' ///
						using "$TABS/balancetables/cz_`samp'`geoglab'.tex", ///
						replace label se booktabs noconstant noobs compress nonumber ///
											b(%03.2f) se(%03.2f) //////
						keep(GM*) ///
						mtitles("1940-1970 Pooled" "1940-1950" "1950-1960" "1960-1970" "Stacked") ///
						coeflabel(mfg_lfshare blackmig3539_share frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2) ///
						title("`samplab'")
						
		
		foreach outcome in schdist_ind cgoodman spdist gen_subcounty gen_town{
			eststo clear

			local controls `b_controls' 

			use "$CLEANDATA/cz_pooled", clear
				if "`samp'"=="td" keep if dcourt==1
		if "`geog'"!="full" keep if region==`geog'

			ren blackmig3539_share blackmig3539

			// FS
			eststo pooled_fs_nc_`samp' : reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
			test GM_hat_raw_pp=0
			local F : di %6.2f r(F)
			estadd local Fs = `F'
			
			// OLS
			eststo pooled_ols_nc_`samp' : reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
			
			// RF
			eststo pooled_rf_nc_`samp' : reg n_`outcome'_cz_pc GM_hat_raw_pp `controls' [aw=popc1940], r
			
			// IV
			eststo pooled_iv_nc_`samp' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
			
			use "$CLEANDATA/cz_stacked", clear
				if "`samp'"=="td" keep if dcourt==1
		if "`geog'"!="full" & "`geog'"!="1" keep if reg`geog'==1
				if "`geog'"=="1" drop if reg2==1 | reg3 == 1 | reg4 == 1
			ren blackmig3539_share blackmig3539

			foreach decade in 1940 1950 1960{
				// FS
				eststo stacked`decade'_fs_nc_`samp' : reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940] if decade==`decade', r
				test GM_hat_raw_pp=0
				local F : di %6.2f r(F)
				estadd local Fs = `F'
				
				// OLS
				eststo stacked`decade'_ols_nc_`samp' : reg n_`outcome'_cz_L0_pc GM_raw_pp `controls' [aw=popc1940] if decade==`decade', r
				
				// RF
				eststo stacked`decade'_rf_nc_`samp' : reg n_`outcome'_cz_L0_pc GM_hat_raw_pp `controls' [aw=popc1940] if decade==`decade', r
				
				// IV
				eststo stacked`decade'_iv_nc_`samp' : ivreg2 n_`outcome'_cz_L0_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940] if decade==`decade', r
			}
			
			// FS
			eststo stacked_fs_nc_`samp' : reg GM_raw_pp GM_hat_raw_pp `controls' i.decade [aw=popc1940], r
			test GM_hat_raw_pp=0
			local F : di %6.2f r(F)
			estadd local Fs = `F'
			
			// OLS
			eststo stacked_ols_nc_`samp' : reg n_`outcome'_cz_L0_pc GM_raw_pp `controls' i.decade [aw=popc1940], r
			
			// RF
			eststo stacked_rf_nc_`samp' : reg n_`outcome'_cz_L0_pc GM_hat_raw_pp `controls' i.decade [aw=popc1940], r
			
			// IV
			eststo stacked_iv_nc_`samp' : ivreg2 n_`outcome'_cz_L0_pc (GM_raw_pp = GM_hat_raw_pp) `controls' i.decade [aw=popc1940], r
			
			// With controls
			local controls `b_controls' 
			
			// Dropping baselines that aren't current outcome variable
			foreach i in `pooled_covars_`samp''{
				if regexm("`i'","cz1940_pc")==0 | regexm("`i'","`outcome'")==1{
					local controls `controls' `i'
				}
			}

			use "$CLEANDATA/cz_pooled", clear
				if "`samp'"=="td" keep if dcourt==1
		if "`geog'"!="full" keep if region==`geog'

			ren mfg_lfshare1940 mfg_lfshare
			ren blackmig3539_share blackmig3539
			// FS
			eststo pooled_fs_c_`samp' : reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
			test GM_hat_raw_pp=0
			local F : di %6.2f r(F)
			estadd local Fs = `F'
			
			// OLS
			eststo pooled_ols_c_`samp' : reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
			
			// RF
			eststo pooled_rf_c_`samp' : reg n_`outcome'_cz_pc GM_hat_raw_pp `controls' [aw=popc1940], r
			
			// IV
			eststo pooled_iv_c_`samp' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
			
			use "$CLEANDATA/cz_stacked", clear
				if "`samp'"=="td" keep if dcourt==1
			if "`geog'"!="full" & "`geog'"!="1" keep if reg`geog'==1
			if "`geog'"=="1" drop if reg2==1 | reg3 == 1 | reg4 == 1
			ren blackmig3539_share blackmig3539

			foreach decade in 1940 1950 1960{
				local controls `b_controls' 
						
				// Dropping baselines that aren't current outcome variable
				foreach i in `stacked_covars_`decade''{
					if regexm("`i'","cz1940_pc")==0 | regexm("`i'","`outcome'")==1{
						local controls `controls' `i'
					}
				}
				// FS
				eststo stacked`decade'_fs_c_`samp' : reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940] if decade==`decade', r
				test GM_hat_raw_pp=0
				local F : di %6.2f r(F)
				estadd local Fs = `F'
				
				// OLS
				eststo stacked`decade'_ols_c_`samp' : reg n_`outcome'_cz_L0_pc GM_raw_pp `controls' [aw=popc1940] if decade==`decade', r
				
				// RF
				eststo stacked`decade'_rf_c_`samp' : reg n_`outcome'_cz_L0_pc GM_hat_raw_pp `controls' [aw=popc1940] if decade==`decade', r
				
				// IV
				eststo stacked`decade'_iv_c_`samp' : ivreg2 n_`outcome'_cz_L0_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940] if decade==`decade', r
			}
			
			local controls `b_controls' 
			// Dropping baselines that aren't current outcome variable
			foreach i in `stacked_covars'{
				if regexm("`i'","cz1940_pc")==0 | regexm("`i'","`outcome'")==1{
					local controls `controls' `i'
				}
			}
		
			// FS
			eststo stacked_fs_c_`samp' : reg GM_raw_pp GM_hat_raw_pp `controls' i.decade [aw=popc1940], r

			test GM_hat_raw_pp=0
			local F : di %6.2f r(F)
			estadd local Fs = `F'
			
			// OLS
			eststo stacked_ols_c_`samp' : reg n_`outcome'_cz_L0_pc GM_raw_pp `controls' i.decade [aw=popc1940], r
			
			// RF
			eststo stacked_rf_c_`samp' : reg n_`outcome'_cz_L0_pc GM_hat_raw_pp `controls' i.decade [aw=popc1940], r
			
			// IV
			eststo stacked_iv_c_`samp' : ivreg2 n_`outcome'_cz_L0_pc (GM_raw_pp = GM_hat_raw_pp) `controls' i.decade [aw=popc1940], r
			
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
							using "$TABS/balancetables/reg_`outcome'_`samp'`geoglab'.tex", ///
							replace se booktabs noconstant noobs compress frag ///
							b(%03.2f) se(%03.2f) ///
							modelwidth(10) ///
							mtitles("1940-1970 Pooled" "1940-1950" "1950-1960" "1960-1970" "Stacked" ///
							"1940-1970 Pooled" "1940-1950" "1950-1960" "1960-1970" "Stacked") ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							posthead("\cmidrule(lr){1-11}" "\multicolumn{10}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-11}" ) ///
							mgroups("Basic controls" "Robust controls", pattern(1 0 0 0 0 1 0 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
							prehead( \begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}  \begin{threeparttable} \caption{Outcome variable `outcome' `samplab'}  \begin{tabular}{l*{11}{c}} \toprule) ///
							stats(Fs N, labels("F-Stat" "Observations")) ///
							keep(GM_hat_raw_pp)
							
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
						using "$TABS/balancetables/reg_`outcome'_`samp'`geoglab'.tex", ///
						append se booktabs noconstant noobs compress frag nonum nomtitles ///
						b(%03.2f) se(%03.2f) ///
						modelwidth(10) ///
						starlevels( * 0.10 ** 0.05 *** 0.01) ///
						posthead("\cmidrule[\heavyrulewidth](lr){1-11} \\ \cmidrule[\heavyrulewidth](lr){1-11}" "\multicolumn{10}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-11}" ) ///
						keep(GM_raw_pp) stats(N, labels("Observations")) 

		
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
						using "$TABS/balancetables/reg_`outcome'_`samp'`geoglab'.tex", ///
						append se booktabs noconstant noobs compress frag nonum nomtitles ///
						b(%03.2f) se(%03.2f) ///
						modelwidth(10) ///
						starlevels( * 0.10 ** 0.05 *** 0.01) ///
						posthead("\cmidrule[\heavyrulewidth](lr){1-11} \\ \cmidrule[\heavyrulewidth](lr){1-11}" "\multicolumn{10}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-11}" ) ///
						keep(GM_hat_raw_pp) stats(N, labels("Observations")) 
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
						using "$TABS/balancetables/reg_`outcome'_`samp'`geoglab'.tex", ///
						append se booktabs noconstant noobs compress frag nonum nomtitles ///
						b(%03.2f) se(%03.2f) ///
						modelwidth(10) ///
						starlevels( * 0.10 ** 0.05 *** 0.01) ///
						posthead("\cmidrule[\heavyrulewidth](lr){1-11} \\ \cmidrule[\heavyrulewidth](lr){1-11}" "\multicolumn{10}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-11}" ) ///
						keep(GM_raw_pp) ///
						postfoot(	\hline\hline \end{tabular}{\caption*{\begin{scriptsize} "Columns 1-4 include region fixed effects, column 5 includes region and decade fixed effects. Columns 6-7 include region fixed effects and all significant covariates from the corresponding balance table. Column 10 includes region and decade fixed effects and all significant covariates from the corresponding balance table. \(p<0.10\), ** \(p<0.05\), *** \(p<0.01\)"\end{scriptsize}}} \end{threeparttable} \end{table}) stats(N, labels("Observations")) 

		}
	}

