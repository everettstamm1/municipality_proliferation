// Merges n_muni_cz variable with derenoncourt data, replicates table 2 using it as outcome variable with and without controls

eststo clear
global y n_muni_cz
global x_ols GM
global x_iv GM_hat2	
global baseline_controls frac_all_upm1940 mfg_lfshare1940  v2_blackmig3539_share1940 reg2 reg3 reg4


use "$DCOURT/data/GM_cz_final_dataset.dta", clear
merge 1:1 cz using "$INTDATA/n_muni_czone.dta", keep(3) nogen
eststo fs : reg $x_ols $x_iv ${baseline_controls}
local F : di %6.3f e(F)
estadd local Fstat = `F'
eststo ols : reg $y $x_ols ${baseline_controls}
local r2 : di %6.3f e(r2)

estadd local Rsquared = `r2'

eststo rf : reg $y $x_iv ${baseline_controls}
local r2 : di %6.3f e(r2)

estadd local Rsquared = `r2'

eststo tsls : ivreg2 $y ($x_ols = $x_iv) ${baseline_controls}

esttab 	fs ///
				ols ///
				rf	///
				tsls ///
				using "$TABS/table_2_ctrls.tex", ///
				replace label se booktabs num noconstant ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				stats(Fstat Rsquared N, labels( ///
				"F-Stat"	///
				"R-squared" ///
				"Observations" ///
				)) ///
				title("Dererencourt Table Two with y=Number of Municipalities Founded by CZ 1940-70, with controls") ///
				keep($x_iv $x_ols) ///
				mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))

eststo clear
eststo fs : reg $x_ols $x_iv 
local F : di %6.3f e(F)
estadd local Fstat = `F'
eststo ols : reg $y $x_ols 
local r2 : di %6.3f e(r2)

estadd local Rsquared = `r2'

eststo rf : reg $y $x_iv 
local r2 : di %6.3f e(r2)

estadd local Rsquared = `r2'

eststo tsls : ivreg2 $y ($x_ols = $x_iv) 

esttab 	fs ///
				ols ///
				rf	///
				tsls ///
				using "$TABS/table_2_noctrls.tex", ///
				replace label se booktabs num noconstant ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				stats(Fstat Rsquared N, labels( ///
				"F-Stat"	///
				"R-squared" ///
				"Observations" ///
				)) ///
				title("Dererencourt Table Two with y=Number of Municipalities Founded by CZ 1940-70, no controls") ///
				keep($x_iv $x_ols) ///
				mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1))