


foreach level in county msa cz{
	if "`level'"=="cz"{
		local levelvar cz
		local levellab "CZ"
	}
	else if "`level'"=="county"{
		local levelvar fips
		local levellab "County"
	}
	else if "`level'"=="msa"{
		local levelvar msapmsa2000
		local levellab "MSA"
	}
	
	// Preclean population data

	use "$INTDATA/cog/2_county_counts.dta", clear
	drop if fips_state == "02" | fips_state=="15"
	g fips = fips_state+fips_county_2002
	destring fips, replace
	rename czone cz

	// Census pop year
	replace year = year-2

	preserve
		collapse (sum) Pop, by(`levelvar' year)

		ren Pop `level'pop
		
		reshape wide `level'pop, i(`levelvar') j(year)
		save "$INTDATA/cog_populations/`level'pop", replace
	restore
	
	replace year = year+2
	
	
	
	// Township reclassification 1952 IOWA
	replace all_local = all_local - gen_town if year==1942 & fips_state=="19"
	replace gen_subcounty = gen_subcounty - gen_town if year==1942 & fips_state=="19"
	replace gen_town = 0  if year==1942 & fips_state=="19"
	
	// School district reclassification 1952 Mississippi and South Carolina
	bys fips (year) : g schdist_ind_impute = schdist_ind[_n+1] if year==1942 & inlist(fips_state,"28","45")
	replace all_local = all_local - schdist_ind + schdist_ind_impute if year==1942 & inlist(fips_state,"28","45")
	replace schdist_ind = schdist_ind_impute if year==1942 & inlist(fips_state,"28","45")
	
	g all_local_nosch = all_local - schdist_ind
	lab var all_local_nosch "Number of Local Govts (no school districts)"
	
	foreach var of varlist gen_muni schdist_ind all_local gen_subcounty spdist all_local_nosch{
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
			
			save "$INTDATA/counts/`var'_`level'", replace
		restore
	}

	// Preclean general purpose govts data
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

			save "$INTDATA/counts/ngov`i'_`level'", replace

		restore
	}

	// Wikiscrape prep
	use "$INTDATA/wikiscrape/wikiscrape_clean", clear

	preserve
		// Drop vars from county merge - keeping only commuting zones and info from settlement_infobox2
		keep `levelvar' wid qid incorp_year 
		
		duplicates drop 



		g n = incorp_year>=1940 & incorp_year<=1970


		g n1940 = incorp_year<1940
		g n1950 = incorp_year<1950 
		g n1960 = incorp_year<1960
		g n1970 = incorp_year<1970
		g n1980 = incorp_year<1980

		g n1940_1950 = incorp_year>=1940 & incorp_year<1950
		g n1950_1960 = incorp_year>=1950 & incorp_year<1960
		g n1960_1970 = incorp_year>=1960 & incorp_year<1970
		g n1970_1980 = incorp_year>=1970 & incorp_year<1980
		g n1980_1990 = incorp_year>=1980 & incorp_year<1990


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

		label var n_muni_`level' "n_muni_`level'"
		label var base_muni_`level'1940 "base_muni_`level'1940"
		label var base_muni_`level'1950 "base_muni_`level'1950"
		label var base_muni_`level'1960 "base_muni_`level'1960"
		label var base_muni_`level'1970 "base_muni_`level'1970"
		label var base_muni_`level'1980 "base_muni_`level'1980"

		label var n_muni_`level'_1940_1950 "n_muni_`level'1940"
		label var n_muni_`level'_1950_1960 "n_muni_`level'1950"
		label var n_muni_`level'_1960_1970 "n_muni_`level'1960"
		label var n_muni_`level'_1970_1980 "n_muni_`level'1970"
		label var n_muni_`level'_1980_1990 "n_muni_`level'1980"

		save "$INTDATA/counts/n_muni_`level'.dta", replace
	restore
	
	
	foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist all_local_nosch{
			// Pooled
			use "$DCOURT/data/GM_`level'_final_dataset.dta", clear
			if "`level'"=="msa"{
				destring smsa, gen(msapmsa2000) 
			}
			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(3) nogen
			merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
			
			save "$CLEANDATA/`level'_`ds'_pooled", replace
			
			// Creating stacked version of data
			use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
			if "`level'"=="msa"{
				destring smsa, gen(msapmsa2000) 
			}
			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(3) nogen
			merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
			
			local ylab: variable label n_muni_`level'

			rename *1940_1950 *1940
			rename *1950_1960 *1950
			rename *1960_1970 *1960

			keep GM_???? GM_hat2_????  mfg_lfshare* v2_blackmig3539_share* `levelvar' reg2 reg3 reg4  n_muni_`level'_???? base_muni_`level'???? `level'pop*
			
			reshape long base_muni_`level' n_muni_`level'_ GM_ GM_hat2_  mfg_lfshare v2_blackmig3539_share `level'pop, i(`levelvar') j(decade)

			ren n_muni_`level'_ n_muni_`level'
			ren GM_ GM
			ren GM_hat2_ GM_hat2

			bys `levelvar' (decade) : g n_muni_`level'_L1 = n_muni_`level'[_n-1] if decade-10 == decade[_n-1]
			bys `levelvar' (decade) : g n_muni_`level'_L2 = n_muni_`level'[_n-2] if decade-20 == decade[_n-2]

			bys `levelvar' (decade) : g base_muni_`level'_L1 = base_muni_`level'[_n-1] if decade-10 == decade[_n-1]
			bys `levelvar' (decade) : g base_muni_`level'_L2 = base_muni_`level'[_n-2] if decade-20 == decade[_n-2]
			
			ren n_muni_`level' n_muni_`level'_L0
			ren base_muni_`level' base_muni_`level'_L0
			
			save "$CLEANDATA/`level'_`ds'_stacked", replace
	}
}


