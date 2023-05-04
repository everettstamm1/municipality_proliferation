
foreach inst in og full{
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
		
		// Preclean cgoodman data
		
		use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear
		destring statefips countyfips, replace
		drop if statefips == 02 | statefips==15
		g cty_fips = 1000*statefips+countyfips
		merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
		merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk.dta", nogen keep(1 3)
		ren czone cz 
		ren cty_fips fips
		
		keep `levelvar' yr_incorp
		local lab: variable label yr_incorp

		g n = yr_incorp>=1940 & yr_incorp<=1970


		g n1940 = yr_incorp<1940
		g n1950 = yr_incorp<1950 
		g n1960 = yr_incorp<1960
		g n1970 = yr_incorp<1970
		g n1980 = yr_incorp<1980

		g n1940_1950 = yr_incorp>=1940 & yr_incorp<1950
		g n1950_1960 = yr_incorp>=1950 & yr_incorp<1960
		g n1960_1970 = yr_incorp>=1960 & yr_incorp<1970
		g n1970_1980 = yr_incorp>=1970 & yr_incorp<1980
		g n1980_1990 = yr_incorp>=1980 & yr_incorp<1990

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

		save "$INTDATA/counts/cgoodman_`level'", replace

		
		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist all_local_nosch cgoodman{
				// Pooled
				use "$DCOURT/data/GM_`level'_final_dataset.dta", clear
				if "`level'"=="msa"{
					destring smsa, gen(msapmsa2000) 
				}
				merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(3) nogen
				merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
				
				save "$CLEANDATA/`level'_`ds'_pooled", replace
				
				// Creating stacked version of data
				if "`inst'"=="og"{
					use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
					drop totblackmigcity3539
					ren GM_hat2_* GM_hat_*
					ren v2_* *
				}
				else if "`inst'"!="og"{
					use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split"
					
					//keep if `inst'_sample == 1
					ren GM_hat`inst'_* GM_hat_*
					ren v`inst'_* *
				}
				if "`level'"=="msa"{
					destring smsa, gen(msapmsa2000) 
				}
				merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(3) nogen
				if "`inst'" == "og" {
					merge 1:1 `levelvar' using "$INTDATA/dcourt_populations/`level'pop", keep(3) nogen 
				}
				else{
					merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
				}
				
				local ylab: variable label n_muni_`level'

				rename *1940_1950 *1940
				rename *1950_1960 *1950
				rename *1960_1970 *1960

				keep GM_*  mfg_lfshare* blackmig3539_share* `levelvar' reg2 reg3 reg4  n_muni_`level'_???? base_muni_`level'???? `level'pop*
				cap drop GM_hat0*  GM_hat1*  GM_hatr* GM_hat7r* GM_hat8* 
				reshape long base_muni_`level' n_muni_`level'_ GM_ GM_hat_ GM_raw_ GM_hat_raw_ GM_hatfull_raw_ GM_actfull_raw_ GM_hatccdb_raw_ GM_actccdb_raw_  GM_hatfull_ GM_actfull_ GM_hatccdb_ GM_actccdb_ mfg_lfshare blackmig3539_share `level'pop, i(`levelvar') j(decade)

				ren n_muni_`level'_ n_muni_`level'
				ren GM_ GM
				ren GM_hat_ GM_hat
				ren GM_raw_ GM_raw
				ren GM_hat_raw_ GM_hat_raw
				cap ren GM_actfull_ GM_actfull
				cap ren GM_actfull_raw_ GM_actfull_raw
				cap ren GM_actccdb_ GM_actccdb
				cap ren GM_actccdb_raw_ GM_actccdb_raw
				cap ren GM_actfull_ GM_actfull
				cap ren GM_actfull_raw_ GM_actfull_raw
				cap ren GM_actccdb_ GM_actccdb
				cap ren GM_actccdb_raw_ GM_actccdb_raw
				
				bys `levelvar' (decade) : g n_muni_`level'_L1 = n_muni_`level'[_n-1] if decade-10 == decade[_n-1]
				bys `levelvar' (decade) : g n_muni_`level'_L2 = n_muni_`level'[_n-2] if decade-20 == decade[_n-2]

				bys `levelvar' (decade) : g base_muni_`level'_L1 = base_muni_`level'[_n-1] if decade-10 == decade[_n-1]
				bys `levelvar' (decade) : g base_muni_`level'_L2 = base_muni_`level'[_n-2] if decade-20 == decade[_n-2]
				
				ren n_muni_`level' n_muni_`level'_L0
				ren base_muni_`level' base_muni_`level'_L0
				lab var n_muni_`level'_L0 "`ylab'"
				
			
				
				g `level'pop1940 = `level'pop if decade == 1940
				bys `levelvar' (`level'pop1940) : replace `level'pop1940 = `level'pop1940[1]
				
				keep if inlist(decade, 1940, 1950, 1960)
				if "`level"=="county"{
					merge 1:1 fips decade using "$INTDATA/cgoodman/county_geogs.dta", keep(1 3) 
					replace frac_land = 0 if _merge==1
					replace frac_total = 0 if _merge==1
					drop _merge
					merge 1:1 fips decade using "$INTDATA/land_cover/frac_unusable", keep(1 3) nogen
					merge m:1 fips using "$INTDATA/lu_lutz_sand/lu_lutz_sand_indicators", keep(1 3) nogen
					ren frac_unbuildable_* frac_ub_*
					foreach geog in land total unusable total_00 total_05 total_10 total_15 total_20 lu_ml_2010 lu_ml_mean ub_1 ub_2{
						qui su frac_`geog' if decade == 1940 & GM < . & n_muni_`level'_L0 < .,d
						g above_med_temp = frac_`geog'>=`r(p50)' if decade == 1940 & GM < . & n_muni_`level'_L0 < .
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
			
			
			save "$CLEANDATA/`level'_`ds'_stacked_`inst'", replace
		}
	}
}


