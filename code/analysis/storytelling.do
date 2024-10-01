use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)
//g one_school = n_schools == 1
//g no_school = n_schools == 0
//g prop_white_students = wtenroll_place / totenroll_place
drop mean_p*


bys cz : egen mean_pmax_shared_muni = mean(pmax_shared_boundary_muni)
bys cz : egen mean_pmax_shared_dist = mean(pmax_shared_boundary_dist)

bys cz : egen mean_psum_shared_muni = mean(psum_shared_boundary_muni)
bys cz : egen mean_psum_shared_dist = mean(psum_shared_boundary_dist)

  

drop wtasenroll totenroll blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname

duplicates drop
g placegroup = .
replace placegroup = 1 if samp_dest == 1
replace placegroup = 2 if samp_dest == 0
replace placegroup = 3 if main_city == 1

replace prop_white1970 = 100* prop_white1970
replace prop_white2010 = 100* prop_white2010

preserve
	keep agg_fam_inc_cz1970 agg_house_value_cz1970 mean_hh_inc_cz cz_prop_white1970 cz_prop_white2010 cz above_x_med popc1940 pop1940
	duplicates drop
	ren agg_fam_inc_cz1970 agg_fam_inc_place1970
	ren agg_house_value_cz1970 agg_house_value_place1970
	ren mean_hh_inc_cz mean_hh_inc_place 
	ren cz_prop_white1970 prop_white1970 
	ren cz_prop_white2010 prop_white2010
	g GEOID = -cz
	drop cz 
	g placegroup = 4
	g weight_pop = pop1940
	tempfile czs
	save `czs'
restore

append using `czs'

lab var agg_fam_inc_place1970 "HH Income, 1970"
lab var agg_house_value_place1970 "Home Value, 1970"
lab var mean_hh_inc_place "HH Income, 2010"
lab var prop_white1970 "Pct White, 1970"
lab var prop_white2010 "Pct White, 2010"



eststo clear
bysort placegroup : eststo : estpost summarize  agg_fam_inc_place1970 agg_house_value_place1970 mean_hh_inc_place prop_white1970 prop_white2010 if above_x_med == 0 [aw=weight_pop], listwise


esttab using "$TABS/implications/richer_whiter.tex", cells("mean(fmt(0 2)) sd(fmt(0 2))") replace nonum booktabs ///
		prehead("\begin{tabular}{l*{10}{c}} \toprule" ///
		"&\multicolumn{8}{l}{Panel A: Below Median GM CZs}\\" "\cmidrule(lr){1-9}" ///
		"&\multicolumn{2}{c}{1940-70 Incorporations}&\multicolumn{2}{c}{All other munis}&\multicolumn{2}{c}{Principle Cities}&\multicolumn{2}{c}{CZ Average}\\ \cmidrule(lr){2-3}  \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" ) ///
		substitute("\_" "_") frag label  noobs
		
	

eststo clear

bysort placegroup : eststo : quietly estpost summarize  agg_fam_inc_place1970 agg_house_value_place1970 mean_hh_inc_place prop_white1970 prop_white2010 if above_x_med == 1


esttab using "$TABS/implications/richer_whiter.tex", cells("mean(fmt(0 2)) sd(fmt(0 2))") booktabs ///
		prehead(" \toprule" ///
		"&\multicolumn{8}{l}{Panel B: Above Median GM CZs}\\" "\cmidrule(lr){1-9}" ///
		"&\multicolumn{2}{c}{1940-70 Incorporations}&\multicolumn{2}{c}{All other munis}&\multicolumn{2}{c}{Principle Cities}&\multicolumn{2}{c}{CZ Average}\\ \cmidrule(lr){2-3}  \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" ) ///
		substitute("\_" "_") frag label nonum noobs append
eststo clear
	
bysort placegroup : eststo : quietly estpost summarize  agg_fam_inc_place1970 agg_house_value_place1970 mean_hh_inc_place prop_white1970 prop_white2010 

