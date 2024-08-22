
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1
g one_school = n_schools == 1
g no_school = n_schools == 0
g prop_white_students = wtenroll_place / totenroll_place

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot
duplicates drop

// Creating interactions
g samp_destXtouching = samp_dest * touching
g above_x_medXtouching = above_x_med * touching
g samp_destXabove_x_medXtouching = above_x_med * samp_dest * touching

g samp_destXlee = samp_dest * len_edge_edge
g above_x_medXlee = above_x_med * len_edge_edge
g samp_destXabove_x_medXlee = above_x_med * samp_dest * len_edge_edge

// Target munis: those who incorporated during the Great migration and received above median GM levels

// 0-th stage

su len_edge_edge, d
g above_len_med = len_edge_edge >= r(p50)
// Set the output directory

// Raw splits
eststo clear
eststo: reg touching samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg len_edge_edge samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg above_len_med samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/0th_stage.tex", replace label title("Raw Splits") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Document they're whiter
eststo clear
eststo: reg prop_white1970 samp_dest above_x_med samp_destXabove_x_med
eststo: reg prop_white1970 samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/prop_white.tex", replace label title("Proportion White 1970") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Document they're whiter schools
eststo clear
eststo: reg prop_white_students samp_dest above_x_med samp_destXabove_x_med
eststo: reg prop_white_students samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/prop_white_students.tex", replace label title("Proportion White 1970") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// One/no School
eststo clear
eststo: reg one_school samp_dest above_x_med samp_destXabove_x_med
eststo: reg one_school samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
eststo: reg no_school samp_dest above_x_med samp_destXabove_x_med
eststo: reg no_school samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/school_presence.tex", replace label title("School Presence") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Exclusive district
eststo clear
eststo: reg exclusive_district samp_dest above_x_med samp_destXabove_x_med
eststo: reg exclusive_district samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/exclusive_district.tex", replace label title("Exclusive District") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Enrollment
eststo clear
eststo: reg avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med
eststo: reg avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/enrollment.tex", replace label title("Average Total Enrollment") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Landuse
eststo clear
eststo: reg landuse_sfr samp_dest above_x_med samp_destXabove_x_med
eststo: reg landuse_sfr samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
eststo: reg landuse_apartment samp_dest above_x_med samp_destXabove_x_med
eststo: reg landuse_apartment samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/landuse.tex", replace label title("Land Use") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Police
eststo clear
eststo: reg pct_exp_pol samp_dest above_x_med samp_destXabove_x_med
eststo: reg pct_exp_pol samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
eststo: reg pc_pol samp_dest above_x_med samp_destXabove_x_med
eststo: reg pc_pol samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
eststo: reg pct_rev_ff samp_dest above_x_med samp_destXabove_x_med
eststo: reg pct_rev_ff samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/police_expenditure.tex", replace label title("Police Expenditure") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Transit
eststo clear
eststo: reg alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med
eststo: reg alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/transit_performance.tex", replace label title("Transit Performance") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// White AP access
eststo clear
eststo: reg wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med
eststo: reg wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med if above_len_med == 0
esttab using "$TABS/implications/white_ap_access.tex", replace label title("White AP Access") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Table 2 setup
// Set the output directory

// 0-th stage
eststo clear
eststo: reghdfe touching samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe len_edge_edge samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe above_len_med samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/0th_stage_full.tex", replace label title("0-th Stage") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Document they're whiter
eststo clear
eststo: reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/prop_white_full.tex", replace label title("Proportion White 1970") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Document their schools are whiter
eststo clear
eststo: reghdfe prop_white_students samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe prop_white_students samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/prop_white_students_full.tex", replace label title("Proportion White Students") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// One/no school
eststo clear
eststo: reghdfe one_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe one_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe no_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe no_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/school_presence_full.tex", replace label title("School Presence") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Exclusive district
eststo clear
eststo: reghdfe exclusive_district samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe exclusive_district samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/exclusive_district_full.tex", replace label title("Exclusive District") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Enrollment
eststo clear
eststo: reghdfe avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/enrollment_full.tex", replace label title("Average Total Enrollment") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Landuse
eststo clear
eststo: reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/landuse_full.tex", replace label title("Land Use") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Police
eststo clear
eststo: reghdfe pct_exp_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pct_exp_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe pc_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pc_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/police_expenditure_full.tex", replace label title("Police Expenditure") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Transit
eststo clear
eststo: reghdfe alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/transit_performance_full.tex", replace label title("Transit Performance") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// White AP Access
eststo clear
eststo: reghdfe wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/white_ap_access_full.tex", replace label title("White AP Access") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// CZ Level stuff

use "$CLEANDATA/mechanisms.dta", clear
keep cz GM_raw_pp GM_hat_raw coastal transpo_cost_1920 v2_sumshares_urban popc1940 ap_gini_cz above_x_med vr_blwt_cz vr_blwtas_cz avg_alltransit_cz vr_bl_cz
duplicates drop
merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(3) keepusing(reg2 reg3 reg4 frac_unc* frac_uninc* change_frac_unc n_schdist_ind_cz) nogen // Need to get right regions...
g schoolflag = n_schdist_ind_cz < .
// Raw differences
// Set the output directory

// Raw differences
eststo clear
eststo: quietly su ap_gini_cz if above_x_med == 0, d
eststo: quietly su ap_gini_cz if above_x_med == 1, d
eststo: quietly su vr_blwt_cz if above_x_med == 0, d
eststo: quietly su vr_blwt_cz if above_x_med == 1, d
eststo: quietly su avg_alltransit_cz if above_x_med == 0, d
eststo: quietly su avg_alltransit_cz if above_x_med == 1, d
esttab using "$TABS/implications/raw_differences_1.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) p50(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    mtitles("GINI (Below)" "GINI (Above)" "VR (Below)" "VR (Above)" "Transit (Below)" "Transit (Above)") ///
    title("Raw Differences - GINI, VR, and Transit Score")

eststo clear
eststo: quietly su change_frac_unc if above_x_med == 0, d
eststo: quietly su change_frac_unc if above_x_med == 1, d
eststo: quietly su frac_uninc1970 if above_x_med == 0, d
eststo: quietly su frac_uninc1970 if above_x_med == 1, d
eststo: quietly su frac_uninc2010 if above_x_med == 0, d
eststo: quietly su frac_uninc2010 if above_x_med == 1, d
esttab using "$TABS/implications/raw_differences_2.tex", replace ///
    cells("mean(fmt(3)) sd(fmt(3)) p50(fmt(3)) min(fmt(3)) max(fmt(3))") ///
    mtitles("Change Uninc (Below)" "Change Uninc (Above)" "Uninc 1970 (Below)" "Uninc 1970 (Above)" "Uninc 2010 (Below)" "Uninc 2010 (Above)") ///
    title("Raw Differences - Fraction Unincorporated") 

// Full main spec
eststo clear
eststo: ivreg2 ap_gini_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 vr_blwtas_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 vr_bl_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
esttab using "$TABS/implications/full_main_spec_1.tex", replace label title("Full Main Specification - GINI and VR") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(GM_raw_pp)

eststo clear
eststo: ivreg2 avg_alltransit_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 change_frac_unc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 frac_uninc1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 frac_uninc2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
esttab using "$TABS/implications/full_main_spec_2.tex", replace label title("Full Main Specification - Transit Score and Fraction Unincorporated") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(GM_raw_pp)