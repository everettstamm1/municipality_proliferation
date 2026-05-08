use "$CLEANDATA/cz_pooled", clear


keep cz cz_name *pop* shift_share_base sumshare_base shift_share_base_white sumshare_base_white  GM_raw_pp WM_raw_pp reg2 reg3 reg4 n_cgoodman* n_schdist_ind* n_gen_muni* n_spdist* n_totfrac*  b_cgoodman* b_schdist_ind* b_gen_muni* b_spdist* b_totfrac* frac_total  occscore* prop_enclosed1940 avg_temp avg_precip has_port coastal m_rr_sqm_total transpo_cost_1920 maxcitypop  cz_popdens1940 mean_income_1940 mean_hv_1940 cz_popdens1940 court_order frac_court_ordered above_x_med growth1930 mfg_lfshare1940 hsgrad unigrad
g any_court_ordered = frac_court_ordered > 0

lab var prop_enclosed1940 "Proportion of main city enclosed"
lab var WM_raw_pp "Percentage Point Change in Urban White Population Share"
lab var maxcitypop "Largest City Population"
lab var mean_hv_1940 "Mean Home Value, 1940"
forv y=1900(10)1930{
	//lab var labforce`y' "Proportion in Labor Force, `y'"
	lab var b_cgoodman_cz`y' "Base Earliest Year of Municipal Incorporation `y'"
}
forv y=1940(10)1970{
	lab var popc`y' "Urban Population, `y'"
	lab var bpopc`y' "Urban Black Population, `y'"
	lab var pop`y' "Total Population, `y'"
	cap lab var bpop`y' "Total Black Population, `y'"
	lab var b_cgoodman_cz`y'_pc "Base Earliest Year of Municipal Incorporation P.C. `y'"

}
lab var wpopc1940 "Urban White Population, 1940"
lab var wpopc1970 "Urban White Population, 1970"
cap lab var wpop1940 "Total White Population, 1940"
cap lab var wpop1970 "Total White Population, 1970"


forv y=1940(10)1970{
	lab var b_spdist_cz`y'_pc "Base Number of Special Purporse Districts P.C. `y'"
	lab var b_gen_muni_cz`y'_pc "Base Number of Municipal Govts P.C. `y'"
	
	lab var b_schdist_ind_cz`y' " Base Number of School Districts `y'"
	lab var b_schdist_ind_cz`y'_pc " Base Number of School Districts P.C. `y'"
}
lab var b_schdist_ind_cz2010 " Base Number of School Districts 2010"
lab var b_totfrac_cz1940_pc "Fraction of Pop in Main City, 1940"
lab var n_totfrac_cz_pc "Change in Fraction of Pop in Main City, 1940-70"
lab var n_cgoodman_cz_pc "New Muni Govts P.C., 1940-70"

lab var shift_share_base "\hat{GM}"
lab var shift_share_base_white "\hat{WM}"
lab var sumshare_base "\hat{GM} sum of shares"
lab var sumshare_base_white "\hat{WM} sum of shares"
lab var above_x_med "Above Median GM"

save "$CLEANDATA/jamie_data_4_13", replace

asdf
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

// GO DELETE THE MEAN STARS YOURSELF BC YOU CANT FIGURE IT OUT
esttab pooled_`samp' pooled_`samp'_means ///
				using "balancetable.tex", ///
				replace label  booktabs noconstant noobs compress nonumber frag mtitle("$\widehat{GM}$" "Mean") ///
				keep(GM*) ///
				prehead( \begin{tabular}{l*{4}{c}} \toprule) ///
				postfoot(	\bottomrule \end{tabular}) ///
				b(%04.3f) se(%04.3f) //////
				starlevels( * 0.10 ** 0.05 *** 0.01) 
