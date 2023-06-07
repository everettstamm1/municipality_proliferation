
foreach level in cz county{
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
	
	// Preclean cog population data

	use "$INTDATA/cog/2_county_counts.dta", clear
	drop if fips_state == "02" | fips_state=="15"
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
	
	// preclean ccdb urbanpop data (from dcourt)
	preserve
		use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
		keep `levelvar' popc1940 popc1950 popc1960 popc1970
		ren popc* `level'pop*
		save "$INTDATA/dcourt_populations/`level'pop", replace
	restore
	
	
	foreach var of varlist gen_muni schdist_ind all_local gen_subcounty spdist all_local_nosch{
		preserve
			local lab: variable label `var'

			bys `levelvar' year : egen n = total(`var'), missing
			keep `levelvar' year n
			duplicates drop 
			
			reshape wide n, i(`levelvar') j(year)
			
			g n_muni_`level' = n1972 - n1942
			g n_muni_`level'40_50 = n1952 - n1942
			g n_muni_`level'50_60 = n1962 - n1952
			g n_muni_`level'60_70 = n1972 - n1962
			g n_muni_`level'70_80 = n1982 - n1972
			g n_muni_`level'80_90 = n1992 - n1982
			
			ren n1942 b_muni_`level'1940
			ren n1952 b_muni_`level'1950
			ren n1962 b_muni_`level'1960
			ren n1972 b_muni_`level'1970
			ren n1982 b_muni_`level'1980
			
			label var b_muni_`level'1940 "Base `lab' 1940"
			label var b_muni_`level'1950 "Base `lab' 1950"
			label var b_muni_`level'1960 "Base `lab' 1960"
			label var b_muni_`level'1970 "Base `lab' 1970"
			label var b_muni_`level'1980 "Base `lab' 1980"

			label var n_muni_`level'40_50 "`lab'"
			label var n_muni_`level'50_60 "`lab'"
			label var n_muni_`level'60_70 "`lab'"
			label var n_muni_`level'70_80 "`lab'"
			label var n_muni_`level'80_90 "`lab'"
			label var n_muni_`level' "`lab'"
			
			ren *muni* *`var'*
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

			g n40_50 = incorp_date`i'>=1940 & incorp_date`i'<1950
			g n50_60 = incorp_date`i'>=1950 & incorp_date`i'<1960
			g n60_70 = incorp_date`i'>=1960 & incorp_date`i'<1970
			g n70_80 = incorp_date`i'>=1970 & incorp_date`i'<1980
			g n80_90 = incorp_date`i'>=1980 & incorp_date`i'<1990

			collapse (sum) n*, by(`levelvar')

			rename n n_muni_`level'

			rename n1940 b_muni_`level'1940
			rename n1950 b_muni_`level'1950
			rename n1960 b_muni_`level'1960
			rename n1970 b_muni_`level'1970
			rename n1980 b_muni_`level'1980

			rename n40_50 n_muni_`level'40_50
			rename n50_60 n_muni_`level'50_60
			rename n60_70 n_muni_`level'60_70
			rename n70_80 n_muni_`level'70_80
			rename n80_90 n_muni_`level'80_90

			label var b_muni_`level'1940 "Base `lab' 1940"
			label var b_muni_`level'1950 "Base `lab' 1950"
			label var b_muni_`level'1960 "Base `lab' 1960"
			label var b_muni_`level'1970 "Base `lab' 1970"
			label var b_muni_`level'1980 "Base `lab' 1980"

			label var n_muni_`level'40_50 "`lab'"
			label var n_muni_`level'50_60 "`lab'"
			label var n_muni_`level'60_70 "`lab'"
			label var n_muni_`level'70_80 "`lab'"
			label var n_muni_`level'80_90 "`lab'"
			label var n_muni_`level' "`lab'"
			
			ren *muni* *ngov`i'*
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

		g n40_50 = incorp_year>=1940 & incorp_year<1950
		g n50_60 = incorp_year>=1950 & incorp_year<1960
		g n60_70 = incorp_year>=1960 & incorp_year<1970
		g n70_80 = incorp_year>=1970 & incorp_year<1980
		g n80_90 = incorp_year>=1980 & incorp_year<1990


		collapse (sum) n*, by(`levelvar')

		rename n n_muni_`level'

		rename n1940 b_muni_`level'1940
		rename n1950 b_muni_`level'1950
		rename n1960 b_muni_`level'1960
		rename n1970 b_muni_`level'1970
		rename n1980 b_muni_`level'1980

		rename n40_50 n_muni_`level'40_50
		rename n50_60 n_muni_`level'50_60
		rename n60_70 n_muni_`level'60_70
		rename n70_80 n_muni_`level'70_80
		rename n80_90 n_muni_`level'80_90

		label var n_muni_`level' "n_muni_`level'"
		label var b_muni_`level'1940 "b_muni_`level'1940"
		label var b_muni_`level'1950 "b_muni_`level'1950"
		label var b_muni_`level'1960 "b_muni_`level'1960"
		label var b_muni_`level'1970 "b_muni_`level'1970"
		label var b_muni_`level'1980 "b_muni_`level'1980"

		label var n_muni_`level'40_50 "n_muni_`level'1940"
		label var n_muni_`level'50_60 "n_muni_`level'1950"
		label var n_muni_`level'60_70 "n_muni_`level'1960"
		label var n_muni_`level'70_80 "n_muni_`level'1970"
		label var n_muni_`level'80_90 "n_muni_`level'1980"
		ren *muni* *wikiscrape*

		save "$INTDATA/counts/n_muni_`level'.dta", replace
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
	
	keep `levelvar' yr_incorp muniname
	local lab: variable label yr_incorp
	
	g n = yr_incorp>=1940 & yr_incorp<=1970
	forv d=1900(10)1980{
		local step = `d'+10
		
		g n`d' = yr_incorp<`d'
		g n`d'_`step' = yr_incorp>=`d' & yr_incorp<`step'

	}


	collapse (sum) n*, by(`levelvar')
	rename n n_muni_`level'
	
	rename n19?? b_muni_`level'19??
	
	ren n19* n_muni_`level'*
	ren *_19?? *_??
	
	label var b_muni_`level'1940 "Base `lab' 1940"
	label var b_muni_`level'1950 "Base `lab' 1950"
	label var b_muni_`level'1960 "Base `lab' 1960"
	label var b_muni_`level'1970 "Base `lab' 1970"
	label var b_muni_`level'1980 "Base `lab' 1980"

	label var n_muni_`level'40_50 "`lab'"
	label var n_muni_`level'50_60 "`lab'"
	label var n_muni_`level'60_70 "`lab'"
	label var n_muni_`level'70_80 "`lab'"
	label var n_muni_`level'80_90 "`lab'"
	label var n_muni_`level' "`lab'"

	
	ren *muni* *cgoodman*
	save "$INTDATA/counts/cgoodman_`level'", replace
	

		
		// Pooled
		use "$DCOURT/data/GM_`level'_final_dataset.dta", clear
		if "`level'"=="msa"{
			destring smsa, gen(msapmsa2000) 
		}
		
		preserve
			use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split", clear
			keep `levelvar' GM_raw GM_raw_pp GM_hat_raw GM_hat_raw_pp vfull_blackmig3539_share reg* pop* bpop* mfg_lfshare*
			foreach var of varlist GM_raw GM_raw_pp GM_hat_raw GM_hat_raw_pp vfull_blackmig3539_share{
				ren `var' `var'_totpop
			}
			tempfile totpop_insts
			save `totpop_insts'
		restore
		
		merge 1:1 `levelvar' using `totpop_insts', update nogen
		
		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist  cgoodman{

			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(1 3) nogen
		}
		merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
		
		if "`level'"=="cz"{
			preserve
				use "$XWALKS/US_place_point_2010_crosswalks.dta", clear
				keep cz cz_name
				duplicates drop
				tempfile cznames
				save `cznames'
			restore
			
			merge 1:1 `levelvar' using `cznames', keep(1 3) nogen
		}
		
		// Incorporated land
		g decade = 1940
		merge 1:1 `levelvar' decade using "$INTDATA/cgoodman/`level'_geogs.dta", keep(1 3) 
		replace frac_land = 0 if _merge==1
		replace frac_total = 0 if _merge==1
		drop _merge decade
		
		
		
	
		save "$CLEANDATA/`level'_pooled", replace
		
		// Creating stacked version of data
		
		use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split",clear
		
		ren vfull_* *
		foreach var of varlist GM_raw* GM_hat_raw* blackmig3539_share*{
				ren `var' totpop_`var'
		}
		// Dropping 1940-70 versions
		drop totpop_GM_raw totpop_GM_raw_pp totpop_GM_hat_raw totpop_GM_hat_raw_pp

		preserve
			use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
			keep `levelvar' GM_raw_pp* GM_hat_raw_pp* popc???? mfg_lfshare* v2_blackmig3539_share* reg2 reg3 reg4 
			
			ren *pp* *ppc*
			ren v2_blackmig3539_share* blackmig3539_share*
			tempfile dcourt
			save `dcourt'
		restore
		
		merge 1:1 `levelvar' using `dcourt', nogen update
		
	
		if "`level'"=="msa"{
			destring smsa, gen(msapmsa2000) 
		}
		

		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist   cgoodman{
			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(1 3) nogen
			 
		}
		
		
			
		merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
		
	
	
		rename *1940_1950 *1940
		rename *1950_1960 *1950
		rename *1960_1970 *1960
		
		rename *00_10 *1900
		rename *10_20 *1910
		rename *20_30 *1920
		rename *30_40 *1930
		rename *40_50 *1940
		rename *50_60 *1950
		rename *60_70 *1960
		rename *70_80 *1970
		rename *80_90 *1980

		keep totpop_* GM_*  mfg_lfshare* blackmig3539_share* `levelvar' reg2 reg3 reg4  n_*_`level'???? b_*_`level'???? `level'pop* bpop* pop*
		cap drop GM_hat0* GM_hat2*  GM_hat1*  GM_hatr* GM_hat7r* GM_hat8* 
		cap drop totpop_blackmig3539_share
		local stubs 
		foreach ds in  gen_muni schdist_ind all_local ngov3 gen_subcounty spdist   cgoodman  {
			local lab`ds' : variable label n_`ds'_`level'1940
			local stubs `stubs' n_`ds'_`level' b_`ds'_`level'

		}
		
		reshape long `stubs' totpop_GM_raw_ totpop_GM_raw_pp_ totpop_GM_hat_raw_ totpop_GM_hat_raw_pp_ GM_raw_ppc_ GM_hat_raw_ppc_  mfg_lfshare blackmig3539_share `level'pop bpop pop bpopc popc, i(`levelvar') j(decade)
		
		
		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist   cgoodman {
			label var n_`ds'_`level' "`lab`ds''"

		}
		
		ren *_ *
		ren totpop_* *_totpop
		/*
		bys `levelvar' (decade) : g n_*_`level'_L1 = n_*_`level'[_n-1] if decade-10 == decade[_n-1]
		bys `levelvar' (decade) : g n_*_`level'_L2 = n_*_`level'[_n-2] if decade-20 == decade[_n-2]

		bys `levelvar' (decade) : g b_*_`level'_L1 = b_*_`level'[_n-1] if decade-10 == decade[_n-1]
		bys `levelvar' (decade) : g b_*_`level'_L2 = b_*_`level'[_n-2] if decade-20 == decade[_n-2]
		*/
		ren n_*_`level' n_*_`level'_L0
		ren b_*_`level' b_*_`level'_L0
		
		
		// Bringing in 1900-30 total and urban populations
		merge 1:1 decade `levelvar' using "$INTDATA/census/`level'_urbanization_1900_1930", update nogen 

		
		foreach var of varlist pop popc bpop bpopc{
			foreach year in 1940 1970{
				g `var'`year' = `var' if decade == `year'
				bys `levelvar' (`var'`year') : replace `var'`year' = `var'`year'[1]
			}
		}		

		keep if mod(decade,10)==0
		
		merge 1:1 `levelvar' decade using "$INTDATA/cgoodman/`level'_geogs.dta", keep(1 3) 
		replace frac_land = 0 if _merge==1
		replace frac_total = 0 if _merge==1
		drop _merge
		/*
		if "`level'"=="county"{
			
			merge 1:1 fips decade using "$INTDATA/land_cover/frac_unusable", keep(1 3) nogen
			merge m:1 fips using "$INTDATA/lu_lutz_sand/lu_lutz_sand_indicators", keep(1 3) nogen
			ren frac_unbuildable_* frac_ub_*
			foreach geog in land total unusable total_00 total_05 total_10 total_15 total_20 lu_ml_2010 lu_ml_mean ub_1 ub_2{
				qui su frac_`geog' if decade == 1940 & GM < .,d
				g above_med_temp = frac_`geog'>=`r(p50)' if decade == 1940 & GM_raw < . 
				bys `levelvar' : egen above_med_`geog' = max(above_med_temp)
				g GM_X_above_med_`geog' = GM * above_med_`geog'
				g GM_hat_X_above_med_`geog' = GM_hat * above_med_`geog'

				drop above_med_temp
			}
			
			
			
			preserve
				use "$RAWDATA/other/district_court_order_data_feb2021.dta", clear
				drop if status_2020 >=4 // Dropping dismissed court orders
				keep cfips 
				ren cfip fips
				destring fips, replace
				duplicates drop
				tempfile co
				save `co'
			restore

			merge m:1 fips using `co', keep(1 3)
			g co_2020 = _merge == 3
			lab var co_2020 "Desegregation Order"
			
			g GM_X_co_2020 = GM * co_2020
			g GM_hat_X_co_2020 = GM_hat * co_2020
			drop _merge
			/*
			merge m:1 fips using "$INTDATA/land_cover/county_tri", keep(3) nogen
			g add_tri_ctrl = cond(mean_tri<.,0,1)
			replace mean_tri = 0 if add_tri_ctrl==1
			*/
			merge m:1 fips using "$CLEANDATA/nces/nces_finance_data.dta", keep(3) nogen
		}
		*/
	preserve
		use "$RAWDATA/dcourt/ICPSR_07735_City_Book_1944_1977/DS0001/City_Book_1944_1977.dta", clear

		*Standardize State Names
		drop if PLACE1=="0000"
		destring STATE1, replace
		statastates, fips(STATE1)  nogen

		cityfix_ccdb

		
					
		ren CC0007 popc1940
		ren CC0010 popc1970
		
		keep if popc1940>25000 & popc1970>25000
		
		merge 1:1 city using "$XWALKS/US_place_point_2010_crosswalks.dta", keepusing(state_fips countyfip cz) keep(1 3) 
		g fips = state_fips*1000+real(countyfip)

		replace cz = 19600 if city == "Belleville, NJ"
		replace fips = 34013 if city == "Belleville, NJ"
		keep `levelvar'
		duplicates drop
		tempfile urban
		save `urban'
	restore
	merge m:1 `levelvar' using `urban', keep(1 3)
	g urban = _merge==3
	drop _merge
	
	preserve 
		use "$DCOURT/data/GM_cz_final_dataset.dta", clear
		ren cz czone
		merge 1:m czone using "$XWALKS/cw_cty_czone", keep(3) nogen
		ren czone cz
		ren cty_fips fips
		keep `levelvar'
		duplicates drop
		tempfile dcourt
		save `dcourt'
	restore
	merge m:1 `levelvar' using `dcourt', keep(1 3)
	g dcourt = _merge==3
	drop _merge
	
	
	if "`level'"=="cz"{
		preserve
			use "$XWALKS/US_place_point_2010_crosswalks.dta", clear
			keep cz cz_name
			duplicates drop
			replace cz_name="Louisville, KY" if cz==13101 // Fill in Louisville, KY name, which was missing.

			tempfile cznames
			save `cznames'
		restore
		
		merge m:1 `levelvar' using `cznames', keep(1 3) nogen
	}
	
	save "$CLEANDATA/`level'_stacked", replace
	
}


