// Merges n_muni_cz variable with derenoncourt data, replicates table 2 using it as outcome variable with and without controls


// Preclean 1940 census data
use "$DCOURT/data/mobility/raw/usa_00097.dta", clear
keep stateicp countyicp perwt
collapse (sum) perwt, by(stateicp countyicp)

merge 1:1 stateicp countyicp using "$DCOURT/data/crosswalks/county1940_crosswalks.dta", keep(1 3) nogen

preserve
	collapse (sum) perwt, by(cz)

	ren perwt czpop1940

	tempfile czpop1940
	save `czpop1940'
restore

collapse (sum) perwt, by(fips)

ren perwt countypop1940

tempfile countypop1940
save `countypop1940'


foreach level in cz county{
	if "`level'"=="cz"{
		local levelvar cz
		local levellab "CZ"
	}
	else if "`level'"=="county"{
		local levelvar fips
		local levellab "County"
	}
	// Preclean county data

	use "$INTDATA/cog/2_county_counts.dta", clear
	drop if fips_state == "02" | fips_state=="15"
	g fips = fips_state+fips_county_2002
	destring fips, replace
	rename czone cz

	foreach var of varlist gen_subcounty gen_muni gen_town spdist schdist_ind schdist all_local {
		preserve
			local lab: variable label `var'

			bys `levelvar' year : egen n = total(`var'), missing
			keep `levelvar' year n
			duplicates drop 
			
			reshape wide n, i(`levelvar') j(year)
			
			g n_muni_`level' = n1972 - n1942
			g n_muni_`level'_1940_1950 = n1952 - n1942
			g n_muni_`level'_1950_1960 = n1962 - n1952
			g n_muni_`level'_1960_1970 = n1972 - n1962
			g n_muni_`level'_1970_1980 = n1982 - n1972
			g n_muni_`level'_1980_1990 = n1992 - n1982
			
			ren n1942 base_muni_`level'1940
			ren n1952 base_muni_`level'1950
			ren n1962 base_muni_`level'1960
			ren n1972 base_muni_`level'1970
			ren n1982 base_muni_`level'1980
			
			label var base_muni_`level'1940 "Base `lab' 1940"
			label var base_muni_`level'1950 "Base `lab' 1950"
			label var base_muni_`level'1960 "Base `lab' 1960"
			label var base_muni_`level'1970 "Base `lab' 1970"
			label var base_muni_`level'1980 "Base `lab' 1980"

			label var n_muni_`level'_1940_1950 "`lab'"
			label var n_muni_`level'_1950_1960 "`lab'"
			label var n_muni_`level'_1960_1970 "`lab'"
			label var n_muni_`level'_1970_1980 "`lab'"
			label var n_muni_`level'_1980_1990 "`lab'"
			label var n_muni_`level' "`lab'"
			
			tempfile `var'
			save ``var''
		restore
	}

	// Preclean general purpose govts data
	use "$INTDATA/cog/4_1_general_purpose_govts.dta", clear
	drop if fips_code_state == "02" | fips_code_state=="15"
	g fips = 1000*fips_state+fips_county_2002
	rename czone cz

	keep if ID_type == 2 | ID_type == 3 // keeping only municipal and town/township observations

	g incorp_date1 = original_incorporation_date
	g incorp_date2 = year_home_rule_adopted

	// Documentation notes some inconsistencies in incorporation dates and home rule charters, so we'll take the earliest reported
	bys id (incorp_date1) : replace incorp_date1 = incorp_date1[1] 
	bys id (incorp_date2) : replace incorp_date2 = incorp_date2[1] 

	g incorp_date3 = cond(incorp_date1<.,incorp_date1,incorp_date2)
	drop if incorp_date3==.

	lab var incorp_date1 "Incorporations"
	lab var incorp_date2 "Home Rule Adoptions"
	lab var incorp_date3 "Incorporations or Home Rule Adoptions"

	keep incorp_date* id `levelvar'
	duplicates drop

	forv i=1/3{
		preserve
			keep `levelvar' incorp_date`i'
			local lab: variable label incorp_date`i'

			g n = incorp_date`i'>=1940 & incorp_date`i'<=1970


			g n1940 = incorp_date`i'<1940
			g n1950 = incorp_date`i'<1950 
			g n1960 = incorp_date`i'<1960
			g n1970 = incorp_date`i'<1970
			g n1980 = incorp_date`i'<1980

			g n1940_1950 = incorp_date`i'>=1940 & incorp_date`i'<1950
			g n1950_1960 = incorp_date`i'>=1950 & incorp_date`i'<1960
			g n1960_1970 = incorp_date`i'>=1960 & incorp_date`i'<1970
			g n1970_1980 = incorp_date`i'>=1970 & incorp_date`i'<1980
			g n1980_1990 = incorp_date`i'>=1980 & incorp_date`i'<1990

			collapse (sum) n*, by(`levelvar')

			rename n n_muni_`level'

			rename n1940 base_muni_`level'1940
			rename n1950 base_muni_`level'1950
			rename n1960 base_muni_`level'1960
			rename n1970 base_muni_`level'1970
			rename n1980 base_muni_`level'1980

			rename n1940_1950 n_muni_`level'_1940_1950
			rename n1950_1960 n_muni_`level'_1950_1960
			rename n1960_1970 n_muni_`level'_1960_1970
			rename n1970_1980 n_muni_`level'_1970_1980
			rename n1980_1990 n_muni_`level'_1980_1990

			label var base_muni_`level'1940 "Base `lab' 1940"
			label var base_muni_`level'1950 "Base `lab' 1950"
			label var base_muni_`level'1960 "Base `lab' 1960"
			label var base_muni_`level'1970 "Base `lab' 1970"
			label var base_muni_`level'1980 "Base `lab' 1980"

			label var n_muni_`level'_1940_1950 "`lab'"
			label var n_muni_`level'_1950_1960 "`lab'"
			label var n_muni_`level'_1960_1970 "`lab'"
			label var n_muni_`level'_1970_1980 "`lab'"
			label var n_muni_`level'_1980_1990 "`lab'"
			label var n_muni_`level' "`lab'"

			tempfile ngov`i'
			save `ngov`i''
		restore
	}

	forv pc=0/1{
		foreach ds in gen_muni schdist_ind  all_local ngov3 wiki{
			if "`ds'"=="wiki"{
				local datapath = "$INTDATA/n_muni_`level'.dta"
				local filepath = "$TABS/wiki"
			}
			else if "`ds'"=="ngov1"{
				local datapath ``ds''
				local filepath = "$TABS/4_1_general_purpose_govts"

			}
			else if "`ds'"=="ngov2"{
				local datapath ``ds''
				local filepath = "$TABS/4_1_general_purpose_govts"
			
			}
			else if "`ds'"=="ngov3"{
				local datapath ``ds''
				local filepath = "$TABS/4_1_general_purpose_govts"
				}
			else{
				local datapath ``ds''
				local filepath = "$TABS/2_county_counts"

			}
			
			eststo clear
			global y n_muni_`level'
			global x_ols GM
			global x_iv GM_hat2	

			global C3 base_muni_`level'1940 reg2 reg3 reg4
			global C5 base_muni_`level'1940 reg2 reg3 reg4 mfg_lfshare1940

			global C6 base_muni_`level'1940 reg2 reg3 reg4 v2_blackmig3539_share1940

			global C4 base_muni_`level'1940 reg2 reg3 reg4 mfg_lfshare1940  v2_blackmig3539_share1940

			use "$DCOURT/data/GM_`level'_final_dataset.dta", clear
			merge 1:1 `levelvar' using "`datapath'", keep(3) nogen
			merge 1:1 `levelvar' using ``level'pop1940', keep(3) nogen
			
			local ylab: variable label $y
			label var $y "y"
			
			if `pc'==1{
				replace $y = $y / `level'pop1940
				local pclab ", Per Capita (1940)"
			}
			else{
				local pclab ""
			}
			forv i=3/6{
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
				
				eststo clear
				eststo fs : reg $x_ols $x_iv ${C`i'}
				local F : di %6.3f e(F)
				estadd local Fstat = `F'
				eststo ols : reg $y $x_ols ${C`i'}
				local r2 : di %6.3f e(r2)

				estadd local Rsquared = `r2'

				eststo rf : reg $y $x_iv ${C`i'}
				local r2 : di %6.3f e(r2)

				estadd local Rsquared = `r2'

				eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}

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
				
				forv i=3/6{
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
					
					eststo clear
					eststo fs : reg $x_ols $x_iv ${C`i'}
					local F : di %6.3f e(F)
					estadd local Fstat = `F'
					eststo ols : reg $y $x_ols ${C`i'}
					local r2 : di %6.3f e(r2)

					estadd local Rsquared = `r2'

					eststo rf : reg $y $x_iv ${C`i'}
					local r2 : di %6.3f e(r2)

					estadd local Rsquared = `r2'

					eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}

					esttab 	fs ///
									ols ///
									rf	///
									tsls ///
									using "`filepath'/table_2_ctrls`i'`d'_`ds'_`pc'_`level'.tex", ///
									replace label se booktabs num noconstant ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									stats(Fstat Rsquared N, labels( ///
									"F-Stat"	///
									"R-squared" ///
									"Observations" ///
									)) ///
									title("Dererencourt Table Two with y=`ylab'`pclab' by `levellab' `labd', with `lab1'") ///
									keep($x_iv $x_ols) ///
									mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
				}
			}


			// Stacked and lagged

			use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
			merge 1:1 `levelvar' using "`datapath'", keep(3) nogen
			merge 1:1 `levelvar' using ``level'pop1940', keep(3) nogen

			local ylab: variable label n_muni_`level'

			rename *1940_1950 *1940
			rename *1950_1960 *1950
			rename *1960_1970 *1960

			keep GM_???? GM_hat2_???? frac_all_upm* mfg_lfshare* v2_blackmig3539_share* `levelvar' reg2 reg3 reg4  n_muni_`level'_???? base_muni_`level'???? `level'pop1940
			reshape long base_muni_`level' n_muni_`level'_ GM_ GM_hat2_ frac_all_upm mfg_lfshare v2_blackmig3539_share, i(`levelvar') j(decade)

			ren n_muni_`level'_ n_muni_`level'
			ren GM_ GM
			ren GM_hat2_ GM_hat2

			bys `levelvar' (decade) : g n_muni_`level'_L1 = n_muni_`level'[_n-1] if decade-10 == decade[_n-1]
			bys `levelvar' (decade) : g n_muni_`level'_L2 = n_muni_`level'[_n-2] if decade-20 == decade[_n-2]

			bys `levelvar' (decade) : g base_muni_`level'_L1 = base_muni_`level'[_n-1] if decade-10 == decade[_n-1]
			bys `levelvar' (decade) : g base_muni_`level'_L2 = base_muni_`level'[_n-2] if decade-20 == decade[_n-2]

			ren n_muni_`level' n_muni_`level'_L0
			ren base_muni_`level' base_muni_`level'_L0

			forv lag = 0/1{
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
				global x_ols GM
				global x_iv GM_hat2	

				la var $x_iv "$\hat{GM}$"
				la var $x_ols "GM"
					
				label var $y "y_L`lag'"
				
				if `pc'==1{
					replace $y = $y / `level'pop1940
					local pclab ", Per Capita (1940)"
				}

				global C3 base_muni_`level'_L`lag' reg2 reg3 reg4 i.decade
				global C5 base_muni_`level'_L`lag' reg2 reg3 reg4 mfg_lfshare i.decade

				global C6 base_muni_`level'_L`lag' reg2 reg3 reg4 v2_blackmig3539_share i.decade

				global C4 base_muni_`level'_L`lag' reg2 reg3 reg4 mfg_lfshare v2_blackmig3539_share i.decade

								
				forv i=3/6{
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
					eststo clear
					eststo fs : reg $x_ols $x_iv ${C`i'}
					local F : di %6.3f e(F)
					estadd local Fstat = `F'
					eststo ols : reg $y $x_ols ${C`i'}
					local r2 : di %6.3f e(r2)

					estadd local Rsquared = `r2'

					eststo rf : reg $y $x_iv ${C`i'}
					local r2 : di %6.3f e(r2)

					estadd local Rsquared = `r2'

					eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${C`i'}

					esttab 	fs ///
									ols ///
									rf	///
									tsls ///
									using "`filepath'/table_2_ctrls`i'_stacked_L`lag'_`ds'_`pc'_`level'.tex", ///
									replace label se booktabs num noconstant ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									stats(Fstat Rsquared N, labels( ///
									"F-Stat"	///
									"R-squared" ///
									"Observations" ///
									)) ///
									title("Dererencourt Table Two with y=`ylab'`pclab' by decade in `levellab' 1940-70, with `lab1'") ///
									keep($x_iv $x_ols) ///
									mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
				}
			}
		}
	}
}
