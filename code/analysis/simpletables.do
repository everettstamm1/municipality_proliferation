// Pooled tables

use "$CLEANDATA/cz_pooled.dta", clear

// Loop 1: over outcomes
foreach y in schdist_ind cgoodman{
	
	local ylab: variable label n_`y'_cz

	// Create PC outcome
	g n_`y'_cz_pc = b_`y'_cz1970/(popc1970/100000) - b_`y'_cz1940/(popc1940/100000)
	
	// Loop 2: over with/without controls
	forv ctrls=3/4{
		
		// Setting controls and creating control label
		if "`ctrls'"=="3" local controls reg2 reg3 reg4
		if "`ctrls'"=="3" local ctrllab "Census Region"

		if "`ctrls'"=="4" local controls mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4
		if "`ctrls'"=="4" local ctrllab "Census Region and Mfg+Blackmig Shares"

		// Loop 3: over raw/per capita
		foreach pop in raw pc{ 
			
			// Set dependent variable and create per capita label
			if "`pop'"=="pc" {
				local yvar n_`y'_cz_pc
				local pclab "Per Capita (100,000)"
			}
			else{
				local yvar n_`y'_cz
				local pclab ""
			}
			
			eststo clear	
			
			// first stage
			eststo fs: reg GM_raw_pp GM_hat2_raw_pp `controls', r
			local F : di %6.3f e(F)
			estadd local Fstat = `F'
			local coef : di %6.3f _b[GM_hat2_raw_pp]
			local se : di %6.3f _se[GM_hat2_raw_pp]
			qui su GM_raw_pp,d
			local ycord = `r(mean)'*0.5
			qui su GM_hat2_raw_pp,d
			local xcord = `r(mean)'*2
			binscatter GM_raw_pp GM_hat2_raw_pp, controls(`controls') ///
											xtitle("Predicted PP Black Migrant ") ytitle("Actual PP Black Migrant") ///
											title("First Stage, Pooled") ///
											note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
											text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
											savegraph("$FIGS/simplefigs/pooled_`y'_`pop'_C`ctrls'_fs.pdf") replace
			// OLS
			eststo ols : reg `yvar' GM_raw_pp `controls', r
			local coef : di %6.3f _b[GM_raw_pp]
			local se : di %6.3f _se[GM_raw_pp]
			qui su `yvar',d
			local ycord = `r(mean)'*0.5
			qui su GM_raw_pp,d
			local xcord = `r(mean)'*2
			binscatter `yvar' GM_raw_pp, controls(`controls') ///
											xtitle("Actual PP Black Migrant") ytitle("`ylab' `pclab'") ///
											title("OLS, Pooled") ///
											note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
											text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
											savegraph("$FIGS/simplefigs/pooled_`y'_`pop'_C`ctrls'_ols.pdf") replace
			// RF
			eststo rf : reg `yvar' GM_hat2_raw_pp `controls', r
			local coef : di %6.3f _b[GM_hat2_raw_pp]
			local se : di %6.3f _se[GM_hat2_raw_pp]
			qui su `yvar',d
			local ycord = `r(mean)'*0.5
			qui su GM_hat2_raw_pp,d
			local xcord = `r(mean)'*2
			binscatter `yvar' GM_hat2_raw_pp, controls(`controls') ///
											xtitle("Predicted PP Black Migrant") ytitle("`ylab' `pclab'") ///
											title("Reduced Form, Pooled") ///
											note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
											text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
											savegraph("$FIGS/simplefigs/pooled_`y'_`pop'_C`ctrls'_rf.pdf") replace
			// IV
			eststo tsls : ivreg2 `yvar' (GM_raw_pp = GM_hat2_raw_pp) `controls', r

			// Export to tables
			esttab 	fs ///
							ols ///
							rf	///
							tsls ///
							using "$TABS/simpletables/pooled_`y'_`pop'_C`ctrls'", ///
							replace label nomtitles se booktabs num noconstant ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(Fstat N, labels( ///
							"F-Stat"	///
							"Observations" ///
							)) ///
							title("Dererencourt Table Two with y=`ylab' `pclab' Pooled, `ctrllab' controls.") ///
							keep(GM_raw_pp GM_hat2_raw_pp) ///
							mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
							
		
		
		
		}
	}
}


// Stacked tables
use "$CLEANDATA/cz_stacked_full.dta", clear

// Keeping only the original 130 CZs
//keep if dcourt==1