esttab using "$TABS/implications/richer_whiter.tex", cells("mean(fmt(0 2)) sd(fmt(0 2))") booktabs ///
		prehead("\toprule" ///
		"&\multicolumn{8}{l}{Panel C: All CZs}\\" "\cmidrule(lr){1-9}" ///
		"&\multicolumn{2}{c}{1940-70 Incorporations}&\multicolumn{2}{c}{All other munis}&\multicolumn{2}{c}{Principle Cities}&\multicolumn{2}{c}{CZ Average}\\ \cmidrule(lr){2-3}  \cmidrule(lr){4-5} \cmidrule(lr){6-7} \cmidrule(lr){8-9}" ) ///
		substitute("\_" "_") frag label nonum append noobs ///
		 postfoot(\midrule \bottomrule \end{tabular})

drop if placegroup == 4

// Pure muni level regs
// Raw splits


replace len_edge_edge = len_edge_edge / 1610 // Miles


twoway (hist len_edge_edge if samp_dest == 1 & above_x_med == 1, start(0) width(10) col(red%30) freq) ///
(hist len_edge_edge if samp_dest == 1 & above_x_med == 0, col(blue%30) start(0) width(10) freq), legend(order(1 "Above Median GM" 2 "Below Median GM")) 

graph export "$FIGS/implications/dist_edge_edge_4070.pdf", as(pdf) replace


su len_edge_edge, d
g below_len_edge = len_edge_edge <r(p50)


eststo clear
eststo: reghdfe touching samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop] if main_city == 0, vce(cl cz) 
eststo: reghdfe below_len_edge samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop] if main_city == 0, vce(cl cz) 
eststo: reghdfe len_edge_edge samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop] if main_city == 0, vce(cl cz) 
esttab using "$TABS/implications/0th_stage_distance_full.tex", replace nolabel title("Raw Splits") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )
	

eststo clear
lab var agg_fam_inc_place1970 "Family Income, 1970"
lab var agg_house_value_place1970 "Home Value, 1970"
lab var mean_hh_inc_place "Household Income, 2010"
lab var prop_white1970 "Prop White, 1970"
lab var prop_white2010 "Prop White, 2010"
lab var place_land "Muni Area"

eststo: reghdfe agg_fam_inc_place1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe agg_house_value_place1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe mean_hh_inc_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe prop_white2010 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe place_pop1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe place_land samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz) 

esttab using "$TABS/implications/0th_stage_economic_full.tex", replace label title("Economic Characteristics") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )
	
lab var exclusive_district_place "Exclusive District Address"
lab var exclusive_district_shape "Exclusive District Shape"
lab var psum_shared_boundary_muni "Prop boundary shared"
lab var min_hausdorff_muni "Min Hausdorff distance"
eststo clear
eststo: reghdfe exclusive_district_place samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe exclusive_district_shape samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe psum_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe min_hausdorff_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/school_exclusivity_full.tex", replace nolabel title("Muni-District similarity") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )


eststo clear
eststo: reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe pct_rev_sa  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe pct_rev_debt  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/muni_exclusivity_full.tex", replace nolabel title("Raw Splits") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )

	


	
	
// Building table
lab var mixed_use "Allows Mixed Use"
lab var attached_sfr "Allows attached SFH"
lab var adu "Allows ADUs"
lab var flex_zoning_br "Allows flex zoning by right"
lab var min_lot_size_mean "Average min lot size"
lab var min_lot_size_max "Max min lot size"

eststo clear
eststo: reghdfe mixed_use samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe attached_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe adu  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe flex_zoning_br  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe min_lot_size_mean  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe min_lot_size_max  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/ai_zoning_density.tex", replace label title("AI Zoning - Density") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )

	

lab var inclusionary_zoning "Inclusionary Zoning"
lab var permit_cap_phasing "Permit caps"
lab var n_approving_agencies "Number of agencies"
lab var mf_public_hearing "Public hearings for MF"
lab var max_review_days "Max review days"

