

local b_controls sumshare_base reg2 reg3 reg4 
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear
drop hsgrad unigrad
ren hsgrad_18 hsgrad
ren unigrad_18 unigrad
local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total  hsgrad unigrad mean_income_1940 cz_popdens1940 growth1930
local means avg_precip_mean avg_temp_mean n_streams_mean coastal_mean mfg_lfshare1940_mean m_rr_sqm_total_mean transpo_cost_1920_mean frac_total_mean  hsgrad_mean unigrad_mean mean_income_1940_mean cz_popdens1940_mean growth1930_mean 
local covars_nss avg_precip_nss avg_temp_nss n_streams_nss coastal_nss mfg_lfshare1940_nss m_rr_sqm_total_nss transpo_cost_1920_nss frac_total_nss  hsgrad_nss unigrad_nss mean_income_1940_nss cz_popdens1940_nss growth1930_nss

local pooled_covars_`samp'  ""
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = shift_share_base
	label var GM`covar' "`lab'"

	eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	eststo `covar'_nss: reg `covar' GM`covar' reg2 reg3 reg4 [aw=popc1940], r
	replace GM`covar' = 1
	qui eststo `covar'_mean : reg `covar' GM`covar' [aw=popc1940], nocons
	
	local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
	di "`covar' p value : `p'"
	if `p'<=`balance_cutoff'{
		local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
	}
}

eststo pooled_`samp' : appendmodels `covars'
eststo pooled_`samp'_nss : appendmodels `covars_nss'
eststo pooled_`samp'_means : appendmodels `means'
// GO DELETE THE MEAN STARS YOURSELF BC YOU CANT FIGURE IT OUT
esttab pooled_`samp'_nss pooled_`samp' pooled_`samp'_means ///
				using "$TABS/balancetables/balancetable.tex", ///
				replace label nomtitles booktabs noconstant noobs compress nonumber frag  ///
				keep(GM*) ///
				prehead( "\begin{tabular}{l*{3}{c}} \toprule" ///
				"&\multicolumn{2}{c}{$\widehat{GM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\") ///
				postfoot(	\bottomrule \end{tabular}) ///
				b(%04.3f) se(%04.3f) //////
				starlevels( * 0.10 ** 0.05 *** 0.01) 


local b_controls sumshare_base_white reg2 reg3 reg4 
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear
drop hsgrad unigrad
ren hsgrad_18 hsgrad
ren unigrad_18 unigrad
local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total  hsgrad unigrad mean_income_1940 cz_popdens1940 growth1930
local means avg_precip_mean avg_temp_mean n_streams_mean coastal_mean mfg_lfshare1940_mean m_rr_sqm_total_mean transpo_cost_1920_mean frac_total_mean  hsgrad_mean unigrad_mean mean_income_1940_mean cz_popdens1940_mean growth1930_mean 
local covars_nss avg_precip_nss avg_temp_nss n_streams_nss coastal_nss mfg_lfshare1940_nss m_rr_sqm_total_nss transpo_cost_1920_nss frac_total_nss  hsgrad_nss unigrad_nss mean_income_1940_nss cz_popdens1940_nss growth1930_nss

local pooled_covars_`samp'  ""
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = shift_share_base_white
	label var GM`covar' "`lab'"

	eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	eststo `covar'_nss: reg `covar' GM`covar' reg2 reg3 reg4 [aw=popc1940], r
	replace GM`covar' = 1
	qui eststo `covar'_mean : reg `covar' GM`covar' [aw=popc1940], nocons
	
	local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
	di "`covar' p value : `p'"
	if `p'<=`balance_cutoff'{
		local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
	}
}

eststo pooled_`samp' : appendmodels `covars'
eststo pooled_`samp'_nss : appendmodels `covars_nss'
eststo pooled_`samp'_means : appendmodels `means'
// GO DELETE THE MEAN STARS YOURSELF BC YOU CANT FIGURE IT OUT
esttab pooled_`samp'_nss pooled_`samp' pooled_`samp'_means ///
				using "$TABS/balancetables/balancetable_white.tex", ///
				replace label nomtitles booktabs noconstant noobs compress nonumber frag  ///
				keep(GM*) ///
				prehead( "\begin{tabular}{l*{3}{c}} \toprule" ///
				"&\multicolumn{2}{c}{$\widehat{GM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\") ///
				postfoot(	\bottomrule \end{tabular}) ///
				b(%04.3f) se(%04.3f) //////
				starlevels( * 0.10 ** 0.05 *** 0.01) 
				
				
				
				
local b_controls sumshare_base_white reg2 reg3 reg4 
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear

local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total  hsgrad unigrad mean_income_1940 cz_popdens1940 growth3040
local means avg_precip_mean avg_temp_mean n_streams_mean coastal_mean mfg_lfshare1940_mean m_rr_sqm_total_mean transpo_cost_1920_mean frac_total_mean  hsgrad_mean unigrad_mean mean_income_1940_mean cz_popdens1940_mean growth3040_mean 
local covars_nss avg_precip_nss avg_temp_nss n_streams_nss coastal_nss mfg_lfshare1940_nss m_rr_sqm_total_nss transpo_cost_1920_nss frac_total_nss  hsgrad_nss unigrad_nss mean_income_1940_nss cz_popdens1940_nss growth3040_nss

local pooled_covars_`samp'  ""
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = GM_hat
	label var GM`covar' "`lab'"

	eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	eststo `covar'_nss: reg `covar' GM`covar' reg2 reg3 reg4 [aw=popc1940], r
	replace GM`covar' = 1
	qui eststo `covar'_mean : reg `covar' GM`covar' [aw=popc1940], nocons
	
	local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
	di "`covar' p value : `p'"
	if `p'<=`balance_cutoff'{
		local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
	}
}

