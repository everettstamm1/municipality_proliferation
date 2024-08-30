
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1
g one_school = n_schools == 1
g no_school = n_schools == 0
g prop_white_students = wtenroll_place / totenroll_place
drop mean_p*

foreach var of varlist pmax_shared_boundary_muni pmax_shared_boundary_dist psum_shared_boundary_muni psum_shared_boundary_dist EI dist_max_int_cz{
	//replace `var' = . if main_city == 1
}


bys cz : egen mean_pmax_shared_muni = mean(pmax_shared_boundary_muni)
bys cz : egen mean_pmax_shared_dist = mean(pmax_shared_boundary_dist)

bys cz : egen mean_psum_shared_muni = mean(psum_shared_boundary_muni)
bys cz : egen mean_psum_shared_dist = mean(psum_shared_boundary_dist)

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot school_level psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int
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
eststo: reg prop_white1970 samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/prop_white.tex", replace label title("Proportion White 1970") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Document they're whiter schools
eststo clear
eststo: reg prop_white_students samp_dest above_x_med samp_destXabove_x_med
eststo: reg prop_white_students samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/prop_white_students.tex", replace label title("Proportion White 1970") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// One/no School
eststo clear
eststo: reg one_school samp_dest above_x_med samp_destXabove_x_med
eststo: reg one_school samp_dest above_x_med samp_destXabove_x_med if main_city
eststo: reg no_school samp_dest above_x_med samp_destXabove_x_med
eststo: reg no_school samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/school_presence.tex", replace label title("School Presence") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Exclusive district
eststo clear
eststo: reg exclusive_district_place samp_dest above_x_med samp_destXabove_x_med
eststo: reg exclusive_district_place samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/exclusive_district.tex", replace label title("Exclusive District") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2
// Exclusive district
eststo clear
eststo: reg exclusive_district_shape samp_dest above_x_med samp_destXabove_x_med
eststo: reg exclusive_district_shape samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/exclusive_district_shape.tex", replace label title("Exclusive District (by overlap)") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2
// Land
eststo clear
eststo: reg place_land samp_dest above_x_med samp_destXabove_x_med
eststo: reg place_land samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/land.tex", replace label title("Land Area") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2
// Land
eststo clear
eststo: reg place_land samp_dest above_x_med samp_destXabove_x_med if main_city==0
eststo: reg place_land samp_dest above_x_med samp_destXabove_x_med if main_city == 0 & main_city == 0
esttab using "$TABS/implications/land_nomain.tex", replace label title("Land Area") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2
	
// Enrollment
eststo clear
eststo: reg avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med
eststo: reg avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/enrollment.tex", replace label title("Average Total Enrollment") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Landuse
eststo clear
eststo: reg landuse_sfr samp_dest above_x_med samp_destXabove_x_med
eststo: reg landuse_sfr samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg landuse_apartment samp_dest above_x_med samp_destXabove_x_med
eststo: reg landuse_apartment samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/landuse.tex", replace label title("Land Use") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Police
eststo clear
eststo: reg pct_exp_pol samp_dest above_x_med samp_destXabove_x_med
eststo: reg pct_exp_pol samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg pc_pol samp_dest above_x_med samp_destXabove_x_med
eststo: reg pc_pol samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg pct_rev_ff samp_dest above_x_med samp_destXabove_x_med
eststo: reg pct_rev_ff samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/police_expenditure.tex", replace label title("Police Expenditure") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// Transit
eststo clear
eststo: reg alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med
eststo: reg alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/transit_performance.tex", replace label title("Transit Performance") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2

// White AP access
eststo clear
eststo: reg wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med
eststo: reg wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/white_ap_access.tex", replace label title("White AP Access") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2
	