eststo clear
eststo: reghdfe inclusionary_zoning samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe permit_cap_phasing samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe n_approving_agencies  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest [aw = weight_pop], vce(cl cz) 
eststo: reghdfe mf_public_hearing  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe max_review_days  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/ai_zoning_regs.tex", replace label title("AI Zoning - Regulations") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )

	
eststo clear


preserve 
	keep  GM_raw_pp GM_hat_raw v2_sumshares_urban coastal transpo_cost_1920 schoolflag popc1940 mean_min_hausdorff_muni EI mean_dist_max_int mean_psum_shared_muni mean_psum_shared_dist cz mean_pmax_shared_muni mean_pmax_shared_dist vr_*_cz diss_*_cz ap_gini_cz
	duplicates drop
	merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(reg2 reg3 reg4)
	lab var EI "Equivalence Index"
	lab var mean_dist_max_int "Largest District Overlap"
	lab var mean_min_hausdorff_muni "Average Hausdorff Distance"
	lab var mean_psum_shared_muni "Average p(muni-dist shared border)"
	eststo : ivreg2 EI (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940] if schoolflag == 1, r
	eststo : ivreg2 mean_dist_max_int (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940] if schoolflag == 1, r
	eststo : ivreg2 mean_min_hausdorff_muni (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940] if schoolflag == 1, r
	eststo : ivreg2 mean_psum_shared_muni (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940] if schoolflag == 1, r

	esttab using "$TABS/implications/school_exclusivity_cz.tex", replace nolabel title("Muni-District similarity, CZ level") ///
		star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep(GM_raw_pp )
	eststo clear
	merge 1:1 cz using "$INTDATA/cz_segregation_vars", keep(3) nogen
	lab var vr_blwt_cz "B/W variance ratio"
	lab var diss_blwt_cz "B/W dissimilarity ratio"
	lab var SP_nexpd_1970 "B/W spatial proximity "
	lab var rco1970 "B/W relative concentration"

	eststo : ivreg2 vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940] if schoolflag == 1, r
	eststo : ivreg2 diss_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940] if schoolflag == 1, r
	eststo : ivreg2 SP_nexpd_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	eststo : ivreg2 rco1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	
	esttab using "$TABS/implications/cz_segregation.tex", replace nolabel title("CZ Segregation") ///
		star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep(GM_raw_pp )
	
restore

// School level stuff
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | leaid == . | schoolflag == 0
//bys leaid : egen n_hs = total(school_level == 3)
//g hs_enroll = totenroll if school_level == 3
//bys leaid : egen hs_totenroll = total(hs_enroll)
//drop hs_enroll

//replace n_ap = . if school_level != 3
//bys leaid : egen mean_ap = mean(n_ap)

replace dist_int_4070 = 0 if mi(dist_int_4070)
g int_0 = dist_int_4070 

keep leaid cz  above_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban  int_0    pct_white_leaid   p_*_rev p_*_capex p_rev_local p_*_tax p_*_exp pe_* rev_state_outlay_capital_debt rev_state_outlay_capital_debt outlay_capital_total totenroll_leaid  cs_mn* blenroll_leaid wtenroll_leaid
foreach var of varlist above_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban{
	g `var'_int_0 = `var' * int_0
}
drop pe_outlay_capital_total
g pe_outlay_capital_total = outlay_capital_total / totenroll_leaid
g log_outlay_capital_total = log(outlay_capital_total)
g log_pe_capex = log(outlay_capital_total/totenroll_leaid)
ren p_capex_exp p_outlay_capital_total

lab var log_outlay_capital_total "Log Capital Outlays"
lab var p_outlay_capital_total "Capital outlays/Total Expenditure"
lab var pe_outlay_capital_total "Capital outlays/Total Enrollment"
lab var log_pe_capex "log(Capital outlays/Total Enrollment)"

