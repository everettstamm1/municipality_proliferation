// educationdata using "school crdc directory", sub(year=2017) clear
//save "$INTDATA/nces/school_crdc_directory.dta", replace

// educationdata using "school ccd directory", sub(year=2017) clear
// save "$INTDATA/nces/school_ccd_directory.dta", replace
// export delimited using "$INTDATA/nces/school_ccd_directory.csv", replace

//educationdata using "school crdc offerings", sub(year=2017) clear
//save "$INTDATA/nces/school_offerings.dta", replace 

//educationdata using "school crdc enrollment race sex", sub(year=2017) clear csv
//save "$INTDATA/nces/school_race.dta", replace

//educationdata using "school ccd enrollment race", sub(year=2017) clear csv
//save "$INTDATA/nces/school_race_ccd.dta", replace

//educationdata using "district edfacts assessments race", sub(year=2017 grade_edfacts=9) clear csv
//save "$INTDATA/nces/school_district_edfacts_race.dta", replace

//educationdata using "district edfacts grad-rates", sub(year=2017) clear csv
//save "$INTDATA/nces/school_district_edfacts_grad.dta", replace

//educationdata using "school crdc school-finance", sub(year=2017) clear csv
//save "$INTDATA/nces/school_finance", replace

//educationdata using "district ccd finance", clear csv
//save "$INTDATA/nces/school_district_finance", replace

//educationdata using "district ccd enrollment race", sub(year=2017) clear csv
//save "$INTDATA/nces/district_race_ccd.dta", replace

//educationdata using "district ccd directory", sub(year=2017) clear csv
//save "$INTDATA/nces/district_ccd_directory", replace

use "$INTDATA/nces/district_ccd_directory", clear
keep if agency_type == 2 | agency_type == 3
g super_leaid = leaid if agency_type == 3

bys fips supervisory_union_number (super_leaid) : replace super_leaid = super_leaid[_N]

tempfile super_leaids
save `super_leaids'

use "$INTDATA/nces/district_ccd_directory", clear
//keep if agency_type == 1 // Normal Schools
//keep if agency_level == 1 | agency_level == 2 | agency_level == 3 // All Schools
//drop if agency_charter_indicator == 1

merge 1:1 leaid using `super_leaids', keep(1 3) nogen
replace super_leaid = leaid if mi(super_leaid)

keep staff_total_fte number_of_schools teachers_total_fte enrollment leaid super_leaid

replace staff_total_fte = . if staff_total_fte < 0
replace teachers_total_fte = . if teachers_total_fte < 0
replace number_of_schools = . if number_of_schools<0

preserve 
	use "$INTDATA/nces/district_race_ccd.dta", clear
	keep if sex == 99 & grade == 99

	keep if inlist(race,99,1,2,3,4)
	keep leaid race enrollment
	reshape wide enrollment, i(leaid) j(race)
	ren enrollment99 totenroll_leaid
	ren enrollment1 wtenroll_leaid
	ren enrollment2 blenroll_leaid
	ren enrollment3 hsenroll_leaid
	ren enrollment4 asenroll_leaid
	egen wtasenroll_leaid = rowtotal(wtenroll_leaid asenroll_leaid)
	keep leaid totenroll_leaid blenroll_leaid hsenroll_leaid wtenroll_leaid wtasenroll_leaid
	tempfile race
	save `race'
restore

merge 1:1 leaid using `race', nogen
/*
preserve
	use "$INTDATA/nces/school_district_finance", clear
	keep if year == 2000 
	drop if leaid == "-1"

		replace super_leaid = leaid if mi(super_leaid)

	foreach var of varlist rev_state_outlay_capital_debt rev_local_parent_govt rev_local_total rev_local_prop_tax rev_local_sales_tax rev_local_utility_tax rev_local_income_tax rev_local_other_sch_systems rev_local_cities_counties exp_total rev_nces outlay_capital_total payments_private_schools payments_charter_schools payments_other_sch_system debt_interest rev_total{
		replace `var'  = . if `var'<0
	}
	g p_state_capex_rev = rev_state_outlay_capital_debt / rev_total
	g p_state_capex_capex = rev_state_outlay_capital_debt / (debt_interest + outlay_capital_total)
	g p_rev_local = rev_local_total / rev_total
	foreach i in prop_tax sales_tax utility_tax income_tax other_tax other_sch_systems cities_counties{
		g p_`i' = rev_local_`i' / rev_total
	}
	g p_capex_exp = outlay_capital_total / exp_total
	g p_capex_debt = (outlay_capital_total + debt_interest)/exp_total
	collapse (sum) p_capex_exp rev_state_outlay_capital_debt p_rev_local p_state_capex_rev p_state_capex_capex outlay_capital_total debt_interest rev_local_*_tax rev_local_total p_*_tax, by(leaid)
	drop if leaid == "20D0631" // Non numeric leaid, not sure why it's here but it isn't in other data
	tempfile finance
	save `finance'
restore 

merge 1:1 leaid using `finance',  nogen
*/
collapse (sum) totenroll_leaid blenroll_leaid hsenroll_leaid wtenroll_leaid wtasenroll_leaid teachers_total_fte staff_total_fte number_of_schools, by(super_leaid)
ren super_leaid leaid

