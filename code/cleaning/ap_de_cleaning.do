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

use "$INTDATA/nces/school_offerings.dta", replace 

// Sample selection
merge m:1 ncessch using "$INTDATA/nces/school_ccd_directory", keep(3) nogen keepusing(school_type school_level school_status charter magnet virtual teachers_fte enrollment)
keep if school_level == 1 | school_level == 2 | school_level == 3 // High schools only
keep if school_type == 1 // Normal Schools
keep if school_status == 1 // Open schools 
drop if charter == 1
//drop if magnet == 1
drop if virtual == 1

// Student teacher ratio
replace enrollment = . if enrollment == 0
replace teachers_fte = . if teachers_fte == 0
g st_ratio = enrollment/teachers_fte 

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
	keep pct_white crdc_id totenrol blenroll wtenroll wtasenroll
	tempfile race
	save `race'
restore


merge 1:1 crdc_id using `race', keep(3) nogen

bys STATEFP PLACEFP : egen ap_mean = mean(ap)
bys STATEFP PLACEFP : egen de_mean = mean(de)

bys STATEFP PLACEFP : egen n_ap_mean = mean(n_ap)
bys STATEFP PLACEFP : egen n_ap_var = sd(n_ap)

bys STATEFP PLACEFP : egen place_enroll = total(enrollment)
bys STATEFP PLACEFP : egen place_teachers = total(teachers_fte)
g st_ratio_mean = place_enroll / place_teachers

g n_ap_w75 = n_ap if pct_white >=0.75

replace n_ap_var = n_ap_var * n_ap_var
replace n_ap_var = n_ap_var * n_ap_var

save "$INTDATA/nces/offerings", replace

keep STATEFP PLACEFP ap_mean de_mean n_ap_mean n_ap_var  st_ratio_mean 
duplicates drop

save "$INTDATA/nces/place_offerings", replace