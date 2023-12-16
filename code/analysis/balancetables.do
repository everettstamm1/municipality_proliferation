

local b_controls reg2 reg3 reg4 blackmig3539_share
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear
local covars urban_share1940 frac_total transpo_cost_1920 coastal urbfrac_in_main_city avg_precip avg_temp
	
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

					
		

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"
foreach covar in `pooled_covars_`samp''{
	eststo clear
	local b_controls reg2 reg3 reg4 blackmig3539_share `covar'

	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist  ///
		using "$TABS/final/main_effect_`covar'.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead( \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat_raw_pp) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_`covar'.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_`covar'.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_`covar'.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))
}
	

	
			

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"
eststo clear
local b_controls reg2 reg3 reg4 blackmig3539_share `pooled_covars_`samp''

foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
	su n_`outcome'_cz_pc [aw=popc1940]
	local dv : di %6.2f r(mean)
	
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls' [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' [aw = popc1940], r
		estadd local Fs = `F'
		estadd local dep_var = `dv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist  ///
	using "$TABS/final/main_effect_all_covars.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
			"\cmidrule(lr){1-6}" ///
			"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
	prehead( \begin{tabular}{l*{7}{c}} \toprule) ///
 keep(GM_hat_raw_pp) 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
	using "$TABS/final/main_effect_all_covars.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
	using "$TABS/final/main_effect_all_covars.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_hat_raw_pp)

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
	using "$TABS/final/main_effect_all_covars.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

	
	


local b_controls reg2 reg3 reg4 blackmig3539_share
local extra_controls urban_share1940 frac_total transpo_cost_1920
 

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




local b_controls reg2 reg3 reg4 blackmig3539_share
local extra_controls urban_share1940 frac_total transpo_cost_1920 m_rr_sqm_total
 
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