lab var int_0 "Prop Border with 40-70 incorporation"
lab var above_x_med_int_0 "Prop Border 40-70 X Above Median GM"
bys leaid (cz) : keep if _n == 1
eststo clear
// gap between economically advantaged and disadvantaged shrinks because advantaged goes down and disadvantaged stays the same
reghdfe cs_mn_avg_ol_neg int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz) 
reghdfe cs_mn_avg_ol_nec int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz) 
reghdfe cs_mn_avg_ol_ecd int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz) 

// Slightly lower overall test scores
reghdfe cs_mn_avg_ol_wbg int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz) 

//eststo: reghdfe math_test_pct_prof_midpt int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 if n_hs > 0 [aw = hs_totenroll], vce(cl cz)
//eststo: reghdfe read_test_pct_prof_midpt int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 if n_hs > 0 [aw = hs_totenroll], vce(cl cz)

eststo: reghdfe mean_ap int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 if n_hs > 0 [aw = hs_totenroll], vce(cl cz)
eststo: reghdfe totenroll int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll], vce(cl cz)
eststo: reghdfe st_ratio_leaid int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban  *_int_0 [aw = totenroll], vce(cl cz)
eststo: reghdfe pct_white_leaid int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll], vce(cl cz)
eststo: reghdfe pct_free_red_lunch_leaid int_0 above_x_med above_x_med_int_0 reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll], vce(cl cz)

esttab using "$TABS/implications/school_level.tex", replace nolabel title("School District Amenities") ///
		star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep(int_0 above_x_med above_x_med_int_0 )
	
eststo clear

eststo: reghdfe p_outlay_capital_total int_0 above_x_med  reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz)

eststo: reghdfe pe_outlay_capital_total int_0 above_x_med  reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban  *_int_0 [aw = totenroll_leaid], vce(cl cz)

eststo: reghdfe log_outlay_capital_total int_0 above_x_med  reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz)
eststo: reghdfe log_pe_capex int_0 above_x_med  reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_int_0 [aw = totenroll_leaid], vce(cl cz)

esttab using "$TABS/implications/school_capex.tex", replace label title("School District Capital Expenditure") ///
		star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep(int_0 above_x_med above_x_med_int_0 ) 
	
	
	
	
