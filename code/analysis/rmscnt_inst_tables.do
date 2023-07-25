
local b_controls reg2 reg3 reg4 blackmig3539_share



// Pooled tables

use "$CLEANDATA/cz_pooled.dta", clear
local inst = "main"

// Loop 0: over urban/total populations
foreach samp in urban {
	if "`samp'"=="urban" local poptab ""
	if "`samp'"=="total" local poptab "_totpop"
	
	if "`samp'"=="urban" local popname "c"
	if "`samp'"=="total" local popname ""
	
	if "`samp'"=="urban" local poplab "Urban Population"
	if "`samp'"=="total" local poplab "Total Population"
	if !("`samp'" == "total" & inlist("`inst'","scnt","rmsc","rmscnt")){
	// Loop 1: over outcomes
		foreach y in schdist_ind cgoodman gen_subcounty spdist gen_town{
			
			local ylab: variable label n_`y'_cz


				
				// Loop 2: over with/without controls
				forv ctrls=3/3{
					
					// Setting controls and creating control label
					if "`ctrls'"=="3" local controls `b_controls'
					if "`ctrls'"=="3" local ctrllab "Census Region and Black Mig Share"


						
						// Set dependent variable and create per capita label
						local yvar n_`y'_cz_pc`popname'
						
						
						eststo clear	
						
						// first stage
						eststo fs: reg GM_raw_pp`poptab' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
						test GM_hat_raw_pp`poptab'=0
						local F : di %6.3f `r(F)'
						estadd local Fstat = `F'
						local coef : di %6.3f _b[GM_hat_raw_pp`poptab']
						local se : di %6.3f _se[GM_hat_raw_pp`poptab']
						qui su GM_raw_pp`poptab',d
						local ycord = `r(mean)'*0.5
						qui su GM_hat_raw_pp`poptab',d
						local xcord = `r(mean)'*2
						binscatter GM_raw_pp`poptab' GM_hat_raw_pp`poptab' [aw=pop`popname'1940], controls(`controls') ///
														xtitle("Predicted PP Black Migrant ") ytitle("Actual PP Black Migrant") ///
														title("First Stage, Pooled, `poplab'") ///
														note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
														text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
														savegraph("$FIGS/simplefigs/pooled_`y'_C`ctrls'_`samp'_fs_`savetab'.pdf") replace
						// OLS
						eststo ols : reg `yvar' GM_raw_pp`poptab' `controls' [aw=pop`popname'1940], r

						local coef : di %6.3f _b[GM_raw_pp`poptab']
						local se : di %6.3f _se[GM_raw_pp`poptab']
						qui su `yvar',d
						local ycord = `r(mean)'*0.5
						qui su GM_raw_pp`poptab',d
						local xcord = `r(mean)'*2
						binscatter `yvar' GM_raw_pp`poptab' [aw=pop`popname'1940], controls(`controls') ///
														xtitle("Actual PP Black Migrant") ytitle("`ylab' `pclab'") ///
														title("OLS, Pooled, `poplab'") ///
														note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
														text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
														savegraph("$FIGS/simplefigs/pooled_`y'_C`ctrls'_`samp'_ols_`savetab'.pdf") replace
						// RF
						eststo rf : reg `yvar' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
						local coef : di %6.3f _b[GM_hat_raw_pp`poptab']
						local se : di %6.3f _se[GM_hat_raw_pp`poptab']
						qui su `yvar',d
						local ycord = `r(mean)'*0.5
						qui su GM_hat_raw_pp`poptab',d
						local xcord = `r(mean)'*2
						binscatter `yvar' GM_hat_raw_pp`poptab' [aw=pop`popname'1940], controls(`controls') ///
														xtitle("Predicted PP Black Migrant") ytitle("`ylab' `pclab'") ///
														title("Reduced Form, Pooled, `poplab'") ///
														note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
														text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
														savegraph("$FIGS/simplefigs/pooled_`y'_C`ctrls'_`samp'_rf_`savetab'.pdf") replace
						// IV
						eststo tsls : ivreg2 `yvar' (GM_raw_pp`poptab' = GM_hat_raw_pp`poptab') `controls' [aw=pop`popname'1940], r

						// Export to tables
						esttab 	fs ///
										ols ///
										rf	///
										tsls ///
										using "$TABS/simpletables/pooled_`y'_C`ctrls'_`samp'_`inst'", ///
										replace label nomtitles se booktabs num noconstant ///
										starlevels( * 0.10 ** 0.05 *** 0.01) ///
										stats(Fstat N, labels( ///
										"F-Stat"	///
										"Observations" ///
										)) ///
										title("Dererencourt Table Two with y=`ylab' Pooled, `poplab', `ctrllab' controls.") ///
										keep(GM_raw_pp`poptab' GM_hat_raw_pp`poptab') ///
										mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
										
					
				
				
				}
			}

	}
}



foreach inst in "" "rm" "nt" "rmnt" "rmsc" "scnt" "rmscnt"{
	if "`inst'"=="" {
		local gmtab = ""
		local datatab = "_south"
		local savetab = "mainsouth"
	}
	else{
		local gmtab = "_`inst'"
		local datatab = "_south"
		local savetab = "`inst'"

	}

	// Pooled tables

	use "$CLEANDATA/cz_pooled_south.dta", clear

	keep if samp_2`inst'==1
	
	// Loop 0: over urban/total populations
	foreach samp in urban {
		if "`samp'"=="urban" local poptab ""
		if "`samp'"=="total" local poptab "_totpop"
		
		if "`samp'"=="urban" local popname "c"
		if "`samp'"=="total" local popname ""
		
		if "`samp'"=="urban" local poplab "Urban Population"
		if "`samp'"=="total" local poplab "Total Population"
		if !("`samp'" == "total" & inlist("`inst'","scnt","rmsc","rmscnt")){
		// Loop 1: over outcomes
			foreach y in schdist_ind cgoodman gen_subcounty spdist gen_town{
				
				local ylab: variable label n_`y'_cz


					
					// Loop 2: over with/without controls
					forv ctrls=3/3{
						
						// Setting controls and creating control label
						if "`ctrls'"=="3" local controls `b_controls'
						if "`ctrls'"=="3" local ctrllab "Census Region and Black Mig Share"


							
							// Set dependent variable and create per capita label
							local yvar n_`y'_cz_pc`popname'
							
							
							eststo clear	
							
							// first stage
							eststo fs: reg GM_raw_pp`poptab' GM`gmtab'_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
							test GM`gmtab'_hat_raw_pp`poptab'=0
							local F : di %6.3f `r(F)'
							estadd local Fstat = `F'
							local coef : di %6.3f _b[GM`gmtab'_hat_raw_pp`poptab']
							local se : di %6.3f _se[GM`gmtab'_hat_raw_pp`poptab']
							qui su GM_raw_pp`poptab',d
							local ycord = `r(mean)'*0.5
							qui su GM`gmtab'_hat_raw_pp`poptab',d
							local xcord = `r(mean)'*2
							binscatter GM_raw_pp`poptab' GM`gmtab'_hat_raw_pp`poptab' [aw=pop`popname'1940], controls(`controls') ///
															xtitle("Predicted PP Black Migrant ") ytitle("Actual PP Black Migrant") ///
															title("First Stage, Pooled, `poplab'") ///
															note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
															text(`ycord' `xcord' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
															savegraph("$FIGS/simplefigs/pooled_`y'_C`ctrls'_`samp'_fs_`savetab'.pdf") replace
							// OLS
							eststo ols : reg `yvar' GM_raw_pp`poptab' `controls' [aw=pop`popname'1940], r

							local coef : di %6.3f _b[GM_raw_pp`poptab']
							local se : di %6.3f _se[GM_raw_pp`poptab']
							qui su `yvar',d
							local ycord = `r(mean)'*0.5
							qui su GM_raw_pp`poptab',d
							local xcord = `r(mean)'*2
							binscatter `yvar' GM_raw_pp`poptab' [aw=pop`popname'1940], controls(`controls') ///
															xtitle("Actual PP Black Migrant") ytitle("`ylab' `pclab'") ///
															title("OLS, Pooled, `poplab'") ///
															note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
															text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
															savegraph("$FIGS/simplefigs/pooled_`y'_C`ctrls'_`samp'_ols_`savetab'.pdf") replace
							// RF
							eststo rf : reg `yvar' GM`gmtab'_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
							local coef : di %6.3f _b[GM`gmtab'_hat_raw_pp`poptab']
							local se : di %6.3f _se[GM`gmtab'_hat_raw_pp`poptab']
							qui su `yvar',d
							local ycord = `r(mean)'*0.5
							qui su GM`gmtab'_hat_raw_pp`poptab',d
							local xcord = `r(mean)'*2
							binscatter `yvar' GM`gmtab'_hat_raw_pp`poptab' [aw=pop`popname'1940], controls(`controls') ///
															xtitle("Predicted PP Black Migrant") ytitle("`ylab' `pclab'") ///
															title("Reduced Form, Pooled, `poplab'") ///
															note("Data at CZ level, 1940-70 sample, with `ctrllab' controls.") ///
															text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
															savegraph("$FIGS/simplefigs/pooled_`y'_C`ctrls'_`samp'_rf_`savetab'.pdf") replace
							// IV
							eststo tsls : ivreg2 `yvar' (GM_raw_pp`poptab' = GM`gmtab'_hat_raw_pp`poptab') `controls' [aw=pop`popname'1940], r

							// Export to tables
							esttab 	fs ///
											ols ///
											rf	///
											tsls ///
											using "$TABS/simpletables/pooled_`y'_C`ctrls'_`samp'_`savetab'", ///
											replace label nomtitles se booktabs num noconstant ///
											starlevels( * 0.10 ** 0.05 *** 0.01) ///
											stats(Fstat N, labels( ///
											"F-Stat"	///
											"Observations" ///
											)) ///
											title("Dererencourt Table Two with y=`ylab' Pooled, `poplab', `ctrllab' controls.") ///
											keep(GM_raw_pp`poptab' GM`gmtab'_hat_raw_pp`poptab') ///
											mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
											
						
						
						
						}
					}

			}
		}
	}