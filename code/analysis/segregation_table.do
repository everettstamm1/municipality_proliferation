
	

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

eststo stu_iqr : ivreg2 achievement_iqr (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su achievement_iqr, d
estadd scalar dv = r(mean)

eststo stu_var : ivreg2 achievement_var_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su achievement_var_cz, d
estadd scalar dv = r(mean)

eststo black_exposure: ivreg2 black_exposure (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su black_exposure, d
estadd scalar dv = r(mean)

eststo white_exposure: ivreg2 white_exposure (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su white_exposure, d
estadd scalar dv = r(mean)


esttab stu_vr stu_diss stu_iqr stu_var black_exposure white_exposure using "$TABS/implications/student_segregation_table.tex", 	replace se booktabs noconstant noobs compress frag label  ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Variance \\ Ratio}" "\shortstack{Dissimilarity \\ Index}" "\shortstack{Interquartile \\ Range}" "\shortstack{Variance}" "\shortstack{Black}" "\shortstack{White}") ///
				keep(GM_raw_pp) b(%05.3f) se(%05.3f) ///
				prehead( "\begin{tabularx}{\textwidth}{l*{6}{>{\centering\arraybackslash}X}} \toprule" ///
				"&\multicolumn{2}{c}{School District Segregation}&\multicolumn{4}{c}{School District Achievement}\\\cmidrule(lr){2-3}\cmidrule(lr){4-7}" ) ///
				postfoot(	\bottomrule \end{tabularx}) stats( dv N, labels("Dep. Var. Mean" "Observations") fmt(3 0))


				

use "$INTDATA/nces/offerings", clear
keep cz sch_vr_blwt_cz sch_diss_blwt_cz
duplicates drop
tempfile seg
save `seg'
use "$CLEANDATA/cz_pooled.dta", clear
lab var GM_raw_pp "GM"
lab var n_schdist_ind_cz_pc "$\Delta$ School Districts P.C."
merge 1:1 cz using "$INTDATA/cz_pop_segregation", keep(1 3) nogen
merge 1:1 cz using "$INTDATA/nces/cz_achievement_segregation", keep(1 3) nogen
merge 1:1 cz using `seg', keep(1 3) nogen
g schoolflag = mi(n_schdist_ind_cz_pc)

ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict muni_e, resid
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
predict schdist_ind_e if e(sample), resid


eststo clear

eststo stu_vr: ivreg2 sch_vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su sch_vr_blwt_cz, d
estadd scalar dv = r(mean)

eststo stu_diss: ivreg2 sch_diss_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su sch_diss_blwt_cz, d
estadd scalar dv = r(mean)

eststo stu_iqr : ivreg2 achievement_iqr (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su achievement_iqr, d
estadd scalar dv = r(mean)

eststo stu_var : ivreg2 achievement_var_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su achievement_var_cz, d
estadd scalar dv = r(mean)

eststo black_exposure: ivreg2 black_exposure (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su black_exposure, d
estadd scalar dv = r(mean)

eststo white_exposure: ivreg2 white_exposure (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
su white_exposure, d
estadd scalar dv = r(mean)


esttab stu_vr stu_diss stu_iqr stu_var black_exposure white_exposure using "$TABS/implications/student_segregation_table_school.tex", 	replace se booktabs noconstant noobs compress frag label  ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("\shortstack{Variance \\ Ratio}" "\shortstack{Dissimilarity \\ Index}" "\shortstack{Interquartile \\ Range}" "\shortstack{Variance}" "\shortstack{Black}" "\shortstack{White}") ///
				keep(GM_raw_pp) b(%05.3f) se(%05.3f) ///
				prehead( "\begin{tabularx}{\textwidth}{l*{6}{>{\centering\arraybackslash}X}} \toprule" ///
				"&\multicolumn{2}{c}{School District Segregation}&\multicolumn{4}{c}{School District Achievement}\\\cmidrule(lr){2-3}\cmidrule(lr){4-7}" ) ///
				postfoot(	\bottomrule \end{tabularx}) stats( dv N, labels("Dep. Var. Mean" "Observations") fmt(3 0))



				

				