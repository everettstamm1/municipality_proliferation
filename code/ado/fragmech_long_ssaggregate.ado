cap prog drop fragmech_long_ssaggregate
prog def fragmech_long_ssaggregate
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) version(string) share_folder(string) origin_id(string)  [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist) totfrac(varlist)]
	
	eststo clear 
	foreach outcome in dead dead_w inc_annex pinc {
		local ctrls `controls' ``outcome''

		su n_`outcome'_cz_pc 
		local dv70_`outcome' : di %6.2f r(mean)
		su ld_`outcome'_cz_pc 
		local dv10_`outcome' : di %6.2f r(mean)
		
		
		// First Stage
		eststo fs_`outcome' : reg `endog' `exog' `ctrls' if !mi(n_`outcome'_cz_pc) [aw=`weight'], r
		test `exog'=0 
		local F_`outcome' : di %6.2f r(F)

		// OLS 1940-70
		eststo ols70_`outcome' : reg n_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		

		// OLS 1940-2010
		eststo ols10_`outcome' : reg ld_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		local N_`outcome' = e(N)

	}
	
	preserve 
		ssaggregate n_dead_cz_pc n_dead_w_cz_pc n_inc_annex_cz_pc  n_pinc_cz_pc ld_dead_cz_pc ld_dead_w_cz_pc ld_inc_annex_cz_pc ld_pinc_cz_pc `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		
		foreach outcome in dead dead_w inc_annex pinc  {
			eststo iv70_`outcome': ivreg2 n_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			
			estadd scalar dep_var70 = `dv70_`outcome''
			eststo iv10_`outcome': ivreg2 ld_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			
			estadd scalar dep_var10 = `dv10_`outcome''
			estadd scalar Fs = `F_`outcome''
			estadd scalar nobs = `N_`outcome''
		}
	restore
	
	local stats `"Fs dep_var70 N, labels("First Stage F-Stat" "Dep. Var. Mean"  "Observations") fmt(2 2 2 0)"'
		

	

	// Panel A: First Stage
	esttab fs_dead fs_dead_w fs_inc_annex   fs_pinc    ///
		using "`path'", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{2}{c}{Disincorporations/Consolidations}&\multicolumn{2}{c}{Incumbent Municipality Land}\\\cmidrule(lr){2-3}\cmidrule(lr){4-5}" ///
                "&\multicolumn{1}{c}{Raw}&\multicolumn{1}{c}{Zero Censored}&\multicolumn{1}{c}{$\Delta \log$ Land}&\multicolumn{1}{c}{$\Delta$ Prop. Incorporated}\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\cmidrule(lr){1-5}" ///
				"\multicolumn{4}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-5}" ) ///
		prehead( \begin{tabularx}{\textwidth}{l*{4}{>{\centering\arraybackslash}X}} \toprule ) ///
	 keep(`exog') 

	// Panel B: OLS
	esttab ols70_dead ols70_dead_w ols70_inc_annex  ols70_pinc  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel B: OLS 1940-1970}\\" "\cmidrule(lr){1-5}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


		
	// Panel C: 2SLS
	esttab iv70_dead iv70_dead_w iv70_inc_annex  iv70_pinc ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel C: 2SLS 1940-1970}\\" "\cmidrule(lr){1-5}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		stats(dep_var70, labels("1940-70 Avg.") fmt(2))
		
		// Panel D: OLS
	esttab ols10_dead ols10_dead_w ols10_inc_annex  ols10_pinc ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel D: OLS 1940-2010}\\" "\cmidrule(lr){1-5}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


		
	// Panel E: 2SLS
	esttab iv10_dead iv10_dead_w iv10_inc_annex  iv10_pinc ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel E: 2SLS 1940-2010}\\" "\cmidrule(lr){1-5}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabularx}) ///
		stats(dep_var10 Fs nobs, labels("1940-2010 Avg." "First Stage F-Stat" "Observations") fmt(2 2 0)) substitute("\midrule" "\cmidrule(lr){1-5}")

	eststo clear
end