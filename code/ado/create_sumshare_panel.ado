cap prog drop create_sumshare_panel
prog def create_sumshare_panel
	syntax, version(string) main_path(string) shift_path(string) origin_id(string) dest_id(string) origin_sample(string) out_path(string) type(string) time(string)
	// Version is an ID you'll create
	// Main path is where your population data is linked and will have destination 
	// and origin variables
	// Shift path is where your origin level shift data is
	// Out path is the folder you want to write to
	
	local version "base"
	local shift_path "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	local main_path "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta"
	local origin_id "origin_fips"
	local dest_id "city"
	local origin_sample "origin_sample"
	local type "black"
	local time "year"
	
	// Get shifts, collapse all years 
	use "`shift_path'", clear
	
	ren proutmig shift_num
	collapse (sum) shift_num, by(`origin_id' `time')
	
	replace shift_num = -shift_num // outflows to inflows
	cap destring `origin_id', replace
	replace year = year - 10
	tempfile m
	save `m'
	
	
	use "`main_path'", clear
	
	keep if `origin_sample' == 1
	keep if `type' == 1
	
	bys `origin_id' : egen shift_denom = total(`type')
	ren city citycode
	merge m:1 city using "$INTDATA/dcourt/xwalk_296_city_cz.dta", keepusing(cz cz_popc1940 cz_popc1950 cz_popc1960)
	// Some CZs have no baseline migration, so filling those as zeros
	ren cz_popc* share_denom*
	replace `type' = 0 if _merge == 2
	replace shift_denom = 0 if _merge == 2
	
	bys cz `origin_id' : egen share_num = total(`type')
	keep cz `origin_id' share_num shift_denom share_denom*
	duplicates drop
	
	reshape long share_denom, i(cz `origin_id') j(`time')
	// Merge in shifts
	merge m:1 `origin_id' `time' using `m', keep(1 3) nogen
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
	
	drop if mi(cz)
	local lab ""
	tempfile sumshares
	save `sumshares'
	
	// Saving shock level instrument
	foreach y in all 1940 1950 1960{
		use `sumshares', clear
		if "`y'"!= "all" keep if year == `y'
		if "`y'"!= "all" local lab "_`y'"
		
		preserve 
			keep `origin_id' shift year
			duplicates drop
			tempfile shock_level_inst
			save "`out_path'/shock_instrument_panel`lab'_`version'.dta", replace
			
		restore

		// Saving shares in long
		preserve 
			keep `origin_id' cz share year
			duplicates drop
			tempfile shares
			save "`out_path'/shares_panel`lab'_`version'.dta", replace
		restore

		// Summing to get shift share and correct sum of shares
		collapse (sum) share shift_share, by(cz year)

		rename share sumshare
		save "`out_path'/dest_instrument_panel`lab'_`version'.dta", replace
		
		clear
	}
end