// Student teacher ratio XXX try for ccd st_ratio
g pct_white_leaid = wtenroll_leaid/totenroll_leaid
g st_ratio_leaid = totenroll_leaid/teachers_total_fte 
g ss_ratio_leaid = totenroll_leaid/staff_total_fte 
drop staff_total_fte teachers_total_fte
destring leaid, replace

preserve
	use "$RAWDATA/seda/seda_geodist_pool_cs_5.0_updated_20240319.dta", clear
	keep if (subcat=="all" & subgroup == "all") | ///
			(subcat == "race" & subgroup == "wht") | ///
			(subcat == "race" & subgroup == "blk") | ///
			(subcat == "race" & subgroup == "wbg") | ///
			(subcat == "ecd" & subgroup == "ecd") | ///
			(subcat == "ecd" & subgroup == "nec") | ///
			(subcat == "ecd" & subgroup == "neg") // neg the gap nec - ecd (not disadvantaged - disadvantaged)
	keep sedalea subgroup cs_mn_avg_ol cs_mn_avg_eb sedaleaname
	replace subgroup = "_"+subgroup
	reshape wide cs_mn_avg_ol cs_mn_avg_eb, i(sedalea) j(subgroup) string
	ren sedalea leaid

	tempfile seda
	save `seda'
restore

merge 1:1 leaid using `seda', nogen 

merge m:1 leaid using "$XWALKS/leaid_place_xwalk", keep(1 3) nogen

/*
foreach var of varlist rev_state_outlay_capital_debt outlay_capital_total debt_interest rev_local_*_tax rev_local_total{
	g pe_`var' = `var'/ totenroll
}
*/

merge 1:m leaid using "$XWALKS/leaid_county_xwalk", keep(1 3) nogen

forv step=0/30{
	local y = 2017 + `step'
	if `y'< 2020 & `y' != 2017{
		g a`y' = year == `y'
		bys leaid : egen has`y' = max(a`y')
		drop if has`y'==1 & year != `y'
		drop has`y' a`y'
	}
	local y = 2017 - `step'
	g a`y' = year == `y'
	bys leaid : egen has`y' = max(a`y')
	drop if has`y'==1 & year != `y'
	drop has`y' a`y'
	qui duplicates report leaid
	if r(unique_value) == r(N){
		di "`y'"
		continue, break
	}
}
drop year
ren county_code cty_fips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
drop cty_fips
preserve
	keep czone leaid
	duplicates drop
	save "$XWALKS/leaid_cz_xwalk", replace
restore 
ren czone cz_leaid

tostring leaid, replace
replace leaid = "0"+leaid if strlen(leaid) == 6
merge 1:1 leaid using "$INTDATA/nces/leaid_areas", keep(1 3) nogen
destring leaid, replace
ren cz_leaid cz

makeDissimilarity , gen(stu_diss_bl_cz) mingroup(blenroll_leaid) majgroup(totenroll_leaid) id(leaid) agg_id(cz) onegroup

makeDissimilarity , gen(stu_diss_blwt_cz) mingroup(blenroll_leaid) majgroup(wtenroll_leaid) id(leaid) agg_id(cz)

makeVR , gen(stu_vr_bl_cz) mingroup(blenroll_leaid) majgroup(totenroll_leaid) id(leaid) agg_id(cz) onegroup

makeVR , gen(stu_vr_blwt_cz) mingroup(blenroll_leaid) majgroup(wtenroll_leaid) id(leaid) agg_id(cz)

makeRCO, gen(stu_RCO_blwt_cz) mingroup(blenroll_leaid) majgroup(wtenroll_leaid) id(leaid) area(area) agg_id(cz) 
makeAtkinson, gen(stu_A_05_blwt_cz) mingroup(blenroll_leaid) majgroup(wtenroll_leaid) id(leaid) agg_id(cz) b(0.5)

makeAtkinson, gen(stu_A_01_blwt_cz) mingroup(blenroll_leaid) majgroup(wtenroll_leaid) id(leaid) agg_id(cz) b(0.1)

