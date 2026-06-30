//New Tests
local do_balance = 1
local do_pretrends = 1
local do_main = 1

foreach inst in original percent{
	if "`inst'"=="original" local pp "_pp"
	if "`inst'"=="percent" local pp ""

	foreach ctrl in blackmig sumshares both{
		eststo clear
		
		if "`ctrl'" == "blackmig" local b_controls reg2 reg3 reg4 blackmig3539_share
		if "`ctrl'" == "sumshares" local b_controls reg2 reg3 reg4 v2_sumshares_urban
		if "`ctrl'" == "both" local b_controls reg2 reg3 reg4 blackmig3539_share v2_sumshares_urban

		local balance_cutoff = 0.10
		local samp = "urban"

		use "$CLEANDATA/cz_pooled", clear
		local covars avg_precip avg_temp coastal mfg_lfshare1940 m_rr_sqm_total p90_total p95_total transpo_cost_1920
		local imbalanced_covars  ""
		keep if dcourt == 1
		foreach covar in `covars' {
			local lab : variable label `covar'
			g GM`covar' = GM_hat_raw`pp'
			label var GM`covar' "`lab'"

			qui eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
			local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
			di "`covar' p value : `p'"
			if `p'<=`balance_cutoff'{
				local imbalanced_covars  "`imbalanced_covars' `covar'"
				}
			}

		eststo pooled_`samp' : appendmodels `covars'

		esttab pooled_`samp'  ///
						using "$TABS/balancetables/balancetable_`inst'_`ctrl'.tex", ///
						replace label se booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{GM}$") ///
						b(%04.3f) se(%04.3f) //////
						keep(GM*) ///
						prehead( \begin{tabular}{l*{1}{c}} \toprule) ///
				postfoot(	\bottomrule \end{tabular}) ///
						starlevels( * 0.10 ** 0.05 *** 0.01)  
		di "SIG: `imbalanced_covars'"
	
		foreach c in "base" "new_ctrls"{
			if "`c'"=="base" local ctrls `b_controls'
			if "`c'"=="new_ctrls" local ctrls `b_controls' `imbalanced_covars'
			
			// Pretrends
			eststo clear
			use "$CLEANDATA/cz_pooled", clear
			local vars n10_cgoodman_cz_pc n20_cgoodman_cz_pc n30_cgoodman_cz_pc n40_cgoodman_cz_pc pre_cgoodman_cz_pc
			keep if dcourt == 1

			foreach var in `vars' {
				local lab : variable label `var'
				g GM`var' = GM_raw_pp
				label var GM`var' "`lab'"

				qui eststo `var': ivreg2 `var' (GM`var' = GM_hat_raw`pp') `ctrls' [aw=popc1940], r
				
				drop GM`var'
				
			}

			eststo tsls_`samp' : appendmodels `vars'

			foreach var in `vars' {
				local lab : variable label `var'
				g GM`var' = GM_hat_raw`pp'
				label var GM`var' "`lab'"

				qui eststo `var': reg `var' GM`var' `ctrls' [aw=popc1940], r
				
				
			}

			eststo rf_`samp' : appendmodels `vars'

			esttab tsls_`samp' rf_`samp' ///
							using "$TABS/balancetables/pretrends_`inst'_`ctrl'_`c'.tex", ///
							replace label se booktabs noconstant noobs compress nonumber frag  mtitles("IV" "Reduced Form") ///
							b(%04.3f) se(%04.3f) //////
							keep(GM*) ///
							prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
					postfoot(	\bottomrule \end{tabular}) ///
							starlevels( * 0.10 ** 0.05 *** 0.01) 
							
			// Main table			
			use "$CLEANDATA/cz_pooled", clear
			keep if dcourt == 1
			lab var GM_hat_raw_pp "$\widehat{GM}$ (pp)"
			lab var GM_hat_raw "$\widehat{GM}$ (pct)"
			
			lab var GM_raw_pp "GM"	
			
			
					
			eststo clear
			foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
				su n_`outcome'_cz_pc [aw=popc1940]
				local dv : di %6.2f r(mean)
				su b_`outcome'_cz1940_pc [aw=popc1940]
				local bv : di %6.2f r(mean)
				
				// First Stage
				eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw`pp' `ctrls' [aw=popc1940], r
				test GM_hat_raw`pp'=0
				local F : di %6.2f r(F)

				// OLS
				eststo ols_`outcome' : reg n_`outcome'_cz_pc GM_raw_pp `ctrls' [aw = popc1940], r
				
				// RF
				eststo rf_`outcome' : reg n_`outcome'_cz_pc GM_hat_raw`pp' `ctrls' [aw = popc1940], r
				
				// 2SLS 
				eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw`pp') `ctrls' [aw = popc1940], r
					estadd scalar Fs = `F'
					estadd scalar dep_var = `dv'
					estadd scalar b_var = `bv'

			}

			// Panel A: First Stage
			esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
				using "$TABS/final/main_effect_`inst'_`ctrl'_`c'.tex", ///
				replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
				b(%04.3f) se(%04.3f) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
						"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
						"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
						"\cmidrule(lr){1-7}" ///
						"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
				prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
			 keep(GM_hat_raw`pp') 

			// Panel B: OLS
			esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
				using "$TABS/final/main_effect_`inst'_`ctrl'_`c'.tex", ///
				se booktabs noconstant compress frag append noobs nonum nomtitle label ///
				posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
				b(%04.3f) se(%04.3f) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				keep(GM_raw_pp)


			// Panel C: RF
			esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
				using "$TABS/final/main_effect_`inst'_`ctrl'_`c'.tex", ///
				se booktabs noconstant compress frag append noobs nonum nomtitle label ///
				posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
				b(%04.3f) se(%04.3f) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				keep(GM_hat_raw`pp')

				
			// Panel D: 2SLS
			esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
				using "$TABS/final/main_effect_`inst'_`ctrl'_`c'.tex", ///
				se booktabs noconstant compress frag append noobs nonum nomtitle label ///
				posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
				b(%04.3f) se(%04.3f) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				keep(GM_raw_pp) ///
				postfoot(	\bottomrule \end{tabular}) ///
				stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

			eststo clear
		}
	}
}
