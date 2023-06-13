// Pooled tables

use "$CLEANDATA/cz_pooled.dta", clear

// Loop 0: over urban/total populations
foreach samp in urban total{
	if "`samp'"=="urban" local poptab ""
	if "`samp'"=="total" local poptab "_totpop"
	
	if "`samp'"=="urban" local popname "c"
	if "`samp'"=="total" local popname ""
	
	if "`samp'"=="urban" local poplab "Urban Population"
	if "`samp'"=="total" local poplab "Total Population"
	
	// Loop 1: over outcomes
	foreach y in schdist_ind cgoodman gen_subcounty gen_muni{
		
		local ylab: variable label n_`y'_cz
		preserve
			if "`samp'"=="total" drop if GM_hat_raw_totpop==0

			// Create PC outcome
			cap drop n_`y'_cz_pc
			g n_`y'_cz_pc = b_`y'_cz1970/(pop`popname'1970/100000) - b_`y'_cz1940/(pop`popname'1940/100000)
			
			// Loop 2: over with/without controls
			forv ctrls=3/4{
				
				// Setting controls and creating control label
				if "`ctrls'"=="3" local controls reg2 reg3 reg4
				if "`ctrls'"=="3" local ctrllab "Census Region"

				if "`ctrls'"=="4" local controls mfg_lfshare1940 blackmig3539_share`poptab' reg2 reg3 reg4
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
					eststo fs: reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls', r
					local F : di %6.3f e(F)
					estadd local Fstat = `F'
					local coef : di %6.3f _b[GM_hat_raw_pp`poptab']
					local se : di %6.3f _se[GM_hat_raw_pp`poptab']
					qui su GM_raw_pp`poptab',d
					local ycord = `r(mean)'*0.5
					qui su GM_hat_raw_pp`poptab',d
					local xcord = `r(mean)'*2
					binscatter GM_raw_pp`poptab' GM_hat_raw_pp`poptab', controls(`controls') ///
													xtitle("Predicted PP Black Migrant ") ytitle("Actual PP Black Migrant") ///
													title("First Stage, Pooled, `poplab'") ///
													note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
													text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
													savegraph("$FIGS/simplefigs/pooled_`y'_`pop'_C`ctrls'_`samp'_fs.pdf") replace
					// OLS
					eststo ols : reg `yvar' GM_raw_pp`poptab' `controls', r
					local coef : di %6.3f _b[GM_raw_pp`poptab']
					local se : di %6.3f _se[GM_raw_pp`poptab']
					qui su `yvar',d
					local ycord = `r(mean)'*0.5
					qui su GM_raw_pp`poptab',d
					local xcord = `r(mean)'*2
					binscatter `yvar' GM_raw_pp`poptab', controls(`controls') ///
													xtitle("Actual PP Black Migrant") ytitle("`ylab' `pclab'") ///
													title("OLS, Pooled, `poplab'") ///
													note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
													text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
													savegraph("$FIGS/simplefigs/pooled_`y'_`pop'_C`ctrls'_`samp'_ols.pdf") replace
					// RF
					eststo rf : reg `yvar' GM_hat_raw_pp`poptab' `controls', r
					local coef : di %6.3f _b[GM_hat_raw_pp`poptab']
					local se : di %6.3f _se[GM_hat_raw_pp`poptab']
					qui su `yvar',d
					local ycord = `r(mean)'*0.5
					qui su GM_hat_raw_pp`poptab',d
					local xcord = `r(mean)'*2
					binscatter `yvar' GM_hat_raw_pp`poptab', controls(`controls') ///
													xtitle("Predicted PP Black Migrant") ytitle("`ylab' `pclab'") ///
													title("Reduced Form, Pooled, `poplab'") ///
													note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
													text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
													savegraph("$FIGS/simplefigs/pooled_`y'_`pop'_C`ctrls'_`samp'_rf.pdf") replace
					// IV
					eststo tsls : ivreg2 `yvar' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls', r

					// Export to tables
					esttab 	fs ///
									ols ///
									rf	///
									tsls ///
									using "$TABS/simpletables/pooled_`y'_`pop'_C`ctrls'_`samp'", ///
									replace label nomtitles se booktabs num noconstant ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									stats(Fstat N, labels( ///
									"F-Stat"	///
									"Observations" ///
									)) ///
									title("Dererencourt Table Two with y=`ylab' `pclab' Pooled,, `poplab', `ctrllab' controls.") ///
									keep(GM_raw_pp`poptab' GM_hat_raw_pp`poptab') ///
									mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
									
				
				
				
				}
			}
		restore
	}
}