keep if n_hs > 0
collapse (mean) bw_gap_* [aw = hs_totenroll], by(cz)
merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(GM_hat_raw GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban popc1940 coastal transpo_cost_1920)
eststo clear
eststo: ivreg2 bw_gap_math_raw (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
eststo: ivreg2 bw_gap_math_pct (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
eststo: ivreg2 bw_gap_read_raw  (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
eststo: ivreg2 bw_gap_read_pct (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
eststo: ivreg2 bw_gap_grad_raw  (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
eststo: ivreg2 bw_gap_grad_pct  (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
esttab using "$TABS/implications/achievement_gaps.tex", replace nolabel title("School District Achievement") ///
		star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep(GM_raw_pp )
	
	
	// New achievement
	use "$CLEANDATA/cz_pooled", clear
	
	merge 1:1 cz using "$INTDATA/nces/cz_acheivement", keep(3) nogen
	lab var n_schdist_ind_cz_pc "New Ind. Sch. Dists., P.C. (total)"

	ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	predict muni_e, resid
	ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	predict schdist_ind_e if e(sample), resid
	
	eststo clear
	foreach t in all wht blk wbg ecd nec neg{
		eststo `t'_iv: ivreg2 cs_mn_avg_ol_`t' (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r

		eststo `t'_ols_muni: reg cs_mn_avg_ol_`t' n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
		eststo `t'_ts_muni: reg cs_mn_avg_ol_`t' n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 muni_e [aw = popc1940], r
		su cs_mn_avg_ol_`t' if e(sample),
		estadd scalar avg_muni = r(mean)
		eststo `t'_ols_schdist: reg cs_mn_avg_ol_`t' n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
		eststo `t'_ts_schdist: reg cs_mn_avg_ol_`t' n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 schdist_ind_e [aw = popc1940], r
		su cs_mn_avg_ol_`t' if e(sample),
		estadd scalar avg_schdist = r(mean)
	}
	
	
	esttab all_iv wht_iv blk_iv wbg_iv nec_iv ecd_iv neg_iv      ///
		using "$TABS/implications/achievement_gaps.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		posthead("&\multicolumn{1}{c}{All}&\multicolumn{1}{c}{White}&\multicolumn{1}{c}{Black}&\multicolumn{1}{c}{W-B Gap}&\multicolumn{1}{c}{Not Ec. Disadvantaged}&\multicolumn{1}{c}{Ec. Disadvantaged}&\multicolumn{1}{c}{NEC-ECD Gap}&\\\cmidrule(lr){2-2}\cmidrule(lr){3-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}\cmidrule(lr){7-7}\cmidrule(lr){8-8}" ///
		"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}&\multicolumn{1}{c}{(7)}\\" ///
				"\cmidrule(lr){1-8}" ///
				"\multicolumn{7}{l}{Panel A: IV with GM}\\" "\cmidrule(lr){1-8}" ) ///
		prehead( \begin{tabular}{l*{9}{c}} \toprule) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
	 keep(GM_raw_pp) 
	
	esttab all_ols_muni wht_ols_muni blk_ols_muni wbg_ols_muni nec_ols_muni ecd_ols_muni neg_ols_muni   ///
		using "$TABS/implications/achievement_gaps.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-8}" "\multicolumn{7}{l}{Panel B: OLS with Munis}\\" "\cmidrule(lr){1-8}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(n_gen_muni_cz_pc)
		
	esttab all_ts_muni wht_ts_muni blk_ts_muni wbg_ts_muni nec_ts_muni ecd_ts_muni neg_ts_muni      ///
		using "$TABS/implications/achievement_gaps.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-8}" "\multicolumn{7}{l}{Panel C: Two Step with Munis}\\" "\cmidrule(lr){1-8}" ) 	b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(n_gen_muni_cz_pc) ///
		stats(avg_muni N, labels("Dep. Var Mean" "Observations") fmt(3 0))
		
	esttab all_ols_schdist wht_ols_schdist blk_ols_schdist wbg_ols_schdist nec_ols_schdist ecd_ols_schdist neg_ols_schdist   ///
		using "$TABS/implications/achievement_gaps.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-8}" "\multicolumn{7}{l}{Panel B: OLS with School Districts}\\" "\cmidrule(lr){1-8}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(n_schdist_ind_cz_pc)
		
	esttab all_ts_schdist wht_ts_schdist blk_ts_schdist wbg_ts_schdist nec_ts_schdist ecd_ts_schdist neg_ts_schdist      ///
		using "$TABS/implications/achievement_gaps.tex", se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-8}" "\multicolumn{7}{l}{Panel E: Two Step with School Districts}\\" "\cmidrule(lr){1-8}" ) 	b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(n_schdist_ind_cz_pc) ///
		postfoot(	\bottomrule \end{tabular}) ///
		stats(avg_schdist N, labels("Dep. Var Mean" "Observations") fmt(3 0))


	
	// All test scores
	reg cs_mn_avg_ol_all n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	reg cs_mn_avg_ol_all muni_hat reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	
	reg cs_mn_avg_ol_all n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	reg cs_mn_avg_ol_all schdist_ind_hat reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	
	// Black test scores
	reg cs_mn_avg_ol_neg n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	reg cs_mn_avg_ol_neg muni_hat reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	
	reg cs_mn_avg_ol_neg n_schdist_ind_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	reg cs_mn_avg_ol_neg schdist_ind_hat reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r

	
	
	
	
	
	
	ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
	predict muni_e, resid
	predict muni_hat
	reg cs_mn_avg_ol_neg muni_hat reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw = popc1940], r
		reg cs_mn_avg_ol_neg n_gen_muni_cz_pc reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 muni_e [aw = popc1940], r


	