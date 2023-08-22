local b_controls reg2 reg3 reg4 blackmig3539_share

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

eststo clear
foreach outcome in cgoodman schdist_ind gen_town spdist{
	su n_`outcome'_cz_pcc
	local dv : di %6.2f r(mean)
	
	// First Stage
	eststo fs_`outcome' : reg GM_raw_pp GM_hat_raw_pp `b_controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.2f r(F)

	// OLS
	eststo ols_`outcome' : reg n_`outcome'_cz_pcc GM_raw_pp `b_controls' [aw = popc1940], r
	
	// RF
	eststo rf_`outcome' : reg n_`outcome'_cz_pcc GM_hat_raw_pp `b_controls' [aw = popc1940], r
	
	// 2SLS 
	eststo iv_`outcome' : ivreg2 n_`outcome'_cz_pcc (GM_raw_pp = GM_hat_raw_pp) `b_controls' [aw = popc1940], r
		estadd local Fs = `F'
		estadd local dep_var = `dv'

}

// Panel A: First Stage
esttab fs_cgoodman fs_schdist_ind fs_gen_town fs_spdist ///
	using "$TABS/final/main_effect.tex", ///
	replace se booktabs noconstant noobs compress frag label  ///
	b(%03.2f) se(%03.2f) ///
	mtitles("Municipalities" "School districts" "Townships" "Special districts") ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-5}" ) ///
	prehead( \begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}  \begin{threeparttable} \caption{Effects of change in Black Migration on Municipal Proliferation}  \begin{tabular}{l*{6}{c}} \toprule) ///
 keep(GM_hat_raw_pp) ///
mgroups("C. Goodman" "Census of Governments", ///
							pattern(1 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
							span erepeat(\cmidrule(lr){@span}))

// Panel B: OLS
esttab ols_cgoodman ols_schdist_ind ols_gen_town ols_spdist ///
	using "$TABS/final/main_effect.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel B: OLS}\\" "\cmidrule(lr){1-5}" ) ///
	b(%03.2f) se(%03.2f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp)


// Panel C: RF
esttab rf_cgoodman rf_schdist_ind rf_gen_town rf_spdist ///
	using "$TABS/final/main_effect.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel C: Reduced Form}\\" "\cmidrule(lr){1-5}" ) ///
	b(%03.2f) se(%03.2f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_hat_raw_pp)

	
// Panel D: 2SLS
esttab iv_cgoodman iv_schdist_ind iv_gen_town iv_spdist ///
	using "$TABS/final/main_effect.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-5}" ) ///
	b(%03.2f) se(%03.2f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(GM_raw_pp) ///
	postfoot(	\bottomrule \end{tabular}{\caption*{\begin{scriptsize} "\(p<0.10\), ** \(p<0.05\), *** \(p<0.01\)"\end{scriptsize}}} \end{threeparttable} \end{table}) ///
	stats(Fs dep_var N, labels("First Stage F-Stat" "Dependent Variable Mean" "Observations") fmt(2 2 0))

	