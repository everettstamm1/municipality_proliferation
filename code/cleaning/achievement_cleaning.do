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

// leaid-county fips xwalk, 2000 definitions

//import delimited "$RAWDATA/nces/school-districts_lea_directory.csv", clear

//drop if county_code < 0 | leaid == . 
//keep leaid county_code fips year

//save "$XWALKS/leaid_county_xwalk.dta", replace

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

collapse (sum) totenroll_leaid blenroll_leaid hsenroll_leaid wtenroll_leaid wtasenroll_leaid teachers_total_fte staff_total_fte number_of_schools, by(super_leaid)
ren super_leaid leaid

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

merge 1:1 leaid using `seda', nogen keep(1 3)

merge m:1 leaid using "$XWALKS/leaid_place_xwalk", keep(1 3) nogen

merge 1:m leaid using "$XWALKS/leaid_county_xwalk", keep(1 3) nogen

// Imputing year closest to 2017
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
ren czone cz

// SD, interquartile range, enrollment of top school districts, diss for achievement, GINI for 

bys cz : egen achievement_var_cz = var(cs_mn_avg_ol_all)
bys cz: egen achievement_iqr = iqr(cs_mn_avg_ol_all)

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


keep cz achievement_iqr achievement_var_cz  
duplicates drop

merge 1:1 cz using `cz_acheivement', keep(1 3) nogen
merge 1:1 cz using `white_achievement', keep(1 3) nogen
merge 1:1 cz using `black_achievement', keep(1 3) nogen

g race_exp = white_exposure - black_exposure
save "$INTDATA/nces/cz_achievement_segregation", replace