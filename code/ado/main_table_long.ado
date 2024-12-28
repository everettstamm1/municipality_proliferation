cap prog drop main_table_long
prog def main_table_long
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string)  [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist) totfrac(varlist)]
	
	eststo clear
	foreach outcome in cgoodman schdist_ind gen_muni spdist totfrac {
		local ctrls `controls' ``outcome''

		su n_`outcome'_cz_pc 
		local dv70 : di %6.2f r(mean)
		su ld_`outcome'_cz_pc 
		local dv10 : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc 
		local bv : di %6.2f r(mean)
		
		// First Stage
		eststo fs_`outcome' : reg GM_raw_pp `exog' `ctrls' if !mi(n_`outcome'_cz_pc) [aw=`weight'], r
		test `exog'=0 
		local F : di %6.2f r(F)

		// OLS 1940-70
		eststo ols70_`outcome' : reg n_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r
		
		// 2SLS 1940-70
		eststo iv70_`outcome' : ivreg2 n_`outcome'_cz_pc (`endog' `endog2' = `exog' `exog2') `ctrls' [aw = `weight'], r
					estadd scalar dep_var70 = `dv70'

		// OLS 1940-2010
		eststo ols10_`outcome' : reg ld_`outcome'_cz_pc `endog' `endog2' `ctrls' [aw = `weight'], r

		// 2SLS 1940-2010
		eststo iv10_`outcome' : ivreg2 ld_`outcome'_cz_pc (`endog' `endog2' = `exog' `exog2') `ctrls' [aw = `weight'], r
		estadd scalar dep_var10 = `dv10'
		estadd scalar Fs = `F'
		estadd scalar b_var = `bv'
	
		if "`deplab'"=="ln"{
			qui su b_`outcome'_cz1970,  d
			estadd scalar real = r(mean)
			predict y_hat, xb
			replace y_hat = exp(y_hat)
			qui su y_hat, d
			estadd scalar pred = r(mean)
			g temp = `endog'
			replace `endog' = 0 
			predict y_cf if e(sample)
			replace y_cf = exp(y_cf)
			qui su y_cf, d
			estadd scalar cf = r(mean)
			local stats `"Fs dep_var b_var real pred cf N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Mean Real 1970 Count"  "Mean Predicted 1970 count" "Mean CF 1970 Count" "Observations") fmt(2 2 2 2 2 2 0)"'
			replace `endog' = temp
			drop y_hat y_cf temp
			
		}
		else{
			local stats `"Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0)"'
		}

	}

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
		stats(dep_var10 b_var Fs N, labels("1940-2010 Avg." "1940 Avg." "First State F-Stat" "Observations") fmt(2 2 2 0)) substitute("\midrule" "\cmidrule(lr){1-6}")

	eststo clear
end