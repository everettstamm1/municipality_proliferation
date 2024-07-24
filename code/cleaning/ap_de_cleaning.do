//educationdata using "school crdc offerings", sub(year=2017) clear
//save "$INTDATA/nces/school_offerings.dta", replace 

//educationdata using "school crdc enrollment race sex", sub(year=2017) clear csv
//save "$INTDATA/nces/school_race.dta", replace

use "$INTDATA/nces/school_offerings.dta", replace 
// Creating number of ap courses with zeros
g n_ap = num_courses_ap if ap_courses_indicator == 1
replace n_ap = . if ap_courses_indicator <= 0

// Dropping clear errors (there were only 38 AP courses in 2017)
replace n_ap = . if n_ap > 38

g ap = ap_courses_indicator if ap_courses_indicator >= 0

// Gifted Talented
g gt = gifted_talented_indicator if gifted_talented_indicator>=0

// Dual Enrollment
g de = sch_dual_indicator if sch_dual_indicator >= 0

destring leaid, replace
merge m:1 year leaid using "$XWALKS/leaid_county_xwalk", keep(3) nogen
ren county_code cty_fips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
merge m:1 leaid using "$XWALKS/leaid_place_xwalk", keep(1 3) nogen

preserve 
	use "$INTDATA/nces/school_race.dta", replace 
	keep if sex == 99 & disability == 99 & lep == 99
	keep if inlist(race,99,1,2)
	keep crdc_id race enrollment_crdc
	reshape wide enrollment_crdc, i(crdc_id) j(race)
	g pct_white = enrollment_crdc1/enrollment_crdc99
	ren enrollment_crdc99 totenroll
	ren enrollment_crdc1 wtenroll
	ren enrollment_crdc2 blenroll
	keep pct_white crdc_id totenrol blenroll wtenroll
	tempfile race
	save `race'
restore

merge 1:1 crdc_id using `race', keep(3) nogen

bys STATEFP PLACEFP : egen ap_mean = mean(ap)
bys STATEFP PLACEFP : egen de_mean = mean(de)

bys STATEFP PLACEFP : egen n_ap_mean = mean(n_ap)
bys STATEFP PLACEFP : egen n_ap_var = sd(n_ap)

g n_ap_w75 = n_ap if pct_white >=0.75

replace n_ap_var = n_ap_var * n_ap_var

save "$INTDATA/nces/offerings", replace

keep STATEFP PLACEFP ap_mean de_mean n_ap_mean n_ap_var 
duplicates drop

save "$INTDATA/nces/place_offerings", replace