// IDEA: reghdfe med_hv_place exp_pc samp_dest above_x_med exp_pcXsamp_dest exp_pcXabove_x_med exp_pcXsamp_destXabove_x_med [aw=weight_pop], vce(cl cz)


use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll_leaid blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname area  stu_diss_bl_cz stu_diss_blwt_cz achievement_diss_blwt_cz achievement_diss_bl_cz stu_RCO_blwt_cz stu_A_05_blwt_cz stu_A_01_blwt_cz stu_A_09_blwt_cz stu_SP_touch_blwt_cz stu_SP_nexpd_blwt_cz stu_vr_bl_cz stu_vr_blwt_cz achievement_VR_blwt_cz achievement_* totenroll_*

duplicates drop
unique STATEFP PLACEFP
assert _N == r(N)
replace place_land = place_land/1000000
replace touching = . if main_city == 1
replace prop_black2010 = 100*prop_black2010
replace prop_white2010 = 100*prop_white2010
replace mean_hh_inc_place = mean_hh_inc_place / 1000
replace place_total = log(place_total)

foreach m in base imbal{
	if "`m'" == "imbal" local ctrls reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940
	if "`m'" == "base" local ctrls reg2 reg3 reg4
	eststo clear
	foreach covar of varlist prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_district_shape {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		
		
						di "here3, m: `m', covar: `covar'"

		su `covar' if above_x_med == 0 & samp_dest == 0 [aw = weight_pop]
		local bdvw : di %6.2f r(mean)
		 eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest  `ctrls' [aw=weight_pop], vce(cl cz) 
		 estadd scalar bdvw = `bdvw'
		
	}

	esttab prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_district_shape ///
				using "$TABS/land_use_index/muni_outcomes_`m'.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Percentage \\ White}" "\shortstack{Land Area}" "\shortstack{2010 Household \\ Income}" "\shortstack{Special \\ Assessments}" "\shortstack{Fines and \\ Forfeitures}" "\shortstack{Single \\ Family}" "Apartments" "\shortstack{Exclusive \\ District}") ///
				mgroups("2010 Muni Characteristics" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ Municipal Land Uses}"  "\shortstack{Muni-District \\ Similarity}" ,pattern(1 0 0 1 0 1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(samp_destXabove_?_med above_?_med samp_dest) b(%5.3f) se(%5.3f) ///
				prehead( \begin{tabularx}{\linewidth}{l*{8}{>{\centering\arraybackslash}X}} \toprule) postfoot(	\bottomrule \end{tabularx}) stats(  bdvw N, labels( "Omitted Category Avg." "Observations") fmt(2 0))

}
/*
// Version for presentation
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname

duplicates drop
replace place_land = place_land/1000000
replace touching = . if main_city == 1
replace prop_white2010 = 100*prop_white2010
replace mean_hh_inc_place = mean_hh_inc_place / 1000

eststo clear
foreach covar of varlist prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_district_shape {
	local mname = subinstr("`covar'","landuse_", "",.)
	lab var `covar' "`mname'"
	
	su `covar' if above_x_med == 0 & samp_dest == 0 [aw = weight_pop]
	local bdvw : di %6.2f r(mean)
	 eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest  reg2 reg3 reg4  v2_sumshares_urban v2_sumshares_urban_samp_dest reg2_samp_dest reg3_samp_dest reg4_samp_dest  coastal coastal_samp_dest transpo_cost_1920 transpo_cost_1920_samp_dest [aw=weight_pop], vce(cl cz) 
	 estadd scalar bdvw = `bdvw'
}

esttab  prop_white2010 place_land mean_hh_inc_place  ///
				using "$TABS/land_use_index/muni_outcomes_ols_polities.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Percentage \\ White}" "\shortstack{Land \\ Area}" "\shortstack{2010 Household \\ Income}" ) ///
				mgroups("2010 Muni Characteristics"  ,pattern(1 0 0 ) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(samp_destXabove_?_med above_?_med samp_dest) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabularx}{\textwidth}{l*{3}{>{\centering\arraybackslash}X}} \toprule ) postfoot(	\bottomrule \end{tabularx}) stats(  bdvw N, labels( "Omitted Category Avg." "Observations") fmt(2 0))
				
				
esttab   pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_district_shape ///
				using "$TABS/land_use_index/muni_outcomes_ols_policies.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Special \\ Assessments}" "\shortstack{Fines and \\ Forfeitures}" "\shortstack{Single \\ Family}" "Apartments" "\shortstack{Exclusive \\ District}") ///
				mgroups("\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ Municipal Land Uses}"  "\shortstack{Muni-District \\ Similarity}" ,pattern(1 0 1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(samp_destXabove_?_med above_?_med samp_dest) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule) postfoot(	\bottomrule \end{tabularx}) stats(  bdvw N, labels( "Omitted Category Avg." "Observations") fmt(2 0))
				
				*/