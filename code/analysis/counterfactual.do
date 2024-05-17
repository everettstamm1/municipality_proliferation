// Read data

use "$CLEANDATA/cz_pooled.dta", clear

foreach outcome in cgoodman gen_muni schdist_ind gen_town spdist{
	
	// First Stage
	reg GM_raw_pp GM_hat_raw reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw=popc1940], r
	predict GM_hat_raw_hat
	
	// Second Stage
	reg n_`outcome'_cz_pc GM_hat_raw_hat reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw=popc1940], r
	predict y_hat
	
	// Counterfactual
	replace GM_hat_raw_hat = 0
	predict cf_`outcome'
	
	// Transformation
	replace cf_`outcome' = (pop1970/10000)*(cf_`outcome' + (b_`outcome'_cz1940/(pop1940/10000))) - b_`outcome'_cz1940
	g real_`outcome' = b_`outcome'_cz1970 - b_`outcome'_cz1940
	drop y_hat GM_hat_raw_hat
}

// Format output
collapse (mean) cf* real*
g n = _n
reshape long cf_ real_, i(n) j(name) string
ren cf_ counterfactual_change
ren real_ real_change
drop n
g difference = counterfactual_change - real_change
estpost tabstat counterfactual_change real_change difference, by(name)

esttab using "$TABS/counterfactual.tex", cells("counterfactual_change real_change difference") noobs nomtitle ///
nonumber varlabels(`e(labels)') varwidth(30)  replace booktabs drop(Total)
