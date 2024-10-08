// Merges n_muni_cz variable with derenoncourt data, replicates table 2 using it as outcome variable with and without controls
forv weight=0/1{
	forv medsplit=1/2{
		foreach inst in full {
			forv drop=0/0{
				foreach x in rank {
					foreach level in county{
						if "`level'"=="cz"{
							local levelvar cz
							local levellab "CZ"
						}
						else if "`level'"=="county"{
							local levelvar fips
							local levellab "County"
						}
						else if "`level'"=="msa"{
							local levelvar msapmsa2000
							local levellab "MSA"
						}
						
						if "`weight'"=="0" local w = 1
						if "`weight'"=="1" local w ="`level'pop1940"
						
						forv pc=0/1{
							foreach ds in schdist_ind all_local all_local_nosch cgoodman{
								if "`ds'"=="wiki"{
									local filepath = "$TABS/wiki"
								}
								else if "`ds'"=="ngov1"{
									local filepath = "$TABS/4_1_general_purpose_govts"

								}
								else if "`ds'"=="ngov2"{
									local filepath = "$TABS/4_1_general_purpose_govts"
								
								}
								else if "`ds'"=="ngov3"{
									local filepath = "$TABS/4_1_general_purpose_govts"
									}
								else if "`ds'"=="cgoodman"{
									local filepath = "$TABS/cgoodman"

								}
								else{
									local filepath = "$TABS/2_county_counts"

								}
								eststo clear
								use "$CLEANDATA/`level'_`ds'_pooled", clear

								global y n_muni_`level'
								global x_ols = cond("`x'"=="rank","GM","GM_raw")
								global x_iv  = cond("`x'"=="rank","GM_hat2","GM_hat2_raw")

								la var $x_iv "$\hat{GM}$ (`x')"
								la var $x_ols "GM  (`x')"
									

								global C3 base_muni_`level'1940 reg2 reg3 reg4
								

								global C4 base_muni_`level'1940 reg2 reg3 reg4 mfg_lfshare1940  blackmig3539_share1940
								//gl C5 ${C4} mean_tri add_tri_ctrl
								
								/*
								
								// Histograms
								foreach var of varlist $y $x_ols $x_iv{
									local lab: variable label `var'

									local time = 1940
									local time_end = 1970
									twoway__histogram_gen `var', freq bin(15) gen(h x, replace)
									
									local min = `r(start)'
									local max = `r(max)'
									local step = `r(width)'
									
									twoway hist `var', freq bin(15) gap(1) ///
									title("Historgram of `lab'"  "`levellab' Level, `time'-`time_end'") ///
									note("Data From CoG 2: County Gov't Counts") xlab(`min'(`step')`max')
									
									graph export "$FIGS/2_county_counts/`level'/`level'_`var'_`time'_`time_end'_hist.png", as(png) replace

								}
								*/
								local ylab: variable label $y
								label var $y "y"
								
								
								if `pc'==1{
									replace $y = $y / `level'pop1940
									local pclab ", Per Capita"
								}
								else{
									local pclab ""
								}
								/*
								forv i=3/4{
									if `i'==3{
										local lab1 "baseline y and division FEs"
									}
									else if `i'==5{
										local lab1 "baseline y, division FEs, and mfg share"

									}
									else if `i'==6{
										local lab1 "baseline y, division FEs, and black mig share"

									}
									else if `i'==4{
										local lab1 "baseline y, division FEs, and mfg and black mig share"
									}
									
									su $x_ols
									local x_mean : di %6.3f `r(mean)'
									su $y
									local y_mean : di %6.3f  `r(mean)'
									eststo fs : reg $x_ols $x_iv ${C`i'}, r 
									local F : di %6.3f e(F)
									estadd local Fstat = `F'
									estadd local dep_mean = `x_mean'
									
									eststo ols : reg $y $x_ols ${C`i'}, r 
									local r2 : di %6.3f e(r2)

									estadd local Rsquared = `r2'
									estadd local dep_mean = `y_mean'

									eststo rf : reg $y $x_iv ${C`i'}, r
									local r2 : di %6.3f e(r2)

									estadd local Rsquared = `r2'
									estadd local dep_mean = `y_mean'

									eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}, r
									estadd local dep_mean = `y_mean'

									esttab 	fs ///
													ols ///
													rf	///
													tsls ///
													using "`filepath'/table_2_ctrls`i'_`ds'_`pc'_`level'.tex", ///
													replace label se booktabs num noconstant ///
													starlevels( * 0.10 ** 0.05 *** 0.01) ///
													stats(Fstat Rsquared N, labels( ///
													"F-Stat"	///
													"R-squared" ///
													"Dep Var Mean" ///
													"Observations" ///
													)) ///
													title("Dererencourt Table Two with y=`ylab'`pclab' by `levellab' 1940-70, with `lab1'") ///
													keep($x_iv $x_ols) ///
													mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
								}

								// split decades
								
								foreach d in _1940_1950 _1950_1960 _1960_1970{
										if "`d'"=="_1940_1950"{
											local labd "1940-50"
										}
										else if "`d'"=="_1950_1960"{
											local labd "1950-60"
										}
										else if "`d'"=="_1960_1970"{
											local labd "1960-70"
										}
									eststo clear
									global y n_muni_`level'`d'
									global x_ols GM`d'
									global x_iv GM_hat2`d'
									
									
									

									local base = substr("`d'",2,4)

									
									global C3 base_muni_`level'`base' reg2 reg3 reg4
									global C5 base_muni_`level'`base' reg2 reg3 reg4 mfg_lfshare`base'

									global C6 base_muni_`level'`base' reg2 reg3 reg4 v2_blackmig3539_share`base'

									global C4 base_muni_`level'`base' reg2 reg3 reg4 mfg_lfshare`base'  v2_blackmig3539_share`base'


									use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
									if "`level'"=="msa"{
										destring smsa, gen(msapmsa2000) 
									}
									merge 1:1 `levelvar' using "`datapath'", keep(3) nogen
									merge 1:1 `levelvar' using ``level'pop1940', keep(3) nogen

									
									
									local ylab: variable label $y
									label var $y "y"

									
									if `pc'==1{
										replace $y = $y / `level'pop1940
										local pclab ", Per Capita (1940)"
									}
									
									la var $x_iv "$\hat{GM}$"
									la var $x_ols "GM"
									
									forv i=3/4{
										if `i'==3{
											local lab1 "baseline y and division FEs"
										}
										else if `i'==5{
											local lab1 "baseline y, division FEs, and mfg share"

										}
										else if `i'==6{
											local lab1 "baseline y, division FEs, and black mig share"

										}
										else if `i'==4{
											local lab1 "baseline y, division FEs, and mfg and black mig share"
										}
										
										su $x_ols
										local x_mean : di %6.3f  `r(mean)'
										su $y
										local y_mean : di %6.3f  `r(mean)'
										eststo fs : reg $x_ols $x_iv ${C`i'}, r 
										local F : di %6.3f e(F)
										estadd local Fstat = `F'
										estadd local dep_mean = `x_mean'
										
										eststo ols : reg $y $x_ols ${C`i'}, r 
										local r2 : di %6.3f e(r2)

										estadd local Rsquared = `r2'
										estadd local dep_mean = `y_mean'

										eststo rf : reg $y $x_iv ${C`i'}, r
										local r2 : di %6.3f e(r2)

										estadd local Rsquared = `r2'
										estadd local dep_mean = `y_mean'

										eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}, r
										estadd local dep_mean = `y_mean'

										esttab 	fs ///
														ols ///
														rf	///
														tsls ///
														using "`filepath'/table_2_ctrls`i'`d'_`ds'_`pc'_`level'.tex", ///
														replace label se booktabs num noconstant ///
														starlevels( * 0.10 ** 0.05 *** 0.01) ///
														stats(Fstat Rsquared dep_mean N, labels( ///
														"F-Stat"	///
														"R-squared" ///
														"Dep Var Mean" ///
														"Observations" ///
														)) ///
														title("Dererencourt Table Two with y=`ylab'`pclab' by `levellab' `labd', with `lab1'") ///
														keep($x_iv $x_ols) ///
														mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
									}
								}
							*/

								// Stacked and lagged

								use "$CLEANDATA/`level'_`ds'_stacked_`inst'.dta", clear
								if "`drop'"=="1"{
									drop if decade == 1940
								}
								local startyr = cond("`drop'"=="1","1950","1940") 

								forv lag = 0/0{
									if `lag'==0{
										local labl "no lags"
									}
									else if `lag'==1{
										local labl "lagged once"
									}
									else if `lag'==2{
										local labl "lagged twice"
									}
									global y n_muni_`level'_L`lag'
									
									global x_ols = cond("`x'"=="rank","GM","GM_raw")
									global x_iv  = cond("`x'"=="rank","GM_hat","GM_hat_raw")

									la var $x_iv "$\hat{GM}$ (`x')"
									la var $x_ols "GM  (`x')"
										
									label var $y "y_L`lag'"
									
									if `pc'==1{
										replace $y = 100000*$y / `level'pop1940
										local pclab ", Per Capita (100,000)"
									}

									global C3 base_muni_`level'_L`lag' reg2 reg3 reg4 i.decade


									global C4 base_muni_`level'_L`lag' reg2 reg3 reg4 mfg_lfshare blackmig3539_share i.decade
									
									gl C5 ${C4} mean_tri add_tri_ctrl

													
									foreach i in 3 4{
										if `i'==3{
											local lab1 "baseline y and division FEs"
										}
									
										else if `i'==4{
											local lab1 "baseline y, division FEs, mfg and black mig share"
										}
										
										
										
										local sample = cond("`inst'"=="og","Original Dererencourt Sample","Full Sample")
										
										
										if `medsplit'==0{
											eststo clear
											su $x_ols
											local x_mean : di %6.3f  `r(mean)'
											su $y
											local y_mean : di %6.3f  `r(mean)'
											eststo fs : reg $x_ols $x_iv ${C`i'}  [aw=`w'], r 
											local F : di %6.3f e(F)
											local coef : di %6.3f _b[$x_iv]
											local se : di %6.3f _se[$x_iv]
											estadd local Fstat = `F'
											estadd local dep_mean = `x_mean'	
											
											/*
											local cords = cond("`x'"=="rank","35 80","2 2")
											binscatter $x_ols $x_iv [aw=`w'], controls(${C`i'}) ///
											xtitle("Predicted Black Migrant Share") ytitle("Actual Black Migrant Share") title("First Stage for `x' values") note("Data at county-decade level, `startyr'-70 sample, with `lab1' controls. `sample'") ///
											text(`cords' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
											savegraph("$FIGS/binscatter/binscatter_ctrls`i'_stacked_L`lag'_`ds'_`pc'_`level'_`x'_`drop'_`inst'_`weight'.pdf") replace
											*/
											
											eststo ols : reg $y $x_ols ${C`i'} [aw=`w'], r 
											local r2 : di %6.3f e(r2)

											estadd local Rsquared = `r2'
											estadd local dep_mean = `y_mean'

											eststo rf : reg $y $x_iv ${C`i'}  [aw=`w'], r
											local r2 : di %6.3f e(r2)

											estadd local Rsquared = `r2'
											estadd local dep_mean = `y_mean'

											eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}  [aw=`w'], r
											estadd local dep_mean = `y_mean'

											esttab 	fs ///
															ols ///
															rf	///
															tsls ///
															using "`filepath'/table_2_ctrls`i'_stacked_L`lag'_`ds'_`pc'_`level'_`x'_`drop'_`inst'_`weight'.tex", ///
															replace label se booktabs num noconstant ///
															starlevels( * 0.10 ** 0.05 *** 0.01) ///
															stats(Fstat Rsquared dep_mean N, labels( ///
															"F-Stat"	///
															"R-squared" ///
															"Dep Var Mean" ///
															"Observations" ///
															)) ///
															title("Dererencourt Table Two with y=`ylab'`pclab' by decade in `levellab' `startyr'-70, with `lab1'") ///
															keep($x_iv $x_ols) ///
															mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
										}
										else if `medsplit'>0{
											if "`medsplit'"=="1" local medvar = "above_med_land"
											if "`medsplit'"=="2" local medvar = "above_med_unusable"
											
											forv ms=0/1{
												local mslab = cond("`ms'"=="0","below","above")
												eststo clear
												su $x_ols if `medvar'==`ms'
												local x_mean : di %6.3f  `r(mean)'
												su $y if `medvar'==`ms'
												local y_mean : di %6.3f  `r(mean)'	
												eststo fs : reg $x_ols $x_iv ${C`i'}  [aw=`w'] if `medvar'==`ms', r 
																								

												local F : di %6.3f e(F)
												local coef : di %6.3f _b[$x_iv]
												local se : di %6.3f _se[$x_iv]
												estadd local Fstat = `F'
												estadd local dep_mean = `x_mean'	
												/*
												local cords = cond("`x'"=="rank","35 80","2 2")
												binscatter $x_ols $x_iv   [aw=`w'] if above_med_land==`ms', controls(${C`i'}) ///
												xtitle("Predicted Black Migrant Share") ytitle("Actual Black Migrant Share") title("First Stage for `x' values") note("Data at county-decade level, `startyr'-70 sample, with `lab1' controls. `sample'") ///
												text(`cords' "Slope: `coef'(`se)')" "First-Stage F-stat: `F'") ///
												savegraph("$FIGS/binscatter/binscatter_ctrls`i'_stacked_L`lag'_`ds'_`pc'_`level'_`x'_`drop'_`inst'_`ms'_`weight'.pdf") replace
												*/
												
													eststo ols : reg $y $x_ols ${C`i'}  [aw=`w'] if `medvar'==`ms', r 
													local r2 : di %6.3f e(r2)

													estadd local Rsquared = `r2'
													estadd local dep_mean = `y_mean'

													eststo rf : reg $y $x_iv ${C`i'}  [aw=`w'] if `medvar'==`ms', r
													local r2 : di %6.3f e(r2)

													estadd local Rsquared = `r2'
													estadd local dep_mean = `y_mean'

													eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}  [aw=`w'] if `medvar'==`ms', r
													estadd local dep_mean = `y_mean'

													esttab 	fs ///
																	ols ///
																	rf	///
																	tsls ///
																	using "`filepath'/table_2_ctrls`i'_stacked_L`lag'_`ds'_`pc'_`level'_`x'_`drop'_`inst'_`medsplit'_`ms'_`weight'.tex", ///
																	replace label se booktabs num noconstant ///
																	starlevels( * 0.10 ** 0.05 *** 0.01) ///
																	stats(Fstat Rsquared dep_mean N, labels( ///
																	"F-Stat"	///
																	"R-squared" ///
																	"Dep Var Mean" ///
																	"Observations" ///
																	)) ///
																	title("Dererencourt Table Two with y=`ylab'`pclab' by decade in `levellab' `startyr'-70, with `lab1', `mslab' median area incorporated.") ///
																	keep($x_iv $x_ols) ///
																	mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
											}
										}
														
									}
								}
							}
						}
					}
				}
			}
		}
	}
}