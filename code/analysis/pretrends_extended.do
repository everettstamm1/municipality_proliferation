
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 

use "$CLEANDATA/cz_pooled", clear
ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"

	eststo clear

foreach outcome in n growth agec blackc literatec labforcec occscorec{
	
	if "`outcome'"=="n" local ylab "Change in Municipalities Per Capita"
	if "`outcome'"=="growth" local ylab "Population Growth"
	if "`outcome'"=="agec" local ylab "Average Age"
	if "`outcome'"=="blackc" local ylab "Percent Black"
	if "`outcome'"=="literatec" local ylab "Percent Literate"
	if "`outcome'"=="labforcec" local ylab "Percent in Labor Force"
	if "`outcome'"=="occscorec" local ylab "Average OCCSCORE"


	if inlist("`outcome'","n","growth") {
		local titles = `"mtitles("1900–10" "1910–20" "1920–30"  "1930–40")"' 
	}
	if !inlist("`outcome'","n","growth") {
		local titles = `"mtitles("1900" "1910" "1920" "1930")"'
	}

	forv t = 10(10)40{
		if "`t'" != "10" local t1 = `t'-10
		if "`t'" == "10" local t1 = "00"

		if "`outcome'" == "n" local y  n`t'_cgoodman_cz_pc

		if "`outcome'" == "growth" local y  growth`t1'`t'

		if !inlist("`outcome'","n","growth") local y  `outcome'19`t1'

		su `y'
		local bmean : di %6.2f r(mean)
		local bsd : di %6.2f r(sd)
		

		eststo mod`t'_`outcome' : reg `y' shift_share_base `b_controls' `extra_controls' [aw=popc1940], r
		estadd scalar basemean = `bmean'
		estadd scalar basesd = `bsd'

	}
	
}


esttab mod10_n mod20_n mod30_n mod40_n    ///
		using "$TABS/balancetables/pretrends_extended.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{1900s}&\multicolumn{1}{c}{1910s}&\multicolumn{1}{c}{1920s}&\multicolumn{1}{c}{1930s}\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
				"\midrule" ///
				"\multicolumn{4}{l}{Panel A: $\Delta$ Municipalities Per Capita}\\" "\cmidrule(lr){1-5}" ) ///
		prehead( \begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule ) ///
	 keep(shift_share_base)  stats(basemean basesd , labels( "Dep. var. mean" "Dep. Var. Std Dev") fmt(2 2))
	 
	 
	// Panel B: OLS
esttab mod10_growth mod20_growth mod30_growth mod40_growth  ///
		using "$TABS/balancetables/pretrends_extended.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\midrule" "\multicolumn{4}{l}{Panel B: Population Growth}\\" "\cmidrule(lr){1-5}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(shift_share_base) stats(basemean basesd , labels( "Dep. var. mean" "Dep. Var. Std Dev") fmt(2 2))
		
		// Panel E: 2SLS
esttab  mod10_occscorec mod20_occscorec mod30_occscorec mod40_occscorec ///
		using "$TABS/balancetables/pretrends_extended.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\midrule" "\multicolumn{5}{l}{Panel C: Occupation Scores}\\" "\cmidrule(lr){1-5}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(shift_share_base) ///
		postfoot(	\bottomrule \end{tabularx}) ///
		stats(basemean basesd N, labels( "Dep. var. Avg." "Dep. var. Std Dev" "Observations") fmt(2 2 0))

