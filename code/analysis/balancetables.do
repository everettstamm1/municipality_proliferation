

local b_controls reg2 reg3 reg4 v2_sumshares_urban
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear
local covars avg_precip avg_temp coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 p90_total p95_total higrade hsgrad unigrad mean_urban_income_1940 cz_popdens1940 growth3040


local pooled_covars_`samp'  ""
keep if dcourt == 1
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = GM_hat_raw
	label var GM`covar' "`lab'"

	qui eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	
	
	local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
	di "`covar' p value : `p'"
	if `p'<=`balance_cutoff'{
		local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
	}
}

eststo pooled_`samp' : appendmodels `covars'
esttab pooled_`samp' `means' ///
				using "$TABS/balancetables/balancetable.tex", ///
				replace label se booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{GM}$" "Mean") ///
				b(%04.3f) se(%04.3f) //////
				keep(GM*) ///
				prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
		postfoot(	\bottomrule \end{tabular}) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) 

					
	
// mean (above/below median sample) - GM_raw -GM_hat -GM_hat with cenreg fe - GM_hat with cenreg fe and sumshares

local b_controls reg2 reg3 reg4 v2_sumshares_urban
local extra_controls transpo_cost_1920 coastal cz_popdens1940 mean_urban_income_1940 growth3040
 

use "$CLEANDATA/cz_pooled", clear
local vars n10_cgoodman_cz_pc n20_cgoodman_cz_pc n30_cgoodman_cz_pc n40_cgoodman_cz_pc pre_cgoodman_cz_pc 
	keep if dcourt == 1

foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = GM_raw_pp
	label var GM`var' "`lab'"

	eststo `var': ivreg2 `var' (GM`var' = GM_hat_raw) `b_controls' `extra_controls' [aw=popc1940], r
	
	drop GM`var'
	
}

eststo tsls_`samp' : appendmodels `vars'

foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = GM_hat_raw
	label var GM`var' "`lab'"

	eststo `var': reg `var' GM`var' `b_controls' `extra_controls' [aw=popc1940], r
	
	
}

eststo rf_`samp' : appendmodels `vars'

esttab tsls_`samp' rf_`samp' ///
				using "$TABS/balancetables/pretrends_new_ctrls.tex", ///
				replace label se booktabs noconstant noobs compress nonumber frag  mtitles("IV" "Reduced Form") ///
				b(%04.3f) se(%04.3f) //////
				keep(GM*) ///
				prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
		postfoot(	\bottomrule \end{tabular}) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) 



local b_controls reg2 reg3 reg4 v2_sumshares_urban
local extra_controls transpo_cost_1920 coastal mean_urban_income_1940 cz_popdens1940 growth3040
 
foreach t in pop age black literate labforce occscore{
	eststo clear
	use "$CLEANDATA/cz_pooled", clear
	ren bpop1940 black1940
	
	local vars `t'1900 `t'1910 `t'1920 `t'1930
		keep if dcourt == 1

	foreach var in `vars' {
		local lab : variable label `var'
		g GM`var' = GM_raw_pp
		label var GM`var' "`lab'"

		eststo `var': ivreg2 `var' (GM`var' = GM_hat_raw) `b_controls' `extra_controls' [aw=popc1940], r
		
		drop GM`var'
		
	}

	eststo tsls_`samp' : appendmodels `vars'

	foreach var in `vars' {
		local lab : variable label `var'
		g GM`var' = GM_hat_raw
		label var GM`var' "`lab'"

		eststo `var': reg `var' GM`var' `b_controls' `extra_controls' [aw=popc1940], r
		
		
	}

	eststo rf_`samp' : appendmodels `vars'

	esttab tsls_`samp' rf_`samp' ///
					using "$TABS/balancetables/pretrends_`t'.tex", ///
					replace label se booktabs noconstant noobs compress nonumber frag  mtitles("IV" "Reduced Form") ///
					b(%04.3f) se(%04.3f) //////
					keep(GM*) ///
					prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
			postfoot(	\bottomrule \end{tabular}) ///
					starlevels( * 0.10 ** 0.05 *** 0.01) 
}

