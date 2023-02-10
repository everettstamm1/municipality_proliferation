// Preclean general purpose govts data
local level = "county"
local levelvar = "fips"
	use "$INTDATA/cog/4_1_general_purpose_govts.dta", clear
	drop if fips_code_state == "02" | fips_code_state=="15"
	g fips = 1000*fips_state+fips_county_2002
	rename czone cz
	rename fips_code_msa msapmsa2000
	keep if ID_type == 2 | ID_type == 3 // keeping only municipal and town/township observations

	g incorp_date1 = original_incorporation_date
	g incorp_date2 = year_home_rule_adopted

	// Documentation notes some inconsistencies in incorporation dates and home rule charters, so we'll take the earliest reported
	bys id (incorp_date1) : replace incorp_date1 = incorp_date1[1] 
	bys id (incorp_date2) : replace incorp_date2 = incorp_date2[1] 

	g incorp_date3 = cond(incorp_date1<.,incorp_date1,incorp_date2)
	drop if incorp_date3==.

	lab var incorp_date1 "Incorporations"
	lab var incorp_date2 "Home Rule Adoptions"
	lab var incorp_date3 "Incorporations or Home Rule Adoptions"

	keep incorp_date* id `levelvar'
	duplicates drop

	forv i=1/3{
		preserve
			keep `levelvar' incorp_date`i'
			local lab: variable label incorp_date`i'

			g n = incorp_date`i'>=1940 & incorp_date`i'<=1970


			g n1940 = incorp_date`i'<1940
			g n1950 = incorp_date`i'<1950 
			g n1960 = incorp_date`i'<1960
			g n1970 = incorp_date`i'<1970
			g n1980 = incorp_date`i'<1980

			g n1940_1950 = incorp_date`i'>=1940 & incorp_date`i'<1950
			g n1950_1960 = incorp_date`i'>=1950 & incorp_date`i'<1960
			g n1960_1970 = incorp_date`i'>=1960 & incorp_date`i'<1970
			g n1970_1980 = incorp_date`i'>=1970 & incorp_date`i'<1980
			g n1980_1990 = incorp_date`i'>=1980 & incorp_date`i'<1990

			collapse (sum) n*, by(`levelvar')

			rename n n_muni_`level'

			rename n1940 base_muni_`level'1940
			rename n1950 base_muni_`level'1950
			rename n1960 base_muni_`level'1960
			rename n1970 base_muni_`level'1970
			rename n1980 base_muni_`level'1980

			rename n1940_1950 n_muni_`level'_1940_1950
			rename n1950_1960 n_muni_`level'_1950_1960
			rename n1960_1970 n_muni_`level'_1960_1970
			rename n1970_1980 n_muni_`level'_1970_1980
			rename n1980_1990 n_muni_`level'_1980_1990

			label var base_muni_`level'1940 "Base `lab' 1940"
			label var base_muni_`level'1950 "Base `lab' 1950"
			label var base_muni_`level'1960 "Base `lab' 1960"
			label var base_muni_`level'1970 "Base `lab' 1970"
			label var base_muni_`level'1980 "Base `lab' 1980"

			label var n_muni_`level'_1940_1950 "`lab'"
			label var n_muni_`level'_1950_1960 "`lab'"
			label var n_muni_`level'_1960_1970 "`lab'"
			label var n_muni_`level'_1970_1980 "`lab'"
			label var n_muni_`level'_1980_1990 "`lab'"
			label var n_muni_`level' "`lab'"
			
			ren * cog4_*
			ren cog4_fips fips
			
			tempfile ngov`i'
			save `ngov`i''
		restore
	}
	
	

	use "$INTDATA/cog/2_county_counts.dta", clear
	drop if fips_state == "02" | fips_state=="15"
	g fips = fips_state+fips_county_2002
	destring fips, replace
	rename czone cz
	replace all_local = all_local - schdist_ind
	foreach var of varlist all_local {
		preserve
			local lab: variable label `var'

			bys `levelvar' year : egen n = total(`var'), missing
			keep `levelvar' year n
			duplicates drop 
			
			reshape wide n, i(`levelvar') j(year)
			
			g n_muni_`level' = n1972 - n1942
			g n_muni_`level'_1940_1950 = n1952 - n1942
			g n_muni_`level'_1950_1960 = n1962 - n1952
			g n_muni_`level'_1960_1970 = n1972 - n1962
			g n_muni_`level'_1970_1980 = n1982 - n1972
			g n_muni_`level'_1980_1990 = n1992 - n1982
			
			ren n1942 base_muni_`level'1940
			ren n1952 base_muni_`level'1950
			ren n1962 base_muni_`level'1960
			ren n1972 base_muni_`level'1970
			ren n1982 base_muni_`level'1980
			
			label var base_muni_`level'1940 "Base `lab' 1940"
			label var base_muni_`level'1950 "Base `lab' 1950"
			label var base_muni_`level'1960 "Base `lab' 1960"
			label var base_muni_`level'1970 "Base `lab' 1970"
			label var base_muni_`level'1980 "Base `lab' 1980"

			label var n_muni_`level'_1940_1950 "`lab'"
			label var n_muni_`level'_1950_1960 "`lab'"
			label var n_muni_`level'_1960_1970 "`lab'"
			label var n_muni_`level'_1970_1980 "`lab'"
			label var n_muni_`level'_1980_1990 "`lab'"
			label var n_muni_`level' "`lab'"
				ren * cog2_*
			ren cog2_fips fips
			tempfile `var'
			save ``var''
		restore
	}
	
	use "$INTDATA/n_muni_county.dta", clear
	ren * wiki_*
	ren wiki_fips fips
	merge 1:1 fips using `ngov3', keep(3) nogen
	merge 1:1 fips using `all_local', keep(3) nogen

	/*
	foreach var of varlist cog_*{
		replace `var' = 0 if _merge==1
	}
	foreach var of varlist wiki_*{
		replace `var' = 0 if _merge==2
	}
	drop _merge
	*/
	foreach var in n_muni_county base_muni_county1940 base_muni_county1950 base_muni_county1960 base_muni_county1970 base_muni_county1980 n_muni_county_1940_1950 n_muni_county_1950_1960 n_muni_county_1960_1970 n_muni_county_1970_1980 n_muni_county_1980_1990{
		di "`var'"
		corr wiki_`var' cog2_`var' cog4_`var'
	}
	

	g statefips = floor(fips/1000)
	drop fips
	collapse (sum) wiki_* cog2_* cog4_*, by(statefips)
	 
	foreach var in n_muni_county base_muni_county1940 base_muni_county1950 base_muni_county1960 base_muni_county1970 base_muni_county1980 n_muni_county_1940_1950 n_muni_county_1950_1960 n_muni_county_1960_1970 n_muni_county_1970_1980 n_muni_county_1980_1990{
		order *`var'
		di "`var'"
		corr wiki_`var' cog2_`var' cog4_`var'
	}
	order statefips
	reshape long cog2_ cog4_ wiki_, i(statefips) j(var) string
adsafs
	g diff = (100* (cog_ - wiki_)/cog_)
	replace diff = 0 if cog_==0 & wiki_ == 0
	collapse (mean) diff, by(statefips)
	