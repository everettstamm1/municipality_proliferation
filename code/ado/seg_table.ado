cap prog drop seg_table
prog def seg_table
	syntax, endog(varname) controls(varlist) exog(varname) weight(varname) path(string) 
	
	eststo clear
	local i = 0
	foreach outcome in stu_vr_blwt_cz stu_diss_blwt_cz achievement_iqr  achievement_var_cz black_exposure white_exposure {
		local ctrls `controls' ``outcome''
		local i = `i' + 1
		su `outcome'
		local dv : di %6.2f r(mean)
		
		
		// First Stage
		eststo fs`i' : reg `endog' `exog' `ctrls' [aw=`weight'], r
		test `exog'=0
		local F : di %6.2f r(F)

		// OLS
		eststo ols`i' : reg `outcome' `endog' `endog2' `ctrls' [aw = `weight'], r
		
		// RF
		eststo rf`i' : reg `outcome' `exog' `exog2' `ctrls' if !mi(`endog') [aw = `weight'], r
		
		// 2SLS 
		eststo iv`i': ivreg2 `outcome' (`endog' `endog2' = `exog' `exog2') `ctrls' [aw = `weight'], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
		

	}

	// Panel A: First Stage
	esttab fs1 fs2 fs3 fs4 fs5 fs6      ///
		using "`path'", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead( "&\multicolumn{1}{c}{\shortstack{Variance \\ Ratio}}&\multicolumn{1}{c}{\shortstack{Dissimilarity \\ Index}}&\multicolumn{1}{c}{\shortstack{Interquartile \\ Range}}&\multicolumn{1}{c}{\shortstack{Variance}}&\multicolumn{1}{c}{\shortstack{Black}}&\multicolumn{1}{c}{\shortstack{White}}\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
				"\cmidrule(lr){1-7}" ///
				"\multicolumn{6}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-7}" ) ///
		prehead( "\begin{tabular}{l*{7}{c}} \toprule" ///
				"&\multicolumn{2}{c}{School District Segregation}&\multicolumn{4}{c}{School District Achievement}\\\cmidrule(lr){2-3}\cmidrule(lr){4-7}" ) ///
	 keep(`exog') 

	// Panel B: OLS
	esttab ols1 ols2 ols3 ols4 ols5 ols6  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2')


	// Panel C: RF
	esttab rf1 rf2 rf3 rf4 rf5 rf5  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`exog' `exog2')

		
	// Panel D: 2SLS
	esttab iv1 iv2 iv3 iv4 iv5 iv6  ///
		using "`path'", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-7}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(`endog' `endog2') ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(Fs dep_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "Observations") fmt(2 2 0))

	eststo clear
end