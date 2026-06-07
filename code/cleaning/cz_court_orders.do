import delimited "$RAWDATA/nces/school-districts_lea_directory.csv", clear
drop if county_code < 0 | leaid == . 

//keep leaid year county_code enrollment
ren county_code cty_fips

preserve
	use "$RAWDATA/other/district_court_order_data_feb2021.dta", clear
	//drop if status_2020 >=4 // Dropping dismissed court orders
	drop if status_2020 == 1 | status_2020 == 2 // Dropping missing status or never ordered
	g dismissed = status_2020 >= 4
	keep leaid 
	duplicates drop
	tempfile co
	save `co'
restore

merge m:1 leaid using `co'
g court_order = _merge==3
drop _merge

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen

g enrollment_co = enrollment*court_order if year == 2000
replace enrollment = . if year!=2000
bys cz year (enrollment): g main_court_ordered = court_order==1 & _n==_N
g frac_court_ordered = court_order if year == 2000

collapse (mean) frac_court_ordered (max) main_court_ordered court_order (sum) enrollment enrollment_co, by(cz)

g frac_enroll_court_ordered = 100*(enrollment_co /enrollment)

lab var frac_court_ordered "Proportion of school districts court ordered, 2000"

lab var frac_enroll_court_ordered "Proportion of students enrolled in court ordered school district, 2000"
lab var court_order "=1 if any school district in CZ in any year was court ordered"
lab var main_court_order "=1 if largest school district in CZ in any year was court ordered"

lab var enrollment "2000 Total Enrollment"

drop enrollment*
save "$CLEANDATA/nces/cz_court_orders", replace