
local b_controls sumshare_base reg2 reg3 reg4 
local balance_cutoff = 0.10

use "cz_pooled", clear


// Creating list of covariates/output names
local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total  hsgrad unigrad mean_income_1940 cz_popdens1940 growth3040

local means avg_precip_mean avg_temp_mean n_streams_mean coastal_mean mfg_lfshare1940_mean m_rr_sqm_total_mean transpo_cost_1920_mean frac_total_mean  hsgrad_mean unigrad_mean mean_income_1940_mean cz_popdens1940_mean growth3040_mean 

local covars_nss avg_precip_nss avg_temp_nss n_streams_nss coastal_nss mfg_lfshare1940_nss m_rr_sqm_total_nss transpo_cost_1920_nss frac_total_nss  hsgrad_nss unigrad_nss mean_income_1940_nss cz_popdens1940_nss growth3040_nss

foreach covar in `covars' {
	local lab : variable label `covar'
	g GM`covar' = shift_share_base
	label var GM`covar' "`lab'"

	eststo `covar': reg `covar' GM`covar' `b_controls' [aw=popc1940], r
	eststo `covar'_nss: reg `covar' GM`covar' reg2 reg3 reg4 [aw=popc1940], r
	replace GM`covar' = 1
	qui eststo `covar'_mean : reg `covar' GM`covar' [aw=popc1940], nocons
	

}

eststo pooled : appendmodels `covars'
eststo pooled_nss : appendmodels `covars_nss'
eststo pooled_means : appendmodels `means'

// GO DELETE THE MEAN COLUMN STARS YOURSELF BC YOU CANT FIGURE IT OUT
esttab pooled_nss pooled pooled_means ///
				using "balancetable.tex", ///
				replace label nomtitles booktabs noconstant noobs compress nonumber frag  ///
				keep(GM*) ///
				prehead( "\begin{tabular}{l*{3}{c}} \toprule" ///
				"&\multicolumn{2}{c}{$\widehat{GM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\") ///
				postfoot(	\bottomrule \end{tabular}) ///
				b(%04.3f) se(%04.3f) //////
				starlevels( * 0.10 ** 0.05 *** 0.01) 

