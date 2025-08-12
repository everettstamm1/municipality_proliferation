

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll_leaid blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname area  stu_diss_bl_cz stu_diss_blwt_cz achievement_diss_blwt_cz achievement_diss_bl_cz stu_RCO_blwt_cz stu_A_05_blwt_cz stu_A_01_blwt_cz stu_A_09_blwt_cz stu_SP_touch_blwt_cz stu_SP_nexpd_blwt_cz stu_vr_bl_cz stu_vr_blwt_cz achievement_VR_blwt_cz achievement_* totenroll_*

duplicates drop
unique STATEFP PLACEFP
assert _N == r(N)

replace place_land = place_land/1000000
replace touching = . if main_city == 1
replace prop_white2010 = 100*prop_white2010
replace mean_hh_inc_place = mean_hh_inc_place / 1000
foreach m in ols{
	if "`m'"=="rf" local mod "Reduced Form"
	if "`m'"=="iv" local mod "IV"
	if "`m'"=="ols" local mod "OLS"

	eststo clear
	foreach covar of varlist touching   pct_rev_debt council_manager {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		
		if "`m'"=="ols"{
		su `covar' if above_x_med == 0
		local bdv : di %6.2f r(mean)
		su `covar' if above_x_med == 0 [aw = weight_pop]
		local bdvw : di %6.2f r(mean)
		eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest reg2 reg3 reg4   [aw=weight_pop], vce(cl cz) 
	 estadd scalar bdv = `bdv'
	 estadd scalar bdvw = `bdvw'
		}
	}
	

	esttab touching  pct_rev_debt council_manager ///
				using "$TABS/land_use_index/touching_pct_rev_debt.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Adjacent to \\ Principle City}" "\shortstack{Outstanding Debt as  \\ Pct of Municipal Revenues}" "\shortstack{City Manager \\ Gov't}") ///
				keep(samp_destXabove_?_med above_?_med samp_dest) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabular}{l*{4}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats(  bdvw N, labels( "Below Median Avg." "Observations") fmt(3 0))

}
