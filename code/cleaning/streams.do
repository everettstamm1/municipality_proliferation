



cd "$RAWDATA/GNIS/DomesticNames_AllStates_Text/Text/"   // Set to your target folder
fs *.txt                // Or *.csv, *.dta, etc.

local count = 1
foreach file in `r(files)' {
    display "Processing file: `file'"
	import delimited using "`file'", delimiter("|") varnames(1) clear
	keep if feature_class == "Stream"
	g cty_fips = 1000*state_numeric + county_numeric
	merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3)
	count if _merge == 3
	if r(N)>0{
		// [process the data...]
		g n_streams = 1
		collapse (sum) n_streams, by(czone)
		tempfile f`count'
		save `f`count''
		local count = `count' +1

	}

}
local end = `count' - 1
clear
forv t=1/`end'{
	di "`t'"
	append using `f`t''
}
rename czone cz
collapse (sum) n_streams, by(cz)
save "$INTDATA/other/streams", replace