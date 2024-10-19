use "$CLEANDATA/cz_pooled.dta", clear

merge 1:1 cz using "$INTDATA/cz_pop_segregation", keep(1 3) nogen
merge 1:1 cz using "$INTDATA/nces/cz_achievement_segregation", keep(1 3) nogen

g schoolflag = mi(n_schdist_ind_cz_pc)

ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict muni_e, resid
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict schdist_ind_e if e(sample), resid


eststo clear

eststo stu_vr: ivreg2 stu_vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su stu_vr_blwt_cz, d
estadd scalar dv = r(mean)
eststo stu_diss: ivreg2 stu_diss_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su stu_diss_blwt_cz, d
estadd scalar dv = r(mean)
eststo stu_RCO : ivreg2 stu_RCO_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su stu_RCO_blwt_cz, d
estadd scalar dv = r(mean)
eststo stu_SP : ivreg2 stu_SP_nexpd_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su stu_SP_nexpd_blwt_cz,
estadd scalar dv = r(mean)
eststo stu_A_01: ivreg2 stu_A_01_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su stu_A_01_blwt_cz,
estadd scalar dv = r(mean)
eststo stu_A_09: ivreg2 stu_A_09_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su stu_A_09_blwt_cz,
estadd scalar dv = r(mean)

eststo pop_vr: ivreg2 pop_vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su pop_vr_blwt_cz, d
estadd scalar dv = r(mean)
eststo pop_diss: ivreg2 pop_diss_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if schoolflag == 0 [aw = popc1940], r
su pop_diss_blwt_cz, d
estadd scalar dv = r(mean)
eststo pop_RCO: ivreg2 pop_RCO_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  [aw = popc1940], r
su pop_RCO_blwt_cz, d
estadd scalar dv = r(mean)
eststo pop_SP: ivreg2 pop_SP_nexpd_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su pop_SP_nexpd_blwt_cz, d
estadd scalar dv = r(mean)
eststo pop_A_01: ivreg2 pop_A_01_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su stu_A_01_blwt_cz, d
estadd scalar dv = r(mean)
eststo pop_A_09: ivreg2 pop_A_09_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su stu_A_09_blwt_cz, d
estadd scalar dv = r(mean)

esttab pop_vr pop_diss pop_RCO pop_SP pop_A_01 pop_A_09 using "$TABS/implications/segregation_table.tex", booktabs compress nolabel replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Variance \\ Ratio}" "\shortstack{Dissimilarity \\ Index}" "\shortstack{Relative \\ Concentration}" "\shortstack{Spatial \\ Proximity}" "\shortstack{Atkinson \\ Index ($\beta = 0.1$)}") ///
				posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel A: Population Segregation}\\" "\cmidrule(lr){1-7}") /// 
				keep(GM_raw_pp) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabular}{l*{7}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats( dv N, labels("Dep. Var. Mean" "Observations") fmt(3 0))


esttab stu_vr stu_diss stu_RCO stu_SP stu_A_01 stu_A_09 using "$TABS/implications/segregation_table.tex", booktabs compress nolabel replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: School District Segregation}\\" "\cmidrule(lr){1-7}") /// 
				keep(GM_raw_pp) b(%05.3f) se(%05.3f) ///
				prehead( \begin{tabular}{l*{7}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats( dv N, labels("Dep. Var. Mean" "Observations") fmt(3 0))

				
// New achievement
use "$CLEANDATA/cz_pooled.dta", clear

merge 1:1 cz using "$INTDATA/cz_pop_segregation", keep(1 3) nogen
merge 1:1 cz using "$INTDATA/nces/cz_achievement_segregation", keep(1 3) nogen

g schoolflag = mi(n_schdist_ind_cz_pc)
lab var n_schdist_ind_cz_pc "New Ind. Sch. Dists., P.C. (total)"

ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict muni_e, resid
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict schdist_ind_e if e(sample), resid

eststo clear
foreach t in vr diss RCO SP_nexpd A_01 A_09{
	eststo `t'_iv: ivreg2 pop_`t'_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	
	eststo `t'_ols_muni: reg pop_`t'_blwt_cz n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	eststo `t'_ts_muni: reg pop_`t'_blwt_cz n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 muni_e [aw = popc1940], r
	su pop_`t'_blwt_cz if e(sample),
	estadd scalar avg_muni = r(mean)
	
	eststo `t'_ols_schdist: reg pop_`t'_blwt_cz n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	eststo `t'_ts_schdist: reg pop_`t'_blwt_cz n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 schdist_ind_e [aw = popc1940], r
	su pop_`t'_blwt_cz if e(sample),
	estadd scalar avg_schdist = r(mean)
}


esttab vr_iv diss_iv RCO_iv SP_nexpd_iv A_01_iv A_09_iv      ///
	using "$TABS/implications/pop_segregation_table_3sls.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	posthead("&\multicolumn{1}{c}{VR}&\multicolumn{1}{c}{Diss}&\multicolumn{1}{c}{RCO}&\multicolumn{1}{c}{SP}&\multicolumn{1}{c}{Atkinson ($\beta = 0.1$)}&\multicolumn{1}{c}{Atkinson ($\beta - 0.9$)}\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}" ///
	"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: IV with GM}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{9}{c}} \toprule) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
 keep(GM_raw_pp) 

esttab vr_ols_muni diss_ols_muni RCO_ols_muni SP_nexpd_ols_muni A_01_ols_muni A_09_ols_muni   ///
	using "$TABS/implications/pop_segregation_table_3sls.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS with Munis}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_gen_muni_cz_pc)
	
esttab vr_ts_muni diss_ts_muni RCO_ts_muni SP_nexpd_ts_muni A_01_ts_muni A_09_ts_muni     ///
	using "$TABS/implications/pop_segregation_table_3sls.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Two Step with Munis}\\" "\cmidrule(lr){1-7}" ) 	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_gen_muni_cz_pc) ///
	stats(avg_muni N, labels("Dep. Var Mean" "Observations") fmt(3 0))
	
