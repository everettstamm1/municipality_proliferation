

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname

duplicates drop
replace place_land = place_land/1000000
replace touching = . if main_city == 1
replace prop_white2010 = 100*prop_white2010
replace mean_hh_inc_place = mean_hh_inc_place / 1000
foreach m in  ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_district_shape {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		if "`m'"=="iv"{
			di "here1, m: `m', covar: `covar'"
			su `covar' if above_x_med == 0
			local bdv : di %6.2f r(mean)
			su `covar' if above_x_med == 0 & samp_dest == 0 [aw = weight_pop]
			local bdvw : di %6.2f r(mean)
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest  transpo_cost_1920 transpo_cost_1920_samp_dest coastal coastal_samp_dest  [aw=weight_pop], cl(cz)
			 estadd scalar bdv = `bdv'
			 estadd scalar bdvw = `bdvw

		}
		else if "`m'"=="rf"{
						di "here2, m: `m', covar: `covar'"
		su `covar' if above_z_med == 0
		local bdv : di %6.2f r(mean)
		su `covar' if above_z_med == 0 [aw = weight_pop]
		local bdvw : di %6.2f r(mean)
			 eststo `covar' : reghdfe `covar' samp_destXabove_z_med above_inst_med  samp_dest  v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest  transpo_cost_1920 transpo_cost_1920_samp_dest coastal coastal_samp_dest  [aw=weight_pop], vce(cl cz) absorb(region)
			 estadd scalar bdv = `bdv'
			 estadd scalar bdvw = `bdvw
		}
		else if "`m'"=="ols"{
						di "here3, m: `m', covar: `covar'"

		su `covar' if above_x_med == 0 & samp_dest == 0 [aw = weight_pop]
		local bdvw : di %6.2f r(mean)
			 eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest  reg2 reg3 reg4  v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest  coastal coastal_samp_dest transpo_cost_1920 transpo_cost_1920_samp_dest [aw=weight_pop], vce(cl cz) 
			 estadd scalar bdvw = `bdvw'
		}
	}

	esttab  prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_district_shape ///
				using "$TABS/land_use_index/muni_outcomes_`m'.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Percentage \\ White}" "\shortstack{Land \\ Area}" "\shortstack{2010 Household \\ Income}" "\shortstack{Special \\ Assessments}" "\shortstack{Fines and \\ Forfeitures}" "\shortstack{Single \\ Family}" "Apartments" "\shortstack{Exclusive \\ District}") ///
				mgroups("2010 Muni Characteristics" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ Municipal Land Uses}"  "\shortstack{Muni-District \\ Similarity}" ,pattern(1 0 0 1 0 1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(samp_destXabove_?_med above_?_med samp_dest) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabularx}{\textwidth}{l*{8}{>{\centering\arraybackslash}X}} \toprule) postfoot(	\bottomrule \end{xtabular}) stats(  bdvw N, labels( "Omitted Category Avg." "Observations") fmt(2 0))

}

xtabular