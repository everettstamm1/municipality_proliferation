cap prog drop main_table_ssaggregate
prog def main_table_ssaggregate
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) deplab(string) version(string) share_folder(string) origin_id(string) [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist) totfrac(varlist)]
	
	local xlab : variable label `endog'

	eststo clear
	foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
		local ctrls `controls' ``outcome''

		su `deplab'_`outcome'_cz_pc 
		local dv_`outcome' : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc 
		local bv_`outcome' : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg `endog' `exog' `ctrls' if !mi(n_`outcome'_cz_pc) [aw=`weight'], r
		test `exog'=0
		local F_`outcome' : di %6.2f r(F)

		// OLS
		eststo ols_`outcome' : reg `deplab'_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		
		// RF
		eststo rf_`outcome' : reg `deplab'_`outcome'_cz_pc `exog' `exog2' `ctrls' [aw = `weight'], r
		local N_`outcome' = e(N)
	}
	
	preserve 
		ssaggregate `deplab'_cgoodman_cz_pc `deplab'_totfrac_cz_pc `deplab'_gen_muni_cz_pc `deplab'_spdist_cz_pc `deplab'_gen_town_cz_pc `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		lab var shift "`xlab'"
		
		foreach outcome in cgoodman  gen_town spdist gen_muni totfrac {
			eststo iv_`outcome': ivreg2 `deplab'_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			estadd scalar Fs = `F_`outcome''
			estadd scalar dep_var = `dv_`outcome''
			estadd scalar b_var = `bv_`outcome''
			estadd scalar nobs = `N_`outcome''
		}
	restore
	
	// Have to do school districts separately as they have some missing values which messes up ssaggregate
	preserve 
		ssaggregate `deplab'_schdist_ind_cz_pc `endog' [aw=`weight'], n(`origin_id') l(cz) sfile("`share_folder'/shares_`version'.dta") controls("`ctrls'") s(share)
		
		merge 1:1 `origin_id' using "`share_folder'/shock_instrument_`version'.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		//lab var shift "`xlab'"
		
		foreach outcome in  schdist_ind  {
			eststo iv_`outcome': ivreg2 `deplab'_`outcome'_cz_pc (`endog' `endog2' = shift) [aw = s_n]
			estadd scalar Fs = `F_`outcome''
			estadd scalar dep_var = `dv_`outcome''
			estadd scalar b_var = `bv_`outcome''
			estadd scalar nobs = `N_`outcome''
		}
	restore
	
	local stats `"Fs dep_var b_var nobs, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0)"'
		

	

	// Panel A: First Stage
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_gen_town fs_spdist fs_totfrac      ///
		using "`path'", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}\cmidrule(lr){7-7}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead(  \begin{tabularx}{.9\hsize}{l*{6}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}) ///
	 keep(`exog') 

	// Panel B: OLS
	esttab ols_cgoodman ols_gen_muni ols_schdist_ind ols_gen_town ols_spdist ols_totfrac  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


	// Panel C: RF
	esttab rf_cgoodman rf_gen_muni rf_schdist_ind rf_gen_town rf_spdist rf_totfrac  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`exog' `exog2')

		
	// Panel D: 2SLS
	esttab iv_cgoodman iv_gen_muni iv_schdist_ind iv_gen_town iv_spdist iv_totfrac  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabularx}) ///
		stats(`stats')

	eststo clear
end