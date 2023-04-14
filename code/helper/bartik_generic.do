/* 
July 12, 2018
This code constructs three types of datasets related to the shift share instrument: 
an origin-destination matrix, shift shares, and shift shares interacted with 
outmigration rates. */

/* Required preliminaries

	1. Set max variable memory:
	clear all
	set maxvar 120000
	
	2. Define globals:
	
	global groups black white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global destination_id city
	global destination_id_code city_code
	global weights_data "$data/instrument/180331_boustan_predict_mig.dta"
	global weight_types act pr
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$data/instrument/shares" 
	global sharesXweights_dir "$data/instrument" 
	
	3. Import starting dataset
*/

	foreach group in $groups{
	
		/* Restrict sample to origin locations of interest and group of interest. */
		keep if $origin_sample == 1
		keep if `group'==1
		
		egen total_`group'$origin_id = total(`group'),by($origin_id)	
		egen total_`group'$destination_id = total(`group'), by($destination_id)
		
		
		keep if $dest_sample == 1
			
		/* Collapse data to destination county X origin county level */
		collapse (sum) $groups (mean) total_* , by($origin_id $destination_id)
		
		gen `group'$origin_id=`group'/total_`group'$origin_id
		
		/***** Save the origin-destination matrix as an intermediate dataset. *****/	
		save "$INTDATA/bartik/${version}_od_matrix_`group'_$start_year.dta", replace

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Construct destination-origin county transition matrix. Save long at o-d level, wide at destination level to analyze shares, and wide at origin levels to create mig figures.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	
		/* Construct predicted in-migration using the actual mig weights and the 
		predicted mig weights. */
		
		use "$INTDATA/bartik/${version}_od_matrix_`group'_$start_year.dta", clear
		
		/* Keep only necessary 
		vars for construction of matrix */
		
		keep `group'$origin_id $origin_id $destination_id total_`group'$destination_id
		tostring $origin_id, replace
		
		/* Make sure there are no duplicate origins. */
		quietly bysort $destination_id $origin_id: gen dup= cond(_N==1,0,_n)  
		tab dup
		drop if dup>0
		drop dup
		
		/* Reshape the dataset as wide at the destination level. Number of variables is # of origins plus 1. */	
		reshape wide `group'$origin_id total_`group'$destination_id, i($destination_id) j($origin_id) string

		foreach var of varlist `group'$origin_id*{
			replace `var'=0 if `var'==.
		}
		
		/***** Save wide version at destination level as dta file. *****/

		save "$INTDATA/bartik/${version}_`group'$origin_id$start_year.dta", replace

		drop total_`group'$destination_id*

		/***** Save wide version at origin level as dta file. *****/
		
		reshape long `group'$origin_id, i($destination_id) j($origin_id) string
			
		reshape wide `group'$origin_id, i($origin_id) j( $destination_id) 
		
		save "$INTDATA/bartik/${version}_wide_`group'$origin_id$start_year.dta", replace

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3. Create two wide datasets at city level: one with all share X weight X year vars and the total for each year and overall total and one with the total for each year and overall total.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	
		foreach weight_type in $weight_types{ // Actual migration and predicted migration ("act" and "pr")
			
			use "$INTDATA/bartik/${version}_wide_`group'$origin_id$start_year.dta", clear
			merge 1:m $origin_id using  "$weights_data", keep (3) nogenerate
			
			foreach var of varlist `group'$origin_id*{
				*replace `weight_type'$weight_var = -`weight_type'$weight_var // Turn outflows into inflows <-  INSTEAD: DO THIS WHERE YOU CREATE THE MIGRATION DATASET
				gen shX`weight_type'_`var'=`var'*`weight_type'$weight_var
				drop if shX`weight_type'_`var'==. // Drop if mig data not available <-- NEED TO LOOK INTO WHY SOME OBS ARE MISSING. IS IT THIS WAY IN ORIGINAL MIGRATION DATA?
				}

			local varlist $origin_id year shX* // Keep only necessary vars
			keep `varlist'
			quietly bysort $origin_id year: gen dup= cond(_N==1,0,_n)  
			tab dup
			drop if dup>0 // AGAIN, NEED TO LOOK INTO WHY THIS IS HAPPENING. WHERE ARE THE MISSING VALUES COMING IN--IN THE MIGRATION DATA? 48203 51037 AND 54041 ARE THE DUPLICATES
			
			reshape long shX`weight_type'_`group'$origin_id, i($origin_id year) j($destination_id)
			reshape wide shX`weight_type'_`group'$origin_id, i($destination_id year) j($origin_id) string
			
			rename *`group'$origin_id* **
			
			reshape wide shX*, i($destination_id) j(year)	
			
			/* Create total inmig var for cities. */
			egen totshX`weight_type'=rowtotal(shX`weight_type'*) 
			replace totshX`weight_type'=-1*totshX`weight_type' // Turn outflows into inflows
			
			foreach var of varlist shX`weight_type'*{
				replace `var'=-1*`var' // Turn outflows into inflows
			}

			/* Create yearly inmig var for cities. */
			local end_year = $start_year + 10*$panel_length
			local lag_start_year=$start_year + 10
			forval year=`lag_start_year'(10)`end_year'{
				egen totshX`weight_type'`year'=rowtotal(shX`weight_type'*`year')
			}
			
			/***** Save one dataset with ALL vars and one with just the yearly totals and overall total, all wide at the city level. *****/
			
			save "$INTDATA/bartik/${version}_`group'_`weight_type'$weight_var$origin_id$start_year`end_year'_all_wide.dta", replace
			keep $destination_id totshX`weight_type'*
			rename totshX* `group'_`weight_type'$weight_var*
			save "$INTDATA/bartik/${version}_`group'_`weight_type'$weight_var$origin_id$start_year`end_year'_collapsed_wide.dta", replace
		}
	}
