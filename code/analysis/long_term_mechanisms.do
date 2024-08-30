

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot school_level psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int
duplicates drop

foreach m in iv rf ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt st_ratio_mean wtenroll_hasap_place wtenroll_hasde_place wtenroll_hasgt_place{
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		if "`m'"=="iv"{
			di "here1, m: `m', covar: `covar'"
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest   , cl(cz)

		}
		else if "`m'"=="rf"{
						di "here2, m: `m', covar: `covar'"

			 eststo `covar' : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest   , vce(cl cz) absorb(region)
		}
		else if "`m'"=="ols"{
						di "here3, m: `m', covar: `covar'"

			 eststo `covar' : reghdfe `covar' above_x_med samp_destXabove_x_med samp_dest reg2 reg3 reg4 v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest  , vce(cl cz) 
		}
	}


	esttab using "$TABS/land_use_index/muni_outcomes_`m'.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}"  "Student-Teacher Ratio" "Pct w/AP" "Pct w/DE" "Pct w/GT") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ White Pop.}",pattern(1 0 1 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(above_*_med samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{9}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 

}


foreach m in iv rf ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt st_ratio_mean wtenroll_hasap_place wtenroll_hasde_place wtenroll_hasgt_place{
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		if "`m'"=="iv"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal *_samp_dest  ,  cl(cz)

		}
		else if "`m'"=="rf"{
			 eststo `covar' : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest v2_sumshares_urban  transpo_cost_1920 coastal *_samp_dest reg2 reg3 reg4  , vce(cl cz) 
		}
		else if "`m'"=="ols"{
			 eststo `covar' : reghdfe `covar' above_x_med samp_destXabove_x_med samp_dest v2_sumshares_urban  transpo_cost_1920 coastal *_samp_dest reg2 reg3 reg4  , vce(cl cz) 
		}
	}


	esttab using "$TABS/land_use_index/muni_outcomes_`m'_new_ctrls.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}"  "Student-Teacher Ratio" "Pct w/AP" "Pct w/DE" "Pct w/GT") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ White Pop.}", pattern(1 0 1 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(above_*_med samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{9}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 

}

/* Normal X/Z


foreach m in iv rf ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt st_ratio_mean wtenroll_hasap_place wtenroll_hasde_place wtenroll_hasgt_place{
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		if "`m'"=="iv"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (GM_raw_pp samp_destXGM = GM_hat_raw samp_destXGM_hat) v2_sumshares_urban v2_sumshares_urban_samp_dest reg2 reg3 reg4 reg*_samp_dest  ,  cl(cz)

		}
		else if "`m'"=="rf"{
			 eststo `covar' : reghdfe `covar' GM_hat_raw samp_destXGM_hat samp_dest v2_sumshares_urban v2_sumshares_urban_samp_dest reg2 reg3 reg4 reg*_samp_dest   , vce(cl cz) 
		}
		else if "`m'"=="ols"{
			 eststo `covar' : reghdfe `covar' GM_raw_pp samp_destXGM samp_dest v2_sumshares_urban v2_sumshares_urban_samp_dest reg2 reg3 reg4 reg*_samp_dest  , vce(cl cz) 
		}
	}


	esttab using "$TABS/land_use_index/muni_outcomes_`m'_full.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}"  "Student-Teacher Ratio" "Pct w/AP" "Pct w/DE" "Pct w/GT") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ White Pop.}", pattern(1 0 1 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(GM_* samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{9}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 

}


foreach m in iv rf ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt st_ratio_mean wtenroll_hasap_place wtenroll_hasde_place wtenroll_hasgt_place{
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		if "`m'"=="iv"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (GM_raw_pp samp_destXGM = GM_hat_raw samp_destXGM_hat) v2_sumshares_urban  transpo_cost_1920 coastal reg2 reg3 reg4 *_samp_dest  , cl(cz)

		}
		else if "`m'"=="rf"{
			 eststo `covar' : reghdfe `covar' GM_hat_raw samp_destXGM_hat samp_dest v2_sumshares_urban  transpo_cost_1920 coastal reg2 reg3 reg4 *_samp_dest  , vce(cl cz)
		}
		else if "`m'"=="ols"{
			 eststo `covar' : reghdfe `covar' GM_raw_pp samp_destXGM samp_dest v2_sumshares_urban  transpo_cost_1920 coastal reg2 reg3 reg4 *_samp_dest  , vce(cl cz)
		}
	}


	esttab using "$TABS/land_use_index/muni_outcomes_`m'_full_new_ctrls.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}"  "Student-Teacher Ratio" "Pct w/AP" "Pct w/DE" "Pct w/GT") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ White Pop.}", pattern(1 0 1 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(GM_* samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{9}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 

}
*/



// MAIN CITY VS NEW

keep if main_city == 1 | 
foreach m in iv rf ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt st_ratio_mean wtenroll_hasap_place wtenroll_hasde_place wtenroll_hasgt_place{
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		if "`m'"=="iv"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal *_samp_dest  ,  cl(cz)

		}
		else if "`m'"=="rf"{
			 eststo `covar' : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest v2_sumshares_urban  transpo_cost_1920 coastal *_samp_dest reg2 reg3 reg4  , vce(cl cz) 
		}
		else if "`m'"=="ols"{
			 eststo `covar' : reghdfe `covar' above_x_med samp_destXabove_x_med samp_dest v2_sumshares_urban  transpo_cost_1920 coastal *_samp_dest reg2 reg3 reg4  , vce(cl cz) 
		}
	}


	esttab using "$TABS/land_use_index/muni_outcomes_`m'_new_ctrls.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}"  "Student-Teacher Ratio" "Pct w/AP" "Pct w/DE" "Pct w/GT") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ White Pop.}", pattern(1 0 1 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(above_*_med samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{9}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 

}
	/*

	// Continuous DID model
	drop if yr_incorp>1970
	g time = 1 if yr_incorp <1940
	replace time = 2 if yr_incorp>=1940 & yr_incorp<=1970

	g treat = cond(time==1,GM_hat_raw,0)

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		eststo `covar' : didregress (`covar' i.region v2_sumshares_urban) (treat, continuous)  , group(cz) time(time) vce(cl cz)


		
	}


	esttab using "$TABS/land_use_index/muni_outcomes_continuous_did.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(treat) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{5}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 
				
				

	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		eststo `covar' : didregress (`covar' i.region v2_sumshares_urban transpo_cost_1920 coastal) (treat, continuous)  , group(cz) time(time) vce(cl cz)


		
	}


	esttab using "$TABS/land_use_index/muni_outcomes_continuous_did_new_ctrls.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(treat) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{5}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 


}
*/


