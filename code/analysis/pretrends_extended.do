
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 

use "$CLEANDATA/cz_pooled", clear
ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"


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

	eststo clear
	forv t = 10(10)40{
		if "`t'" != "10" local t1 = `t'-10
		if "`t'" == "10" local t1 = "00"

		if "`outcome'" == "n" local y  n`t'_cgoodman_cz_pc

		if "`outcome'" == "growth" local y  growth`t1'`t'

		if !inlist("`outcome'","n","growth") local y  `outcome'19`t1'

		su `y'
		local bmean : di %6.2f r(mean)
		local bsd : di %6.2f r(sd)
		

		eststo mod`t' : reg `y' shift_share_base `b_controls' `extra_controls' [aw=popc1940], r
		estadd scalar basemean = `bmean'
		estadd scalar basesd = `bsd'

	}
	di "HERE"
	esttab mod10 mod20 mod30 mod40  ///
					using "$TABS/balancetables/pretrends_`outcome'.tex", booktabs compress label replace lines se frag ///
					 starlevels( * 0.10 ** 0.05 *** 0.01) ///
					`titles' ///
					keep(shift_share_base) b(%5.3f) se(%5.3f) ///
					mgroups("`ylab'" ,pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
					prehead( \begin{tabularx}{\linewidth}{l*{4}{>{\centering\arraybackslash}X}} \toprule) postfoot(	\bottomrule \end{tabularx}) stats(basemean basesd N , labels( "Dep. var. mean" "Dep. Var. Std Dev" "Observations" ) fmt(2 2 0))
}
