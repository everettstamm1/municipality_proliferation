cap prog drop main_table_long_ssaggregate2
prog def main_table_long_ssaggregate2
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) version(string) share_folder(string) origin_id(string)  [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist) totfrac(varlist)]
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_muni spdist totfrac {
		local ctrls `controls' ``outcome''

		su n2_`outcome'_cz_pc 
		local dv70_`outcome' : di %6.2f r(mean)
		su ld2_`outcome'_cz_pc 
		local dv10_`outcome' : di %6.2f r(mean)
		su b_`outcome'_cz1950_pc 
		local bv_`outcome' : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `exog' `ctrls' if !mi(n_`outcome'_cz_pc) [aw=`weight'], r
		test `exog'=0 
		local F_`outcome' : di %6.2f r(F)

		// OLS 1940-70
		eststo ols70_`outcome' : reg n2_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		
			
		

		// OLS 1940-2010
		eststo ols10_`outcome' : reg ld2_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		local N_`outcome' = e(N)

	}
	
	preserve 
		ssaggregate n2_cgoodman_cz_pc n2_totfrac_cz_pc n2_gen_muni_cz_pc n2_spdist_cz_pc ld2_cgoodman_cz_pc ld2_totfrac_cz_pc ld2_gen_muni_cz_pc ld2_spdist_cz_pc `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		
		foreach outcome in cgoodman  spdist gen_muni totfrac {
			eststo iv70_`outcome': ivreg2 n2_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			
			estadd scalar dep_var70 = `dv70_`outcome''
			eststo iv10_`outcome': ivreg2 ld2_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			
			estadd scalar dep_var10 = `dv10_`outcome''
			estadd scalar Fs = `F_`outcome''
			estadd scalar b_var = `bv_`outcome''
			estadd scalar nobs = `N_`outcome''
		}
	restore
	
	preserve 
		ssaggregate n2_schdist_ind_cz_pc ld2_schdist_ind_cz_pc `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		
		foreach outcome in schdist_ind {
			eststo iv70_`outcome': ivreg2 n2_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			
			estadd scalar dep_var70 = `dv70_`outcome''
			eststo iv10_`outcome': ivreg2 ld2_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			
			estadd scalar dep_var10 = `dv10_`outcome''
			estadd scalar Fs = `F_`outcome''
			estadd scalar b_var = `bv_`outcome''
			estadd scalar nobs = `N_`outcome''
		}
	restore
	local stats `"Fs dep_var70 b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0)"'
		

	

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_spdist  fs_totfrac    ///
		using "`path'", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}" ///
				"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
		prehead( \begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}) ///
	 keep(`exog') 

	// Panel B: OLS
	esttab ols70_cgoodman ols70_gen_muni ols70_schdist_ind ols70_spdist ols70_totfrac  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel B: OLS 1940-1970}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


		
	// Panel C: 2SLS
	esttab iv70_cgoodman iv70_gen_muni iv70_schdist_ind iv70_spdist iv70_totfrac ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel C: 2SLS 1940-1970}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		stats(dep_var70, labels("1940-70 Avg.") fmt(2))
		
		// Panel D: OLS
	esttab ols10_cgoodman ols10_gen_muni ols10_schdist_ind ols10_spdist ols10_totfrac ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: OLS 1940-2010}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


		
	// Panel E: 2SLS
	esttab iv10_cgoodman iv10_gen_muni iv10_schdist_ind iv10_spdist iv10_totfrac ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel E: 2SLS 1940-2010}\\" "\cmidrule(lr){1-6}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabularx}) ///
		stats(dep_var10 b_var Fs nobs, labels("1940-2010 Avg." "1940 Avg." "First State F-Stat" "Observations") fmt(2 2 2 0)) substitute("\midrule" "\cmidrule(lr){1-6}")

	eststo clear
end