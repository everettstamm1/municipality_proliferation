
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
nbreg n_schdist_ind_cz_pc GM_raw_pp reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [pw=popc1940], r
// Coef: -.0655289

// Reduced Form Poisson
nbreg n_schdist_ind_cz_pc GM_hat_raw reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [pw=popc1940], r
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