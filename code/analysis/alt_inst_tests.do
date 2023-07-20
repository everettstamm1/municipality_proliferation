// Alt Inst tests
foreach samp in urban  {
	if "`samp'"=="urban" local poptab ""
	if "`samp'"=="total" local poptab "_totpop"
	if "`samp'"=="td" local poptab "_totpop"

	if "`samp'"=="urban" local popname "c"
	if "`samp'"=="total" local popname ""
	if "`samp'"=="td" local popname ""

	if "`samp'"=="urban" local poplab "Urban Population"
	if "`samp'"=="total" local poplab "Total Population"		
	if "`samp'"=="td" local poplab "Total Population"		


	use "$CLEANDATA/cz_pooled", clear
	if "`samp'"=="td" keep if dcourt==1
	
	foreach outcome in cgoodman schdist_ind spdist gen_subcounty{
		preserve
			ivreg2 n_`outcome'_cz_pc`popname' (GM_raw_pp = GM_1940_hat_raw_pp GM_7r_hat_raw_pp GM_r_hat_raw_pp GM_hat_raw_pp) reg2 reg3 reg4 [aw = pop`popname'1940], r
			local hansenj : di %4.2f e(jp)
			
			global spec1 (GM_raw_pp = GM_hat_raw_pp)  reg2 reg3 reg4
			global spec2 (GM_raw_pp = GM_7r_hat_raw_pp)  reg2 reg3 reg4
			global spec3 (GM_raw_pp = GM_r_hat_raw_pp) reg2 reg3 reg4
			global spec4 (GM_raw_pp = GM_1940_hat_raw_pp)  reg2 reg3 reg4
			
			forval spec=1(1)4{
				tempfile spec`spec'
				parmby "ivreg2 n_`outcome'_cz_pc`popname' ${spec`spec'} [aw = pop`popname'1940]", lab saving(`"spec`spec'"', replace) idn(`l') ids(spec) ylabel 
			}
				
			drop _all
			forval spec=1(1)4{
				capture append using "spec`spec'"
			}
			
			tempfile overid_coefplot
			save `overid_coefplot'
			
			use `overid_coefplot', clear 
			keep if regexm(parm,"GM")==1
			g x=_n
			twoway scatter estimate x , mcolor(jmpgreen) ///
			|| rcap min95 max95 x, lcolor(jmpgreen%20)  ///
			title("Alternative instrument test, outcome `outcome'")  ///
			xsc(range(1(1)4)) xla(none, value angle(45))  ///
			xla(1 "Baseline" 2 "Resid State FEs" 3 "Top Urban Dropped" 4 "1940 Southern State of Birth" , add custom labcolor(jmpblue)) ///
			caption("Hansen J Statistic: `hansenj'", ring(0) pos(8)) ///
			xtitle("") graphregion(color(white)) plotregion(ilcolor(white)) ylabel(,nogrid ) legend(off)
			
			graph export "$FIGS/exogeneity_tests/D16_alt_inst_pooled_`outcome'_`samp'.png", replace as(png)
		restore
	}
}


// White instruments

eststo clear
use "$CLEANDATA/cz_pooled", clear

foreach outcome in cgoodman schdist_ind gen_subcounty spdist{
	qui: reg n_`outcome'_cz_pcc GM_8_hat_raw_pp reg2 reg3 reg4 [aw=popc1940], r 
	local coeff : di %4.3f _b[GM_8_hat_raw_pp]
	local coeff_se : di %4.3f _se[GM_8_hat_raw_pp]

	* Paper version
	
	* Slides version
	binscatter n_`outcome'_cz_pcc GM_8_hat_raw_pp [aw=popc1940], controls( reg2 reg3 reg4 ) ///
	reportreg lcolor(myslate*1.5) ylabel(,nogrid) mcolor(jmpgreen) xtitle("Percentile of predicted white s pop change 40-70") ytitle("Black M Inc Rank in 2015, Parents 25p") ///
	note("Slope = `coeff' (`coeff_se')") title("White instrument, outcome: `outcome'")
	graph export "$FIGS/exogeneity_tests/D14_`outcome'.png", replace 
}