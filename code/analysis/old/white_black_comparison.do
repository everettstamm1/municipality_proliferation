
use "$CLEANDATA/cz_pooled", clear

keep if dcourt == 1

eststo clear
g mig = .
g mighat = .
lab var mig "Migration"
lab var mighat "$\widehat{Migration}$"

foreach c in white black{
	if "`c'"=="white"{
		di "here"
		replace mig = WM
		replace mighat = GM_2w_hat
		local sumshare v2w_sumshares_urban
	}
	if "`c'" == "black"{
		replace mig = GM
		replace mighat = GM_hat
		local sumshare v2_sumshares_urban
	}
	foreach outcome in cgoodman gen_muni schdist_ind spdist  totfrac {

		su n_`outcome'_cz_pc 
		local dv : di %6.2f r(mean)
		su b_`outcome'_cz1940_pc 
		local bv : di %6.2f r(mean)
		
		// First Stage - black
		eststo fs_`c'_`outcome' : reg mig mighat `sumshare' reg2 reg3 reg4 coastal transpo_cost_1920 if !mi(n_`outcome'_cz_pc) [aw=popc1940], r
		test mighat=0
		local F : di %6.2f r(F)
		
		// 2SLS 
		eststo iv_`c'_`outcome' : ivreg2 n_`outcome'_cz_pc (mig = mighat)  `sumshare' reg2 reg3 reg4 coastal transpo_cost_1920 [aw = popc1940], r
			estadd scalar Fs = `F'
			estadd scalar dep_var = `dv'
			estadd scalar b_var = `bv'
		
		
		local stats `"Fs dep_var b_var N, labels("First Stage F-Stat" "Dep. Var. Mean" "1940 Dep. Var. Mean" "Observations") fmt(2 2 2 0)"'
		

	}
}

// Panel A: First Stage
esttab fs_black_cgoodman fs_white_cgoodman fs_black_gen_muni fs_white_gen_muni fs_black_schdist_ind fs_white_schdist_ind fs_black_spdist fs_white_spdist fs_black_totfrac fs_white_totfrac      ///
	using "$TABS/final/white_black_pctile.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	posthead("&\multicolumn{2}{c}{C. Goodman}&\multicolumn{6}{c}{Census of Governments}&\multicolumn{2}{c}{Census}\\\cmidrule(lr){2-3}\cmidrule(lr){4-9}\cmidrule(lr){10-11}" ///
			"&\multicolumn{4}{c}{Municipalities}&\multicolumn{2}{c}{School districts}&\multicolumn{2}{c}{Special districts}&\multicolumn{2}{c}{Main City Share}\\\cmidrule(lr){2-5}\cmidrule(lr){6-9}\cmidrule(lr){10-11}" ///
			"&\multicolumn{1}{c}{Black}&\multicolumn{1}{c}{White}&\multicolumn{1}{c}{Black}&\multicolumn{1}{c}{White}&\multicolumn{1}{c}{Black}&\multicolumn{1}{c}{White}&\multicolumn{1}{c}{Black}&\multicolumn{1}{c}{White}&\multicolumn{1}{c}{Black}&\multicolumn{1}{c}{White}\\ \cmidrule(lr){1-11}" ///
			"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}&\multicolumn{1}{c}{(7)}&\multicolumn{1}{c}{(8)}&\multicolumn{1}{c}{(9)}&\multicolumn{1}{c}{(10)}\\" ///
			"\cmidrule(lr){1-11}" ///
			"\multicolumn{10}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-11}" ) ///
	prehead( \begin{tabularx}{.9\hsize}{l*{10}{>{\centering\arraybackslash}X}} \toprule) ///
 keep(mighat) 
	
// Panel D: 2SLS
esttab iv_black_cgoodman iv_white_cgoodman iv_black_gen_muni iv_white_gen_muni iv_black_schdist_ind iv_white_schdist_ind iv_black_spdist iv_white_spdist iv_black_totfrac iv_white_totfrac  ///
	using "$TABS/final/white_black_pctile.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-11}" "\multicolumn{10}{l}{Panel B: 2SLS}\\" "\cmidrule(lr){1-11}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(mig) ///
	postfoot(	\bottomrule \end{tabularx}) ///
	stats(`stats')

eststo clear