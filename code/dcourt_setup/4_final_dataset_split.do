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

		

		use "$RAWDATA/dcourt/clean_city_population_census_1940.dta", clear // 711 cities in non-South
		keep city citycode popc1940 bpopc1940 cz cz_name south
		
		merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keepusing(pop1940 bpop1970 bpop1960 pop1960 pop1970) 
		rename bpop1970  bpopc1970
		rename bpop1960 bpopc1960
		rename pop1960 popc1960
		rename pop1970 popc1970
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
		replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
		replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
		//keep if bpopc1970!=. & pop1940!=.
		keep if bpopc1970!=. & pop1940 != .
		drop pop1940 // the CCDB pop we filter on
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
		merge 1:1 city using "$INTDATA/dcourt/census_1950_racepop_cz", keepusing(pop bpop) nogen
		rename pop popc1950
		rename bpop bpopc1950
		
		drop if bpopc1940 ==. | bpopc1950 ==. | bpopc1960 ==. | bpopc1970 ==. | ///
						popc1940 ==. | popc1950 ==. | popc1960 ==. | popc1970 ==.
		keep if popc1940 >=25000 | popc1970>=25000
		drop *_merge
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*2. Merge in data for instrument.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%


		
		* Version 2 of the instrument: 
		*	1935-1940 black southern migrant location choice X total 1940-1970 Post-LASSO predicted net-migration for southern counties
		*	See Derenoncourt (2019) Appendix B.2 for more details: https://www.dropbox.com/s/58cv5fv1hsofau8/derenoncourt_2019_appendix.pdf?dl=0
		
		* 	See more here: https://www.cdc.gov/nchs/data/data_acces_files/NCHSUrbruralFileDocumentationInternet2.pdf
		
		merge 1:1 city using "$INTDATA/dcourt/instrument/city_crosswalked/2_black_prmig_1940_1970_wide_xw.dta"
				g samp_2 = _merge==3
				ren sumshares v2_sumshares

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
			rename `var' v2_`var'
		}
		rename totblackmigcity3539 v`v'_totblackmigcity3539
		
		
		
		
		keep *_proutmigpr*  popc1940 bpopc*  popc* *migcity3539   city city_original cz cz_name  samp_* *_sumshares citycode
		drop if popc1970==.
		save "$INTDATA/dcourt/GM_city_final_dataset_split.dta", replace
		sleep 1000
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*3. Construct measure of black urban pop change and instrument for black urban in-migration at CZ level.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		/* Generate measure of black urban in-migration at the CZ level. */
			use "$INTDATA/dcourt/GM_city_final_dataset_split.dta", clear
			
		
			collapse (sum) *_sumshares *_proutmigpr*  popc* bpopc*   *migcity3539 , by(cz)
				
			
		
			* Instrument by version
			* Version 0
			local base = 1940
			foreach d in 1950 1960 1970{
				
			* Actual black pop change in city
				g bc`base'_`d'=100*(bpopc`d'-bpopc`base')/popc`base'
				g bcpp`base'_`d'=100*((bpopc`d'/popc`d')-(bpopc`base'/popc`base'))

				
				* Versions 1, 2, 1940
				g v2_bc_pred`base'_`d'=100*v2_black_proutmigpr`d'/popc`base'
				
				g v2_blackmig3539_share`base'=100*v`v'_totblackmigcity3539/popc`base'

				
				
					
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
			
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*5. Create rank measure of shock. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*6. Finalize mechanism variables 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*6. Create regional dummies. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*7. Create additional 1940 controls. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			
			
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
		*8. Label key variables and save final dataset. 
		*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	rename bcpp* GM_raw_pp_*
	rename v2_bc_pred* GM_hat_raw_*
	keep cz GM_raw_pp_* GM_hat_raw_*
			
		save "$CLEANDATA/dcourt/GM_final_dataset_split.dta", replace
	

