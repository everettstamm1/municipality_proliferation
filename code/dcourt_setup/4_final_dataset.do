/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

4. Assemble final dataset.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*0. Create list of 130 CZs for later reference
	*1. Select sample of cities using complete count 1940 and CCDB 1944-1977. 
	*2. Merge in data for instrument.
	*3. Construct measure of black urban pop change and instrument for black urban in-migration at CZ level.
	*4. Merge in all outcome variables, controls, and mechanism datasets.
	*5. Create rank measure of Great Migration shock. 
	*6. Save final dataset.
*first created: 08/23/2018
*last updated: 12/29/2019
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

	// 0. Create list of 130 CZs for later reference
	use "$RAWDATA/dcourt/clean_city_population_census_1940.dta", clear // 711 cities in non-South
	

	merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keepusing(bpop1970 bpop1960 nwhtpop1950 nwhtpop1960 pop1940 pop1950 pop1960 pop1970)

	foreach var of varlist bpop1960 nwhtpop1950 nwhtpop1960{
		ren `var' `var'_ccdb
	}
	ren _merge ccdb_merge
	/* Keep cities large enough (25k+) to appear in CCDB in 1940 and 1970. Results are 
		robust to changing this criterion.*/
		rename bpop1970 bpopc1970 // rename so it is clear these numbers correspond to city populations
		rename pop1970 popc1970 // rename so it is clear these numbers correspond to city populations
		rename pop1950 popc1950 // rename so it is clear these numbers correspond to city populations

		/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
		Keep them in sample by retrieving 1970 black pop info from Census for these cities */
		replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		//replace wpopc1970= 23013 if city=="Butte, MT"
		
		replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		//replace wpopc1970= 25346 if city=="Amsterdam, NY"
		
		keep if  bpopc1970!=. & pop1940!=.
		
		/* The following non-southern cities are missing Black population data in 1970 though they have total population data for that year
		city
		Bolingbrook, IL
		Burbank, IL
		Burton, MI
		Farmington Hills, MI
		Grosse Pointe Woods, MI
		Irvine, CA
		Rancho Palos Verdes, CA
		Romulus, MI
		*/	
		
		drop if ccdb_merge==2 // Dropping cities in CCDB that do not appear in the 1940 Census list of non-southern cities, see analysis of non-matches above. 
		drop ccdb_merge
		
	merge 1:1 city using "$INTDATA/dcourt/census_1950_1960_racepop_cz", keepusing(pop1950 bpop1950 nwhtpop1950)
	foreach var of varlist pop1950 bpop1950 nwhtpop1950 {
		ren `var' `var'_census
	}
	ren _merge census_merge
	
	
	// Imputing Black urban population 1950 as close to CCDB data we can
	// First by multiplying CCDB nonwhite population by ratio of Black to nonwhite population from census
	g adjust = bpop1950_census/nwhtpop1950_census
	g bpop1950_ccdb = nwhtpop1950_ccdb * adjust
	// For cities with missing values of adjust, instead adjust by nationwide mean ratio
	qui su adjust,d
	replace bpop1950_ccdb = nwhtpop1950_ccdb * `r(mean)' if bpop1950_ccdb==.
	
	// If still missing, just use census urban Black population
	g bpopc1950 = cond(bpop1950_ccdb<.,bpop1950_ccdb,bpop1950_census)
	drop adjust

	drop *_ccdb *_census*
	
	//keep if popc1940 >=25000 | popc1970>=25000
	drop *_merge

	drop if bpopc1940 ==. | bpopc1970 ==. | ///
					popc1940 ==.  | popc1970 ==.
	keep if popc1940 >=25000 | popc1970>=25000
	keep cz cz_name
	duplicates drop
	save "$INTDATA/dcourt/original_130_czs", replace


*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Select sample of cities using complete count 1940 census and CCDB 1944-1977.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	/* Load city population data constructed from complete count 1940 census */
		local varstubs = ""
		local varstubs2 = "2 1940 r"
		
		use "$RAWDATA/dcourt/clean_city_population_census_1940.dta", clear // 711 cities in non-South
		merge 1:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta", keepusing(wpopc1940)  // add in white urban pop
		
		keep if _merge==3 | citycode == 910 /*butte, MT, correction later */ | citycode == 170 /* Amsterdam, NY,  correction later */
		drop _merge
		
		
		merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keepusing(bpop1970 bpop1960 nwhtpop1950 nwhtpop1960 pop1960 whtpop1970 pop1950 pop1940 pop1970)
		ren whtpop1970 wpopc1970
		foreach var of varlist bpop1960 nwhtpop1950 nwhtpop1960  pop1960{
		ren `var' `var'_ccdb
	}
			ren _merge ccdb_merge

		/*
		* Analysis of non-matches
		not matched                           789
					from master                       273  (_merge==1) // 273 cities from 1940 census city file do not match
					from using                        516  (_merge==2) // 516 cities from CCDB file do not match because they are Southern or they are non-Southern but do not appear in 1940 Census
		
		Here are the cities that do not appear in 1940 census, are non-southern, and have non-missing data for black pop in 1970: Boise city, ID; East Providence, RI: Huntington Park CA; West
		Haven CT; and Warwick, RI 
		
		Here are the cities that do not appear in 1940 census, are non-southern, and are missing data for black pop in 1970:
		Ardmore, PA
		Arlington, MA
		Arlington, VA
		Belmont, MA
		Belvedere, CA
		Bogota, NJ
		Brookline, MA
		Clarksburg, WV
		Drexel Hill, PA
		Haverford College, PA
		Newport, KY
		Secaucus, NJ
		Watertown, MA
		West Hartford, CT
		Woodbridge, NJ

			matched                               438  (_merge==3)
		
		*/
		
		
		
		/* Keep cities large enough (25k+) to appear in CCDB in 1940 and 1970. Results are 
		robust to changing this criterion.*/
		rename bpop1970 bpopc1970 // rename so it is clear these numbers correspond to city populations
		rename pop1970 popc1970 // rename so it is clear these numbers correspond to city populations
		rename pop1950 popc1950 // rename so it is clear these numbers correspond to city populations
		rename pop1960 popc1960 // rename so it is clear these numbers correspond to city populations
		rename bpop1960 bpopc1960 // rename so it is clear these numbers correspond to city populations
		/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
		Keep them in sample by retrieving 1970 black pop info from Census for these cities */
		replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace wpopc1970= 23013 if city=="Butte, MT"
		
		replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		replace wpopc1970= 25346 if city=="Amsterdam, NY"
		keep if  bpopc1970!=. & pop1940!=.
		/* The following non-southern cities are missing Black population data in 1970 though they have total population data for that year
		city
		Bolingbrook, IL
		Burbank, IL
		Burton, MI
		Farmington Hills, MI
		Grosse Pointe Woods, MI
		Irvine, CA
		Rancho Palos Verdes, CA
		Romulus, MI
		*/	
		
		drop if ccdb_merge==2 // Dropping cities in CCDB that do not appear in the 1940 Census list of non-southern cities, see analysis of non-matches above. 
		drop ccdb_merge
		
			
		// Imputing Black urban population 1950 using census data as close to CCDB data we can

		merge 1:1 city using "$INTDATA/dcourt/census_1950_1960_racepop_cz", keepusing(pop1950 bpop1950 nwhtpop1950) nogen
		foreach var of varlist pop1950 bpop1950 nwhtpop1950 {
			ren `var' `var'_census
		}
		
		
		// First by multiplying CCDB nonwhite population by ratio of Black to nonwhite population from census
		g adjust = bpop1950_census/nwhtpop1950_census
		g bpop1950_ccdb = nwhtpop1950_ccdb * adjust
		// For cities with missing values of adjust, instead adjust by nationwide mean ratio
		qui su adjust,d
		replace bpop1950_ccdb = nwhtpop1950_ccdb * `r(mean)' if bpop1950_ccdb==.
		
		// If still missing, just use census urban Black population
		g bpopc1950 = cond(bpop1950_ccdb<.,bpop1950_ccdb,bpop1950_census)
		drop adjust

		drop *_ccdb *_census*
		
		//keep if popc1940 >=25000 | popc1970>=25000
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*2. Merge in data for instrument.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		
		* Version 0 of the instrument: 1935-1940 black southern migrant location choice X observed total 1940-1970 net-migration for southern counties
		foreach v in "0"{
		merge 1:1 city using "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_actmig_1940_1970_wide_xw.dta"
		
		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2 
		drop _merge
		
		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		foreach var of varlist black_actoutmigact*{
		replace `var'=0 if `var'==.
		rename `var' v`v'_`var'
		}
		rename totblackmigcity3539 v`v'_totblackmigcity3539
		}

		* Version 1 of the instrument: 
		*	1935-1940 black southern migrant location choice X total 1940-1970 predicted net-migration for southern counties
		*	Original Boustan (2010) variables for prediction. 
		*	See Boustan (2016) replication files for more details: https://scholar.princeton.edu/lboustan/data-books#ch4.
		
		* Version 2 of the instrument: 
		*	1935-1940 black southern migrant location choice X total 1940-1970 Post-LASSO predicted net-migration for southern counties
		*	See Derenoncourt (2019) Appendix B.2 for more details: https://www.dropbox.com/s/58cv5fv1hsofau8/derenoncourt_2019_appendix.pdf?dl=0
		
		* Version 1940 of the instrument: 
		*	1940 black southern-born state of birth X total 1940-1970 Post-LASSO predicted net-migration for southern states

		* Version r of the instrument: 
		*	1935-1940 black southern migrant location choice X total 1940-1970 Post-LASSO predicted net-migration for southern counties
		* 	excluding the 42 major urban southern counties (NCHS-defined “central” counties of MSAs of 1 million or more population)
		* 	See more here: https://www.cdc.gov/nchs/data/data_acces_files/NCHSUrbruralFileDocumentationInternet2.pdf

		foreach v in `varstubs2'{
		merge 1:1 city using  "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_prmig_1940_1970_wide_xw.dta"

		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		g samp_`v' = _merge==3
		drop if _merge==2 
		drop _merge
		
		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */

		foreach var of varlist black_proutmigpr*{
			replace `var'=0 if `var'==.
			rename `var' v`v'_`var'
		}
		rename totblackmigcity3539 v`v'_totblackmigcity3539
		}
	
		* Version 7r of the instrument: 
		*	1935-1940 black southern migrant location choice X total observed 1940-1970 net-migration for southern counties,
		*	residualized on southern state fixed effects.
		foreach v in "7r" {
		merge 1:1 city using  "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_residmig_1940_1970_wide_xw.dta", keepusing(totblackmigcity3539 black_residoutmigresid*)
		*keep if _merge==3
		
		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2 
		drop _merge
		
		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		
		foreach var of varlist black_residoutmigresid*{
		replace `var'=0 if `var'==.
		rename `var' v`v'_`var'
		}
		rename totblackmigcity3539 v`v'_totblackmigcity3539
		}
		
		* Version 8 of the instrument: 
		*	1935-1940 white southern migrant location choice X total observed 1940-1970 white net-migration for southern counties,
		foreach v in "8" {
		merge 1:1 city using  "$INTDATA/dcourt/instrument/city_crosswalked/`v'_white_actmig_1940_1970_wide_xw.dta", keepusing(totwhitemigcity3539 white_actoutmigact*)
		
		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2 
		drop _merge

		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		
		foreach var of varlist white_actoutmigact*{
		replace `var'=0 if `var'==.
		rename `var' v`v'_`var'
		}
		rename totwhitemigcity3539 v`v'_totwhitemigcity3539
		}
		
		* Version 80 of the instrument: 
		*	1935-1940 black southern migrant location choice X total observed 1940-1970 black net-migration for southern counties,
		foreach v in "80" {
		merge 1:1 city using  "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_actmig_1940_1970_wide_xw.dta", keepusing(totblackmigcity3539 black_actoutmigact*)
		
		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2 
		drop _merge

		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		
		foreach var of varlist black_actoutmigact*{
		replace `var'=0 if `var'==.
		rename `var' v`v'_`var'
		}
		rename totblackmigcity3539 v`v'_totblackmigcity3539
		}
		
		* Placebo versions of the instrument: 
		*	1935-1940 white southern migrant location choice X normally distributed random shocks,
		*	with mean 0 and variance 5, iterated 1000 times.

		
		forval i=1(1)1000{
		qui merge 1:1 city using  "$INTDATA/dcourt/instrument/city_crosswalked/rndmig/r`i'_black_prmig_1940_1940_wide_xw.dta" 
		*keep if _merge==3
		
		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		qui drop if _merge==2 
		qui drop _merge
		
		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		foreach var of varlist black_proutmigpr*{
		qui replace `var'=0 if `var'==.
		qui rename `var' vr`i'_`var'
		}
		qui rename totblackmigcity3539 vr`i'_totblackmigcity3539
		}
		
		/*
		* Northern CZ measure of 1940 southern county upward mobility: 
		*	1935-1940 black southern migrant location choice X total observed 1940-1970 net-migration for southern counties,
		*	residualized on southern state fixed effects.	
		foreach v in "m" {
		
		if "`v'"=="m"{
		local svar smob
		}
			
		local group "black"
		
		merge 1:1 city using "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_`svar'_1940_1940_wide_xw.dta"
		* keep if _merge==3
		
		/* Drop cities for which there's no hope of getting predictions for black southern mob in 1970
		for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2
		drop _merge

		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		foreach var of varlist `group'_proutmigpr*{
		egen mean`svar'_`var'=mean(`var')
		replace `var'=mean`svar'_`var' if `var'==.
		replace `var'=popc1940*`var'
		rename `var' v`v'_`var'
		}
		}	
		
		*/
		g wpopc4070 = wpopc1970 - wpopc1940
		g nbpopc4070 = (popc1970 - bpopc1970) - (popc1940 - bpopc1940)
		keep *_proutmigpr* *_actoutmigact* *_residoutmigresid* nbpopc4070 popc1940 bpopc1940 popc1970 popc1960 bpopc1950 bpopc1960 popc1950 bpopc1970 *migcity3539 statefip citycode city city_original cz cz_name wpopc1940 wpopc1970 samp_*
		drop if popc1970==.
		
		save "$INTDATA/dcourt/GM_city_final_dataset`samptab'.dta", replace
		
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*3. Construct measure of black urban pop change and instrument for black urban in-migration at CZ level.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	
		
			use "$INTDATA/dcourt/GM_city_final_dataset.dta", clear
			local levelvar cz
			local varstubs = ""
			local varstubs2 = "2 1940 r"
			collapse (sum) *_proutmigpr* *_actoutmigact* *_residoutmigresid* nbpopc4070  popc* bpopc* *migcity3539 wpopc1940 wpopc1970 (max) samp_*, by(cz)
			
			g bpopc4070 = bpopc1970-bpopc1940

			* Actual black pop change in city
			g bc1940_1970=100*(bpopc4070)/popc1940
			g bcpp1940_1970=100*((bpopc1970/popc1970)-(bpopc1940/popc1940))
			
			g wcpp1940_1970=100*((wpopc1970/popc1970)-(wpopc1940/popc1940))

			* Instrument by version
			* Version 0
			foreach v in "0"{
			g v`v'_bc_pred1940_1970=100*v`v'_black_actoutmigact/popc1940
			
			g v`v'_blackmig3539_share1940=100*v`v'_totblackmigcity3539/popc1940
			}
			
			* Versions 1, 2, 1940
			foreach v in `varstubs2' {
			g v`v'_bc_pred1940_1970=100*v`v'_black_proutmigpr/popc1940
			
			g v`v'_blackmig3539_share1940=100*v`v'_totblackmigcity3539/popc1940
			
			g v`v'_bcpp_pred1940_1970=100*((v`v'_black_proutmigpr+bpopc1940)/(popc1940 + v`v'_black_proutmigpr) - bpopc1940/popc1940)



			}
			
			
			* Versions 7r
			foreach v in "7r"{
			g v`v'_bc_resid1940_1970=100*v`v'_black_residoutmigresid/popc1940
			
			g v`v'_blackmig3539_share1940=100*v`v'_totblackmigcity3539/popc1940
			g v`v'_bcpp_pred1940_1970=100*((v`v'_black_residoutmigresid+bpopc1940)/(popc1940 + v`v'_black_residoutmigresid) - bpopc1940/popc1940)

			}
			
			* Versions 8
			foreach v in "8"{

			g v`v'_wc_pred1940_1970=100*v`v'_white_actoutmigact/popc1940
			g v`v'_wcpp_pred1940_1970=100*((v`v'_white_actoutmigact+wpopc1940)/(popc1940+ v`v'_white_actoutmigact) - wpopc1940/popc1940)

			g v`v'_whitemig3539_share1940=100*v`v'_totwhitemigcity3539/popc1940
			}
				
		
			* Placebo shocks
			forval i=1(1)1000{
				g vr`i'_bc_pred1940_1970 = 100*vr`i'_black_proutmigpr/popc1940

			g vr`i'_bcpp_pred1940_1970=100* ((vr`i'_black_proutmigpr+bpopc1940)/(popc1940 +  vr`i'_black_proutmigpr) - bpopc1940/popc1940)

			}
		
