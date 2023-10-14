

local b_controls reg2 reg3 reg4 blackmig3539_share
local extra_controls urban_share1940 frac_total transpo_cost_1920 m_rr_sqm_total

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
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
		using "$TABS/final/main_effect.tex", ///
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
		using "$TABS/final/main_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

	

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' `extra_controls' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' `extra_controls' [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist  ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
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
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

	

//1950-70
use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n2_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n2_`outcome'_cz_pc GM_raw_pp `b_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n2_`outcome'_cz_pc GM_hat_raw_pp `b_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n2_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls'  [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum  ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead(   \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat_raw_pp)
	

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_1950_1970.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

		eststo clear

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n2_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' `extra_controls' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n2_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n2_`outcome'_cz_pc GM_hat_raw_pp `b_controls' `extra_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n2_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' `extra_controls'  [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum  ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead(   \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat_raw_pp)
	

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_1950_1970_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

		eststo clear

// Long differences
use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su ld_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg ld_`outcome'_cz_pc GM_raw_pp `b_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg ld_`outcome'_cz_pc GM_hat_raw_pp `b_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 ld_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls'  [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist ///
		using "$TABS/final/main_effect_ld.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum  ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead(   \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat_raw_pp)
	

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_ld.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_ld.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_ld.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

		eststo clear
		



use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su ld_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' `extra_controls' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg ld_`outcome'_cz_pc GM_raw_pp `b_controls' `extra_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg ld_`outcome'_cz_pc GM_hat_raw_pp `b_controls' `extra_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 ld_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' `extra_controls'  [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum  ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead(   \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat_raw_pp)
	

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_ld_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

		eststo clear
		


		

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat "$\widehat{GM}$ Percentile"
lab var GM "GM Percentile"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
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
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist ///
		using "$TABS/final/main_effect_pctile.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum  ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead(   \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat)
	

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_pctile.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_pctile.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_pctile.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

		eststo clear		

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat "$\widehat{GM}$ Percentile"
lab var GM "GM Percentile"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM GM_hat `b_controls' `extra_controls' [aw=popc1940], r
		test GM_hat=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc GM `b_controls' `extra_controls'  [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat `b_controls' `extra_controls'  [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM = GM_hat) `b_controls' `extra_controls'  [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum  ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead(   \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_hat)
	

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_hat)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/main_effect_pctile_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

		eststo clear
		
		
// White inst
use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1
local b_controls reg2 reg3 reg4 v8_whitemig3539_share1940
local extra_controls urban_share1940 frac_total transpo_cost_1920 m_rr_sqm_total

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg WM_raw_pp GM_8_hat_raw_pp `b_controls' [aw=popc1940], r
		test GM_8_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc WM_raw_pp `b_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_8_hat_raw_pp `b_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (WM_raw_pp = GM_8_hat_raw_pp) `b_controls' [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist  ///
		using "$TABS/final/white_effect.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead( \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_8_hat_raw_pp) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/white_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/white_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_8_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/white_effect.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

	

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_8_hat_raw_pp "$\widehat{WM}$"
lab var WM_raw_pp "WM"

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
		su n_`outcome'_cz_pc [aw=popc1940]
		local dv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg WM_raw_pp GM_8_hat_raw_pp `b_controls' `extra_controls' [aw=popc1940], r
		test GM_8_hat_raw_pp=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg n_`outcome'_cz_pc WM_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// RF
		eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_8_hat_raw_pp `b_controls' `extra_controls' [aw = popc1940], r
		
		// 2SLS 
		eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (WM_raw_pp = GM_8_hat_raw_pp) `b_controls' `extra_controls' [aw = popc1940], r
			estadd local Fs = `F'
			estadd local dep_var = `dv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist  ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead( \begin{tabular}{l*{7}{c}} \toprule) ///
	 keep(GM_8_hat_raw_pp) 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp)


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_8_hat_raw_pp)

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist ///
		using "$TABS/final/white_effect_new_ctrl.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(WM_raw_pp) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

	
