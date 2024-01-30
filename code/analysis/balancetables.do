

local b_controls reg2 reg3 reg4 blackmig3539_share
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear
local covars avg_precip avg_temp coastal mfg_lfshare1940 m_rr_sqm_total p90_total p95_total transpo_cost_1920
	
local pooled_covars_`samp'  ""
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = GM_hat_raw_pp
	label var GM`covar' "`lab'"

	qui eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
	di "`covar' p value : `p'"
	if `p'<=`balance_cutoff'{
		local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
	}
}

eststo pooled_`samp' : appendmodels `covars'

esttab pooled_`samp'  ///
				using "$TABS/balancetables/balancetable.tex", ///
				replace label se booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{GM}$") ///
				b(%04.3f) se(%04.3f) //////
				keep(GM*) ///
				prehead( \begin{tabular}{l*{1}{c}} \toprule) ///
		postfoot(	\bottomrule \end{tabular}) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) 

					
	


local b_controls reg2 reg3 reg4 blackmig3539_share
local extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
 

use "$CLEANDATA/cz_pooled", clear
local vars n10_cgoodman_cz_pc n20_cgoodman_cz_pc n30_cgoodman_cz_pc n40_cgoodman_cz_pc pre_cgoodman_cz_pc
	
foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = GM_raw_pp
	label var GM`var' "`lab'"

	qui eststo `var': ivreg2 `var' (GM`var' = GM_hat_raw_pp) `b_controls' `extra_controls' [aw=popc1940], r
	
	drop GM`var'
	
}

eststo tsls_`samp' : appendmodels `vars'

foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = GM_hat_raw_pp
	label var GM`var' "`lab'"

	qui eststo `var': reg `var' GM`var' `b_controls' `extra_controls' [aw=popc1940], r
	
	
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




use "$CLEANDATA/cz_pooled", clear
local vars n10_cgoodman_cz_pc n20_cgoodman_cz_pc n30_cgoodman_cz_pc n40_cgoodman_cz_pc pre_cgoodman_cz_pc
	
foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = GM_raw_pp
	label var GM`var' "`lab'"

	qui eststo `var': ivreg2 `var' (GM`var' = GM_hat_raw_pp) `b_controls' [aw=popc1940], r
	
	drop GM`var'
	
}

eststo tsls_`samp' : appendmodels `vars'

foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = GM_hat_raw_pp
	label var GM`var' "`lab'"

	qui eststo `var': reg `var' GM`var' `b_controls' [aw=popc1940], r
	
	
}

eststo rf_`samp' : appendmodels `vars'

esttab tsls_`samp' rf_`samp' ///
				using "$TABS/balancetables/pretrends.tex", ///
				replace label se booktabs noconstant noobs compress nonumber frag mtitles("IV" "Reduced Form") ///
				b(%04.3f) se(%04.3f) //////
				keep(GM*) ///
				prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
		postfoot(	\bottomrule \end{tabular}) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) 