/*
			* Northern CZ measure of 1940 southern county upward mobility
			foreach v in "m"{
			
			if "`v'"=="m"{
			local svar smob
			}
				
			local group "black"
			
			g v`v'_black`svar'1940=v`v'_`group'_proutmigpr/popc1940
			}
			*/
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*4. Merge in all datasets.
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			
			// White migration instrument
			merge 1:1 cz using "$INTDATA/dcourt/clean_cz_snq_european_immigration_instrument.dta", keep(1 3) nogen
			// mfg_lfshare1940
			merge 1:1 cz using "$INTDATA/dcourt/clean_cz_industry_employment_1940_1970.dta", keep(1 3) nogen

			
			
			/* Get state and region info from cz-to-state_id-to-region crosswalk. */
			merge 1:1 cz using "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", keepusing(state_id region cz_name) keep (3) nogenerate
			replace cz_name="Louisville, KY" if cz==13101 // Fill in Louisville, KY name, which was missing.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*5. Create rank measure of shock. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			* OLS
			xtile GM = bc1940_1970, nq(100) 

			* Instrument by version
			* Version 0
			foreach v in "0"{	
			xtile GM_`v'_hat = v`v'_bc_pred1940_1970, nq(100) 
			}
			
			* Versions 1, 2, 1940
			foreach v in `varstubs2'{	
			xtile GM_`v'_hat = v`v'_bc_pred1940_1970, nq(100) 
			}
		
			
			* Versions 7r
			foreach v in "7r"{	
			xtile GM_`v'_hat = v`v'_bc_resid1940_1970, nq(100) 
			}	
			
			* Versions 8
			foreach v in "8" {	
			xtile GM_`v'_hat = v`v'_wc_pred1940_1970, nq(100) 
			}
			
		
			* Placebo shocks
			forval i=1(1)1000{	
			xtile GM_r`i'_hat = vr`i'_bc_pred1940_1970, nq(100) 
			}	
			
			
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*6. Finalize mechanism variables 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
			/*
			* Construct Bartik instrument for employment
			local sectorlist ag const fire gov man min nr rtl svc tcu wh

			* Construct Bartik shares: share of each industry located in CZ 
			foreach year in 1940 1970 {
				foreach sector in `sectorlist' {
					egen tot_emp_`sector'`year' = sum(emp_`sector'`year')
					gen empshare_`sector'`year' = emp_`sector'`year' / tot_emp_`sector'`year'
				}
			}
			
			* Construct Bartik shock using national leave-one-out growth rates for each industry
			foreach sector in `sectorlist' {
				gen tot_LOO_`sector'1970 =  tot_emp_`sector'1970-emp_`sector'1970[_n]
				gen tot_LOO_`sector'1940 =  tot_emp_`sector'1940-emp_`sector'1940[_n]
				gen gr_LOO_`sector'1940_1970 = tot_LOO_`sector'1970-tot_LOO_`sector'1940
			}

			g empchange_1940_1970=emp_tot1970-emp_tot1940
			g empchange1940_1970_pred = 0
			foreach sector in `sectorlist' {
				replace empchange1940_1970_pred = empchange1940_1970_pred + empshare_`sector'1940*gr_LOO_`sector'1940_1970
			}
			
			* Construct actual and predicted change in employment-to-population (epop) ratio (growth)
			g epopchange_1940_1970=empchange_1940_1970/popc1940
			g epopchange_1940_1970_pred=empchange1940_1970_pred/popc1940
			
			* Convert to percentiles to match functional form in rest of analysis
			xtile emp_hat = epopchange_1940_1970_pred, nq(100)
			xtile emp = epopchange_1940_1970, nq(100)
			
			* Remove unnecessary vars
			foreach sector in `sectorlist' {
				drop emp_`sector'*
			}	
			
			if "`level'"=="cz"{

				* Construct European migration shock rank
				xtile eur_mig = wt_instmig_avg, nq(100) 

				* Construct quartiles of black population
				//xtile bpopquartile = bpopshare1940, nq(4)
				
				* Standardize all mechanism vars	
				qui ds *murder_rate*
				foreach var in `r(varlist)'{
				egen `var'_st = std(`var')
				}
				
				qui ds *polpht* *polshare* *polexppc* *fireexppc* *fireshare* *edushare* *eduexpps* 
				foreach var in `r(varlist)'{
				egen `var'_st = std(`var')
				}

				qui ds *prv*
				foreach var in `r(varlist)'{
				egen `var'_st = std(`var')
				}
				
				qui ds c_whtpop_share*
				foreach var in `r(varlist)'{
				egen `var'_st = std(`var')
				}		

				qui ds *jail_rate* *prison_rate*
				foreach var in `r(varlist)'{
				egen `var'_st = std(`var')
				}

				egen wt_racial_animus_st = std(wt_racial_animus)
				
				* Generate standardized mech vars for post 1970 averages
				
				* Govt spending
				foreach cat in "pol" "fire" "hlthhosp" "sani" "rec" "edu"{
				* Exp share
				egen `cat'share_mean1972_2002=rowmean(`cat'share1972 `cat'share1977 `cat'share1982 `cat'share1987 `cat'share1992 `cat'share1997 `cat'share2002 )
				egen `cat'share_mean1972_2002_st=std(`cat'share_mean1972_2002)	
				}
				
				* Per cap
				foreach cat in "pol" "fire" "hlthhosp" "sani" "rec"{
				egen `cat'exppc_mean1972_2002=rowmean(`cat'exppc1972 `cat'exppc1977 `cat'exppc1982 `cat'exppc1987 `cat'exppc1992 `cat'exppc1997 `cat'exppc2002 )
				egen `cat'exppc_mean1972_2002_st=std(`cat'exppc_mean1972_2002)
				}
				
				* Per pupil edu expenditures
				egen eduexpps_mean1972_2002=rowmean(eduexpps1972 eduexpps1977 eduexpps1982 eduexpps1987 eduexpps1992 eduexpps1997 eduexpps2002 )
				egen eduexpps_mean1972_2002_st=std(eduexpps_mean1972_2002)
				
				* Murder
				egen murder_mean1931_1943= rowmean(murder_rate1931 murder_rate1943 )
				egen murder_mean1931_1943_st=std(murder_mean1931_1943)
				egen murder_mean1977_2002= rowmean(murder_rate1977 murder_rate1982 murder_rate1987 murder_rate1992  murder_rate1997 murder_rate2002 )
				egen murder_mean1977_2002_st=std(murder_mean1977_2002)
				
				* Incarceration
				egen total_prison_mean1983_2000=rowmean(total_prison_rate1983 total_prison_rate1984 total_prison_rate1985 total_prison_rate1986 total_prison_rate1987 total_prison_rate1988 total_prison_rate1989 total_prison_rate1990 total_prison_rate1991 total_prison_rate1992 total_prison_rate1993 total_prison_rate1994 total_prison_rate1995 total_prison_rate1996 total_prison_rate1997 total_prison_rate1998 total_prison_rate1999 total_prison_rate2000)
				egen total_prison_mean1983_2000_st=std(total_prison_mean1983_2000)

				* White private school rates
				egen w_prv_mean1970_2000 = rowmean(w_prv_elemhs_share1970 w_prv_elemhs_share1980 w_prv_elemhs_share1990 w_prv_elemhs_share2000)
				egen w_prv_mean1970_2000_st = std(w_prv_mean1970_2000)

				* Black private school rates
				egen b_prv_mean1970_2000 = rowmean(b_prv_elemhs_share1970 b_prv_elemhs_share1980 b_prv_elemhs_share1990 b_prv_elemhs_share2000)
				egen b_prv_mean1970_2000_st = std(b_prv_mean1970_2000)
				
				* Private school rates
				egen prv_mean1970_2000 = rowmean(prv_elemhs_share1970 prv_elemhs_share1980 prv_elemhs_share1990 prv_elemhs_share2000)
				egen prv_mean1970_2000_st = std(prv_mean1970_2000)
				
				* Standardize remaining mechanism variables
				* Racial segregation
				egen cs_race_theil2000_st= std(cs_race_theil_2000)
				
				* Income segregation
				egen cs00_seg_inc_st=std(cs00_seg_inc)
				
				* Commute times
				egen frac_traveltime_lt15_st = std(frac_traveltime_lt15)

				* Wallace votes
				drop wallace_per_white_vote
				
			*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
			*6. Clean mobility outcome data
			*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

				* Construct change in black men's upward mobility variable
				* Create z-score of 1940 measure of black boys' educational upward mobility
				egen mean_bmedu1940=mean(frac_blackm_upm1940)
				egen sd_bmedu1940=sd(frac_blackm_upm1940)
				g bmedu1940_zscore=(frac_blackm_upm1940-mean_bmedu1940)/sd_bmedu1940
				
				* Create z-score of contemporary measure of black men's income upward mobility
				egen mean_bminc1940=mean(kir_black_male_p50)
				egen sd_bminc1940=sd(kir_black_male_p50)
				g bminc1940_zscore=(kir_black_male_p50-mean_bminc1940)/sd_bminc1940

				* Construct change in z-score
				g mobchangeb=bminc1940_zscore-bmedu1940_zscore
				
				* Standardize change in z-score
				egen mobchangeb_st=std(mobchangeb)
				
				* Construct racial gap in income upward mobility outcomes by CZ 
				foreach p in "25" "50" "75"{
					g racegap2015_p`p'_cz=kfr_white_pooled_p`p'2015*100-kfr_black_pooled_p`p'2015*100
					}
			}
			*/
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*6. Create regional dummies. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			tabulate region, gen(reg)	
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*7. Create additional 1940 controls. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			
			merge 1:1 cz using "$RAWDATA/dcourt/clean_cz_population_1940_1970", keep(1 3) keepusing(pop1940 pop1950 pop1960 pop1970) nogen
			
				*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
			*8. Label key variables and save final dataset. 
			*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		
			
			//la var frac_all_upm1940 "Edu. Upward Mobility 1940"
			la var v2_blackmig3539_share1940 "Black Southern Mig 1935-1940"
			la var reg2 "Midwest"
			la var reg3 "South"
			la var reg4 "West"	
			
		
			la var GM_2_hat "$\hat{GM}$"
			la var GM "GM"
			
			ren GM_2_hat GM_hat
			ren bc1940_1970 GM_raw
			ren bcpp1940_1970 GM_raw_pp
			ren wcpp1940_1970 WM_raw_pp
			
			ren v2_bc_pred1940_1970 GM_hat_raw
			ren v2_bcpp_pred1940_1970 GM_hat_raw_pp
			
			ren v8_wc_pred1940_1970 GM_8_hat_raw
			ren v8_wcpp_pred1940_1970 GM_8_hat_raw_pp
			
			
			forv i=1(1)1000{	
			ren vr`i'_bcpp_pred1940_1970 GM_hat_raw_r`i'
			}	
			
			foreach v in 1940 r 7r{
				ren v`v'_bcpp_pred1940_1970 GM_`v'_hat_raw_pp
			}
			
			
			
			
			save "$CLEANDATA/dcourt/GM_cz_final_dataset.dta", replace
		
	
