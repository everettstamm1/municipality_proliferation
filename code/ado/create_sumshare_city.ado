cap prog drop create_sumshare_city
prog def create_sumshare_city
	syntax, version(string) main_path(string) shift_path(string) origin_id(string) dest_id(string) origin_sample(string) out_path(string) type(string) shift_name(string)
	// Version is an ID you'll create
	// Main path is where your population data is linked and will have destination 
	// and origin variables
	// Shift path is where your origin level shift data is
	// Out path is the folder you want to write to
	
	// Get shifts, collapse all years 
	use "`shift_path'", clear
	
	ren `shift_name' shift_num
	collapse (sum) shift_num, by(`origin_id')
	replace shift_num = -shift_num // outflows to inflows
	cap destring `origin_id', replace
	
	tempfile m
	save `m'
	
	use "`main_path'", clear
	
	keep if `origin_sample' == 1
	keep if `type' == 1
	
	bys `origin_id' : egen shift_denom = total(`type')
	
	// Getting 1940 City Population. Also applies destination sample selection.
	cap ren city citycode 
	merge m:1 city using "$INTDATA/dcourt/xwalk_296_city_cz.dta", keepusing(popc1940) keep(2 3)
	ren popc1940 share_denom

	
	// Some cities have no baseline migration, so filling those as zeros
	replace `type' = 0 if _merge == 2
	replace shift_denom = 0 if _merge == 2
	
	bys city `origin_id' : egen share_num = total(`type')
	keep city `origin_id' share_num share_denom shift_denom
	duplicates drop
	
	// Merge in shifts
	merge m:1 `origin_id' using `m', keep(1 3) nogen
	replace shift_num = 0 if mi(shift_num)

	// Double Checking bc we have some denominator
	replace shift_num = 0 if mi(shift_num)
	replace share_num = 0 if mi(shift_num)
	replace share_denom = 0 if mi(shift_num)
	replace shift_denom = 0 if mi(shift_denom)
	
	g share = share_num / share_denom
	g shift = shift_num / shift_denom
	
	replace share = 0 if mi(share)
	replace shift = 0 if mi(shift)
	
	g shift_share = share * shift
	
	// Saving shock level instrument
	preserve 
		keep `origin_id' shift
		duplicates drop
		tempfile shock_level_inst
		save "`out_path'/shock_instrument_city_`version'.dta", replace
	restore

	// Saving shares in long
	preserve 
		keep `origin_id' city share
		duplicates drop
		tempfile shares
		save "`out_path'/shares_city_`version'.dta", replace
	restore

	// Summing to get shift share and correct sum of shares
	collapse (sum) share shift_share, by(city)

	rename share sumshare
	save "`out_path'/dest_instrument_city_`version'.dta", replace
	
	clear
end