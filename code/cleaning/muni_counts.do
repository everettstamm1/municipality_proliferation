// Preclean cog population data

	use "$INTDATA/cog/2_county_counts.dta", clear
	drop if fips_state == "02" | fips_state=="15"
	destring fips, replace
	rename czone cz
	keep if cz<.
	// Notes from here: https://play.google.com/books/reader?id=hQCIHGUmiyAC&pg=GBS.PP4&hl=en
//Maine , Mary- land , Massachusetts , North Carolina , Rhode Island , and Virginia are completely excluded (DC as well by our interpretation)-> Drop these CZs
// Tennessee, Vermont, and CONNECTICUT all have a different definition resulting in large numbers of dependent school systems, but only starting in 1957. Impute backwards and or exclude from analysis. 

	// Full removal
	g schdist_m1_flag =  inlist(fips_state,"09","11","23","24","25","37","44","50","51")
	g schdist_ind_m1 = schdist_ind if schdist_m1_flag==0
	
	// Backwards Imputation
	// Need to impute dependent schools for 1942, 1952, 1997, 2012
	
	// Dependent 1997 and 2012
	g schdist_dep_m2 = schdist_dep
	bys fips (year) : replace schdist_dep_m2 = (schdist_dep_m2[_n-1] + schdist_dep_m2[_n+1])/2 if year==1997
	bys fips (year) : replace schdist_dep_m2 = schdist_dep_m2[_n-1] if year == 2012
	
	// Backwards for 1942 and 1952 
	g schdist_m2_flag =  inlist(fips_state,"11","23","24","25","37","44","51")
	g schdist_ind_m2 = schdist_ind if schdist_m2_flag==0
	g schdist_dep_1957 = schdist_dep_m2 if year == 1957
	bys fips (schdist_dep_1957) : replace schdist_dep_m2 = schdist_dep_1957[1] if inlist(fips_state,"09","47","50") & inlist(year,1942,1952)
	g schdist_m2 = schdist_ind_m2 + cond(inlist(fips_state,"09","47","50"), schdist_dep_m2,0)
	// Census pop year
	replace year = year-2

	preserve
		collapse (sum) Pop, by(cz year)

		ren Pop czpop
		
		reshape wide czpop, i(cz) j(year)
		save "$INTDATA/cog_populations/czpop", replace
	restore
	
	replace year = year+2
	
	/*
	// preclean ccdb urbanpop data (from dcourt)
	preserve
		use "$DCOURT/data/GM_cz_final_dataset_split.dta", clear
		keep cz popc1940 popc1950 popc1960 popc1970
		ren popc* czpop*
		save "$INTDATA/dcourt_populations/czpop", replace
	restore
	*/
	
	foreach var of varlist gen_town gen_muni schdist_ind all_local gen_subcounty spdist all_local_nosch schdist schdist_ind_m1 schdist_m2 {
		preserve
			local lab: variable label `var'
			if "`var'"=="schdist_ind_m1"{
				bys cz (schdist_m1_flag) : replace schdist_m1_flag = schdist_m1_flag[_N]
				keep if schdist_m1_flag==0
			} 
			else if "`var'"=="schdist_m2"{
				bys cz (schdist_m2_flag) : replace schdist_m2_flag = schdist_m2_flag[_N]
				keep if schdist_m2_flag==0
			}
			
			bys cz year : egen n = total(`var'), missing
			keep cz year n
			duplicates drop 
			
			reshape wide n, i(cz) j(year)
			
			g n_muni_cz = n1972 - n1942
			g n_muni_cz40_50 = n1952 - n1942
			g n_muni_cz50_60 = n1962 - n1952
			g n_muni_cz60_70 = n1972 - n1962
			g n_muni_cz70_80 = n1982 - n1972
			g n_muni_cz80_90 = n1992 - n1982
			g n_muni_cz90_00 = n2002 - n1992
			g n_muni_cz00_10 = n2012 - n2002

			ren n1942 b_muni_cz1940
			ren n1952 b_muni_cz1950
			ren n1962 b_muni_cz1960
			ren n1972 b_muni_cz1970
			ren n1982 b_muni_cz1980
			ren n1992 b_muni_cz1990
			ren n2002 b_muni_cz2000
			ren n2012 b_muni_cz2010

			label var b_muni_cz1940 "Base `lab' 1940"
			label var b_muni_cz1950 "Base `lab' 1950"
			label var b_muni_cz1960 "Base `lab' 1960"
			label var b_muni_cz1970 "Base `lab' 1970"
			label var b_muni_cz1980 "Base `lab' 1980"
			label var b_muni_cz1990 "Base `lab' 1990"
			label var b_muni_cz2000 "Base `lab' 2000"
			label var b_muni_cz2010 "Base `lab' 2010"

			label var n_muni_cz40_50 "`lab'"
			label var n_muni_cz50_60 "`lab'"
			label var n_muni_cz60_70 "`lab'"
			label var n_muni_cz70_80 "`lab'"
			label var n_muni_cz80_90 "`lab'"
			label var n_muni_cz90_00 "`lab'"
			label var n_muni_cz00_10 "`lab'"

			label var n_muni_cz "`lab'"
			
			ren *muni* *`var'*
			keep b_* n_* cz
			save "$INTDATA/counts/`var'_cz", replace
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

	keep incorp_date* id cz
	duplicates drop

	forv i=1/3{
		preserve
			keep cz incorp_date`i'
			local lab: variable label incorp_date`i'

			g n = incorp_date`i'>=1940 & incorp_date`i'<=1970


			g n1940 = incorp_date`i'<1940
			g n1950 = incorp_date`i'<1950 
			g n1960 = incorp_date`i'<1960
			g n1970 = incorp_date`i'<1970
			g n1980 = incorp_date`i'<1980

			g n40_50 = incorp_date`i'>=1940 & incorp_date`i'<1950
			g n50_60 = incorp_date`i'>=1950 & incorp_date`i'<1960
			g n60_70 = incorp_date`i'>=1960 & incorp_date`i'<1970
			g n70_80 = incorp_date`i'>=1970 & incorp_date`i'<1980
			g n80_90 = incorp_date`i'>=1980 & incorp_date`i'<1990

			collapse (sum) n*, by(cz)

			rename n n_muni_cz

			rename n1940 b_muni_cz1940
			rename n1950 b_muni_cz1950
			rename n1960 b_muni_cz1960
			rename n1970 b_muni_cz1970
			rename n1980 b_muni_cz1980

			rename n40_50 n_muni_cz40_50
			rename n50_60 n_muni_cz50_60
			rename n60_70 n_muni_cz60_70
			rename n70_80 n_muni_cz70_80
			rename n80_90 n_muni_cz80_90

			label var b_muni_cz1940 "Base `lab' 1940"
			label var b_muni_cz1950 "Base `lab' 1950"
			label var b_muni_cz1960 "Base `lab' 1960"
			label var b_muni_cz1970 "Base `lab' 1970"
			label var b_muni_cz1980 "Base `lab' 1980"

			label var n_muni_cz40_50 "`lab'"
			label var n_muni_cz50_60 "`lab'"
			label var n_muni_cz60_70 "`lab'"
			label var n_muni_cz70_80 "`lab'"
			label var n_muni_cz80_90 "`lab'"
			label var n_muni_cz "`lab'"
			
			ren *muni* *ngov`i'*
			save "$INTDATA/counts/ngov`i'_cz", replace

		restore
	}

	// Wikiscrape prep
	use "$INTDATA/wikiscrape/wikiscrape_clean", clear

	preserve
		// Drop vars from county merge - keeping only commuting zones and info from settlement_infobox2
		keep cz wid qid incorp_year 
		
		duplicates drop 



		g n = incorp_year>=1940 & incorp_year<=1970


		g n1940 = incorp_year<1940
		g n1950 = incorp_year<1950 
		g n1960 = incorp_year<1960
		g n1970 = incorp_year<1970
		g n1980 = incorp_year<1980

		g n40_50 = incorp_year>=1940 & incorp_year<1950
		g n50_60 = incorp_year>=1950 & incorp_year<1960
		g n60_70 = incorp_year>=1960 & incorp_year<1970
		g n70_80 = incorp_year>=1970 & incorp_year<1980
		g n80_90 = incorp_year>=1980 & incorp_year<1990


		collapse (sum) n*, by(cz)

		rename n n_muni_cz

		rename n1940 b_muni_cz1940
		rename n1950 b_muni_cz1950
		rename n1960 b_muni_cz1960
		rename n1970 b_muni_cz1970
		rename n1980 b_muni_cz1980

		rename n40_50 n_muni_cz40_50
		rename n50_60 n_muni_cz50_60
		rename n60_70 n_muni_cz60_70
		rename n70_80 n_muni_cz70_80
		rename n80_90 n_muni_cz80_90

		label var n_muni_cz "n_muni_cz"
		label var b_muni_cz1940 "b_muni_cz1940"
		label var b_muni_cz1950 "b_muni_cz1950"
		label var b_muni_cz1960 "b_muni_cz1960"
		label var b_muni_cz1970 "b_muni_cz1970"
		label var b_muni_cz1980 "b_muni_cz1980"

		label var n_muni_cz40_50 "n_muni_cz1940"
		label var n_muni_cz50_60 "n_muni_cz1950"
		label var n_muni_cz60_70 "n_muni_cz1960"
		label var n_muni_cz70_80 "n_muni_cz1970"
		label var n_muni_cz80_90 "n_muni_cz1980"
		ren *muni* *wikiscrape*

		save "$INTDATA/counts/n_muni_cz.dta", replace
	restore
	

	// Preclean cgoodman data
	use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear
	destring statefips countyfips, replace
	drop if statefips == 02 | statefips==15
	g cty_fips = 1000*statefips+countyfips
	merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
	merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk.dta", nogen keep(1 3)
	ren czone cz 
	ren cty_fips fips
	//replace yr_incorp = yr_incorp-2
	keep cz yr_incorp muniname
	local lab: variable label yr_incorp
	
	g n = yr_incorp>=1940 & yr_incorp<1970
	forv d=1700(10)2010{
		local step = `d'+10
		
		g n`d' = yr_incorp<`d'

	}


	collapse (sum) n*, by(cz)
	rename n n_muni_cz
		rename n17?? b_muni_cz17??

	rename n18?? b_muni_cz18??

	rename n19?? b_muni_cz19??
	rename n20?? b_muni_cz20??

	

	label var b_muni_cz1940 "Base `lab' 1940"
	label var b_muni_cz1950 "Base `lab' 1950"
	label var b_muni_cz1960 "Base `lab' 1960"
	label var b_muni_cz1970 "Base `lab' 1970"
	label var b_muni_cz1980 "Base `lab' 1980"
	label var b_muni_cz1990 "Base `lab' 1990"
	label var b_muni_cz2000 "Base `lab' 2000"
	label var b_muni_cz2010 "Base `lab' 2010"

	label var n_muni_cz "`lab'"

	
	ren *muni* *cgoodman*
	save "$INTDATA/counts/cgoodman_cz", replace
	