esttab vr_ols_schdist diss_ols_schdist RCO_ols_schdist SP_nexpd_ols_schdist A_01_ols_schdist  A_09_ols_schdist ///
	using "$TABS/implications/pop_segregation_table_3sls.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: OLS with School Districts}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_schdist_ind_cz_pc)
	
esttab vr_ts_schdist diss_ts_schdist RCO_ts_schdist SP_nexpd_ts_schdist A_01_ts_schdist  A_09_ts_schdist    ///
	using "$TABS/implications/pop_segregation_table_3sls.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel E: Two Step with School Districts}\\" "\cmidrule(lr){1-7}" ) 	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_schdist_ind_cz_pc) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(avg_schdist N, labels("Dep. Var Mean" "Observations") fmt(3 0))
	
	

eststo clear
foreach t in vr diss RCO SP_nexpd A_01 A_09{
	eststo `t'_iv: ivreg2 stu_`t'_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	
	eststo `t'_ols_muni: reg stu_`t'_blwt_cz n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	eststo `t'_ts_muni: reg stu_`t'_blwt_cz n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 muni_e [aw = popc1940], r
	su pop_`t'_blwt_cz if e(sample),
	estadd scalar avg_muni = r(mean)
	
	eststo `t'_ols_schdist: reg stu_`t'_blwt_cz n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	eststo `t'_ts_schdist: reg stu_`t'_blwt_cz n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 schdist_ind_e [aw = popc1940], r
	su pop_`t'_blwt_cz if e(sample),
	estadd scalar avg_schdist = r(mean)
}


esttab vr_iv diss_iv RCO_iv SP_nexpd_iv A_01_iv A_09_iv      ///
	using "$TABS/implications/stu_segregation_table_3sls.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	posthead("&\multicolumn{1}{c}{VR}&\multicolumn{1}{c}{Diss}&\multicolumn{1}{c}{RCO}&\multicolumn{1}{c}{SP}&\multicolumn{1}{c}{Atkinson ($\beta = 0.1$)}&\multicolumn{1}{c}{Atkinson ($\beta - 0.9$)}\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}" ///
	"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}" ///
			"\multicolumn{6}{l}{Panel A: IV with GM}\\" "\cmidrule(lr){1-7}" ) ///
	prehead( \begin{tabular}{l*{9}{c}} \toprule) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
 keep(GM_raw_pp) 

esttab vr_ols_muni diss_ols_muni RCO_ols_muni SP_nexpd_ols_muni A_01_ols_muni A_09_ols_muni   ///
	using "$TABS/implications/stu_segregation_table_3sls.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel B: OLS with Munis}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_gen_muni_cz_pc)
	
esttab vr_ts_muni diss_ts_muni RCO_ts_muni SP_nexpd_ts_muni A_01_ts_muni A_09_ts_muni     ///
	using "$TABS/implications/stu_segregation_table_3sls.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel C: Two Step with Munis}\\" "\cmidrule(lr){1-7}" ) 	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_gen_muni_cz_pc) ///
	stats(avg_muni N, labels("Dep. Var Mean" "Observations") fmt(3 0))
	
