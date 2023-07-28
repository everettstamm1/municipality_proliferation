/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

4. Assemble final dataset.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Select sample of cities using complete count 1940 and CCDB 1944-1977. 
	*2. Merge in data for instrument.
	*3. Construct measure of black urban pop change and instrument for black urban in-migration at CZ level.
	*4. Merge in all outcome variables, controls, and mechanism datasets.
	*5. Create rank measure of Great Migration shock. 
	*6. Save final dataset.
*first created: 08/23/2018
*last updated: 12/29/2019
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	



*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Select sample of cities using complete count 1940 census and CCDB 1944-1977.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	/* Load city population data constructed from complete count 1940 census */
	
	foreach samp in full dcourt {
		if "`samp'" == "dcourt" {
			local samptab = ""
			local varstubs2 = "2"
			
			use "$RAWDATA/dcourt/clean_city_population_census_1940.dta", clear // 711 cities in non-South
			merge 1:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta", keepusing(wpopc1940)  // add in white urban pop
			keep if _merge==3 | citycode == 910 /*butte, MT, correction later */ | citycode == 170 /* Amsterdam, NY,  correction later */
			drop _merge
			
		}
		if "`samp'" == "full" {
			local samptab = "_full"
			local varstubs2 = "2 2rm 2nt 2rmnt 2rmsc 2rmscnt  2scnt"
			
			use "$INTDATA/dcourt/clean_city_population_census_1940_full.dta", clear // 711 cities in non-South

		}
		ren popc1940 pop1940_census_full
		ren bpopc1940 bpop1940_census_full
		merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keepusing(bpop1970 bpop1960 nwhtpop1950 nwhtpop1960 pop1940 pop1950 pop1960 pop1970) 
		foreach var of varlist bpop1970 bpop1960 nwhtpop1950 nwhtpop1960 pop1940 pop1950 pop1960 pop1970{
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
		//rename bpop1970 bpopc1970 // rename so it is clear these numbers correspond to city populations
		//rename pop1970 popc1970 // rename so it is clear these numbers correspond to city populations
		
		/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
		Keep them in sample by retrieving 1970 black pop info from Census for these cities */
		replace bpop1970_ccdb=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace pop1970_ccdb=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace bpop1970_ccdb=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		replace pop1970_ccdb=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		keep if bpop1970_ccdb!=. & pop1940_ccdb!=.

		
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
		merge 1:1 city using "$INTDATA/dcourt/census_1950_1960_racepop_cz", keepusing(pop1950 pop1960 bpop1950 bpop1960 nwhtpop1950 nwhtpop1960 cz cz_name)
		foreach var of varlist pop1950 pop1960 bpop1950 bpop1960 nwhtpop1950 nwhtpop1960 {
			ren `var' `var'_census
		}
		ren _merge census_merge
		
		g popc1940 = pop1940_census_full
		g bpopc1940 = bpop1940_census_full
		
		g popc1950 = cond(pop1950_ccdb<.,pop1950_ccdb,pop1950_census)
		
		g adjust = bpop1950_census/nwhtpop1950_census
		g bpop1950_ccdb = nwhtpop1950_ccdb * adjust
		qui su adjust,d
		replace bpop1950_ccdb = nwhtpop1950_ccdb * `r(mean)' if bpop1950_ccdb==.
		g bpopc1950 = cond(bpop1950_ccdb<.,bpop1950_ccdb,bpop1950_census)
		drop adjust

		g popc1960 = pop1960_ccdb
		g bpopc1960 = bpop1960_ccdb
		
		g popc1970 = pop1970_ccdb
		g bpopc1970 = bpop1970_ccdb
		
		drop *_ccdb *_census*
		drop if bpopc1940 ==. | bpopc1950 ==. | bpopc1960 ==. | bpopc1970 ==. | ///
						popc1940 ==. | popc1950 ==. | popc1960 ==. | popc1970 ==.
		//keep if popc1940 >=25000 | popc1970>=25000
		drop *_merge
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
		* 	excluding the 42 major urban southern counties (NCHS-defined "central" counties of MSAs of 1 million or more population)
		* 	See more here: https://www.cdc.gov/nchs/data/data_acces_files/NCHSUrbruralFileDocumentationInternet2.pdf

		foreach v in `varstubs2'{
		merge 1:1 city using "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_prmig_1940_1970_wide_xw.dta"
				g samp_`v' = _merge==3

		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2 
		drop _merge
		
		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		foreach var of varlist black_proutmigpr*{
		if "`samp'"=="dcourt" replace `var'=0 if `var'==.
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
		merge 1:1 city using "$INTDATA/dcourt/instrument/city_crosswalked/`v'_white_actmig_1940_1970_wide_xw.dta", keepusing(totwhitemigcity3539 white_actoutmigact*)
		
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
		
		* Placebo versions of the instrument: 
		*	1935-1940 white southern migrant location choice X normally distributed random shocks,
		*	with mean 0 and variance 5, iterated 1000 times.

	/*
		forval i=1(1)1000{
		merge 1:1 city using  ${instrument}/city_crosswalked/rndmig/r`i'_black_prmig_1940_1940_wide_xw.dta 
		*keep if _merge==3
		
		/* Drop cities for which there's no hope of getting predictions for black pop in 
		1970 data for these cities. This set of cities will change depending on the 
		migration matrix used.*/
		drop if _merge==2 
		drop _merge
		
		/* Assume zero change in black pop for cities that black migrants did not move 
		to between 1935 and 1940. Results are robust to changing this criterion. 
		Uncomment "keep if _merge==3" and run again. */
		foreach var of varlist black_proutmigpr*{
		replace `var'=0 if `var'==.
		rename `var' vr`i'_`var'
		}
		rename totblackmigcity3539 vr`i'_totblackmigcity3539
		}

	*/
		
		
		keep *_proutmigpr* *_actoutmigact* *_residoutmigresid* popc1940 bpopc*  popc* *migcity3539 statefip citycode city city_original cz cz_name  wpopc1940 samp_*
		drop if popc1970==.
		save "$INTDATA/dcourt/GM_city_final_dataset_split`samptab'.dta", replace
		sleep 1000
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*3. Construct measure of black urban pop change and instrument for black urban in-migration at CZ level.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		/* Generate measure of black urban in-migration at the CZ level. */
		foreach level in cz {
			di "HERE"
			use "$INTDATA/dcourt/GM_city_final_dataset_split`samptab'.dta", clear
			if "`level'"=="cz"{
				local levelvar cz
			}
			else if "`level'"=="county"{
				merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(countyfip state_fips)
				destring countyfip, replace
				g fips = 1000*state_fips + countyfip
				drop state_fips countyfip
				local levelvar fips
			}
			else if "`level'"=="msa"{
				merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(smsa)
				local levelvar smsa
			}
		
			collapse (sum) *_proutmigpr* *_actoutmigact* *_residoutmigresid* popc* bpopc*   *migcity3539 , by(`levelvar')
				
			
		
			* Instrument by version
			* Version 0
			local base = 1940
			foreach d in 1950 1960 1970{
				* Actual black pop change in city
					g bc`base'_`d'=100*(bpopc`d'-bpopc`base')/popc`base'
					g bcpp`base'_`d'=100*(bpopc`d'/popc`d')-(bpopc`base'/popc`base')

				foreach v in "0"{
				g v`v'_bc_pred`base'_`d'=100*v`v'_black_actoutmigact`d'/popc`base'
				
				g v`v'_blackmig3539_share`base'=100*v`v'_totblackmigcity3539/popc`base'
				}
				
				* Versions 1, 2, 1940
				foreach v in `varstubs2'{
				g v`v'_bc_pred`base'_`d'=100*v`v'_black_proutmigpr`d'/popc`base'
				
				g v`v'_blackmig3539_share`base'=100*v`v'_totblackmigcity3539/popc`base'
				g v`v'_bcpp_pred`base'_`d'=100*((v`v'_black_proutmigpr`d'+bpopc`base')/(v`v'_black_proutmigpr`d'+ popc`base') - bpopc`base'/popc`base')

				}
				
				
				
				* Versions 7r
				foreach v in "7r"{
				g v`v'_bc_resid`base'_`d'=100*v`v'_black_residoutmigresid`d'/popc`base'
				
				g v`v'_blackmig3539_share`base'=100*v`v'_totblackmigcity3539/popc`base'
				}
				
				* Versions 8
				foreach v in "8"{

				g v`v'_wpopchange_pred`base'_`d'=100*v`v'_white_actoutmigact`d'/popc`base'
				
				g v`v'_whitemig3539_share`base'=100*v`v'_totwhitemigcity3539/popc`base'
				}
				
				* Placebo shocks
			/* not ready, finish later
				forval i=1(1)1000{
					g vr`i'_bc_pred1940_1970=100*vr`i'_black_proutmigpr/popc1940
					g vr`i'_bcpp_pred`base'_`d' = 100*(vr`i'_black_proutmigpr)
					g vr`i'_blackmig3539_share1940=100*vr`i'_totblackmigcity3539/popc1940
				}
				*/
					
				local base = `d'

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
			if "`level'"=="cz"{
				global datasets ///
					"$INTDATA/dcourt/clean_cz_snq_european_immigration_instrument.dta"  "$INTDATA/dcourt/clean_cz_industry_employment_1940_1970.dta"

			}
		
			//"$mobdata/clean_cz_mobility_1900_2015_split_`level'.dta" /// <- HISTORICAL & CONTEMPORARY MOBILITY OUTCOMES
			// "$population/clean_`level'_population_1940_1970.dta" //  <- POPULATION
			foreach dataset in "$datasets"{
			merge 1:1 `levelvar' using "`dataset'"
			drop if _merge==2
			drop _merge
			 
			}

			// Everett: We don't need this so it's only gonna reduce our sample size, dropping
			* Carter (1986) 1960s riots data shared only with author by Robert Margo and William Collins
			//cap merge 1:1 cz using "$incarceration/clean_cz_riots_1964_1971.dta" 
			//cap drop if _merge==2
			//cap drop _merge
			
			if "`level'"=="cz"{
				/* Get state and region info from cz-to-state_id-to-region crosswalk. */
					merge 1:1 cz using "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", keepusing(state_id region cz_name) keep (3) nogenerate
					replace cz_name="Louisville, KY" if cz==13101 // Fill in Louisville, KY name, which was missing.
				}
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*5. Create rank measure of shock. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			* OLS
			local base = 1940
			foreach d in 1950 1960 1970{
				xtile GM_`base'_`d' = bc`base'_`d', nq(100) 

				* Instrument by version
				* Version 0
				foreach v in "0"{	
				xtile GM_hat`v'_`base'_`d' = v`v'_bc_pred`base'_`d', nq(100) 
				}
				
				* Versions 1, 2, 1940
				foreach v in `varstubs2'{	
				xtile GM_hat`v'_`base'_`d' = v`v'_bc_pred`base'_`d', nq(100) 
				}
				
				
				* Versions 7r
				foreach v in "7r"{	
				xtile GM_hat`v'_`base'_`d' = v`v'_bc_resid`base'_`d', nq(100) 
				}	
				
				* Versions 8
				foreach v in "8" {	
				xtile GM_hat`v'_`base'_`d' = v`v'_wpopchange_pred`base'_`d', nq(100) 
				}
				local base = `d'
			}
				/*
				
			* Placebo shocks
			forval i=1(1)1000{	
				xtile GM_hatr`i' = vr`i'_bc_pred1940_1970, nq(100) 
			}
			*/
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*6. Finalize mechanism variables 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
			
			* Construct Bartik instrument for employment
			local sectorlist ag const fire gov man min nr rtl svc tcu wh

			* Construct Bartik shares: share of each industry located in CZ 
			foreach year in 1940 1970 {
				foreach sector in `sectorlist' {
					egen tot_emp_`sector'`year' = sum(emp_`sector'`year')
					gen empshare_`sector'`year' = emp_`sector'`year' / tot_emp_`sector'`year'
				}
			}
			/*
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
			g epopchange_1940_1970=empchange_1940_1970/pop1940
			g epopchange_1940_1970_pred=empchange1940_1970_pred/pop1940
			
			* Convert to percentiles to match functional form in rest of analysis
			xtile emp_hat = epopchange_1940_1970_pred, nq(100)
			xtile emp = epopchange_1940_1970, nq(100)
			
			* Remove unnecessary vars
			foreach sector in `sectorlist' {
				drop emp_`sector'*
			}	
		*/
			
				
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*6. Create regional dummies. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			tabulate region, gen(reg)	

		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*7. Create additional 1940 controls. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			
			
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*8. Label key variables and save final dataset. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		
			
			//la var frac_all_upm1940 "Edu. Upward Mobility 1940"
			la var v2_blackmig3539_share1940 "Black Southern Mig 1935-1940"
			la var reg2 "Midwest"
			la var reg3 "South"
			la var reg4 "West"	
			
			//la var GM_hat2 "$\hat{GM}$"
			//la var GM "GM"

			local base = 1940
			foreach d in 1950 1960 1970{
				ren bc`base'_`d' GM_raw_`base'_`d'
				ren bcpp`base'_`d' GM_raw_pp_`base'_`d'

				ren v2_bc_pred`base'_`d' GM_hat_raw_`base'_`d'
				ren v2_bcpp_pred`base'_`d' GM_hat_raw_pp_`base'_`d'


				if "`samp'"=="full"{
					foreach v in rm nt rmnt rmsc rmscnt scnt {					
						ren v2`v'_bcpp_pred`base'_`d' GM_`v'_hat_raw_pp_`base'_`d'
						ren v2`v'_bc_pred`base'_`d' GM_`v'_hat_raw_`base'_`d'
					}
				}
				local base = `d'
			}
			
			save "$CLEANDATA/dcourt/GM_`level'_final_dataset_split`samptab'.dta", replace
		}
	}
