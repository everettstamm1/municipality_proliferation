
foreach level in cz {
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
			keep b_* n_* `levelvar'
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
	

	foreach samp in  dcourt south{
		if "`samp'" == "dcourt" {
			local samptab = ""
			local outsamptab = ""

		}
		if "`samp'" == "south" {
			local samptab = "_full"
			local outsamptab = "_south"
		}
		// Pooled
		
		use "$DCOURT/data/GM_`level'_final_dataset`samptab'.dta", clear
		keep `levelvar' GM GM_hat2 GM*raw GM*raw_pp GM*hat_raw GM*hat_raw_pp v2*blackmig3539_share1940 popc* bpopc* mfg_lfshare1940 reg* frac_all_upm1940  GM_hat_raw_r*
		ren GM_hat2 GM_hat
		if "`samp'"=="south" ren v2*_blackmig3539_share1940 *blackmig3539_share
		if "`samp'"=="dcourt" ren v2_blackmig3539_share1940 blackmig3539_share

		if "`level'"=="msa"{
			destring smsa, gen(msapmsa2000) 
		}
		
		preserve
			use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split`samptab'", clear
			keep `levelvar' GM GM_hat GM*raw GM*raw_pp GM*hat_raw GM*hat_raw_pp v*_blackmig3539_share reg* pop1940 bpop1940 mfg_lfshare1940 pop1970 bpop1970 mfg_lfshare1970
			ren vfull*_blackmig3539_share *blackmig3539_share
			foreach var of varlist GM* *blackmig3539_share mfg_lfshare1940{
				ren `var' `var'_totpop
			}
			
			tempfile totpop_insts
			save `totpop_insts'
		restore
		
		merge 1:1 `levelvar' using `totpop_insts', update nogen
		
		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist  cgoodman{

			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(1 3) nogen keepusing(n_`ds'_`level' b_`ds'_`level'1970 b_`ds'_`level'1940)
		}
		
		//merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
		
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
		
		
		foreach geog in land total{
			qui su frac_`geog' if GM_raw_pp < .,d
			g above_med_temp = frac_`geog'>=`r(p50)' if  GM_raw_pp < . 
			bys `levelvar' : egen above_med_`geog' = max(above_med_temp)
			drop above_med_temp
			
			qui su frac_`geog' if  GM_raw_pp_totpop < .,d
			g above_med_temp = frac_`geog'>=`r(p50)' if GM_raw_pp_totpop < . 
			bys `levelvar' : egen above_med_`geog'_totpop = max(above_med_temp)
			drop above_med_temp
		}
		
		if "`level'" == "cz"{
			merge 1:1 cz using "$DCOURT/data/crosswalks/original_130_czs"
			
			g dcourt = _merge==3
			drop _merge
			lab var dcourt "Derenoncourt Sample of 130 CZs"
			
			merge 1:1 cz using "$INTDATA/covariates/covariates.dta", keep(1 3) nogen
			merge 1:1 cz using "$INTDATA/census/maxcitypop", keep(1 3) nogen

		}
		// Missing dummies
		foreach var of varlist frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2{
			g `var'_m = `var'==.
			replace `var' = 0 if `var'==.
		}
		replace n_cgoodman_cz = 0 if n_cgoodman_cz==.
		replace b_cgoodman_cz1940 = 0 if b_cgoodman_cz1940==.
		replace b_cgoodman_cz1970 = 0 if b_cgoodman_cz1970==.
		// Adding labels

		foreach ds in  gen_muni schdist_ind all_local ngov3 gen_subcounty spdist   cgoodman  {
				local label : variable label n_`ds'_`level'
				lab var n_`ds'_`level' "New Govs, `label'"
				lab var b_`ds'_`level'1940 "Base Govs 1940, `label'"
				lab var b_`ds'_`level'1970 "Base Govs 1970, `label'"
				
				g b_`ds'_`level'1940_pc = b_`ds'_`level'1940/(pop1940/10000) 
				g b_`ds'_`level'1940_pcc = b_`ds'_`level'1940/(popc1940/10000) 
				g n_`ds'_`level'_pc = b_`ds'_`level'1970/(pop1970/10000) - b_`ds'_`level'1940/(pop1940/10000) 
				g n_`ds'_`level'_pcc = b_`ds'_`level'1970/(popc1970/10000) - b_`ds'_`level'1940/(popc1940/10000) 
				lab var n_`ds'_`level'_pc "New `label', P.C. (total)"
				lab var n_`ds'_`level'_pcc "New `label', P.C. (urban)"

		}
		
		lab var GM_raw_totpop "Percentage Change in Total Black Population"
		lab var GM_hat_raw_totpop "Predicted Percentage Change in Total Black Population"
		lab var GM_raw_pp_totpop "Percentage Point Change in Total Black Population"
		lab var GM_hat_raw_pp_totpop "Predicted Percentage Point Change in Total Black Population"
		lab var GM_totpop "Percentile Point Change in Total Black Population"
		lab var GM_hat_totpop "Predicted Percentile Point Change in Total Black Population"
		lab var GM_raw_pp "Percentage Point Change in Urban Black Population"
		lab var GM_hat_raw_pp "Predicted Percentage Point Change in Urban Black Population"
		lab var GM_raw "Percentage Change in Urban Black Population"
		lab var GM_hat_raw "Predicted Percentage Change in Urban Black Population"
		lab var GM "Percentile Change in Urban Black Population"
		lab var GM_hat "Predicted Percentile Change in Urban Black Population"
		
		lab var blackmig3539_share_totpop "Total Population Share of 1935-39 Black Migrants"
		lab var blackmig3539_share "Urban Population Share of 1935-39 Black Migrants"

	

		foreach y in 1940 1970{
			lab var bpop`y' "Total Black Population, `y'"
			lab var bpopc`y' "Urban Black Population, `y'"
			lab var pop`y' "Total Population, `y'"
			lab var popc`y' "Urban Population, `y'"
			lab var mfg_lfshare`y' "Share of LF employed in manufacturing, `y'"
		}
		
		lab var frac_land "Fraction of CZ land incorporated"
		lab var frac_total "Fraction of CZ area incorporated"
		cap lab var cz "Commuting Zone (1990)"
		cap lab var fips "County FIPS Code"
		

		lab var totfrac_in_main_city "Fraction of population in largest city"
		lab var urbfrac_in_main_city "Fraction of urban population in largest city"
		lab var n_wells "Number of Oil/Nat Gas Wells, 1940"
		lab var max_temp "Maximum Temperature, 1940"
		lab var min_temp "Minimum Temperature, 1940"
		lab var avg_temp "Average Temperature, 1940"
		lab var avg_precip "Average Precipitation, 1940"
		lab var has_port "Has Port, 1940"
		lab var coastal "Coastal"
		lab var transpo_cost_1920 "Average Transport Cost out of CZ, 1920 (Donaldson and Hornbeck)"
		lab var m_rr "Meters of Railroad, 1940"
		lab var m_rr_sqm2 "Meters of Railroad per Square Meter of Land, 1940"

		save "$CLEANDATA/`level'_pooled`outsamptab'", replace
		
		// Creating stacked version of data
		use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split`samptab'",clear
		
		rename *1940_1950 *1940
		rename *1950_1960 *1950
		rename *1960_1970 *1960
		
		ren vfull_* *
		ren vfull* *
		drop rm_* nt_* rmnt_* 

		foreach var of varlist GM* blackmig3539_share*{
				ren `var' totpop_`var'
		}
		
		
		
		// Dropping 1940-70 versions
		drop totpop_GM_raw totpop_GM_raw_pp totpop_GM_hat_raw totpop_GM_hat_raw_pp totpop_GM totpop_GM_hat

		preserve
			use "$DCOURT/data/GM_`level'_final_dataset_split`samptab'.dta", clear

			keep `levelvar' GM* popc???? bpopc???? mfg_lfshare* v2*blackmig3539_share* reg2 reg3 reg4  frac_all_upm*
			drop GM_hat0* GM_hat7r* GM_hat8*
			ren GM_hat2_* GM_hat_*
			ren v2_blackmig3539_share* blackmig3539_share*
			
			if "`samp'"=="south" ren v2*_blackmig3539_share* *_blackmig3539_share*

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
		
		
			
		//merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
		
	
	
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

		keep totpop_* GM_* frac_all_upm* mfg_lfshare* blackmig3539_share* `levelvar' reg2 reg3 reg4  n_*_`level'???? b_*_`level'????  bpop* pop*
		cap drop GM_hat0* GM_hat2* GM_hat1*  GM_hatr* GM_hat7r* GM_hat8* 
		cap drop totpop_blackmig3539_share
		local stubs 
		foreach ds in  gen_muni schdist_ind all_local ngov3 gen_subcounty spdist   cgoodman  {
			local lab`ds' : variable label n_`ds'_`level'1940
			local stubs `stubs' n_`ds'_`level' b_`ds'_`level'

		}
		if "`samp'"=="south"{
			foreach gm in rm nt rmnt  {
				local stubs `stubs' totpop_GM_`gm'_hat_raw_pp_ totpop_GM_`gm'_hat_raw_ tp_`gm'_blackmig3539_share
				drop totpop_GM_`gm'_hat_raw_pp totpop_GM_`gm'_hat_raw // dropping 1940-70 versions
			}
			foreach gm in rm nt rmnt rmsc scnt rmscnt {
				local stubs `stubs' GM_`gm'_hat_raw_pp_ `gm'_blackmig3539_share
			}
		}
			
		qui reshape long `stubs' frac_all_upm totpop_GM_ GM_ GM_hat_ totpop_GM_hat totpop_GM_raw_ totpop_GM_raw_pp_ totpop_GM_hat_raw_ totpop_GM_hat_raw_pp_ GM_raw_pp_ GM_hat_raw_pp_  mfg_lfshare totpop_blackmig3539_share blackmig3539_share bpop pop bpopc popc, i(`levelvar') j(decade)
		
		replace n_cgoodman_cz = 0 if n_cgoodman_cz==.
		replace b_cgoodman_cz = 0 if b_cgoodman_cz==.

		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist cgoodman {
			label var n_`ds'_`level' "`lab`ds''"

			g frac = b_`ds'_`level'/(pop/10000)
			g fracc = b_`ds'_`level'/(popc/10000)
			
			bys cz (decade) : g n_`ds'_`level'_L0_pc = frac[_n+1] - frac
			bys cz (decade) : g n_`ds'_`level'_L0_pcc = fracc[_n+1] - fracc
			
			g b_`ds'_`level'1940_pc = frac if decade == 1940
			g b_`ds'_`level'1940_pcc = fracc if decade == 1940

			bys cz (b_`ds'_`level'1940_pc) : replace b_`ds'_`level'1940_pc = b_`ds'_`level'1940_pc[1]
			bys cz (b_`ds'_`level'1940_pcc) : replace b_`ds'_`level'1940_pcc = b_`ds'_`level'1940_pcc[1]

			lab var n_`ds'_`level'_L0_pc "New `lab`ds'', P.C. (total)"
			lab var n_`ds'_`level'_L0_pcc "New `lab`ds'', P.C. (urban)"
		
			drop frac fracc
		}
		
		ren *_ *
		ren totpop_* *_totpop
		if "`samp'"=="south" ren tp_* *_totpop
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
		
		foreach geog in land total{
			qui su frac_`geog' if decade == 1940 & GM_raw_pp < .,d
			g above_med_temp = frac_`geog'>=`r(p50)' if decade == 1940 & GM_raw_pp < . 
			bys `levelvar' : egen above_med_`geog' = max(above_med_temp)
			drop above_med_temp
			
			qui su frac_`geog' if decade == 1940 & GM_raw_pp_totpop < .,d
			g above_med_temp = frac_`geog'>=`r(p50)' if decade == 1940 & GM_raw_pp_totpop < . 
			bys `levelvar' : egen above_med_`geog'_totpop = max(above_med_temp)
			drop above_med_temp
		}
		
	
	
	if "`level'"=="cz"{
		
		merge m:1 cz using "$DCOURT/data/crosswalks/original_130_czs"
			
		g dcourt = _merge==3
		drop _merge
		lab var dcourt "Derenoncourt Sample of 130 CZs"
		
		
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
	
	merge m:1 cz using "$INTDATA/covariates/covariates.dta", keep(1 3) nogen
	merge m:1 cz using "$INTDATA/census/maxcitypop", keep(1 3) nogen
	
	// Missing dummies
	foreach var of varlist frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2{
			g `var'_m = `var'==.
			replace `var' = 0 if `var'==.
	}
	
	// Adding labels
	lab var decade "Decade Start"
	
	foreach ds in  gen_muni schdist_ind all_local ngov3 gen_subcounty spdist   cgoodman  {
		  local label : variable label n_`ds'_`level'_L0
			lab var n_`ds'_`level'_L0 "New Govs, `label'"
			lab var b_`ds'_`level'_L0 "Base Govs, `label'"
	}
	
	lab var GM_raw_totpop "Percentage Change in Total Black Population"
	lab var GM_hat_raw_totpop "Predicted Percentage Change in Total Black Population"
	lab var GM_raw_pp_totpop "Percentage Point Change in Total Black Population"
	lab var GM_hat_raw_pp_totpop "Predicted Percentage Point Change in Total Black Population"
	lab var GM_raw_pp "Percentage Point Change in Urban Black Population"
	lab var GM_hat_raw_pp "Predicted Percentage Point Change in Urban Black Population"
	
	lab var mfg_lfshare "Share of LF employed in manufacturing"
	lab var blackmig3539_share_totpop "Total Population Share of 1935-39 Black Migrants"
	lab var blackmig3539_share "Urban Population Share of 1935-39 Black Migrants"

	lab var bpop "Total Black Population"
	lab var bpopc "Urban Black Population"
	lab var pop "Total Population"
	lab var popc "Urban Population"

	foreach y in 1940 1970{
		lab var bpop`y' "Total Black Population, `y'"
		lab var bpopc`y' "Urban Black Population, `y'"
		lab var pop`y' "Total Population, `y'"
		lab var popc`y' "Urban Population, `y'"
	}
	
	lab var frac_land "Fraction of CZ land incorporated"
	lab var frac_total "Fraction of CZ area incorporated"
	lab var cz "Commuting Zone (1990)"
	cap lab var fips "County FIPS Code"
		
	lab var totfrac_in_main_city "Fraction of population in largest city"
	lab var urbfrac_in_main_city "Fraction of urban population in largest city"
	lab var n_wells "Number of Oil/Nat Gas Wells, 1940"
	lab var max_temp "Maximum Temperature, 1940"
	lab var min_temp "Minimum Temperature, 1940"
	lab var avg_temp "Average Temperature, 1940"
	lab var avg_precip "Average Precipitation, 1940"
	lab var has_port "Has Port, 1940"
	lab var coastal "Coastal"
	lab var transpo_cost_1920 "Average Transport Cost out of CZ, 1920 (Donaldson and Hornbeck)"
	lab var m_rr "Meters of Railroad, 1940"
	lab var m_rr_sqm2 "Meters of Railroad per Square Meter of Land, 1940"
	
	save "$CLEANDATA/`level'_stacked`outsamptab'", replace
	}
}


