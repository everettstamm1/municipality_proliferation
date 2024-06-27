cap prog drop poisson_table
prog def poisson_table
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) type(string) [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist)]
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni {
		su n_`outcome'_cz_pc [aw=`weight']
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc [aw=`weight']
		local bv : di %6.2f r(mean)
		
		local ctrls `controls' ``outcome''
		di "`ctrls'"
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `exog' `ctrls' b_`outcome'_cz1940 pop1940 bpop1940 [pw=`weight'], r
		test `exog'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : poisson b_`outcome'_cz1970 `endog' `endog2' `ctrls' b_`outcome'_cz1940  [pw = `weight'], r 
		
		// RF
		eststo rf_`outcome' : poisson b_`outcome'_cz1970 `exog' `exog2' `ctrls' b_`outcome'_cz1940  [pw = `weight'], r 
		
		// 2SLS 
		if "`type'"=="ivpoisson"{
			eststo iv_`outcome' : ivpoisson cfunction b_`outcome'_cz1970 (`endog' `endog2' = `exog' `exog2') `ctrls' b_`outcome'_cz1940  [pw = `weight'], vce(r) 
		}
		else if "`type'"=="manual"{
						
			reg b_`outcome'_cz1970 `endog' `endog2' `exog' `exog2' `ctrls'  b_`outcome'_cz1940 [aw=`weight'], r
			predict v2, resid
			eststo iv_`outcome': poisson b_`outcome'_cz1970 pop1940 GM_raw_pp `ctrls' b_`outcome'_cz1940  v2 [pw=`weight'], r 
			drop v2
		}
		estadd scalar Fs = `F'
		estadd scalar dep_var = `dv'
		estadd scalar b_var = `bv'

	}

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist      ///
		using "`path'", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\\\cmidrule(lr){2-3}\cmidrule(lr){4-5}\cmidrule(lr){6-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead( \begin{tabular}{l*{8}{c}} \toprule) ///
	 keep(`exog') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist   ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist   ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`exog' `exog2')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist   ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0))

	eststo clear
end