// Loop 1: over outcomes
foreach y in  cgoodman schdist_ind{
	
	local ylab: variable label n_`y'_cz

	// Create PC dependent variables
	g frac = b_`y'_cz/(pop/100000)
	g fracc = b_`y'_cz/(popc/100000)
	
	bys cz (decade) : g n_`y'_cz_L0_pc = 100*(frac[_n+1] - frac)
	bys cz (decade) : g n_`y'_cz_L0_pcc = 100*(fracc[_n+1] - fracc)

	drop frac fracc
	
	preserve
		// Dropping decades out of sample
		keep if inlist(decade,1940,1950,1960)
		
		// Loop 2: over with/without controls
		forv ctrls=3/4{
			
			// Setting controls and creating control label
			if "`ctrls'"=="3" local controls reg2 reg3 reg4 i.decade
			if "`ctrls'"=="3" local ctrllab "Census Region and Decade FEs"

			if "`ctrls'"=="4" local controls mfg_lfshare blackmig3539_share reg2 reg3 reg4 i.decade
			if "`ctrls'"=="4" local ctrllab "Census Region a nd Decade FEs and Mfg+Blackmig Shares"

			// Loop 3: over raw/per capita
			foreach pop in raw pc{ 
				
				
				// Loop 4: over full/urban
				foreach inst in full urban{
					
					// Set dependent, independent, and instrumental variables and create per capita label
					if "`pop'"=="pc" & "`inst'" == "full"{
						local  yvar n_`y'_cz_L0_pc
						local pclab "Per Capita (100,000)"
						local x GM_raw_pp
						local z GM_hat_raw_pp
					}
					else if "`pop'"=="pc" & "`inst'" == "urban"{
						local  yvar n_`y'_cz_L0_pcc
						local pclab "Per Capita (100,000)"
						local x GM_raw_ppc
						local z GM_hat2_raw_ppc
					}
					else if "`pop'"=="raw" & "`inst'" == "full"{
						local  yvar n_`y'_cz_L0
						local pclab ""
						local x GM_raw_pp
						local z GM_hat_raw_pp
					}
					else if "`pop'"=="raw" & "`inst'" == "urban"{
						local yvar n_`y'_cz_L0
						local pclab ""
						local x GM_raw_ppc
						local z GM_hat2_raw_ppc
					}
					
					
					
					eststo clear
					// first stage
					eststo fs: reg `x' `z' `controls', r
					local F : di %6.3f e(F)
					estadd local Fstat = `F'
					local coef : di %6.3f _b[`z']
					local se : di %6.3f _se[`z']
					qui su `x',d
					local ycord = `r(mean)'*0.5
					qui su `z',d
					local xcord = `r(mean)'*2

					binscatter `x' `z', controls(`controls') ///
												xtitle("Predicted PP Black Migrant") ytitle("Actual PP Black Migrant") ///
												title("First Stage, Stacked") ///
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls, `inst' sample.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`inst'_fs.pdf") replace
					// OLS
					eststo ols : reg `yvar' `x' `controls', r
					local coef : di %6.3f _b[`x']
					local se : di %6.3f _se[`x']
					qui su `yvar',d
					local ycord = `r(mean)'*0.5
					qui su `x',d
					local xcord = `r(mean)'*2
					binscatter `yvar' `x', controls(`controls') ///
												xtitle("Actual PP Black Migrant") ytitle("`ylab' `pclab'") ///
												title("OLS, Stacked") ///
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`inst'_ols.pdf") replace
												
					// RF
					eststo rf : reg `yvar' `z' `controls', r
					local coef : di %6.3f _b[`z']
					local se : di %6.3f _se[`z']
					qui su `yvar',d
					local ycord = `r(mean)'*0.5
					qui su `z',d
					local xcord = `r(mean)'*2
					
					binscatter `yvar' `z', controls(`controls') ///
												xtitle("Predicted PP Black Migrant") ytitle("`ylab' `pclab'") ///
												title("Reduced Form, Stacked") ///
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`inst'_rf.pdf") replace
					// IV
					eststo tsls : ivreg2 `yvar' (`x' = `z') `controls', r

					// Export to tables
					esttab 	fs ///
									ols ///
									rf	///
									tsls ///
									using "$TABS/simpletables/stacked_`y'_`pop'_C`ctrls'_`inst'", ///
									replace label se booktabs num noconstant nomtitles ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									stats(Fstat N, labels( ///
									"F-Stat"	///
									"Observations" ///
									)) ///
									title("Dererencourt Table Two with y=`ylab' `pclab' Pooled, `ctrllab' controls.") ///
									keep(`x' `z') ///
									mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
				}
			}
		}
	restore
}


// Stacked tables Keeping only the original 130 CZs

use "$CLEANDATA/cz_stacked_full.dta", clear

keep if dcourt==1

// Loop 1: over outcomes
foreach y in  cgoodman schdist_ind{
	
	local ylab: variable label n_`y'_cz

	// Create PC dependent variables
	g frac = b_`y'_cz/(pop/100000)
	g fracc = b_`y'_cz/(popc/100000)
	
	bys cz (decade) : g n_`y'_cz_L0_pc = 100*(frac[_n+1] - frac)
	bys cz (decade) : g n_`y'_cz_L0_pcc = 100*(fracc[_n+1] - fracc)

	drop frac fracc
	
	preserve
		// Dropping decades out of sample
		keep if inlist(decade,1940,1950,1960)
		
		// Loop 2: over with/without controls
		forv ctrls=3/4{
			
			// Setting controls and creating control label
			if "`ctrls'"=="3" local controls reg2 reg3 reg4 i.decade
			if "`ctrls'"=="3" local ctrllab "Census Region and Decade FEs"

			if "`ctrls'"=="4" local controls mfg_lfshare blackmig3539_share reg2 reg3 reg4 i.decade
			if "`ctrls'"=="4" local ctrllab "Census Region a nd Decade FEs and Mfg+Blackmig Shares"

			// Loop 3: over raw/per capita
			foreach pop in raw pc{ 
				
				
				// Loop 4: over full/urban
				foreach inst in full urban{
					
					// Set dependent, independent, and instrumental variables and create per capita label
					if "`pop'"=="pc" & "`inst'" == "full"{
						local  yvar n_`y'_cz_L0_pc
						local pclab "Per Capita (100,000)"
						local x GM_raw_pp
						local z GM_hat_raw_pp
					}
					else if "`pop'"=="pc" & "`inst'" == "urban"{
						local  yvar n_`y'_cz_L0_pcc
						local pclab "Per Capita (100,000)"
						local x GM_raw_ppc
						local z GM_hat2_raw_ppc
					}
					else if "`pop'"=="raw" & "`inst'" == "full"{
						local  yvar n_`y'_cz_L0
						local pclab ""
						local x GM_raw_pp
						local z GM_hat_raw_pp
					}
					else if "`pop'"=="raw" & "`inst'" == "urban"{
						local yvar n_`y'_cz_L0
						local pclab ""
						local x GM_raw_ppc
						local z GM_hat2_raw_ppc
					}
					
					
					
					eststo clear
					// first stage
					eststo fs: reg `x' `z' `controls', r
					local F : di %6.3f e(F)
					estadd local Fstat = `F'
					local coef : di %6.3f _b[`z']
					local se : di %6.3f _se[`z']
					qui su `x',d
					local ycord = `r(mean)'*0.5
					qui su `z',d
					local xcord = `r(mean)'*2

					binscatter `x' `z', controls(`controls') ///
												xtitle("Predicted PP Black Migrant") ytitle("Actual PP Black Migrant") ///
												title("First Stage, Stacked") ///
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls, `inst' sample.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`inst'_fs_dc.pdf") replace
					// OLS
					eststo ols : reg `yvar' `x' `controls', r
					local coef : di %6.3f _b[`x']
					local se : di %6.3f _se[`x']
					qui su `yvar',d
					local ycord = `r(mean)'*0.5
					qui su `x',d
					local xcord = `r(mean)'*2
					binscatter `yvar' `x', controls(`controls') ///
												xtitle("Actual PP Black Migrant") ytitle("`ylab' `pclab'") ///
												title("OLS, Stacked") ///
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`inst'_ols_dc.pdf") replace
												
					// RF
					eststo rf : reg `yvar' `z' `controls', r
					local coef : di %6.3f _b[`z']
					local se : di %6.3f _se[`z']
					qui su `yvar',d
					local ycord = `r(mean)'*0.5
					qui su `z',d
					local xcord = `r(mean)'*2
					
					binscatter `yvar' `z', controls(`controls') ///
												xtitle("Predicted PP Black Migrant") ytitle("`ylab' `pclab'") ///
												title("Reduced Form, Stacked") ///
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`inst'_rf_dc.pdf") replace
					// IV
					eststo tsls : ivreg2 `yvar' (`x' = `z') `controls', r

					// Export to tables
					esttab 	fs ///
									ols ///
									rf	///
									tsls ///
									using "$TABS/simpletables/stacked_`y'_`pop'_C`ctrls'_`inst'_dc", ///
									replace label se booktabs num noconstant nomtitles ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									stats(Fstat N, labels( ///
									"F-Stat"	///
									"Observations" ///
									)) ///
									title("Dererencourt Table Two with y=`ylab' `pclab' Pooled, `ctrllab' controls.") ///
									keep(`x' `z') ///
									mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
				}
			}
		}
	restore
}