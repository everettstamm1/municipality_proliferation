cap prog drop main_table_towns_ssaggregate
prog def main_table_towns_ssaggregate
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) version(string) share_folder(string) origin_id(string)  [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist) totfrac(varlist)]
	
	eststo clear
	foreach outcome in gen_town {
		local ctrls `controls' ``outcome''

		su n_`outcome'_cz_pc 
		local dv70_`outcome' : di %6.2f r(mean)
		su ld_`outcome'_cz_pc 
		local dv10_`outcome' : di %6.2f r(mean)

		su b_`outcome'_cz1940_pc 
		local bv_`outcome' : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg `endog' `exog' `ctrls' [aw=`weight'], r
		test `exog'=0
		local F_`outcome' : di %6.2f r(F)

		// OLS
		eststo ols70_`outcome' : reg n_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		
		// OLS
		eststo ols10_`outcome' : reg ld_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		local N_`outcome' = e(N)

		
		
		

	}
	// 2SLS 
	preserve 
		ssaggregate n_gen_town_cz_pc ld_gen_town_cz_pc `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		
		foreach outcome in   gen_town  {
			eststo iv70_`outcome': ivreg2 n_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			estadd scalar dep_var70 = `dv70_`outcome''
			eststo iv10_`outcome': ivreg2 ld_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			estadd scalar dep_var10 = `dv10_`outcome''
			estadd scalar Fs = `F_`outcome''
			estadd scalar b_var = `bv_`outcome''
			estadd scalar nobs = `N_`outcome''

		}
	restore
	
	local stats `"Fs dep_var b_var nobs, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0)"'
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

	// Panel B: OLS70
	esttab ols70_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel B: OLS 1940-1970}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


	// Panel C: IV70
	esttab iv70_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel C: 2SLS 1940-1970}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		stats(dep_var70, labels("1940-70 Avg.") fmt(2))
	// Panel D: OLS10
	
	esttab ols10_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel D: OLS 1940-2010}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')
		
	// Panel D: 2SLS
	esttab iv10_gen_town  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-2}" "\multicolumn{1}{l}{Panel E: 2SLS 1940-2010}\\" "\cmidrule(lr){1-2}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(`stats')

	eststo clear
end