// White AP access
eststo clear
eststo: reg min_hausdorff_muni samp_dest above_x_med samp_destXabove_x_med
eststo: reg min_hausdorff_muni samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg pmax_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med
eststo: reg pmax_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med if main_city == 0
eststo: reg psum_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med
eststo: reg psum_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med if main_city == 0
esttab using "$TABS/implications/muni_dist_similarity.tex", replace label title("Muni Dist Similarity") ///
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
eststo: reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/prop_white_full.tex", replace label title("Proportion White 1970") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Document their schools are whiter
eststo clear
eststo: reghdfe prop_white_students samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe prop_white_students samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/prop_white_students_full.tex", replace label title("Proportion White Students") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// One/no school
eststo clear
eststo: reghdfe one_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe one_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe no_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe no_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/school_presence_full.tex", replace label title("School Presence") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Exclusive district
eststo clear
eststo: reghdfe exclusive_district_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if schoolflag == 1 [aw = weight_pop], vce(cl cz)
eststo: reghdfe exclusive_district_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if schoolflag == 1 &  main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/exclusive_district_full.tex", replace label title("Exclusive District") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)
// Exclusive district, shape
eststo clear
eststo: reghdfe exclusive_district_shape samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if schoolflag == 1 [aw = weight_pop], vce(cl cz)
eststo: reghdfe exclusive_district_shape samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if schoolflag == 1 & main_city == 0 [aw = weight_pop], vce(cl cz)

esttab using "$TABS/implications/exclusive_district_shape_full.tex", replace label title("Exclusive District (by Overlap)") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)
// Land
eststo clear
eststo: reghdfe place_land samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe place_land samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)

esttab using "$TABS/implications/land_full.tex", replace label title("Land Area") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)
	// Land no main city
eststo clear
eststo: reghdfe place_land samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe place_land samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 & main_city == 0 [aw = weight_pop], vce(cl cz)

esttab using "$TABS/implications/land_nomain_full.tex", replace label title("Land Area") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)
// Enrollment
eststo clear
eststo: reghdfe avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if schoolflag == 1 [aw = weight_pop], vce(cl cz)
eststo: reghdfe avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 & schoolflag==1 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/enrollment_full.tex", replace label title("Average Total Enrollment") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Landuse
eststo clear
eststo: reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/landuse_full.tex", replace label title("Land Use") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Police
eststo clear
eststo: reghdfe pct_exp_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pct_exp_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe pc_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pc_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/police_expenditure_full.tex", replace label title("Police Expenditure") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// Transit
eststo clear
eststo: reghdfe alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/transit_performance_full.tex", replace label title("Transit Performance") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// White AP Access
eststo clear
eststo: reghdfe wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/white_ap_access_full.tex", replace label title("White AP Access") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)
	
// Muni Dist Similarity
eststo clear
eststo: reghdfe min_hausdorff_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe min_hausdorff_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe pmax_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe pmax_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
eststo: reghdfe psum_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz)
eststo: reghdfe psum_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
esttab using "$TABS/implications/muni_dist_similarity_full.tex", replace label title("Muni-Dist Similarity") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(samp_dest above_x_med samp_destXabove_x_med)

// CZ Level stuff

use "$CLEANDATA/mechanisms.dta", clear
keep cz GM_raw_pp GM_hat_raw coastal transpo_cost_1920 v2_sumshares_urban popc1940 ap_gini_cz above_x_med vr_blwt_cz vr_blwtas_cz avg_alltransit_cz vr_bl_cz diss_bl_cz diss_blwt_cz diss_blwtas_cz dist_max_int_cz EI mean_pmax_* mean_psum_* mean_min_* 
duplicates drop


merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(3) keepusing(cz_name reg2 reg3 reg4 frac_unc* frac_uninc* change_frac_unc n_schdist_ind_cz) nogen // Need to get right regions...
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
eststo: ivreg2 vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 vr_blwtas_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 vr_bl_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 diss_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 diss_blwtas_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 diss_bl_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
esttab using "$TABS/implications/full_main_spec_1.tex", replace label title("Full Main Specification - GINI, VR, Dissimilarity") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(GM_raw_pp)

eststo clear
eststo: ivreg2 avg_alltransit_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 change_frac_unc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 frac_uninc1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
eststo: ivreg2 frac_uninc2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
esttab using "$TABS/implications/full_main_spec_2.tex", replace label title("Full Main Specification - Transit Score and Fraction Unincorporated") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(GM_raw_pp)
	
