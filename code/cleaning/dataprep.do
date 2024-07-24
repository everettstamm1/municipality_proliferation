
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
		collapse (sum) Pop, by(`levelvar' year)

		ren Pop `level'pop
		
		reshape wide `level'pop, i(`levelvar') j(year)
		save "$INTDATA/cog_populations/`level'pop", replace
	restore
	
	replace year = year+2
	
	/*
	// preclean ccdb urbanpop data (from dcourt)
	preserve
		use "$DCOURT/data/GM_`level'_final_dataset_split.dta", clear
		keep `levelvar' popc1940 popc1950 popc1960 popc1970
		ren popc* `level'pop*
		save "$INTDATA/dcourt_populations/`level'pop", replace
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
			g n_muni_`level'90_00 = n2002 - n1992
			g n_muni_`level'00_10 = n2012 - n2002

			ren n1942 b_muni_`level'1940
			ren n1952 b_muni_`level'1950
			ren n1962 b_muni_`level'1960
			ren n1972 b_muni_`level'1970
			ren n1982 b_muni_`level'1980
			ren n1992 b_muni_`level'1990
			ren n2002 b_muni_`level'2000
			ren n2012 b_muni_`level'2010

			label var b_muni_`level'1940 "Base `lab' 1940"
			label var b_muni_`level'1950 "Base `lab' 1950"
			label var b_muni_`level'1960 "Base `lab' 1960"
			label var b_muni_`level'1970 "Base `lab' 1970"
			label var b_muni_`level'1980 "Base `lab' 1980"
			label var b_muni_`level'1990 "Base `lab' 1990"
			label var b_muni_`level'2000 "Base `lab' 2000"
			label var b_muni_`level'2010 "Base `lab' 2010"

			label var n_muni_`level'40_50 "`lab'"
			label var n_muni_`level'50_60 "`lab'"
			label var n_muni_`level'60_70 "`lab'"
			label var n_muni_`level'70_80 "`lab'"
			label var n_muni_`level'80_90 "`lab'"
			label var n_muni_`level'90_00 "`lab'"
			label var n_muni_`level'00_10 "`lab'"

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
	replace yr_incorp = yr_incorp-2
	keep `levelvar' yr_incorp muniname
	local lab: variable label yr_incorp
	
	g n = yr_incorp>=1940 & yr_incorp<=1970
	forv d=1900(10)2010{
		local step = `d'+10
		
		g n`d' = yr_incorp<`d'

	}


	collapse (sum) n*, by(`levelvar')
	rename n n_muni_`level'
	
	rename n19?? b_muni_`level'19??
	rename n20?? b_muni_`level'20??

	

	label var b_muni_`level'1940 "Base `lab' 1940"
	label var b_muni_`level'1950 "Base `lab' 1950"
	label var b_muni_`level'1960 "Base `lab' 1960"
	label var b_muni_`level'1970 "Base `lab' 1970"
	label var b_muni_`level'1980 "Base `lab' 1980"
	label var b_muni_`level'1990 "Base `lab' 1990"
	label var b_muni_`level'2000 "Base `lab' 2000"
	label var b_muni_`level'2010 "Base `lab' 2010"

	label var n_muni_`level' "`lab'"

	
	ren *muni* *cgoodman*
	save "$INTDATA/counts/cgoodman_`level'", replace
	

	foreach samp in dcourt {
		if "`samp'" == "dcourt" {
			local samptab = ""
			local outsamptab = ""

		}
		if "`samp'" == "south" {
			local samptab = "_full"
			local outsamptab = "_south"
		}
		// Pooled
		
		use "$CLEANDATA/dcourt/GM_`level'_final_dataset.dta", clear
		g ne_ut = state_id == 31 | state_id == 49
		if "`samp'"=="south" keep `levelvar' GM GM_hat GM*raw GM*raw_pp GM*hat_raw GM*hat_raw_pp v2*blackmig3539_share1940 popc* bpopc* mfg_lfshare1940 reg*    GM_r_hat_raw_pp GM_1940_hat_raw_pp GM_7r_hat_raw_pp v2_black_proutmigpr wt_instmig_avg wt_instmig_avg_pp samp_* WM_raw_pp ne_ut v8_whitemig3539_share1940 pop1940 pop1950 pop1960 pop1970 *_sumshares GM_hat_r*
		if "`samp'"=="dcourt" keep `levelvar' GM GM_hat GM*raw GM*raw_pp GM*hat_raw GM*hat_raw_pp v2*blackmig3539_share1940 popc* bpopc* mfg_lfshare1940 reg*    GM_r_hat_raw_pp GM_1940_hat_raw_pp GM_7r_hat_raw_pp v2_black_proutmigpr wt_instmig_avg wt_instmig_avg_pp WM_raw_pp ne_ut v8_whitemig3539_share1940 pop1940 pop1950 pop1960 pop1970  *_sumshares GM_hat_r*
		


		if "`samp'"=="south" ren v2*_blackmig3539_share1940 *blackmig3539_share
		if "`samp'"=="dcourt" ren v2_blackmig3539_share1940 blackmig3539_share

		if "`level'"=="msa"{
			destring smsa, gen(msapmsa2000) 
		}
		
		
		merge m:1 cz using "$INTDATA/dcourt/original_130_czs"
			
		g dcourt = _merge==3
		drop _merge
		lab var dcourt "Derenoncourt Sample of 130 CZs"
		// Fixing sample flags
		if "`samp'"=="south"{
			foreach s in 2 2rm 2nt 2rmnt 2rmsc 2scnt 2rmscnt{
				replace samp_`s' = (dcourt==1 | samp_`s'==1)
			}
		}
		
		/*
		preserve
			use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split`samptab'_totalpop", clear
			keep `levelvar' GM GM_hat GM*raw GM*raw_pp GM*hat_raw GM*hat_raw_pp v*_blackmig3539_share reg* bpop1940 mfg_lfshare1940 bpop1970 mfg_lfshare1970 pop1950
			ren vfull*_blackmig3539_share *blackmig3539_share
			foreach var of varlist GM* *blackmig3539_share mfg_lfshare1940{
				ren `var' `var'_totpop
			}
			
			tempfile totpop_insts
			save `totpop_insts'
		restore
		
		
		merge 1:1 `levelvar' using `totpop_insts', update nogen
		*/
		foreach ds in gen_muni schdist_ind all_local gen_subcounty spdist gen_town schdist schdist_ind_m1 schdist_m2{

			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(1 3) nogen keepusing(n_`ds'_`level' b_`ds'_`level'1970 b_`ds'_`level'1960 b_`ds'_`level'1940 b_`ds'_`level'1950 b_`ds'_`level'2010)
		}
		merge 1:1 `levelvar' using "$INTDATA/counts/cgoodman_`level'", keep(1 3) nogen keepusing(n_cgoodman_`level' b_cgoodman_`level'*)

		//merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
		
		if "`level'"=="cz"{
			preserve
				use "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", clear
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
			foreach tail in 90 95 {
				qui su frac_`geog' if GM_raw_pp < .,d
				g temp = frac_`geog'>=`r(p`tail')' if GM_raw_pp < . 
				bys `levelvar' : egen p`tail'_`geog' = max(temp)
				drop temp
			}
		}
		
		if "`level'" == "cz"{
			
			merge 1:1 cz using "$INTDATA/covariates/covariates.dta", keep(1 3) nogen
			merge 1:1 cz using "$INTDATA/census/maxcitypop", keep(1 3) nogen
			ren cz czone
			merge 1:1 czone using "$INTDATA/census/home_values", keep(1 3) nogen
			merge 1:1 czone using "$INTDATA/census/incomes", keep(1 3) nogen
			ren czone cz
		}
		// Missing dummies
		foreach var of varlist frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city m_rr m_rr_sqm_land m_rr_sqm_total{
			g `var'_m = `var'==.
			replace `var' = 0 if `var'==.
		}
		
		
		replace n_cgoodman_cz = 0 if n_cgoodman_cz==.
		replace b_cgoodman_cz1940 = 0 if b_cgoodman_cz1940==.
		replace b_cgoodman_cz1960 = 0 if b_cgoodman_cz1960==.
		replace b_cgoodman_cz1970 = 0 if b_cgoodman_cz1970==.
		replace b_cgoodman_cz1950 = 0 if b_cgoodman_cz1950==.
		replace b_cgoodman_cz2010 = 0 if b_cgoodman_cz2010==.

		merge 1:1 cz using "$INTDATA/census/urb_pop_2010.dta", keep(1 3) nogen keepusing(pop2010)

		
		preserve
			use "$INTDATA/census/cz_urbanization_1900_1930", clear
			keep pop cz decade
			reshape wide pop, i(cz) j(decade)
			tempfile oldpops
			save `oldpops'
		restore
		
		merge 1:1 cz using `oldpops', keep(1 3) nogen
		
		// Adding labels
		foreach ds in  gen_muni schdist_ind all_local gen_subcounty spdist  gen_town cgoodman schdist schdist_ind_m1 schdist_m2{
				local label : variable label n_`ds'_`level'
				lab var n_`ds'_`level' "New Govs, `label'"
				lab var b_`ds'_`level'1940 "Base Govs 1940, `label'"
				lab var b_`ds'_`level'1970 "Base Govs 1970, `label'"
				
				g b_`ds'_`level'1940_pc = b_`ds'_`level'1940/(pop1940/10000) 
				g b_`ds'_`level'1950_pc = b_`ds'_`level'1950/(pop1950/10000) 
				g b_`ds'_`level'1960_pc = b_`ds'_`level'1960/(pop1960/10000) 
				g b_`ds'_`level'1970_pc = b_`ds'_`level'1970/(pop1970/10000) 

				g b_`ds'_`level'1940_pcc = b_`ds'_`level'1940/(popc1940/10000)
				g b_`ds'_`level'1970_pcc = b_`ds'_`level'1970/(popc1970/10000) 

				
				g n1_`ds'_`level'_pc = (pop1970/10000)/b_`ds'_`level'1970 - (pop1940/10000)/b_`ds'_`level'1940

				g n_`ds'_`level'_pc = b_`ds'_`level'1970/(pop1970/10000) - b_`ds'_`level'1940/(pop1940/10000) 
				g n2_`ds'_`level'_pc = b_`ds'_`level'1970/(pop1970/10000) - b_`ds'_`level'1950/(pop1950/10000) 
				g ld_`ds'_`level'_pc = b_`ds'_`level'2010/(pop2010/10000) - b_`ds'_`level'1940/(pop1940/10000) 

				g n_`ds'_`level'_pcc = b_`ds'_`level'1970/(popc1970/10000) - b_`ds'_`level'1940/(popc1940/10000) 
				g n2_`ds'_`level'_pcc = b_`ds'_`level'1970/(popc1970/10000) - b_`ds'_`level'1950/(popc1950/10000) 
				
				g n_`ds'_`level'_ld = log(b_`ds'_`level'1970) - log(b_`ds'_`level'1940)
				

				g l_b_`ds'_`level'1940 = log(b_`ds'_`level'1940)
				g l_b_`ds'_`level'1950 = log(b_`ds'_`level'1950)
				g l_b_`ds'_`level'1960 = log(b_`ds'_`level'1960)
				g l_b_`ds'_`level'1970 = log(b_`ds'_`level'1970)

				//g n3_`ds'_`level'_pc = (b_`ds'_`level'- b_`ds'_`level'1940)/(pop1940/10000) 
				lab var n_`ds'_`level'_pc "New `label', P.C. (total)"
				lab var n_`ds'_`level'_pcc "New `label', P.C. (urban)"
				lab var n2_`ds'_`level'_pcc "New `label', P.C. (urban) 1950-70"
				lab var ld_`ds'_`level'_pc "New `label', P.C. (urban) 1940-2010"

		}
		
		forv y=1940(10)1970{
			g l_pop`y' = log(pop`y')
			g l_popc`y' = log(popc`y')
		}
		
		// Pretrends, cgoodman only
		g n10_cgoodman_`level'_pc = b_cgoodman_cz1910/(pop1910/10000) -  b_cgoodman_cz1900/(pop1900/10000)
		g n20_cgoodman_`level'_pc = b_cgoodman_cz1920/(pop1920/10000) -  b_cgoodman_cz1910/(pop1910/10000)
		g n30_cgoodman_`level'_pc = b_cgoodman_cz1930/(pop1930/10000) -  b_cgoodman_cz1920/(pop1920/10000)
		g n40_cgoodman_`level'_pc = b_cgoodman_cz1940/(pop1940/10000) -  b_cgoodman_cz1930/(pop1930/10000)
		g pre_cgoodman_`level'_pc = b_cgoodman_cz1940/(pop1940/10000) -  b_cgoodman_cz1910/(pop1910/10000)
		
		
		lab var GM_raw_pp "Percentage Point Change in Urban Black Population"
		lab var GM_hat_raw_pp "Predicted Percentage Point Change in Urban Black Population"
		lab var GM_raw "Percentage Change in Urban Black Population"
		lab var GM_hat_raw "Predicted Percentage Change in Urban Black Population"
		lab var GM "Percentile Change in Urban Black Population"
		lab var GM_hat "Predicted Percentile Change in Urban Black Population"
		
		lab var blackmig3539_share "Urban Population Share of 1935-39 Black Migrants"

	

		foreach y in 1940 1970{
			//lab var bpop`y' "Total Black Population, `y'"
			lab var bpopc`y' "Urban Black Population, `y'"
			lab var pop`y' "Total Population, `y'"
			lab var popc`y' "Urban Population, `y'"
			//lab var mfg_lfshare`y' "Share of LF employed in manufacturing, `y'"
		}
		
		lab var frac_land "Fraction of CZ land incorporated"
		lab var frac_total "Fraction of CZ area incorporated"
		lab var p90_total "Above 90th percentile area incorporated"
		lab var p95_total "Above 95th percentile area incorporated"
		lab var p90_land "Above 90th percentile land incorporated"
		lab var p95_land "Above 95th percentile land incorporated"
		
		cap lab var cz "Commuting Zone (1990)"
		cap lab var fips "County FIPS Code"
		

		lab var totfrac_in_main_city "Fraction of population in largest city"
		lab var n_wells "Number of Oil/Nat Gas Wells, 1940"
		lab var max_temp "Maximum Temperature, 1940"
		lab var min_temp "Minimum Temperature, 1940"
		lab var avg_temp "Average Temperature, 1940"
		lab var avg_precip "Average Precipitation, 1940"
		lab var has_port "Has Port, 1940"
		lab var coastal "Coastal"
		lab var transpo_cost_1920 "Average Transport Cost out of CZ, 1920"
		lab var m_rr "Meters of Railroad, 1940"
		lab var m_rr_sqm_land "Meters of Railroad per Square Meter of Land, 1940"
		lab var m_rr_sqm_total "Meters of Railroad per Square Meter of Area, 1940"
		lab var frac_total "Fraction of area incorporated"
		lab var coastal "Coastal CZ" 
		lab var avg_precip "Average precipitation" 
		lab var avg_temp "Average temperature"
		
		
		lab var n10_cgoodman_cz_pc  "New municipalities per capita, 1900-10"
		lab var n20_cgoodman_cz_pc  "New municipalities per capita, 1910-20"
		lab var n30_cgoodman_cz_pc  "New municipalities per capita, 1920-30"
		lab var n40_cgoodman_cz_pc  "New municipalities per capita, 1930-40"
		lab var pre_cgoodman_cz_pc "New municipalities per capita, 1910-40"
		
		forv i=2/5{
			g pop1940_`i' = pop1940^`i'
			g popc1940_`i' = popc1940^`i'

		}
		
		merge 1:1 `level' using "$INTDATA/census/maxcitypop_ccdb", keep(1 3) nogen
		merge 1:1 `level' using "$INTDATA/census/maxcitypop_2010", keep(1 3) nogen

		// Total Fraction in main city outcomes, giving them unintuitive names so they can be ran properly in the table creation code, ignore the "n" and "pc"
		g b_totfrac_cz1940_pc = 100* (maxcitypop1940/pop1940)
		g n_totfrac_cz_pc = 100*((maxcitypop1970/pop1970) - (maxcitypop1940/pop1940))
		g n2_totfrac_cz_pc = 100*((maxcitypop1970/pop1970) - (maxcitypop1950/pop1950))
		g ld_totfrac_cz_pc = 100*((maxcitypop2010/pop2010) - (maxcitypop1940/pop1940))
		g n_totfrac_cz_ld = log(maxcitypop2010) - log(maxcitypop1940)
		g l_b_totfrac_cz1940 = log(maxcitypop1940/pop1940)
		g l_b_totfrac_cz1970 = log(maxcitypop1970/pop1970)

		// Adding measure of enclosedness
		preserve	
			import delimited using "$CLEANDATA/other/length_enclosed.csv", clear
			duplicates drop
			keep cz total_length
			tempfile length
			save `length'
		restore
		
		merge 1:1 cz using `length', assert(3) nogen

		preserve 
			import delimited using "$DATA/qgis/enclosedness/enclosed_1940.csv", clear
			keep cz_2 cz_2_2 len
			g cz = cond(mi(cz_2), cz_2_2, cz_2) 
			collapse (sum) len, by(cz)
			ren len enclosed1940
			tempfile enclosed1940
			save `enclosed1940'
		restore
		
		merge 1:1 cz using `enclosed1940', keep(1 3) nogen
		replace enclosed1940 = 0 if mi(enclosed1940)
		preserve 
			import delimited using "$DATA/qgis/enclosedness/enclosed_1970.csv", clear
			keep cz_2 cz_2_2 len
			g cz = cond(mi(cz_2), cz_2_2, cz_2) 
			collapse (sum) len, by(cz)
			ren len enclosed1970
			tempfile enclosed1970
			save `enclosed1970'
		restore
		
		merge 1:1 cz using `enclosed1970', keep(1 3) nogen
		replace enclosed1970 = 0 if mi(enclosed1970)
		
		g prop_enclosed1940 = enclosed1940/total_length
		g prop_enclosed1970 = enclosed1970/total_length
		
		g change_enclosed4070 = (enclosed1970 - enclosed1940)/(total_length - enclosed1940)
		
		// New York causing problems but clearly fully enclosed by 1940
		replace prop_enclosed1940 = 1 if cz==19400
		replace prop_enclosed1970 = 1 if cz==19400
		replace change_enclosed4070 = 1 if cz == 19400
		foreach s of varlist *_sumshares{
		    g `s'_total = `s'/(pop1940/10000)
			g `s'_urban = `s'/(popc1940/10000)
		}
		
		lab var v2_sumshares_urban "Sum of shares control"

		// Pick School District Version
		if $schdist_version == 1{
			ren *schdist_ind_m1* *temporary*

			drop *schdist_ind*
			ren *temporary* *schdist_ind*
		}
		else if $schdist_version == 2{

			ren *schdist_m2* *temporary*

			drop *schdist_ind*
			ren *temporary* *schdist_ind*
		}
		
		// Add total black pop
		preserve
			use "$INTDATA/census/cz_race_data.dta", clear
			keep year cz black 
			keep if year >= 1940 & year <= 1970
			ren black bpop
			reshape wide bpop, i(cz) j(year)
			tempfile bpop
			save `bpop'
		restore
		
		merge 1:1 cz using `bpop', keep(3) nogen
		
		preserve
			import excel using "$CLEANDATA/other/touching_munis.xlsx", clear first
			g touching40 = yr_ncrp<=1940
			g touching70 = yr_ncrp<=1970
			collapse (sum) touching40 touching70, by(cz)
			g touching_diff = touching70 - touching40
			tempfile touching 
			save `touching'
		restore
		
		merge 1:1 cz using `touching', assert(1 3)
		
		replace touching40 = 0 if _merge == 1
		replace touching70 = 0 if _merge == 1
		replace touching_diff = 0 if _merge == 1
		drop _merge
		save "$CLEANDATA/`level'_pooled`outsamptab'", replace
		
		/*
		// Creating stacked version of data
		use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split`samptab'_totalpop",clear
		
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
			use "$CLEANDATA/dcourt/GM_`level'_final_dataset_split`samptab'", clear
			keep `levelvar' GM* popc???? bpopc???? mfg_lfshare* v2*blackmig3539_share* reg2 reg3 reg4  
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
		

		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist gen_town cgoodman{
			merge 1:1 `levelvar' using "$INTDATA/counts/`ds'_`level'", keep(1 3) nogen
			 
		}
		
		
			
		//merge 1:1 `levelvar' using "$INTDATA/cog_populations/`level'pop", keep(3) nogen
		
	
	
		rename *1940_1950 *1940
		rename *1950_1960 *1950
		rename *1960_1970 *1960
		

		keep totpop_* GM_*  mfg_lfshare* blackmig3539_share* `levelvar' reg2 reg3 reg4  n_*_`level'???? b_*_`level'????  bpop* pop*
		cap drop GM_hat0* GM_hat2* GM_hat1*  GM_hatr* GM_hat7r* GM_hat8* 
		cap drop totpop_blackmig3539_share
		local stubs 
		foreach ds in  gen_muni schdist_ind all_local ngov3 gen_subcounty spdist gen_town  cgoodman  {
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
			
		qui reshape long `stubs' totpop_GM_ GM_ GM_hat_ totpop_GM_hat totpop_GM_raw_ totpop_GM_raw_pp_ totpop_GM_hat_raw_ totpop_GM_hat_raw_pp_ GM_raw_pp_ GM_hat_raw_pp_  mfg_lfshare totpop_blackmig3539_share blackmig3539_share bpop pop bpopc popc, i(`levelvar') j(decade)
		
		
		
		// Bringing in 1900-30 total and urban populations
		merge 1:1 decade `levelvar' using "$INTDATA/census/`level'_urbanization_1900_1930", update nogen 
		
		replace n_cgoodman_cz = 0 if n_cgoodman_cz==.
		replace b_cgoodman_cz = 0 if b_cgoodman_cz==.

		foreach ds in gen_muni schdist_ind all_local ngov3 gen_subcounty spdist cgoodman gen_town {
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
		
		merge m:1 cz using "$INTDATA/dcourt/original_130_czs"
			
		g dcourt = _merge==3
		drop _merge
		lab var dcourt "Derenoncourt Sample of 130 CZs"
		
		
		preserve
			use "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", clear
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
	
	
	merge m:1 cz using "$RAWDATA/dcourt/clean_cz_population_density_1940.dta", keepusing(pop_density1940) keep(1 3) nogen
	//replace b_cgoodman_cz2010 = 0 if b_cgoodman_cz2010==.
	g urban_share1940 = popc1940/pop1940
	gen ln_pop_dens1940= log(pop_density1940)
	save "$CLEANDATA/`level'_stacked`outsamptab'", replace
	*/
	}
}


