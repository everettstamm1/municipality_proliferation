
local use_sumshare = 1
local use_pct_inst = 1


// Controls
if `use_sumshare' == 0 local b_controls reg2 reg3 reg4 blackmig3539_share 
if `use_sumshare' == 1 local b_controls reg2 reg3 reg4 v2_sumshares_urban 


if `use_sumshare' == 0 & `use_pct_inst' == 0 local extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local extra_controls coastal transpo_cost_1920  
if `use_sumshare' == 1 & `use_pct_inst' == 1 local extra_controls coastal transpo_cost_1920  

// Inst
if `use_pct_inst' == 0 local inst GM_hat_raw_pp
if `use_pct_inst' == 1 local inst GM_hat_raw

// White inst
if `use_pct_inst' == 0 local winst GM_8_hat_raw
if `use_pct_inst' == 1 local winst GM_8_hat_raw_pp

// White controls
if `use_sumshare' == 0 local w_b_controls reg2 reg3 reg4 v8_whitemig3539_share1940 
if `use_sumshare' == 1 local w_b_controls reg2 reg3 reg4 v8_sumshares_urban 

if `use_sumshare' == 0 & `use_pct_inst' == 0 local w_extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local w_extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local w_extra_controls coastal transpo_cost_1920  
if `use_sumshare' == 1 & `use_pct_inst' == 1 local w_extra_controls coastal transpo_cost_1920  



use "$CLEANDATA/cz_pooled", clear
ren *schdist_m2* *temporary*

drop *schdist_ind*
ren *temporary* *schdist_ind*
keep if dcourt == 1
lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

qui su GM_raw_pp, d
g GM_raw_pp_recentered = GM_raw_pp - `r(mean)'


qui su GM_hat_raw_pp, d
g GM_hat_raw_pp_recentered = GM_hat_raw_pp - `r(mean)'
lab var GM_hat_raw_pp_recentered "$\widehat{GM}$, recentered"
lab var GM_raw_pp_recentered "GM, recentered"
g order = frac_total^2

qui su prop_enclosed, d
g above_med_enclosed = prop_enclosed >= `r(p50)'

g GM_X_above_med_enclosed = GM_raw_pp * above_med_enclosed
g GM_hat_X_above_med_enclosed = `inst' * above_med_enclosed

