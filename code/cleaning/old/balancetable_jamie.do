
use jamie_data_3_23, clear

local b_controls sumshare_base reg2 reg3 reg4 
local balance_cutoff = 0.10
local covars avg_precip avg_temp coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total  hsgrad unigrad mean_income_1940 cz_popdens1940 growth3040
local means avg_precip_mean avg_temp_mean coastal_mean mfg_lfshare1940_mean m_rr_sqm_total_mean transpo_cost_1920_mean frac_total_mean  hsgrad_mean unigrad_mean mean_income_1940_mean cz_popdens1940_mean growth3040_mean 

local pooled_covars_`samp'  ""
foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = shift_share_base
	label var GM`covar' "`lab'"

	eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	replace GM`covar' = 1
	qui eststo `covar'_mean : reg `covar' GM`covar' [aw=popc1940], nocons
	
	
}


eststo pooled_`samp' : appendmodels `covars'
eststo pooled_`samp'_means : appendmodels `means'

// GO DELETE THE STARS ON THE MEAN COLUMN MANUALLY BC IDK HOW ELSE TO
esttab pooled_`samp' pooled_`samp'_means ///
				using "balancetable.tex", ///
				replace label  booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{GM}$" "Mean") ///
				keep(GM*) ///
				prehead( \begin{tabular}{l*{4}{c}} \toprule) ///
				postfoot(	\bottomrule \end{tabular}) ///
				b(%04.3f) se(%04.3f) //////
				starlevels( * 0.10 ** 0.05 *** 0.01) 