cap prog drop main_table_towns_ssaggregate
prog def main_table_towns
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) deplab(string) [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist) totfrac(varlist)]
	
	eststo clear
	foreach outcome in gen_town {
		local ctrls `controls' ``outcome''

		su `deplab'_`outcome'_cz_pc 
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc 
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg `endog' `exog' `ctrls' [aw=`weight'], r
		test `exog'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg `deplab'_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		
		// RF
		eststo rf_`outcome' : reg `deplab'_`outcome'_cz_pc `exog' `exog2' `ctrls' [aw = `weight'], r
		local N_`outcome' = e(N)

		
		
		

	}
	// 2SLS 
	preserve 
		ssaggregate `deplab'_`outcome'_cz_pc  `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		
		foreach outcome in   gen_town  {
			eststo iv_`outcome': ivreg2 `deplab'_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			estadd scalar Fs = `F_`outcome''
			estadd scalar dep_var = `dv_`outcome''
			estadd scalar b_var = `bv_`outcome''
			estadd scalar nobs = `N_`outcome''
		}
	restore
	
	local stats `"Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0)"'

	// Panel A: First Stage
	esttab fs_gen_town      ///
		using "`path'", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{Census of Governments}\\\cmidrule(lr){2-2}" ///
                "&\multicolumn{1}{c}{Townships}\\\cmidrule(lr){2-2}" ///
				"&\multicolumn{1}{c}{(1)}\\" ///
				"\cmidrule(lr){1-2}" ///
				"\multicolumn{1}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-2}" ) ///
		prehead( \begin{tabular}{l*{3}{c}} \toprule) ///
	 keep(`exog') 

	// Panel B: OLS
	esttab ols_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


	// Panel C: RF
	esttab rf_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`exog' `exog2')

		
	// Panel D: 2SLS
	esttab iv_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(`stats')

	eststo clear
end