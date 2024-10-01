use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1
g one_school = n_schools == 1
g no_school = n_schools == 0
g prop_white_students = wtenroll_place / totenroll_place
drop mean_p*

foreach var of varlist pmax_shared_boundary_muni pmax_shared_boundary_dist psum_shared_boundary_muni psum_shared_boundary_dist EI mean_dist_max_int{
	//replace `var' = . if main_city == 1
}


bys cz : egen mean_pmax_shared_muni = mean(pmax_shared_boundary_muni)
bys cz : egen mean_pmax_shared_dist = mean(pmax_shared_boundary_dist)

bys cz : egen mean_psum_shared_muni = mean(psum_shared_boundary_muni)
bys cz : egen mean_psum_shared_dist = mean(psum_shared_boundary_dist)

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot school_level psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid teachers_fte bw_*
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

eststo: reghdfe agg_fam_inc_place1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe agg_house_value_place1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe mean_hh_inc_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe prop_white2010 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe place_pop1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 

esttab using "$TABS/implications/0th_stage_economic_full.tex", replace label title("Economic Characteristics") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )
	
lab var exclusive_district_place "Exclusive District Address"
lab var exclusive_district_shape "Exclusive District Shape"
lab var psum_shared_boundary_muni "Prop boundary shared"
lab var min_hausdorff_muni "Min Hausdorff distance"
eststo clear
eststo: reghdfe exclusive_district_place samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe exclusive_district_shape samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe psum_shared_boundary_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe min_hausdorff_muni samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/school_exclusivity_full.tex", replace nolabel title("Muni-District similarity") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )


eststo clear
eststo: reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med  reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest if main_city == 1 | samp_dest == 1  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1  [aw = weight_pop], vce(cl cz) 
eststo: reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe pct_rev_sa  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe pct_rev_debt  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 


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
eststo: reghdfe mixed_use samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe attached_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe adu  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe flex_zoning_br  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe min_lot_size_mean  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe min_lot_size_max  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/ai_zoning_density.tex", replace label title("AI Zoning - Density") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )

	

lab var inclusionary_zoning "Inclusionary Zoning"
lab var permit_cap_phasing "Permit caps"
lab var n_approving_agencies "Number of agencies"
lab var mf_public_hearing "Public hearings for MF"
lab var max_review_days "Max review days"

eststo clear
eststo: reghdfe inclusionary_zoning samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe permit_cap_phasing samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe n_approving_agencies  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920  *_samp_dest if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe mf_public_hearing  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 
eststo: reghdfe max_review_days  samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 *_samp_dest  if main_city == 1 | samp_dest == 1 [aw = weight_pop], vce(cl cz) 


esttab using "$TABS/implications/ai_zoning_regs.tex", replace label title("AI Zoning - Regulations") ///
    star(* 0.10 ** 0.05 *** 0.01) b(3) se(3) r2 keep( samp_dest above_x_med samp_destXabove_x_med )

	
eststo clear


preserve 
	keep  GM_raw_pp GM_hat_raw v2_sumshares_urban coastal transpo_cost_1920 schoolflag popc1940 mean_min_hausdorff_muni EI mean_dist_max_int mean_psum_shared_muni mean_psum_shared_dist cz mean_pmax_shared_muni mean_pmax_shared_dist vr_*_cz diss_*_cz
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
keep if main_city == 1 | samp_dest == 1
bys leaid : egen n_hs = total(school_level == 3)
g hs_enroll = totenroll if school_level == 3
bys leaid : egen hs_totenroll = total(hs_enroll)
drop hs_enroll

replace n_ap = . if school_level != 3
bys leaid : egen mean_ap = mean(n_ap)

replace dist_int_4070 = 0 if mi(dist_int_4070)
g int_0 = dist_int_4070 

keep leaid cz hs_totenroll above_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban mean_ap int_0 totenroll st_ratio_leaid n_hs pct_white_leaid pct_free_red_lunch_leaid bw_* p_*_rev p_*_capex p_rev_local p_*_tax p_*_exp pe_* rev_state_outlay_capital_debt rev_state_outlay_capital_debt outlay_capital_total totenroll_leaid math_test_pct_prof_midpt read_test_pct_prof_midpt
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
	