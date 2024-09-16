//educationdata using "school crdc directory", sub(year=2017) clear
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

use "$INTDATA/nces/school_offerings.dta", replace 

// Sample selection
merge m:1 ncessch using "$INTDATA/nces/school_ccd_directory", keep(3) nogen keepusing( free_or_reduced_price_lunch school_type school_level school_status charter magnet virtual teachers_fte enrollment)
keep if school_level == 1 | school_level == 2 | school_level == 3 // All Schools
keep if school_type == 1 // Normal Schools
keep if school_status == 1 // Open schools 
drop if charter == 1
//drop if magnet == 1
drop if virtual == 1


// Creating number of ap courses with zeros
g n_ap = num_courses_ap if ap_courses_indicator == 1
replace n_ap = 0 if ap_courses_indicator == 0
replace n_ap = . if ap_courses_indicator < 0

// Dropping clear errors (there were only 38 AP courses in 2017)
replace n_ap = . if n_ap > 38

g ap = ap_courses_indicator if ap_courses_indicator >= 0

// Gifted Talented
g gt = gifted_talented_indicator if gifted_talented_indicator>=0

// Dual Enrollment
g de = sch_dual_indicator if sch_dual_indicator >= 0

destring leaid, replace
merge m:1 year leaid using "$XWALKS/leaid_county_xwalk", keep(1 3) nogen
ren county_code cty_fips
//merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
//merge m:1 leaid using "$XWALKS/leaid_place_xwalk", keep(1 3) nogen
merge m:1 ncessch using "$XWALKS/ncessch_place_xwalk", keep(1 3) nogen keepusing(PLACEFP STATEFP)

preserve 
	use "$INTDATA/nces/school_race.dta", clear 
	keep if sex == 99 & disability == 99 & lep == 99
	keep if inlist(race,99,1,2,4)
	keep crdc_id race enrollment_crdc
	reshape wide enrollment_crdc, i(crdc_id) j(race)
	g pct_white = enrollment_crdc1/enrollment_crdc99
	ren enrollment_crdc99 totenroll
	ren enrollment_crdc1 wtenroll
	ren enrollment_crdc2 blenroll
	ren enrollment_crdc4 asenroll
	egen wtasenroll = rowtotal(wtenroll asenroll)
	keep pct_white crdc_id totenroll blenroll wtenroll wtasenroll
	tempfile race
	save `race'
restore

merge 1:1 crdc_id using `race', keep(3) nogen

preserve
	use "$INTDATA/nces/school_district_edfacts_race", clear
	keep if race == 1 | race == 2
	replace math_test_pct_prof_midpt = . if math_test_pct_prof_midpt<0
	replace read_test_pct_prof_midpt = . if read_test_pct_prof_midpt<0

	bys leaid (race) : g bw_gap_math_raw = math_test_pct_prof_midpt - math_test_pct_prof_midpt[_n + 1] if race == 1
	bys leaid (race) : g bw_gap_math_pct = (math_test_pct_prof_midpt - math_test_pct_prof_midpt[_n + 1])/math_test_pct_prof_midpt if race == 1
	bys leaid (race) : g bw_gap_read_raw = read_test_pct_prof_midpt - read_test_pct_prof_midpt[_n + 1] if race == 1
	bys leaid (race) : g bw_gap_read_pct = (read_test_pct_prof_midpt - read_test_pct_prof_midpt[_n + 1])/read_test_pct_prof_midpt if race == 1
	foreach var of varlist bw_gap_*{
		bys leaid (race) : replace `var' = `var'[1]
	}
	
	destring leaid, replace
	keep leaid bw_gap_*
	duplicates drop
	tempfile test_scores
	save `test_scores'
restore

merge m:1 leaid using `test_scores', keep(1 3)
g math_flag = _merge == 3 & mi(bw_gap_math_raw)
g read_flag = _merge == 3 & mi(bw_gap_read_raw)
drop _merge

