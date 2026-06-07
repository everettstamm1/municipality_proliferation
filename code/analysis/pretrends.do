
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 

use "$CLEANDATA/cz_pooled", clear
ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"
foreach var in pre 20 30 40{
	if "`var'" != "pre" local y1 = `var'-10
	//if "`var'" == "10" local y1 = "00"
	if "`var'"=="pre" local y1 = "10"
	su n`var'_cgoodman_cz_pc
	local bmean : di %6.2f r(mean)
	local bsd : di %6.2f r(sd)
	
	
	eststo n`var' : reg n`var'_cgoodman_cz_pc shift_share_base `b_controls' `extra_controls' [aw=popc1940], r
	estadd scalar basemean = `bmean'
	estadd scalar basesd = `bsd'
}


esttab npre n20 n30 n40  ///
				using "$TABS/balancetables/pretrends.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("1910-1940" "1910-20" "1920-30" "1930-40") ///
				keep(shift_share_base) b(%5.3f) se(%5.3f) ///
				mgroups("Change in Municipalities Per Capita" ,pattern(1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				prehead( \begin{tabularx}{\linewidth}{l*{4}{>{\centering\arraybackslash}X}} \toprule) postfoot(	\bottomrule \end{tabularx}) stats(basemean basesd N , labels( "Dep. var. mean" "Dep. Var. Std Dev" "Observations" ) fmt(2 2 0))
