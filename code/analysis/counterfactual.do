// Read data

use "$CLEANDATA/cz_pooled.dta", clear
ren *schdist_m2* *temporary*

drop *schdist_ind*
ren *temporary* *schdist_ind*
keep if dcourt == 1



foreach outcome in cgoodman gen_muni schdist_ind gen_town spdist{
	
	//hist n_`outcome'_cz_pc, freq
	//graph export "$FIGS/`outcome'_hist.pdf", replace
	
	// First Stage
	reg GM_raw_pp GM_hat_raw reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw=popc1940], r
	predict GM_hat_raw_hat
	
	// Second Stage
	reg n_`outcome'_cz_pc GM_hat_raw_hat reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw=popc1940], r
	predict pred_`outcome' if e(sample)
	
	// Counterfactual
	replace GM_hat_raw_hat = 0
	predict cf_`outcome' if e(sample)
	
	// Transformation
	replace cf_`outcome' = (pop1970/10000)*(cf_`outcome' + (b_`outcome'_cz1940/(pop1940/10000))) - b_`outcome'_cz1940
	replace pred_`outcome' = (pop1970/10000)*(pred_`outcome' + (b_`outcome'_cz1940/(pop1940/10000))) - b_`outcome'_cz1940

	g real_`outcome' = b_`outcome'_cz1970 - b_`outcome'_cz1940
	drop GM_hat_raw_hat
}

// Format output
collapse (mean) cf* real* pred_*
g n = _n
reshape long cf_ real_ pred_, i(n) j(name) string
ren cf_ counterfactual_change
ren real_ real_change
ren pred_ pred_change

drop n
g cf_real_difference = counterfactual_change - real_change
g pred_real_difference = pred_change - real_change
g cf_pred_difference = counterfactual_change - pred_change

estpost tabstat counterfactual_change pred_change real_change cf_real_difference pred_real_difference cf_pred_difference, by(name)

esttab using "$TABS/counterfactual.tex", cells("counterfactual_change real_change difference") noobs nomtitle ///
nonumber varlabels(`e(labels)') varwidth(30)  replace booktabs drop(Total)
