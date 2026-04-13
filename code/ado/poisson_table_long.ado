cap prog drop poisson_table_long 

prog def poisson_table_long

	syntax, endog(varlist) controls(varlist) exog(varlist) weight(varname) path(string)  exposure(varname) [endog2(varlist) exog2(varlist) cgoodman(varlist) gen_muni(varlist) schdist_ind(varlist) gen_town(varlist) spdist(varlist)] 

	local useinst : word 1 of `exog' 
	eststo clear 
	foreach outcome in cgoodman schdist_ind spdist gen_muni { 
		su n_`outcome'_cz1970 
		local dv70_`outcome' : di %6.2f r(mean) 
		su n_`outcome'_cz2010 
		local dv10_`outcome' : di %6.2f r(mean) 
		su b_`outcome'_cz1940 
		local bv_`outcome' : di %6.2f r(mean) 
		local ctrls `controls' ``outcome'' 
		// First Stage 
		eststo fs_`outcome' : reg GM_raw_pp `exog' `ctrls' [pw=`weight'], r 
		test `useinst'=0 
		local F : di %6.2f r(F) 
		// OLS 
		eststo ols70_`outcome' : poisson b_`outcome'_cz1970 `endog' `endog2' `ctrls'  [pw = `weight'], r exposure(`exposure')
		eststo ols10_`outcome' : poisson b_`outcome'_cz2010 `endog' `endog2' `ctrls'  [pw = `weight'], r  exposure(`exposure')
		local N_`outcome' = e(N) 
		// 2SLS 
		eststo iv70_`outcome': ivpoisson gmm b_`outcome'_cz1970 (`endog' = `exog') `ctrls'  [aw=`weight'], vce(r)  exposure(`exposure')
		estadd scalar dep_var70 = `dv70_`outcome'' 
		eststo iv10_`outcome': ivpoisson gmm b_`outcome'_cz2010 (`endog' = `exog') `ctrls'  [aw=`weight'], vce(r)   exposure(`exposure')
		estadd scalar Fs = `F' 
		estadd scalar dep_var10 = `dv10_`outcome'' 
		estadd scalar b_var = `bv_`outcome'' 
		estadd scalar nobs = `N_`outcome'' 
		} 
	// Panel A: First Stage 
	esttab fs_cgoodman fs_gen_muni fs_schdist_ind fs_spdist /// 
	using "`path'", /// 
	replace se booktabs noconstant noobs compress frag label nomtitles nonum eqlabels(, none) ///
	b(%04.3f) se(%04.3f) /// 
	starlevels( * 0.10 ** 0.05 *** 0.01) /// 
	posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}" /// 
	"&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" /// 
	"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
	"\cmidrule(lr){1-5}" /// 
	"\multicolumn{4}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-5}" ) /// 
	prehead( \begin{tabularx}{\textwidth}{l*{4}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}) /// 
	keep(`exog') 
	
	// Panel B: OLS 
	esttab ols70_cgoodman ols70_gen_muni ols70_schdist_ind ols70_spdist /// 
	using "`path'", /// 
	se booktabs noconstant compress frag append noobs nonum nomtitle label eqlabels(, none) /// 
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel B: OLS 1940-1970}\\" "\cmidrule(lr){1-5}" ) /// 
	b(%04.3f) se(%04.3f) /// 
	starlevels( * 0.10 ** 0.05 *** 0.01) /// 
	keep(`endog' ) 
	
	// Panel C: 2SLS 
	esttab iv70_cgoodman iv70_gen_muni iv70_schdist_ind iv70_spdist /// 
	using "`path'", /// 
	se booktabs noconstant compress frag append noobs nonum nomtitle label eqlabels(, none) /// 
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel C: 2SLS 1940-1970}\\" "\cmidrule(lr){1-5}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) /// 
	keep(`endog') /// 
	stats(dep_var70, labels("1940-70 Avg.") fmt(2)) 
	
	// Panel D: OLS 
	esttab ols10_cgoodman ols10_gen_muni ols10_schdist_ind ols10_spdist /// 
	using "`path'", /// 
	se booktabs noconstant compress frag append noobs nonum nomtitle label eqlabels(, none) /// 
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel D: OLS 1940-2010}\\" "\cmidrule(lr){1-5}" ) ///
	b(%04.3f) se(%04.3f) /// 
	starlevels( * 0.10 ** 0.05 *** 0.01) /// 
	keep(`endog') 
	
	// Panel E: 2SLS 
	esttab iv10_cgoodman iv10_gen_muni iv10_schdist_ind iv10_spdist /// 
	using "`path'", /// 
	se booktabs noconstant compress frag append noobs nonum nomtitle label eqlabels(, none) /// 
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel E: 2SLS 1940-2010}\\" "\cmidrule(lr){1-5}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(`endog' ) /// 
	postfoot( \bottomrule \end{tabularx}) /// 
	stats(dep_var10 b_var Fs nobs, labels("1940-2010 Avg." "1940 Avg." "First Stage F-Stat" "Observations") fmt(2 2 2 0)) substitute("\midrule" "\cmidrule(lr){1-5}") 
	eststo clear
end