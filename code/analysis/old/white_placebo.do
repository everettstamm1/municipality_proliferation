

// White balance
local b_controls reg2 reg3 reg4 sumshare_base_white
local balance_cutoff = 0.10
local samp = "urban"

use "$CLEANDATA/cz_pooled", clear
local covars avg_precip avg_temp coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total  hsgrad unigrad mean_income_1940 cz_popdens1940 growth3040

local pooled_covars_`samp'  ""
keep if dcourt == 1
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = shift_share_base_white
	label var GM`covar' "`lab'"

	qui eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	
	
	local p =2*ttail(e(df_r),abs(_b[GM`covar']/_se[GM`covar']))
	di "`covar' p value : `p'"
	if `p'<=`balance_cutoff'{
		local pooled_covars_`samp'  "`pooled_covars_`samp'' `covar'"
	}
}

eststo pooled_`samp' : appendmodels `covars'
esttab pooled_`samp' `means' ///
				using "$TABS/balancetables/balancetable_white.tex", ///
				replace label se booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{WM}$" "Mean") ///
				b(%04.3f) se(%04.3f) //////
				keep(GM*) ///
				prehead( \begin{tabular}{l*{2}{c}} \toprule) ///
		postfoot(	\bottomrule \end{tabular}) ///
				starlevels( * 0.10 ** 0.05 *** 0.01) 
				
				

lab var GM_raw_pp "GM_raw_pp"			
				
main_table_ssaggregate, endog(WM_raw_pp) exog(shift_share_base_white) controls(reg2 reg3 reg4 sumshare_base_white coastal mfg_lfshare1940 frac_total hsgrad mean_income_1940 growth3040) weight(popc1940) path("$TABS/final/white_ssaggregate.tex") deplab(n)	version("base_white")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

		