preserve
	use "$INTDATA/nces/school_district_edfacts_race", clear
	keep if race == 99 & sex == 99 & lep == 99 & homeless == 99 & migrant == 99 & disability == 99 & econ_disadvantaged ==99 & foster_care ==99 & military_connected==99 
	replace math_test_pct_prof_midpt = . if math_test_pct_prof_midpt<0
	replace read_test_pct_prof_midpt = . if read_test_pct_prof_midpt<0

	
	destring leaid, replace
	keep leaid math_test_pct_prof_midpt read_test_pct_prof_midpt
	duplicates drop
	tempfile test_scores
	save `test_scores'
restore

merge m:1 leaid using `test_scores', keep(1 3) nogen

preserve
	use "$INTDATA/nces/school_district_edfacts_grad", clear
	keep if race == 1 | race == 2
	replace grad_rate_midpt = . if grad_rate_midpt<0

	bys leaid (race) : g bw_gap_grad_raw = grad_rate_midpt - grad_rate_midpt[_n + 1] if race == 1
	bys leaid (race) : g bw_gap_grad_pct = (grad_rate_midpt - grad_rate_midpt[_n + 1])/grad_rate_midpt if race == 1
	
	foreach var of varlist bw_gap_*{
		bys leaid (race) : replace `var' = `var'[1]
	}
	destring leaid, replace
	keep leaid bw_gap_*
	duplicates drop
	tempfile grad
	save `grad'
restore

merge m:1 leaid using `grad', keep(1 3) nogen

preserve
	use "$INTDATA/nces/school_district_finance", clear
	keep if year == 2000 
	drop if leaid == "-1"
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
	
	keep leaid p_capex_exp rev_state_outlay_capital_debt p_rev_local p_state_capex_rev p_state_capex_capex outlay_capital_total debt_interest rev_local_*_tax rev_local_total p_*_tax
	drop if leaid == "20D0631" // Non numeric leaid, not sure why it's here but it isn't in other data
	destring leaid, replace
	tempfile finance
	save `finance'
restore 

merge m:1 leaid using `finance', keep(1 3) nogen

// Student teacher ratio
replace teachers_fte = . if teachers_fte == 0
g st_ratio = totenroll/teachers_fte 

bys STATEFP PLACEFP : egen ap_mean = mean(ap)
bys STATEFP PLACEFP : egen de_mean = mean(de)

bys STATEFP PLACEFP : egen n_ap_mean = mean(n_ap)
bys STATEFP PLACEFP : egen n_ap_var = sd(n_ap)

bys STATEFP PLACEFP : egen place_enroll = total(totenroll)
bys STATEFP PLACEFP : egen place_teachers = total(teachers_fte)
g st_ratio_mean = place_enroll / place_teachers

g n_ap_w75 = n_ap if pct_white >=0.75

replace n_ap_var = n_ap_var * n_ap_var
replace n_ap_var = n_ap_var * n_ap_var

save "$INTDATA/nces/offerings", replace
preserve

	keep STATEFP PLACEFP ap_mean de_mean n_ap_mean n_ap_var  st_ratio_mean 
	duplicates drop

	save "$INTDATA/nces/place_offerings", replace
restore

collapse (mean) math_test_pct_prof_midpt read_test_pct_prof_midpt rev_local_*_tax rev_local_total debt_interest outlay_capital_total rev_state_outlay_capital_debt p_*  bw_gap_* (sum) free_or_reduced_price_lunch teachers_fte wtenroll totenroll, by(leaid)

foreach var of varlist rev_state_outlay_capital_debt outlay_capital_total debt_interest rev_local_*_tax rev_local_total{
	g pe_`var' = `var'/ totenroll
}

g st_ratio_leaid = totenroll/teachers_fte
g pct_white_leaid = wtenroll/totenroll
g pct_free_red_lunch_leaid = free_or_reduced_price_lunch/ totenroll
ren totenroll totenroll_leaid  
drop free_or_reduced_price_lunch wtenroll

save "$INTDATA/nces/leaid_offerings", replace