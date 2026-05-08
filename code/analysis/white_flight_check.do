

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll_leaid blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname area  stu_diss_bl_cz stu_diss_blwt_cz achievement_diss_blwt_cz achievement_diss_bl_cz stu_RCO_blwt_cz stu_A_05_blwt_cz stu_A_01_blwt_cz stu_A_09_blwt_cz stu_SP_touch_blwt_cz stu_SP_nexpd_blwt_cz stu_vr_bl_cz stu_vr_blwt_cz achievement_VR_blwt_cz achievement_* totenroll_*

duplicates drop

lab var wf_cc1970 "Moved From Central City"
lab var wf_smsa1970 "Moved Within SMSA"
lab var wf_smsarev1970 "Non-Movers"

foreach m in base imbal{
	if "`m'" == "imbal" local ctrls reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940
	if "`m'" == "base" local ctrls reg2 reg3 reg4

	eststo clear
	foreach covar of varlist wf_smsarev1970 wf_smsa1970 wf_cc1970 {
		
		su `covar' if above_x_med == 0
		local bdv : di %6.2f r(mean)
		su `covar' if above_x_med == 0 [aw = weight_pop]
		local bdvw : di %6.2f r(mean)
		eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest `ctrls'   [aw=weight_pop], vce(cl cz) 
	 estadd scalar bdv = `bdv'
	 estadd scalar bdvw = `bdvw'
		}
	
	

	esttab  wf_smsarev1970 wf_smsa1970 wf_cc1970 ///
				using "$TABS/land_use_index/wf_check_`m'.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Share \\ Non-Movers}" "\shortstack{Share Moved  \\ Within SMSA}" "\shortstack{Share Moved From \\ SMSA Central City}") ///
				keep(samp_destXabove_x_med above_x_med samp_dest) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabular}{l*{4}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats(  bdvw N, labels( "Below Median Avg." "Observations") fmt(3 0))

}


foreach m in base imbal{
	if "`m'" == "imbal" local ctrls reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940
	if "`m'" == "base" local ctrls reg2 reg3 reg4

	eststo clear
	foreach covar of varlist wwf_smsarev1970 wwf_smsa1970 wwf_cc1970 {
		
		su `covar' if above_x_med == 0
		local bdv : di %6.2f r(mean)
		su `covar' if above_x_med == 0 [aw = weight_pop]
		local bdvw : di %6.2f r(mean)
		eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest `ctrls'   [aw=weight_pop], vce(cl cz) 
	 estadd scalar bdv = `bdv'
	 estadd scalar bdvw = `bdvw'
		}
	
	

	esttab  wwf_smsarev1970 wwf_smsa1970 wwf_cc1970 ///
				using "$TABS/land_use_index/wwf_check_`m'.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Share \\ Non-Movers}" "\shortstack{Share Moved  \\ Within SMSA}" "\shortstack{Share Moved From \\ SMSA Central City}") ///
				keep(samp_destXabove_x_med above_x_med samp_dest) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabular}{l*{4}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats(  bdvw N, labels( "Below Median Avg." "Observations") fmt(3 0))

}