esttab vr_ols_schdist diss_ols_schdist RCO_ols_schdist SP_nexpd_ols_schdist A_01_ols_schdist  A_09_ols_schdist ///
	using "$TABS/implications/stu_segregation_table_3sls.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel D: OLS with School Districts}\\" "\cmidrule(lr){1-7}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_schdist_ind_cz_pc)
	
esttab vr_ts_schdist diss_ts_schdist RCO_ts_schdist SP_nexpd_ts_schdist A_01_ts_schdist  A_09_ts_schdist    ///
	using "$TABS/implications/stu_segregation_table_3sls.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-7}" "\multicolumn{6}{l}{Panel E: Two Step with School Districts}\\" "\cmidrule(lr){1-7}" ) 	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_schdist_ind_cz_pc) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(avg_schdist N, labels("Dep. Var Mean" "Observations") fmt(3 0))
	
	
	

use "$CLEANDATA/cz_pooled.dta", clear
lab var GM_raw_pp "GM"
lab var n_schdist_ind_cz_pc "$\Delta$ School Districts P.C."
merge 1:1 cz using "$INTDATA/cz_pop_segregation", keep(1 3) nogen
merge 1:1 cz using "$INTDATA/nces/cz_achievement_segregation", keep(1 3) nogen

g schoolflag = mi(n_schdist_ind_cz_pc)

ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict muni_e, resid
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict schdist_ind_e if e(sample), resid


eststo clear

eststo stu_vr: ivreg2 stu_vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su stu_vr_blwt_cz, d
estadd scalar dv = r(mean)

eststo stu_diss: ivreg2 stu_diss_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su stu_diss_blwt_cz, d
estadd scalar dv = r(mean)

