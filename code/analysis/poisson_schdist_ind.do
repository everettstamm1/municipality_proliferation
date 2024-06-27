
use "$CLEANDATA/cz_pooled.dta", clear
ren *schdist_m2* *temporary*

drop *schdist_ind*
ren *temporary* *schdist_ind*
keep if dcourt == 1
drop if n_schdist_ind_cz_pc==.

// Clearly School Districts have (invese of) poisson distribution compared to the normal-ish distributions of others
foreach outcome in cgoodman gen_muni schdist_ind gen_town spdist{
	//hist n_schdist_ind_cz_pc, freq
	//graph export "$FIGS/schdist_ind_hist.pdf", replace
}

// So what we need is to invert the school districts outcome so it's all positive, run a poisson regression, interpret the coefficient, and compute counterfactual

replace n_schdist_ind_cz_pc = -n_schdist_ind_cz_pc

// First Stage
reg GM_raw_pp GM_hat_raw reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw=popc1940], r
predict GM_hat_raw_hat

// Endogeneous Poisson
poisson n_schdist_ind_cz_pc GM_raw_pp reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [pw=popc1940], r
// Coef: -.0655289

// Reduced Form Poisson
poisson n_schdist_ind_cz_pc GM_hat_raw reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [pw=popc1940], r
// Coef:  -.2332381 

// IV Poisson
ivpoisson cfunction n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [pw=popc1940], vce(r)

// Coef: -.0604874 

//reg n_schdist_ind_cz_pc GM_raw_pp GM_hat_raw reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw=popc1940], r
//predict v2, resid
//poisson n_schdist_ind_cz_pc pop1940 GM_raw_pp reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban v2 [pw=popc1940], r 

predict y_hat if e(sample)

// Counterfactual IV Poisson
replace GM_raw_pp = 0
predict cf_schdist_ind if e(sample)

order y_hat cf_schdist_ind n_schdist_ind_cz_pc

// Transformation
replace cf_schdist_ind = (pop1970/10000)*((-1)*cf_schdist_ind + (b_schdist_ind_cz1940/(pop1940/10000))) - b_schdist_ind_cz1940
g pred_schdist_ind = (pop1970/10000)*((-1)*y_hat + (b_schdist_ind_cz1940/(pop1940/10000)))  - b_schdist_ind_cz1940
g check = (pop1970/10000)*((-1)*n_schdist_ind_cz_pc + (b_schdist_ind_cz1940/(pop1940/10000)))  - b_schdist_ind_cz1940

g real_schdist_ind = b_schdist_ind_cz1970  - b_schdist_ind_cz1940


// Format output
collapse (mean) cf* real* check pred_*
g n = _n
reshape long cf_ real_, i(n) j(name) string
ren cf_ counterfactual_change
ren real_ real_change
ren pred_ pred_change
drop n
drop n
g cf_real_difference = counterfactual_change - real_change
g pred_real_difference = pred_change - real_change
g cf_pred_difference = counterfactual_change - pred_change







use "$CLEANDATA/cz_pooled", clear

// New balance tables

local b_controls reg2 reg3 reg4 v2_sumshares_urban pop1940 bpop1940
local balance_cutoff = 0.10
local samp = "urban"

foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni {
	
use "$CLEANDATA/cz_pooled", clear
local covars avg_precip avg_temp coastal mfg_lfshare1940 m_rr_sqm_total p90_total p95_total transpo_cost_1920
local pooled_covars_`samp'  ""
keep if dcourt == 1
	foreach covar in `covars' {
		local lab : variable label `covar'
		g GM`covar' = GM_hat_raw
		label var GM`covar' "`lab'"

		qui eststo `covar': reg `covar' GM`covar' `b_controls' b_`outcome'_cz1940 [aw=popc1940], r
		local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
		di "`covar' p value : `p'"
		if `p'<=`balance_cutoff'{
			local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
		}
	}

	eststo pooled_`samp' : appendmodels `covars'

	esttab pooled_`samp'  ///
					using "$TABS/balancetables/balancetable_`outcome'.tex", ///
					replace label se booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{GM}$") ///
					b(%04.3f) se(%04.3f) //////
					keep(GM*) ///
					prehead( \begin{tabular}{l*{1}{c}} \toprule) ///
			postfoot(	\bottomrule \end{tabular}) ///
					starlevels( * 0.10 ** 0.05 *** 0.01) 
}

// School districts get mfg_lfshare1940 and transpo_cost_1920, special districts get average temp

keep if dcourt == 1
g ldiff =log(pop1970) - log(pop1940)
poisson_table, endog(GM_raw_pp) exog(GM_hat_raw) type("ivpoisson") controls(reg2 reg3 reg4 v2_sumshares_urban bpop1940)  weight(popc1940) path("$TABS/poisson/base.tex") spdist(avg_temp) schdist_ind(mfg_lfshare1940 transpo_cost_1920)