// Stacked tables
use "$CLEANDATA/cz_stacked.dta", clear

// Keeping only the original 130 CZs
//keep if dcourt==1

// Loop 0: over urban/total populations
foreach samp in urban total{
	if "`samp'"=="urban" local poptab ""
	if "`samp'"=="total" local poptab "_totpop"
	
	if "`samp'"=="urban" local popname "c"
	if "`samp'"=="total" local popname ""
	
	if "`samp'"=="urban" local poplab "Urban Population"
	if "`samp'"=="total" local poplab "Total Population"
	
	// Loop 1: over outcomes
	foreach y in  cgoodman  schdist_ind gen_subcounty gen_muni{
		
		local ylab: variable label n_`y'_cz_L0

		// Create PC dependent variables
		cap drop n_`y'_cz_L0_pc
		g frac = b_`y'_cz/(pop`popname'/100000)
		bys cz (decade) : g n_`y'_cz_L0_pc = 100*(frac[_n+1] - frac)
		drop frac
		
		preserve
			// Dropping decades out of sample
			keep if inlist(decade,1940,1950,1960)
			//if "`samp'"=="total" drop if GM_hat_raw_totpop==0
			// Loop 2: over with/without controls
			forv ctrls=3/4{
				
				// Setting controls and creating control label
				if "`ctrls'"=="3" local controls reg2 reg3 reg4 i.decade
				if "`ctrls'"=="3" local ctrllab "Census Region and Decade FEs"

				if "`ctrls'"=="4" local controls mfg_lfshare blackmig3539_share reg2 reg3 reg4 i.decade
				if "`ctrls'"=="4" local ctrllab "Census Region a nd Decade FEs and Mfg+Blackmig Shares"

				// Loop 3: over raw/per capita
				foreach pop in raw pc{ 
					
					// Set dependent, independent, and instrumental variables and create per capita label
					if "`pop'"=="pc"{
						local yvar n_`y'_cz_L0_pc
						local pclab "Per Capita (100,000)"
						
					}

					else if "`pop'"=="raw"{
						local yvar n_`y'_cz_L0
						local pclab ""
						
					}
					local x GM_raw_pp`poptab'
					local z GM_hat_raw_pp`poptab'
					
					
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
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls, `poplab'.") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`samp'_fs.pdf") replace
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
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls, `poplab'") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`samp'_ols.pdf") replace
												
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
												note("Data at CZ-decade level, 1940-70 sample, with `ctrllab' controls, `poplab'") ///
												text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
												savegraph("$FIGS/simplefigs/stacked_`y'_`pop'_C`ctrls'_`samp'_rf.pdf") replace
					// IV
					eststo tsls : ivreg2 `yvar' (`x' = `z') `controls', r

					// Export to tables
					esttab 	fs ///
									ols ///
									rf	///
									tsls ///
									using "$TABS/simpletables/stacked_`y'_`pop'_C`ctrls'_`samp'", ///
									replace label se booktabs num noconstant nomtitles ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									stats(Fstat N, labels( ///
									"F-Stat"	///
									"Observations" ///
									)) ///
									title("Dererencourt Table Two with y=`ylab' `pclab' Pooled, `ctrllab' controls, `poplab'") ///
									keep(`x' `z') ///
									mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
				}
				
			}
		restore
	}
}


