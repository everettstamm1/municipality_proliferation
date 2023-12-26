/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

3. Construct versions of shift-share instrument.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Version 0: Observed southern county net-migration.
	*2. Version 1: Original Boustan (2010) predicted southern county net-migration.
	*3. Version 2: Post-LASSO prediction of southern county net-migration.
	*4. Version 1940: 1940 southern state of birth shares.
	*5. Version 7r: Within state southern mig variation, observed.
	*6. Version 8: White southern migration.
	*7. Version r: Non-urban migration. 
	*8. Version r1-r1000: Placebo migration shocks.
	*9. Version m: Northern measure of 1940 southern county upward mobility.
	*10. Crosswalk city identifiers for each instrument's datasets.
*first created: 12/30/2019
*last updated:  01/16/2020
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Observed southern county net-migration.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/1_boustan_predict_mig.dta"
	global version 0
	global weight_types act // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*2. Original Boustan (2010) predicted southern county net-migration.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/1_boustan_predict_mig.dta"
	global version 1
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3. Post-LASSO prediction of southern county net-migration.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
		
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*4. 1940 southern state of birth shares.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

* Note: Needs to be run on server for space issues
	local years =  "1940"
	foreach year in `years'{
	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_state_fips
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/3_lasso_boustan_predict_mig_state.dta"
	global version `year'
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$RAWDATA/dcourt/clean_IPUMS_`year'_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	}		
		
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*5. Within state southern mig variation, observed
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/3_residstate_act_mig.dta"
	global version 7r
	global weight_types resid // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*6. White southern migration.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups white // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/5_white_mig.dta"
	global version 8
	global weight_types act // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
		
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*7. Non-urban migration.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/rur_boustan_predict_mig.dta"
	global version r
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*8. Placebo migration shocks.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
/* Derenoncourt doesn't set a seed here so I'm copying her outputs into $RAWDATA/dcourt/rndmig
	forval i=1(1)1000{      	
	use	$xwalks/county1940_crosswalks.dta, clear
	g rndmig`i'=rnormal(0,sqrt(5))
	
	rename fips_str origin_fips
	rename rndmig`i' proutmig
	g year=1940
	
	keep origin_fips year proutmig
	
	tempfile rndmig`i'1940
	
	save `rndmig`i'1940'
	
	cap mkdir "$data/instrument/rndmig
	cap mkdir "$data/instrument/shares/rndmig

	clear all
	set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "`rndmig`i'1940'"
	global version r`i'
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 0
	global shares_dir "$data/instrument/shares/rndmig" 
	global sharesXweights_dir "$data/instrument/rndmig" 
	
	use "$RAWDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta, clear
		
	do "$CODE/helper/bartik_generic.do
	}

*/
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*9. Northern measure of 1940 southern county upward mobility.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Mobility
	use	"$RAWDATA/dcourt/clean_county_edu_upm_1940.dta", clear
	
	g frac_black_upm=black_upm/black_n
	rename fips_str origin_fips
	rename frac_black_upm proutmig
	g year=1940
	
	keep origin_fips year proutmig
	
	save "$INTDATA/dcourt/instrument/mobility1940.dta", replace

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/instrument/mobility1940.dta"
	global version m
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 0
	global shares_dir "$data/instrument/shares" 
	global sharesXweights_dir "$data/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$bartik/bartik_sum_to_one.do"

	
	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3a. Post-LASSO prediction of southern county net-migration, Rural migrants only
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
/* No longer used do to data concerns
	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample_rural
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2rm
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3b. Post-LASSO prediction of southern county net-migration, Rural migrants only, southern cities allowed
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample_rural
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample_allcities
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2rmsc
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3c. Post-LASSO prediction of southern county net-migration, Rural migrants only, southern cities allowed, Nonsouthern texas
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample_rural_notx
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample_allcities
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2rmscnt
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3d. Post-LASSO prediction of southern county net-migration, Nonsouthern texas
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample_notx
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample_tx
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2nt
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3e. Post-LASSO prediction of southern county net-migration, Nonsouthern texas, southern cities allowed
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample_notx
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample_allcities
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2scnt
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3f. Post-LASSO prediction of southern county net-migration, Nonsouthern texas, rural migrants only
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	clear all
	//set maxvar 120000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample_rural_notx
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample_tx
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version 2rmnt
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 3
	global shares_dir "$INTDATA/dcourt/shares" 
	global sharesXweights_dir "$INTDATA/dcourt/instrument" 
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear
		
	do "$CODE/helper/bartik_generic.do"
	*/
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*10. Clean and standardize city names and output final instrument measures at the city-level
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	* Version 0
	foreach v in "0"{
	
		local origincode origin_fips
		if `v'>1000{
		local origincode origin_state_fips
		}
		
		use "$INTDATA/dcourt/bartik/`v'_black`origincode'1940.dta", clear
		
		order black* total*
		egen totblackmigcity3539=rowmean(total_blackcity*)
		sum totblackmigcity3539
		
		drop total* black*
		save "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", replace
		
		use "$INTDATA/dcourt/bartik/`v'_black_actoutmig`origincode'19401970_collapsed_wide.dta", clear
		merge 1:1 city using "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/instrument/`v'_black_actmig_1940_1970_wide.dta", replace
	
		use "$INTDATA/dcourt/instrument/`v'_black_actmig_1940_1970_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
		//A - fix spelling and formatting variations
		split city, p(,) g(part)
		replace city = proper(part1) + "," + upper(part2) 
		drop part1 part2
			
		*** Initial cleaning done. Save at this point.
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_actmig_1940_1970_wide_preprocessed.dta", replace
		
		use "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_actmig_1940_1970_wide_preprocessed.dta", clear
		g city_original=city
			
		replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
		replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
		replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
		replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
		replace city = "Norristown, PA" if city == "Norristown Borough, PA"
		replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
		replace city = "Jamestown, NY" if city == "Jamestown , NY"
		replace city = "Kensington, PA" if city == "Kensington,"
		replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
		replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
		replace city = "DuBois, PA" if city == "Du Bois, PA"
		replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
		replace city = "McKeesport, PA" if city == "Mckeesport, PA"
		replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
		replace city = "Lafayette, IN" if city == "La Fayette, IN"
		replace city = "Schenectady, NY" if city == "Schenectedy, NY"
		replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
		replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
		replace city = "New Kensington, PA" if city == "Kensington, PA"
	
		//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
		//B1 - the following cities overlap with their subsitutes
		*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
		replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
		replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
	
		//B2 - the following cities just share a border with their subsitutes but do not overlap
		replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
		replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
		replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
	
		//B3 - the following cities do not share a border with their substitutes but are within a few miles
		replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
		replace city = "Wallington, NJ" if city == "Nutley, NJ" 
		replace city = "Short Hills, NJ" if city == "South Orange, NJ"
		replace city = "Lafayette, IN" if city == "Lafayette, IL"
		   
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"    
		*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_actmig_1940_1970_wide_xw.dta", replace
	}

	* Versions 1, 2, 1940	
	foreach v in "1" "2" /*"2rm" "2nt" "2rmnt" "2rmsc" "2rmscnt"  "2scnt" */ "1940" "r"{
	
		local origincode origin_fips
	
		if "`v'"=="1940" {
		local origincode origin_state_fips
		}
		

		use "$INTDATA/dcourt/bartik/`v'_black`origincode'1940.dta", clear
		
		order black* total*
		egen totblackmigcity3539=rowmean(total_blackcity*)
		sum totblackmigcity3539
		
		drop total* black*
		save "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", replace
		
		use "$INTDATA/dcourt/bartik/`v'_black_proutmig`origincode'19401970_collapsed_wide.dta", clear
		merge 1:1 city using "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/instrument/`v'_black_prmig_1940_1970_wide.dta", replace
	
		use "$INTDATA/dcourt/instrument/`v'_black_prmig_1940_1970_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
			//A - fix spelling and formatting variations
			split city, p(,) g(part)
			replace city = proper(part1) + "," + upper(part2) 
			drop part1 part2
		
		*** Initial cleaning done. Save at this point.
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_prmig_1940_1970_wide_preprocessed.dta", replace
		
		use "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_prmig_1940_1970_wide_preprocessed.dta", clear
		g city_original=city
		
		replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
		replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
		replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
		replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
		replace city = "Norristown, PA" if city == "Norristown Borough, PA"
		replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
		replace city = "Jamestown, NY" if city == "Jamestown , NY"
		replace city = "Kensington, PA" if city == "Kensington,"
		replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
		replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
		replace city = "DuBois, PA" if city == "Du Bois, PA"
		replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
		replace city = "McKeesport, PA" if city == "Mckeesport, PA"
		replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
		replace city = "Lafayette, IN" if city == "La Fayette, IN"
		replace city = "Schenectady, NY" if city == "Schenectedy, NY"
		replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
		replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
		replace city = "New Kensington, PA" if city == "Kensington, PA"
	
		//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
		//B1 - the following cities overlap with their subsitutes
		*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
		replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
		replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
	
		//B2 - the following cities just share a border with their subsitutes but do not overlap
		replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
		replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
		replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
	
		//B3 - the following cities do not share a border with their substitutes but are within a few miles
		replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
		replace city = "Wallington, NJ" if city == "Nutley, NJ" 
		replace city = "Short Hills, NJ" if city == "South Orange, NJ"
		replace city = "Lafayette, IN" if city == "Lafayette, IL"
	   
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"    
		*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_prmig_1940_1970_wide_xw.dta", replace
	}

	foreach v in "7r" {
		
		local origincode origin_fips
		
		use "$INTDATA/dcourt/bartik/`v'_black`origincode'1940.dta", clear
		
		order black* total*
		egen totblackmigcity3539=rowmean(total_blackcity*)
		sum totblackmigcity3539
		
		*egen totblackmig3539=sum(totblackmigcity3539)
		drop total* black*
		save "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", replace
		
		use "$INTDATA/dcourt/bartik/`v'_black_residoutmig`origincode'19401970_collapsed_wide.dta", clear
		merge 1:1 city using "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/instrument/`v'_black_residmig_1940_1970_wide.dta", replace
		
		use "$INTDATA/dcourt/instrument/`v'_black_residmig_1940_1970_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
		//A - fix spelling and formatting variations
		split city, p(,) g(part)
		replace city = proper(part1) + "," + upper(part2) 
		drop part1 part2
		
		*** Initial cleaning done. Save at this point.
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_residmig_1940_1970_wide_preprocessed.dta", replace
		
		use "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_residmig_1940_1970_wide_preprocessed.dta", clear
		g city_original=city
		
		replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
		replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
		replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
		replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
		replace city = "Norristown, PA" if city == "Norristown Borough, PA"
		replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
		replace city = "Jamestown, NY" if city == "Jamestown , NY"
		replace city = "Kensington, PA" if city == "Kensington,"
		replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
		replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
		replace city = "DuBois, PA" if city == "Du Bois, PA"
		replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
		replace city = "McKeesport, PA" if city == "Mckeesport, PA"
		replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
		replace city = "Lafayette, IN" if city == "La Fayette, IN"
		replace city = "Schenectady, NY" if city == "Schenectedy, NY"
		replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
		replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
		replace city = "New Kensington, PA" if city == "Kensington, PA"
	
		//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
		//B1 - the following cities overlap with their subsitutes
		*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
		replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
		replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
	
		//B2 - the following cities just share a border with their subsitutes but do not overlap
		replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
		replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
		replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
	
		//B3 - the following cities do not share a border with their substitutes but are within a few miles
		replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
		replace city = "Wallington, NJ" if city == "Nutley, NJ" 
		replace city = "Short Hills, NJ" if city == "South Orange, NJ"
		replace city = "Lafayette, IN" if city == "Lafayette, IL"
		
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"    
		*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_residmig_1940_1970_wide_xw.dta", replace
	}
	
	* Version 8	
	foreach v in  "8" {
		use "$INTDATA/dcourt/bartik/`v'_whiteorigin_fips1940.dta", clear
		order white* total*
		egen totwhitemigcity3539=rowmean(total_whitecity*)
		sum totwhitemigcity3539
		drop total* white*
		save "$INTDATA/dcourt/instrument/`v'_city_whitemigshare3539.dta", replace
		
		use "$INTDATA/dcourt/bartik/`v'_white_actoutmigorigin_fips19401970_collapsed_wide.dta", clear
		merge 1:1 city using "$INTDATA/dcourt/instrument/`v'_city_whitemigshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/instrument/`v'_white_actmig_1940_1970_wide.dta", replace
	
		use "$INTDATA/dcourt/instrument/`v'_white_actmig_1940_1970_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
			//A - fix spelling and formatting variations
			split city, p(,) g(part)
			replace city = proper(part1) + "," + upper(part2) 
			drop part1 part2
		
	*** Initial cleaning done. Save at this point.
	save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_white_actmig_1940_1970_wide_preprocessed.dta", replace
	
	use "$INTDATA/dcourt/instrument/city_crosswalked/`v'_white_actmig_1940_1970_wide_preprocessed.dta", clear
	g city_original=city
		
			replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
			replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
			replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
			replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
			replace city = "Norristown, PA" if city == "Norristown Borough, PA"
			replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
			replace city = "Jamestown, NY" if city == "Jamestown , NY"
			replace city = "Kensington, PA" if city == "Kensington,"
			replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
			replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
			replace city = "DuBois, PA" if city == "Du Bois, PA"
			replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
			replace city = "McKeesport, PA" if city == "Mckeesport, PA"
			replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
			replace city = "Lafayette, IN" if city == "La Fayette, IN"
			replace city = "Schenectady, NY" if city == "Schenectedy, NY"
			replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
			replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
			replace city = "New Kensington, PA" if city == "Kensington, PA"
		
			//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
			//B1 - the following cities overlap with their subsitutes
			replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
			replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
		
			//B2 - the following cities just share a border with their subsitutes but do not overlap
			replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
			replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
			replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
		
			//B3 - the following cities do not share a border with their substitutes but are within a few miles
			replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
			replace city = "Wallington, NJ" if city == "Nutley, NJ" 
			replace city = "Short Hills, NJ" if city == "South Orange, NJ"
			replace city = "Lafayette, IN" if city == "Lafayette, IL"
	   
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"    
		*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_white_actmig_1940_1970_wide_xw.dta", replace
}
		
	* Version m (southern upward mobility in the North)
	foreach v in "m"{
	
	if "`v'"=="m"{
	local svar smob
	}
		local destinationcode city
		
		use "$INTDATA/dcourt/bartik/`v'_black`destinationcode'1940.dta", clear
		
		order black* total*
		egen totblackmigcity3539=rowmean(total_blackcity*)
		sum totblackmigcity3539
		
		drop total* black*
		save "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", replace
		
		use "$INTDATA/dcourt/bartik/`v'_black_proutmig`destinationcode'19401940_collapsed_wide.dta", clear
		merge 1:1 city using "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/instrument/`v'_black_`svar'_1940_1940_wide.dta", replace
	
		use "$INTDATA/dcourt/instrument/`v'_black_`svar'_1940_1940_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
		//A - fix spelling and formatting variations
		split city, p(,) g(part)
		replace city = proper(part1) + "," + upper(part2) 
		drop part1 part2
		
		*** Initial cleaning done. Save at this point.
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_`svar'_1940_1940_wide_preprocessed.dta", replace
		
		use "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_`svar'_1940_1940_wide_preprocessed.dta", clear
		g city_original=city
		
		replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
		replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
		replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
		replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
		replace city = "Norristown, PA" if city == "Norristown Borough, PA"
		replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
		replace city = "Jamestown, NY" if city == "Jamestown , NY"
		replace city = "Kensington, PA" if city == "Kensington,"
		replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
		replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
		replace city = "DuBois, PA" if city == "Du Bois, PA"
		replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
		replace city = "McKeesport, PA" if city == "Mckeesport, PA"
		replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
		replace city = "Lafayette, IN" if city == "La Fayette, IN"
		replace city = "Schenectady, NY" if city == "Schenectedy, NY"
		replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
		replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
		replace city = "New Kensington, PA" if city == "Kensington, PA"
	
		//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
		//B1 - the following cities overlap with their subsitutes
		*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
		replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
		replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
	
		//B2 - the following cities just share a border with their subsitutes but do not overlap
		replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
		replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
		replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
	
		//B3 - the following cities do not share a border with their substitutes but are within a few miles
		replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
		replace city = "Wallington, NJ" if city == "Nutley, NJ" 
		replace city = "Short Hills, NJ" if city == "South Orange, NJ"
		replace city = "Lafayette, IN" if city == "Lafayette, IL"
	   
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"    
		*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		save "$INTDATA/dcourt/instrument/city_crosswalked/`v'_black_`svar'_1940_1940_wide_xw.dta", replace
	}	

	
	* Version r`i' (placebo shocks)
	forval i=1(1)1000{
	
		local origincode origin_fips
		
		use "$RAWDATA/dcourt/rndmig_shares/r`i'_black`origincode'1940.dta", clear
		
		order black* total*
		egen totblackmigcity3539=rowmean(total_blackcity*)
		sum totblackmigcity3539
		
		drop total* black*
		save "$INTDATA/dcourt/bartik/rndmig/r`i'_city_blackmigshare3539.dta", replace
		
		use "$RAWDATA/dcourt/rndmig/r`i'_black_proutmig`origincode'19401940_collapsed_wide.dta", clear
		merge 1:1 city using "$INTDATA/dcourt/bartik/rndmig/r`i'_city_blackmigshare3539.dta", keep(3) nogenerate
		
		save "$INTDATA/dcourt/bartik/rndmig/r`i'_black_prmig_1940_1940_wide.dta", replace
	
		use "$INTDATA/dcourt/bartik/rndmig/r`i'_black_prmig_1940_1940_wide.dta", clear
		decode city, gen(city_str)
		drop city 
		rename city_str city
		
		*Standardize City Names
			//A - fix spelling and formatting variations
			split city, p(,) g(part)
			replace city = proper(part1) + "," + upper(part2) 
			drop part1 part2
		
		*** Initial cleaning done. Save at this point.
		save "$INTDATA/dcourt/instrument/city_crosswalked/rndmig/r_`i'_black_prmig_1940_1940_wide_preprocessed.dta", replace
		
		use "$INTDATA/dcourt/instrument/city_crosswalked/rndmig/r_`i'_black_prmig_1940_1940_wide_preprocessed.dta", clear
		g city_original=city
		
		replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
		replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
		replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
		replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
		replace city = "Norristown, PA" if city == "Norristown Borough, PA"
		replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
		replace city = "Jamestown, NY" if city == "Jamestown , NY"
		replace city = "Kensington, PA" if city == "Kensington,"
		replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
		replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
		replace city = "DuBois, PA" if city == "Du Bois, PA"
		replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
		replace city = "McKeesport, PA" if city == "Mckeesport, PA"
		replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
		replace city = "Lafayette, IN" if city == "La Fayette, IN"
		replace city = "Schenectady, NY" if city == "Schenectedy, NY"
		replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
		replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
		replace city = "New Kensington, PA" if city == "Kensington, PA"
	
		//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
		//B1 - the following cities overlap with their subsitutesq
		*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
		replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
		replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
	
		//B2 - the following cities just share a border with their subsitutes but do not overlap
		replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
		replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
		replace city = "Bogota, NJ" if city == "Teaneck, NJ" 
	
		//B3 - the following cities do not share a border with their substitutes but are within a few miles
		replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
		replace city = "Wallington, NJ" if city == "Nutley, NJ" 
		replace city = "Short Hills, NJ" if city == "South Orange, NJ"
		replace city = "Lafayette, IN" if city == "Lafayette, IL"
	   
		*Merge with State Crosswalks
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"    
		*Resolve Unmerged Cities
		tab _merge
		
		*Save
		drop if _merge==2
		drop _merge
		save "$INTDATA/dcourt/instrument/city_crosswalked/rndmig/r`i'_black_prmig_1940_1940_wide_xw.dta", replace
	}
	