eststo stu_RCO : ivreg2 achievement_iqr (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su achievement_iqr, d
estadd scalar dv = r(mean)

eststo stu_SP : ivreg2 achievement_var_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su achievement_var_cz, d
estadd scalar dv = r(mean)

eststo stu_A_01: ivreg2 black_exposure (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su black_exposure, d
estadd scalar dv = r(mean)

eststo stu_A_09: ivreg2 white_exposure (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su white_exposure, d
estadd scalar dv = r(mean)


esttab stu_vr stu_diss stu_RCO stu_SP stu_A_01 stu_A_09 using "$TABS/implications/student_segregation_table.tex", 	replace se booktabs noconstant noobs compress frag label  ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Variance \\ Ratio}" "\shortstack{Dissimilarity \\ Index}" "\shortstack{Interquartile \\ Range}" "\shortstack{Variance}" "\shortstack{Black}" "\shortstack{White}") ///
				keep(GM_raw_pp) b(%05.3f) se(%05.3f) ///
				prehead( "\begin{tabularx}{\textwidth}{l*{6}{>{\centering\arraybackslash}X}} \toprule" ///
				"&\multicolumn{2}{c}{School District Segregation}&\multicolumn{4}{c}{School District Achievement}\\\cmidrule(lr){2-3}\cmidrule(lr){4-7}" ) ///
				postfoot(	\bottomrule \end{tabularx}) stats( dv N, labels("Dep. Var. Mean" "Observations") fmt(3 0))


// New achievement
/*
aggregate total achievement to CZ level weighted by black then white enrollment, then take difference
VR, Diss, IQR, Var, White, Black
figure 2 legend bottom left within region
appendix table with township by itself
debt and adjacency in appendix
drop unweighted mean from table 2, drop sqkm, pct instead of percent
*/
use "$CLEANDATA/cz_pooled", clear

merge 1:1 cz using "$INTDATA/nces/cz_achievement_segregation", keep(3) nogen
lab var n_schdist_ind_cz_pc "New Ind. Sch. Dists., P.C. (total)"

ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict muni_e, resid
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict schdist_ind_e if e(sample), resid
ren achievement_* a_*
ren totenroll_* te_*


eststo clear
foreach t in race_exp race_self_exp a_iqr a_var_cz{
	eststo `t'_iv: ivreg2 `t' (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if !mi(n_schdist_ind_cz_pc) [aw = popc1940], r

	eststo `t'_ols_muni: reg `t' n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 if !mi(n_schdist_ind_cz_pc) [aw = popc1940], r
	eststo `t'_ts_muni: reg `t' n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 muni_e if !mi(n_schdist_ind_cz_pc) [aw = popc1940], r
	su `t' if e(sample),
	estadd scalar avg_muni = r(mean)
	eststo `t'_ols_schdist: reg `t' n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	eststo `t'_ts_schdist: reg `t' n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 schdist_ind_e [aw = popc1940], r
	su `t' if e(sample),
	estadd scalar avg_schdist = r(mean)
}


esttab  race_exp_iv race_self_exp_iv a_iqr_iv a_var_cz_iv      ///
	using "$TABS/implications/achievement_gaps_2.tex", ///
	replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
	b(%04.3f) se(%04.3f) ///
	posthead("&\multicolumn{1}{c}{B-W Exposure}&\multicolumn{1}{c}{B-W Achievement Gap}&\multicolumn{1}{c}{IQR}&\multicolumn{1}{c}{Var(Achievement)}&\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}" ///
	"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}\\" ///
			"\cmidrule(lr){1-5}" ///
			"\multicolumn{4}{l}{Panel A: IV with GM}\\" "\cmidrule(lr){1-5}" ) ///
	prehead( \begin{tabular}{l*{6}{c}} \toprule) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
 keep(GM_raw_pp) 

esttab race_exp_ols_muni race_self_exp_ols_muni a_iqr_ols_muni a_var_cz_ols_muni   ///
	using "$TABS/implications/achievement_gaps_2.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel B: OLS with Munis}\\" "\cmidrule(lr){1-5}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_gen_muni_cz_pc)
	
esttab race_exp_ts_muni race_self_exp_ts_muni a_iqr_ts_muni a_var_cz_ts_muni      ///
	using "$TABS/implications/achievement_gaps_2.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel C: Two Step with Munis}\\" "\cmidrule(lr){1-5}" ) 	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_gen_muni_cz_pc) ///
	stats(avg_muni N, labels("Dep. Var Mean" "Observations") fmt(3 0))
	
esttab race_exp_ols_schdist race_self_exp_ols_schdist a_iqr_ols_schdist a_var_cz_ols_schdist    ///
	using "$TABS/implications/achievement_gaps_2.tex", ///
	se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel B: OLS with School Districts}\\" "\cmidrule(lr){1-5}" ) ///
	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_schdist_ind_cz_pc)
	
esttab race_exp_ts_schdist race_self_exp_ts_schdist a_iqr_ts_schdist a_var_cz_ts_schdist      ///
	using "$TABS/implications/achievement_gaps_2.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
	posthead("\cmidrule(lr){1-5}" "\multicolumn{4}{l}{Panel E: Two Step with School Districts}\\" "\cmidrule(lr){1-5}" ) 	b(%04.3f) se(%04.3f) ///
	starlevels( * 0.10 ** 0.05 *** 0.01) ///
	keep(n_schdist_ind_cz_pc) ///
	postfoot(	\bottomrule \end{tabular}) ///
	stats(avg_schdist N, labels("Dep. Var Mean" "Observations") fmt(3 0))
	
	
	
	
	
use "$CLEANDATA/cz_pooled.dta", clear

merge 1:1 cz using "$INTDATA/cz_pop_segregation", keep(1 3) nogen
merge 1:1 cz using "$INTDATA/nces/cz_achievement_segregation", keep(1 3) nogen

g schoolflag = mi(n_schdist_ind_cz_pc)
lab var n_schdist_ind_cz_pc "New Ind. Sch. Dists., P.C. (total)"

ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict muni_e, resid
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict schdist_ind_e if e(sample), resid

eststo clear
foreach t in vr diss RCO SP_nexpd A_01 A_09{
	eststo `t'_iv: ivreg2 pop_`t'_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	su pop_`t'_blwt_cz, d
	estadd scalar dv = r(mean)
}



esttab vr_iv diss_iv RCO_iv SP_nexpd_iv A_01_iv A_09_iv  using "$TABS/implications/pop_segregation_table.tex", 	nomtitles replace se booktabs noconstant noobs compress frag label  ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				posthead("&\multicolumn{1}{c}{VR}&\multicolumn{1}{c}{Diss}&\multicolumn{1}{c}{RCO}&\multicolumn{1}{c}{SP}&\multicolumn{1}{c}{Atkinson ($\beta = 0.1$)}&\multicolumn{1}{c}{Atkinson ($\beta = 0.9$)}\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}" ///
	"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}\\" ///
			"\cmidrule(lr){1-7}") ///
				keep(GM_raw_pp) b(%05.3f) se(%05.3f) ///
				prehead( "\begin{tabular}{l*{7}{c}} \toprule") ///
				postfoot(	\bottomrule \end{tabular}) stats( dv N, labels("Dep. Var. Mean" "Observations") fmt(3 0))



				