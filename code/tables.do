// Merges n_muni_cz variable with derenoncourt data, replicates table 2 using it as outcome variable with and without controls


// Preclean 1940 census data
use "$DCOURT/data/mobility/raw/usa_00097.dta", clear
keep stateicp countyicp perwt
collapse (sum) perwt, by(stateicp countyicp)

merge 1:1 stateicp countyicp using "$DCOURT/data/crosswalks/county1940_crosswalks.dta", keep(1 3) nogen
collapse (sum) perwt, by(cz)

ren perwt pop1940

tempfile czpop1940
save `czpop1940'

// Preclean county data

use "$INTDATA/cog/2_county_counts.dta", clear
drop if fips_state == "02" | fips_state=="15"

foreach var of varlist gen_subcounty gen_muni gen_town spdist schdist_ind schdist all_local {
	preserve
		local lab: variable label `var'

		rename czone cz
		bys cz year : egen n = total(`var'), missing
		keep cz year n
		duplicates drop 
		
		reshape wide n, i(cz) j(year)
		
		g n_muni_cz = n1972 - n1942
		g n_muni_cz_1940_1950 = n1952 - n1942
		g n_muni_cz_1950_1960 = n1962 - n1952
		g n_muni_cz_1960_1970 = n1972 - n1962
		g n_muni_cz_1970_1980 = n1982 - n1972
		g n_muni_cz_1980_1990 = n1992 - n1982
		
		ren n1942 base_muni_cz1940
		ren n1952 base_muni_cz1950
		ren n1962 base_muni_cz1960
		ren n1972 base_muni_cz1970
		ren n1982 base_muni_cz1980
		
		label var base_muni_cz1940 "Base `lab' 1940"
		label var base_muni_cz1950 "Base `lab' cz1950"
		label var base_muni_cz1960 "Base `lab' cz1960"
		label var base_muni_cz1970 "Base `lab' cz1970"
		label var base_muni_cz1980 "Base `lab' cz1980"

		label var n_muni_cz_1940_1950 "`lab'"
		label var n_muni_cz_1950_1960 "`lab'"
		label var n_muni_cz_1960_1970 "`lab'"
		label var n_muni_cz_1970_1980 "`lab'"
		label var n_muni_cz_1980_1990 "`lab'"
		label var n_muni_cz "`lab'"
		
		tempfile `var'
		save ``var''
	restore
}

// Preclean general purpose govts data
use "$INTDATA/cog/4_1_general_purpose_govts.dta", clear
drop if fips_code_state == "02" | fips_code_state=="15"

keep if ID_type == 2 | ID_type == 3 // keeping only municipal and town/township observations
g incorp_date1 = original_incorporation_date
g incorp_date2 = year_home_rule_adopted
g incorp_date3 = cond(original_incorporation_date<.,original_incorporation_date,year_home_rule_adopted)

lab var incorp_date1 "Incorporations"
lab var incorp_date2 "Home Rule Adoptions"
lab var incorp_date3 "Incorporations or Home Rule Adoptions"

destring incorp_date*, replace
drop if incorp_date3==.

forv i=1/3{
	preserve
		keep czone incorp_date`i'
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

		collapse (sum) n*, by(czone)

		rename n n_muni_cz

		rename n1940 base_muni_cz1940
		rename n1950 base_muni_cz1950
		rename n1960 base_muni_cz1960
		rename n1970 base_muni_cz1970
		rename n1980 base_muni_cz1980

		rename n1940_1950 n_muni_cz_1940_1950
		rename n1950_1960 n_muni_cz_1950_1960
		rename n1960_1970 n_muni_cz_1960_1970
		rename n1970_1980 n_muni_cz_1970_1980
		rename n1980_1990 n_muni_cz_1980_1990

		rename czone cz

		label var base_muni_cz1940 "Base `lab' 1940"
		label var base_muni_cz1950 "Base `lab' cz1950"
		label var base_muni_cz1960 "Base `lab' cz1960"
		label var base_muni_cz1970 "Base `lab' cz1970"
		label var base_muni_cz1980 "Base `lab' cz1980"

		label var n_muni_cz_1940_1950 "`lab'"
		label var n_muni_cz_1950_1960 "`lab'"
		label var n_muni_cz_1960_1970 "`lab'"
		label var n_muni_cz_1970_1980 "`lab'"
		label var n_muni_cz_1980_1990 "`lab'"
		label var n_muni_cz "`lab'"

		tempfile ngov`i'
		save `ngov`i''
	restore
}

forv pc=0/1{
	foreach ds in gen_subcounty gen_muni gen_town spdist schdist_ind schdist all_local ngov1 ngov2 ngov3 wiki{
		if "`ds'"=="wiki"{
			local datapath = "$INTDATA/n_muni_czone.dta"
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
		global y n_muni_cz
		global x_ols GM
		global x_iv GM_hat2	

		global baseline_controls0 
		global baseline_controls1 base_muni_cz1940 

		global baseline_controls2 base_muni_cz1940 reg2 reg3 reg4

		global baseline_controls3 base_muni_cz1940 mfg_lfshare1940  v2_blackmig3539_share1940 reg2 reg3 reg4

		use "$DCOURT/data/GM_cz_final_dataset.dta", clear
		merge 1:1 cz using "`datapath'", keep(3) nogen
		merge 1:1 cz using `czpop1940', keep(3) nogen
		
		local ylab: variable label $y
		label var $y "y"
		
		if `pc'==1{
			replace $y = $y / czpop1940
			local pclab ", Per Capita (1940)"
		}
		
		forv i=0/3{
			if `i'==0{
				local lab1 "no controls"
			}
			else if `i'==1{
				local lab1 "baseline y controls"
			}
			else if `i'==2{
				local lab1 "baseline y and division FEs"
			}
			else if `i'==3{
				local lab1 "baseline y, division FEs, and mfg and black mig share"
			}
			
			eststo clear
			eststo fs : reg $x_ols $x_iv ${baseline_controls`i'}
			local F : di %6.3f e(F)
			estadd local Fstat = `F'
			eststo ols : reg $y $x_ols ${baseline_controls`i'}
			local r2 : di %6.3f e(r2)

			estadd local Rsquared = `r2'

			eststo rf : reg $y $x_iv ${baseline_controls`i'}
			local r2 : di %6.3f e(r2)

			estadd local Rsquared = `r2'

			eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${baseline_controls`i'}

			esttab 	fs ///
							ols ///
							rf	///
							tsls ///
							using "`filepath'/table_2_ctrls`i'_`ds'_`pc'.tex", ///
							replace label se booktabs num noconstant ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(Fstat Rsquared N, labels( ///
							"F-Stat"	///
							"R-squared" ///
							"Observations" ///
							)) ///
							title("Dererencourt Table Two with y=`ylab'`pclab by CZ 1940-70, with `lab1'") ///
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
			global y n_muni_cz`d'
			global x_ols GM`d'
			global x_iv GM_hat2`d'
			
			
			

			local base = substr("`d'",2,4)

			global baseline_controls0 
			global baseline_controls1 base_muni_cz`base'

			global baseline_controls2 base_muni_cz`base' reg2 reg3 reg4

			global baseline_controls3 base_muni_cz`base' mfg_lfshare`base'  v2_blackmig3539_share`base' reg2 reg3 reg4

			use "$DCOURT/data/GM_cz_final_dataset_split.dta", clear
			merge 1:1 cz using "`datapath'", keep(3) nogen
			merge 1:1 cz using `czpop1940', keep(3) nogen

			
			
			local ylab: variable label $y
			label var $y "y"

			
			if `pc'==1{
				replace $y = $y / czpop1940
				local pclab ", Per Capita (1940)"
			}
			
			la var $x_iv "$\hat{GM}$"
			la var $x_ols "GM"
			
			forv i=0/3{
				if `i'==0{
					local lab1 "no controls"
				}
				else if `i'==1{
					local lab1 "baseline y controls"
				}
				else if `i'==2{
					local lab1 "baseline y and division FEs"
				}
				else if `i'==3{
					local lab1 "baseline y, division FEs, and mfg and black mig share"
				}
				
				eststo clear
				eststo fs : reg $x_ols $x_iv ${baseline_controls`i'}
				local F : di %6.3f e(F)
				estadd local Fstat = `F'
				eststo ols : reg $y $x_ols ${baseline_controls`i'}
				local r2 : di %6.3f e(r2)

				estadd local Rsquared = `r2'

				eststo rf : reg $y $x_iv ${baseline_controls`i'}
				local r2 : di %6.3f e(r2)

				estadd local Rsquared = `r2'

				eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${baseline_controls`i'}

				esttab 	fs ///
								ols ///
								rf	///
								tsls ///
								using "`filepath'/table_2_ctrls`i'`d'_`ds'_`pc'.tex", ///
								replace label se booktabs num noconstant ///
								starlevels( * 0.10 ** 0.05 *** 0.01) ///
								stats(Fstat Rsquared N, labels( ///
								"F-Stat"	///
								"R-squared" ///
								"Observations" ///
								)) ///
								title("Dererencourt Table Two with y=`ylab'`pclab' by CZ `labd', with `lab1'") ///
								keep($x_iv $x_ols) ///
								mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
			}
		}


		// Stacked and lagged

		use "$DCOURT/data/GM_cz_final_dataset_split.dta", clear
		merge 1:1 cz using "`datapath'", keep(3) nogen
		merge 1:1 cz using `czpop1940', keep(3) nogen

		local ylab: variable label n_muni_cz

		rename *1940_1950 *1940
		rename *1950_1960 *1950
		rename *1960_1970 *1960

		keep GM_???? GM_hat2_???? frac_all_upm* mfg_lfshare* v2_blackmig3539_share* cz reg2 reg3 reg4  n_muni_cz_???? base_muni_cz???? czpop1940
		reshape long base_muni_cz n_muni_cz_ GM_ GM_hat2_ frac_all_upm mfg_lfshare v2_blackmig3539_share, i(cz) j(decade)

		ren n_muni_cz_ n_muni_cz
		ren GM_ GM
		ren GM_hat2_ GM_hat2

		bys cz (decade) : g n_muni_cz_L1 = n_muni_cz[_n-1] if decade-10 == decade[_n-1]
		bys cz (decade) : g n_muni_cz_L2 = n_muni_cz[_n-2] if decade-20 == decade[_n-2]

		bys cz (decade) : g base_muni_cz_L1 = base_muni_cz[_n-1] if decade-10 == decade[_n-1]
		bys cz (decade) : g base_muni_cz_L2 = base_muni_cz[_n-2] if decade-20 == decade[_n-2]

		ren n_muni_cz n_muni_cz_L0
		ren base_muni_cz base_muni_cz_L0

		forv lag = 0/2{
			if `lag'==0{
				local labl "no lags"
			}
			else if `lag'==1{
				local labl "lagged once"
			}
			else if `lag'==2{
				local labl "lagged twice"
			}
			global y n_muni_cz_L`lag'
			global x_ols GM
			global x_iv GM_hat2	

			la var $x_iv "$\hat{GM}$"
			la var $x_ols "GM"
				
			label var $y "y_L`lag'"
			
			if `pc'==1{
				replace $y = $y / czpop1940
				local pclab ", Per Capita (1940)"
			}
			
			global baseline_controls0 i.decade
			global baseline_controls1 base_muni_cz_L`lag' i.decade

			global baseline_controls2 base_muni_cz_L`lag' reg2 reg3 reg4 i.decade

			global baseline_controls3 base_muni_cz_L`lag' mfg_lfshare  v2_blackmig3539_share reg2 reg3 reg4 i.decade
				
			forv i=0/3{
				if `i'==0{
					local lab1 "decade FEs"
				}
				else if `i'==1{
					local lab1 "decade FEs and baseline y controls"
				}
				else if `i'==2{
					local lab1 "decade FEs, baseline y, and division FEs"
				}
				else if `i'==3{
					local lab1 "decade FEs, baseline y, division FEs, and mfg and black mig share"
				}
				
				eststo clear
				eststo fs : reg $x_ols $x_iv ${baseline_controls`i'}
				local F : di %6.3f e(F)
				estadd local Fstat = `F'
				eststo ols : reg $y $x_ols ${baseline_controls`i'}
				local r2 : di %6.3f e(r2)

				estadd local Rsquared = `r2'

				eststo rf : reg $y $x_iv ${baseline_controls`i'}
				local r2 : di %6.3f e(r2)

				estadd local Rsquared = `r2'

				eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${baseline_controls`i'}

				esttab 	fs ///
								ols ///
								rf	///
								tsls ///
								using "`filepath'/table_2_ctrls`i'_stacked_L`lag'_`ds'_`pc'.tex", ///
								replace label se booktabs num noconstant ///
								starlevels( * 0.10 ** 0.05 *** 0.01) ///
								stats(Fstat Rsquared N, labels( ///
								"F-Stat"	///
								"R-squared" ///
								"Observations" ///
								)) ///
								title("Dererencourt Table Two with y=`ylab'`pclab by decade in CZ 1940-70, with `lab1'") ///
								keep($x_iv $x_ols) ///
								mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))
			}
		}
	}
}