local b_controls_X `b_controls'
local extra_controls_X `extra_controls'
local w_b_controls_X `w_b_controls'
local w_extra_controls_X `w_extra_controls'
foreach controls in b extra w_b w_extra{
	foreach var of varlist ``controls'_controls'{
		cap confirm variable `var'_X_ame
		if _rc!= 0 {
			g `var'_X_ame = `var' * above_med_enclosed
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_ame
	}
}
	
	

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' `b_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

	eststo clear

	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)		
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls' [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' `extra_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
	eststo clear

	// Recentered table
	
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp_recentered GM_hat_raw_pp_recentered `b_controls' [aw=popc1940], r
		test GM_hat_raw_pp_recentered=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp_recentered `b_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat_raw_pp_recentered `b_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp_recentered = GM_hat_raw_pp_recentered) `b_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_recentered.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(GM_hat_raw_pp_recentered) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_recentered.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp_recentered)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_recentered.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp_recentered)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_recentered.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp_recentered) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

	eststo clear

	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)		
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp_recentered GM_hat_raw_pp_recentered `b_controls' `extra_controls' [aw=popc1940], r
		test GM_hat_raw_pp_recentered=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp_recentered `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat_raw_pp_recentered `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp_recentered = GM_hat_raw_pp_recentered) `b_controls' `extra_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_recentered_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(GM_hat_raw_pp_recentered) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_recentered_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp_recentered)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_recentered_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp_recentered)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_recentered_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp_recentered) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
	eststo clear
	
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' wt_instmig_avg_pp [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' wt_instmig_avg_pp [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' `b_controls' wt_instmig_avg_pp [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' wt_instmig_avg_pp [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_eurmig.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_eurmig.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_eurmig.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_eurmig.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

	eststo clear

eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls' wt_instmig_avg_pp [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls' wt_instmig_avg_pp [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' `b_controls' `extra_controls' wt_instmig_avg_pp [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' `extra_controls' wt_instmig_avg_pp [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_eurmig_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_eurmig_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_eurmig_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_eurmig_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
	eststo clear
	
// Quadratic Effect


lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

g GM_raw_pp_2 = GM_raw_pp^2
g `inst'_2 = `inst'^2

eststo clear
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	su n_`outcome'_cz_pc [aw=popc1940]
	local dv : di %6.2f r(mean)
	su b_`outcome'_cz1940_pc [aw=popc1940]
	local bv : di %6.2f r(mean)
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
	test `inst'=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp GM_raw_pp_2 `b_controls'  [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' `inst'_2 `b_controls'  [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp GM_raw_pp_2 = `inst' `inst'_2) `b_controls'  [aw = popc1940], r
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
	using "$TABS/final/main_effect_quad.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
 keep(`inst') 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
	using "$TABS/final/main_effect_quad.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp GM_raw_pp_2)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
	using "$TABS/final/main_effect_quad.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`inst' `inst'_2)

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
	using "$TABS/final/main_effect_quad.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp GM_raw_pp_2) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

eststo clear


lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"



eststo clear
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	su n_`outcome'_cz_pc [aw=popc1940]
	local dv : di %6.2f r(mean)
	su b_`outcome'_cz1940_pc [aw=popc1940]
	local bv : di %6.2f r(mean)
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls' [aw=popc1940], r
	test `inst'=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp GM_raw_pp_2 `b_controls'  `extra_controls' [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' `inst'_2 `b_controls'  `extra_controls' [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp GM_raw_pp_2 = `inst' `inst'_2) `b_controls'  `extra_controls' [aw = popc1940], r
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
	using "$TABS/final/main_effect_quad_new_ctrl.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
 keep(`inst') 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
	using "$TABS/final/main_effect_quad_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp GM_raw_pp_2)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
	using "$TABS/final/main_effect_quad_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`inst' `inst'_2)

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
	using "$TABS/final/main_effect_quad_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp GM_raw_pp_2) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

eststo clear
	


lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	

//1950-70


lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n2_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n2_`outcome'_cz_pc GM_raw_pp `b_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n2_`outcome'_cz_pc `inst' `b_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n2_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls'  [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
	eststo clear


lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n2_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls'[aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n2_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n2_`outcome'_cz_pc `inst' `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n2_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' `extra_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

		eststo clear

// Long differences



lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su ld_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg ld_`outcome'_cz_pc GM_raw_pp `b_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg ld_`outcome'_cz_pc `inst' `b_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 ld_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls'  [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_ld.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_ld.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_ld.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_ld.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
 eststo clear
		





lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su ld_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls'[aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg ld_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg ld_`outcome'_cz_pc `inst' `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 ld_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' `extra_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
eststo clear


		


lab var GM_hat "$\widehat{GM}$ Percentile"
lab var GM "GM Percentile"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM GM_hat `b_controls'  [aw=popc1940], r
		test GM_hat=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM `b_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat `b_controls'   [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM = GM_hat) `b_controls'   [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}
// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_pctile.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(GM_hat) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_pctile.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_pctile.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_pctile.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

		eststo clear		



lab var GM_hat "$\widehat{GM}$ Percentile"
lab var GM "GM Percentile"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM GM_hat `b_controls' `extra_controls'[aw=popc1940], r
		test GM_hat=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM = GM_hat) `b_controls' `extra_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(GM_hat) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

		eststo clear
		
		
		
		
// White inst


lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg WM_raw_pp `winst' `w_b_controls' [aw=popc1940], r
		test GM_8_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc WM_raw_pp `w_b_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `winst' `w_b_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (WM_raw_pp = `winst') `w_b_controls' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/white_effect.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`winst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/white_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/white_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`winst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/white_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
eststo clear




lab var GM_8_hat_raw_pp "$\widehat{WM}$"
lab var WM_raw_pp "WM"
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg WM_raw_pp `winst' `w_b_controls' `w_extra_controls'[aw=popc1940], r
		test GM_8_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc WM_raw_pp `w_b_controls' `w_extra_controls'[aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `winst' `w_b_controls' `w_extra_controls'[aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (WM_raw_pp = `winst') `w_b_controls' `w_extra_controls'[aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'
	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`winst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`winst')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
eststo clear



local b_controls_X `b_controls'
local extra_controls_X `extra_controls'
local w_b_controls_X `w_b_controls'
local w_extra_controls_X `w_extra_controls'
foreach controls in b extra w_b w_extra{
	foreach var of varlist ``controls'_controls'{
		cap confirm variable `var'_X_ame
		if _rc!= 0 {
			g `var'_X_ame = `var' * above_med_enclosed
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_ame
	}
}
	
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst' GM_hat_X_above_med_enclosed  above_med_enclosed `b_controls_X' [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp GM_X_above_med_enclosed above_med_enclosed `b_controls_X' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' GM_hat_X_above_med_enclosed above_med_enclosed  `b_controls_X' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp GM_X_above_med_enclosed = `inst' GM_hat_X_above_med_enclosed) above_med_enclosed  `b_controls_X' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_med_enclosed.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_med_enclosed.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp GM_X_above_med_enclosed)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_med_enclosed.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst' GM_hat_X_above_med_enclosed)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_med_enclosed.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp GM_X_above_med_enclosed) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

	eststo clear
	
	
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=popc1940]
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `inst'  GM_hat_X_above_med_enclosed  above_med_enclosed  `b_controls_X' `extra_controls_X' [aw=popc1940], r
		test `inst'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp GM_X_above_med_enclosed `b_controls_X' `extra_controls_X' above_med_enclosed [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc `inst' GM_hat_X_above_med_enclosed `b_controls_X' `extra_controls_X' above_med_enclosed [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp GM_X_above_med_enclosed = `inst' GM_hat_X_above_med_enclosed) above_med_enclosed `b_controls_X' `extra_controls_X' [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "$TABS/final/main_effect_med_enclosed_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`inst') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "$TABS/final/main_effect_med_enclosed_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp GM_X_above_med_enclosed)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "$TABS/final/main_effect_med_enclosed_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`inst' GM_hat_X_above_med_enclosed)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "$TABS/final/main_effect_med_enclosed_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp GM_X_above_med_enclosed) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

	eststo clear
	
// Log Differences

	

eststo clear
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	su n_`outcome'_cz_ld [aw=popc1940]
	local dv : di %6.2f r(mean)
	su b_`outcome'_cz1940_pc [aw=popc1940]
	local bv : di %6.2f r(mean)
	
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
	test `inst'=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg n_`outcome'_cz_ld GM_raw_pp `b_controls' [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg n_`outcome'_cz_ld `inst' `b_controls' [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 n_`outcome'_cz_ld (GM_raw_pp = `inst') `b_controls' [aw = popc1940], r
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
		estadd scalar b_var = `bv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
	using "$TABS/final/main_effect_log.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
 keep(`inst') 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
	using "$TABS/final/main_effect_log.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
	using "$TABS/final/main_effect_log.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`inst')

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
	using "$TABS/final/main_effect_log.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

eststo clear

foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
	su n_`outcome'_cz_ld [aw=popc1940]
	local dv : di %6.2f r(mean)
	su b_`outcome'_cz1940_pc [aw=popc1940]
	local bv : di %6.2f r(mean)		
	
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls' [aw=popc1940], r
	test `inst'=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg n_`outcome'_cz_ld GM_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg n_`outcome'_cz_ld `inst' `b_controls' `extra_controls' [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 n_`outcome'_cz_ld (GM_raw_pp = `inst') `b_controls' `extra_controls' [aw = popc1940], r
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
		estadd scalar b_var = `bv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
	using "$TABS/final/main_effect_log_new_ctrl.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
 keep(`inst') 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
	using "$TABS/final/main_effect_log_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
	using "$TABS/final/main_effect_log_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`inst')

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
	using "$TABS/final/main_effect_log_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
eststo clear



// Log Baseline
	

eststo clear
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	su n_`outcome'_cz_ld [aw=popc1940]
	local dv : di %6.2f r(mean)
	su b_`outcome'_cz1940_pc [aw=popc1940]
	local bv : di %6.2f r(mean)
	
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' l_b_`outcome'_cz1940 l_pop1940 [aw=popc1940], r
	test `inst'=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg l_b_`outcome'_cz1970 GM_raw_pp `b_controls' l_b_`outcome'_cz1940 l_pop1940 [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg l_b_`outcome'_cz1970 `inst' `b_controls' l_b_`outcome'_cz1940 l_pop1940 [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 l_b_`outcome'_cz1970 (GM_raw_pp = `inst') `b_controls' l_b_`outcome'_cz1940 l_pop1940 [aw = popc1940], r
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
		estadd scalar b_var = `bv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
	using "$TABS/final/main_effect_logb.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
 keep(`inst') 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
	using "$TABS/final/main_effect_logb.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
	using "$TABS/final/main_effect_logb.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`inst')

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
	using "$TABS/final/main_effect_logb.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

eststo clear

foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac{
	su n_`outcome'_cz_ld [aw=popc1940]
	local dv : di %6.2f r(mean)
	su b_`outcome'_cz1940_pc [aw=popc1940]
	local bv : di %6.2f r(mean)		
	
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp `inst' `b_controls' `extra_controls' l_b_`outcome'_cz1940 l_pop1940 [aw=popc1940], r
	test `inst'=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg l_b_`outcome'_cz1970 GM_raw_pp `b_controls' `extra_controls' l_b_`outcome'_cz1940 l_pop1940 [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg l_b_`outcome'_cz1970 `inst' `b_controls' `extra_controls' l_b_`outcome'_cz1940 l_pop1940 [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 l_b_`outcome'_cz1970 (GM_raw_pp = `inst') `b_controls' `extra_controls' l_b_`outcome'_cz1940 l_pop1940 [aw = popc1940], r
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
		estadd scalar b_var = `bv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
	using "$TABS/final/main_effect_logb_new_ctrl.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
 keep(`inst') 

// Panel B: OLS
esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
	using "$TABS/final/main_effect_logb_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp)


// Panel C: RF
esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
	using "$TABS/final/main_effect_logb_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`inst')

	
// Panel D: 2SLS
esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
	using "$TABS/final/main_effect_logb_new_ctrl.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))
eststo clear