makeAtkinson, gen(stu_A_09_blwt_cz) mingroup(blenroll_leaid) majgroup(wtenroll_leaid) id(leaid) agg_id(cz) b(0.9)




ren leaid GEOID
makeSP, gen(stu_SP_touch_blwt_cz)  mingroup(blenroll_leaid) majgroup(wtenroll_leaid) agg_id(cz) distances("$CLEANDATA/other/touching_dist_schools.dta") id(GEOID)

makeSP, gen(stu_SP_nexpd_blwt_cz)  mingroup(blenroll_leaid) majgroup(wtenroll_leaid) agg_id(cz) distances("$CLEANDATA/other/touching_dist_schools.dta") id(GEOID) nexpd
ren GEOID leaid
ren  cz cz_leaid
// SD, interquartile range, enrollment of top school districts, diss for achievement, GINI for 

bys cz : egen achievement_var_cz = var(cs_mn_avg_ol_all)
bys cz: egen achievement_iqr = iqr(cs_mn_avg_ol_all)

bys cz: egen achievement_p75 = pctile(cs_mn_avg_ol_all), p(75)
bys cz: egen achievement_p90 = pctile(cs_mn_avg_ol_all), p(90)
bys cz: egen achievement_p95 = pctile(cs_mn_avg_ol_all), p(95)
bys cz: egen achievement_top = max(cs_mn_avg_ol_all)

g temp = totenroll_leaid if cs_mn_avg_ol_all >= achievement_p75
bys cz: egen totenroll_p75_cz = mean(temp)
drop temp
g temp = totenroll_leaid if cs_mn_avg_ol_all >= achievement_p90
bys cz: egen totenroll_p90_cz = mean(temp)
drop temp

makeDissimilarity , gen(achievement_diss_blwt_cz) mingroup(cs_mn_avg_ol_blk) majgroup(cs_mn_avg_ol_wht) id(leaid) agg_id(cz)
makeVR , gen(achievement_VR_blwt_cz) mingroup(cs_mn_avg_ol_blk) majgroup(cs_mn_avg_ol_wht) id(leaid) agg_id(cz)

makeDissimilarity , gen(achievement_diss_bl_cz) mingroup(cs_mn_avg_ol_blk) majgroup(cs_mn_avg_ol_all) id(leaid) agg_id(cz) onegroup

//g `num' = leaid_enrollment* abs(leaid_achievement - cz_achievement)
//g `denom' = 2 * cz_enrollment * cz_achievement * (1 - cz_achievement)
save "$INTDATA/nces/leaid_offerings", replace

preserve 
	collapse (mean) cs_mn_* [aw = totenroll_leaid], by(cz)
	tempfile cz_acheivement
	save `cz_acheivement'
restore


preserve 
	collapse (mean) cs_mn_avg_ol_all [aw = blenroll_leaid], by(cz)
	ren cs_mn_avg_ol_all black_exposure
	tempfile black_achievement
	save `black_achievement'
restore

preserve 
	collapse (mean) cs_mn_avg_ol_all [aw = wtenroll_leaid], by(cz)
	ren cs_mn_avg_ol_all white_exposure
	tempfile white_achievement
	save `white_achievement'
restore


preserve 
	collapse (mean) cs_mn_avg_ol_blk [aw = blenroll_leaid], by(cz)
	ren cs_mn_avg_ol_blk bblack_exposure
	tempfile bblack_achievement
	save `bblack_achievement'
restore

preserve 
	collapse (mean) cs_mn_avg_ol_wht [aw = wtenroll_leaid], by(cz)
	ren cs_mn_avg_ol_wht wwhite_exposure
	tempfile wwhite_achievement
	save `wwhite_achievement'
restore

drop if stu_RCO_blwt_cz == .
keep cz stu_* achievement_diss_blwt_cz achievement_VR_blwt_cz totenroll_p90_cz totenroll_p75_cz achievement_iqr achievement_var_cz achievement_diss_bl_cz  
duplicates drop

merge 1:1 cz using `cz_acheivement', keep(1 3) nogen
merge 1:1 cz using `white_achievement', keep(1 3) nogen
merge 1:1 cz using `black_achievement', keep(1 3) nogen
merge 1:1 cz using `wwhite_achievement', keep(1 3) nogen
merge 1:1 cz using `bblack_achievement', keep(1 3) nogen

g race_exp = white_exposure - black_exposure
g race_self_exp = wwhite_exposure - bblack_exposure
ren cz_leaid cz
save "$INTDATA/nces/cz_achievement_segregation", replace