eststo pooled_`samp' : appendmodels `covars'
eststo pooled_`samp'_nss : appendmodels `covars_nss'
eststo pooled_`samp'_means : appendmodels `means'
// GO DELETE THE MEAN STARS YOURSELF BC YOU CANT FIGURE IT OUT
esttab pooled_`samp'_nss pooled_`samp' pooled_`samp'_means ///
				using "$TABS/balancetables/balancetable_pctile.tex", ///
				replace label nomtitles booktabs noconstant noobs compress nonumber frag  ///
				keep(GM*) ///
				prehead( "\begin{tabular}{l*{3}{c}} \toprule" ///
				"&\multicolumn{2}{c}{$\widehat{GM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\") ///
				postfoot(	\bottomrule \end{tabular}) ///
				b(%04.3f) se(%04.3f) //////
				starlevels( * 0.10 ** 0.05 *** 0.01) 
					
	
// mean (above/below median sample) - GM_raw -GM_hat -GM_hat with cenreg fe - GM_hat with cenreg fe and sumshares

local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 

use "$CLEANDATA/cz_pooled", clear
local vars n10_cgoodman_cz_pc n20_cgoodman_cz_pc n30_cgoodman_cz_pc n40_cgoodman_cz_pc pre_cgoodman_cz_pc  
keep if dcourt == 1
local xlab : variable label GM_hat_raw

preserve
	ssaggregate `vars'  GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`b_controls' `extra_controls'") s(share)
		
	merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
	replace shift = 0 if mi(shift)
	lab var shift "`xlab'"
	foreach var in `vars' {
		local lab : variable label `var'
		g GM`var' = GM_raw_pp
		label var GM`var' "`lab'"

		eststo `var': ivreg2 `var' (GM`var' = shift)  [aw=s_n]
		
		drop GM`var'
		
	}
restore

eststo tsls_`samp' : appendmodels `vars'

foreach var in `vars' {
	local lab : variable label `var'
	g GM`var' = shift_share_base
	label var GM`var' "`lab'"

	eststo `var': reg `var' GM`var' `b_controls' `extra_controls' [aw=popc1940], r
	
	
}

eststo rf_`samp' : appendmodels `vars'

esttab tsls_`samp' rf_`samp' ///
				using "$TABS/balancetables/pretrends_new_ctrls.tex", ///
				replace label se booktabs noconstant noobs compress nonumber frag  mtitles("IV" "Reduced Form") ///
				b(%04.3f) se(%04.3f) //////
				keep(GM*) ///
				prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
		postfoot(	\bottomrule \end{tabular}) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) 



local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 
foreach t in pop age black literate labforce occscore popc agec blackc literatec labforcec occscorec{
	eststo clear
	use "$CLEANDATA/cz_pooled", clear
	ren bpop1940 black1940
	//g t1900 = log(pop1910) - log(pop1900)
	//replace pop1910 = log(pop1920) - log(pop1910)
	//replace pop1920 = log(pop1930) - log(pop1920)
	//replace pop1930 = log(pop1940) - log(pop1930)
	
	g t1900 = 100*(pop1910 - pop1900) / pop1900
	g t1910 = 100*(pop1920 - pop1910) / pop1910
	g t1920 = 100*(pop1930 - pop1920) / pop1920
	g t1930 = 100*(pop1940 - pop1930) / pop1930
	drop pop19??
	rename t19?? pop19??
	
	
	g t1900 = 100*(popc1910 - popc1900) / popc1900
	g t1910 = 100*(popc1920 - popc1910) / popc1910
	g t1920 = 100*(popc1930 - popc1920) / popc1920
	g t1930 = 100*(popc1940 - popc1930) / popc1930
	drop popc1900 popc1910 popc1920 popc1930
	rename t19?? popc19??
	local vars `t'1900 `t'1910 `t'1920 `t'1930
	keep if dcourt == 1

	foreach var in `vars' {
		local lab : variable label `var'
		g GM`var' = GM_raw_pp
		label var GM`var' "`lab'"

		eststo `var': ivreg2 `var' (GM`var' = shift_share_base) `b_controls' `extra_controls' [aw=popc1940], r
		
		drop GM`var'
		
	}

	eststo tsls_`samp' : appendmodels `vars'

	foreach var in `vars' {
		local lab : variable label `var'
		g GM`var' = shift_share_base
		label var GM`var' "`lab'"

		eststo `var': reg `var' GM`var' `b_controls' `extra_controls' [aw=popc1940], r
		
		
	}

	eststo rf_`samp' : appendmodels `vars'

	esttab tsls_`samp' rf_`samp' ///
					using "$TABS/balancetables/pretrends_`t'.tex", ///
					replace label se booktabs noconstant noobs compress nonumber frag  mtitles("IV" "Reduced Form") ///
					b(%04.3f) se(%04.3f) //////
					keep(GM*) ///
					prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
			postfoot(	\bottomrule \end{tabular}) ///
					starlevels( * 0.10 ** 0.05 *** 0.01) 
}