eststo clear
eststo: ivreg2 EI (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 dist_max_int_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban  if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 mean_min_hausdorff_muni (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 mean_min_hausdorff_dist (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r

esttab using "$TABS/implications/full_main_spec_3.tex", replace title("Full Main Specification - Muni-Dist Similarity 1") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(GM_raw_pp)
	
eststo clear
eststo: ivreg2 mean_pmax_shared_boundary_muni (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 mean_pmax_shared_boundary_dist (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 mean_psum_shared_boundary_muni (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
eststo: ivreg2 mean_psum_shared_boundary_dist (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if schoolflag <= 1 [aw = popc1940], r
esttab using "$TABS/implications/full_main_spec_4.tex", replace title("Full Main Specification - Muni-Dist Similarity 1") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 ar2  keep(GM_raw_pp)



use "$CLEANDATA/mechanisms.dta", clear
keep cz GM_raw_pp GM_hat_raw coastal transpo_cost_1920 v2_sumshares_urban popc1940 above_x_med p_ft_salary* fte_*  n* ft* p_ftp_*
drop n_schools n_ap n_ap* ncessch 
duplicates drop
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) keepusing(pop2010 cz_name reg2 reg3 reg4 frac_unc* frac_uninc* change_frac_unc n_schdist_ind_cz n_spdist_cz_pc) nogen // Need to get right regions...

foreach i in Total Education Fire HCD_Welfare Health Libraries Other Parks Police State Streets Transit Utilities {
	forv l=1/5{
		g ftratio`i'`l' = ft`i'`l'/fte`i'`l'
	}
	
	
	foreach j in ftp ft ftratio ft_salary{
		egen d1 = rowtotal(`j'`i'1 `j'`i'2 `j'`i'3 `j'`i'4 `j'`i'5)
		egen d2 = rowtotal(`j'`i'2 `j'`i'4)
		egen d3 = rowtotal(`j'`i'2 `j'`i'3 `j'`i'4)
		g pr_sd_all`i'`j' = `j'`i'4/d1
		g pr_sd_muni`i'`j' = `j'`i'4/d2
		g pr_sd_mt`i'`j' =  `j'`i'4/d3
		drop d1 d2 d3
	}
	egen d1 = rowmean(ft_salary`i'1 ft_salary`i'2 ft_salary`i'3 ft_salary`i'5)
	g d2 = ft_salary`i'2 
	egen d3 = rowmean(ft_salary`i'2 ft_salary`i'3 )
	g sr_all_`i' = ft_salary`i'4/d1
	g sr_muni_`i' = ft_salary`i'4/d2
	g sr_mt_`i' = ft_salary`i'4/d3
	drop d1 d2 d3

}

ivreg2 n_spdist_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r



ivreg2 pr_sd_muniTotalft_salary (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r // GM effect positive on wages to special district workers relative to municipal workers
ivreg2 pr_sd_muniTotalft (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r // GM effect positive on proportion of employment in special districts over municipalities
ivreg2 pr_sd_allTotalftp (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r // GM effect positive on proportion of payroll spending in special districts over municipalities
ivreg2 pr_sd_allTotalftratio (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r // GM effect negative on proportion of payroll spending in special districts over municipalities




// Proportion Specialdistrict spending, employment, salary difference
use "$CLEANDATA/mechanisms.dta", clear
keep cz GM_raw_pp GM_hat_raw coastal transpo_cost_1920 v2_sumshares_urban popc1940 above_x_med p_ft_salary* fte_*  n* ft* p_ftp_*
drop n_schools n_ap n_ap* ncessch p_ft_salary* fte* p_ftp*
ren ft_salary* p_ft_salary_*
ren ftp* p_ftp_*
duplicates drop

reshape long ftTotal nTotal p_ft_salary_Total p_ftp_Total ftEducation ftFire ftHCD_Welfare ftHealth ftLibraries ftOther ftParks ftPolice ftState ftStreets ftTransit ftUtilities nEducation nFire nHCD_Welfare nHealth nLibraries nOther nParks nPolice nState nStreets nTransit nUtilities p_ft_salary_Education p_ft_salary_Fire p_ft_salary_HCD_Welfare p_ft_salary_Health p_ft_salary_Libraries p_ft_salary_Other p_ft_salary_Parks p_ft_salary_Police p_ft_salary_State p_ft_salary_Streets p_ft_salary_Transit p_ft_salary_Utilities p_ftp_Education p_ftp_Fire p_ftp_HCD_Welfare p_ftp_Health p_ftp_Libraries p_ftp_Other p_ftp_Parks p_ftp_Police p_ftp_State p_ftp_Streets p_ftp_Transit p_ftp_Utilities, i(cz) j(govttype)

merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) keepusing(pop2010 cz_name reg2 reg3 reg4 frac_unc* frac_uninc* change_frac_unc n_schdist_ind_cz) nogen // Need to get right regions...


g schoolflag = n_schdist_ind_cz < .
drop n_schdist_ind_cz  
foreach var of varlist n* {
	g pc_`var' = 10000*`var'/pop2010
}
ren pc_n* pc*
foreach var of varlist ft* {
	replace `var' = 10000*`var'/pop2010
}
ren p_ft_salary_* salary_*
foreach var of varlist p_ftp* {
	replace `var' = `var'/pop2010
}
keep above_x_med n* pc* cz p_ftp_* salary_* ft* govttype

reshape long pc n p_ftp_ salary_ ft, i(cz govttype) j(type) string
replace type = "Housing and Welfare" if type == "HCD_Welfare"

g spdist = govttype == 4
drop if govttype == 5
drop if type == "Education"
collapse (sum) ft p_ftp_ pc n (mean) salary_, by(cz type spdist above_x_med)

forv sp=0/1{
	if `sp' == 1 local govt "Special Districts"
	if `sp' == 0 local govt "Other Local Governments"
	foreach v in ft p_ftp_ pc salary_{
		if "`v'"=="ft" local ylab "Full Time Employees per 10,000"
		if "`v'"=="p_ftp_" local ylab "Total Full-Time Payrolls per 10,000"
		if "`v'"=="pc" local ylab "Number of Governments per 10,000"
		if "`v'"=="salary_" local ylab "Average Salary"
	
		su `v' if spdist == `sp' & above_x_med == 0 & type == "Total"
		local belowtotal = r(mean)
		su `v' if spdist == `sp' & above_x_med == 1 & type == "Total"
		local abovetotal = r(mean)

		graph bar `v' if spdist == `sp' & type != "Total", ///
			over(above_x_med, relabel(1 "Below Median" 2 "Above Median")) ///
			over(type, label(angle(45) labsize(small))) ///
			asyvars ///
			bar(1, color(blue%50)) bar(2, color(red%50)) ///
			ytitle("`ylab'") ///
			title("`govt'") ///
			note("Above total mean: `abovetotal', below total mean: `belowtotal'") ///
			legend(rows(1)) ///
			blabel(bar, format(%9.2f) size(vsmall) angle(45) position(outside)) ///
			ylabel(, angle(45))
		graph export "$FIGS/implications/spdist_emp_`v'_`sp'.pdf", as(pdf) replace
		
	}
} 



use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | leaid == .
bys leaid : egen n_hs = total(school_level == 3)
g hs_enroll = totenroll if school_level == 3
bys leaid : egen hs_totenroll = total(hs_enroll)
drop hs_enroll
drop if n_hs == 0
replace n_ap = . if school_level != 3
bys leaid : egen mean_ap = mean(n_ap)

keep leaid cz hs_totenroll above_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban mean_ap dist_int_4070
foreach var of varlist above_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban{
	g `var'_dist_int_4070 = `var' * dist_int_4070
}
duplicates drop
reghdfe mean_ap dist_int_4070 above_x_med above_x_med_dist_int_4070 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_dist_int_4070 [aw = hs_totenroll], vce(cl cz)
