	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear

	keep if dest_sample == 1
	collapse perwt white black, 
		/* Restrict sample to origin locations of interest and group of interest. */
		
		egen total_white$origin_id = total(`group'),by($origin_id)	
		egen total_`group'$destination_id = total(`group'), by($destination_id)
		
		
		keep if $dest_sample == 1
			
		/* Collapse data to destination county X origin county level */
		collapse (sum) $groups (mean) total_* , by($origin_id $destination_id)
		
		gen `group'$origin_id=`group'/total_`group'$origin_id
		
		/***** Save the origin-destination matrix as an intermediate dataset. *****/	
		save "$INTDATA/dcourt/bartik/${version}_od_matrix_`group'_$start_year.dta", replace
		
use "$RAWDATA/census/usa_00065.dta/usa_00065.dta" if (city !=0 ) & (migrate5 == 2 | migrate5 == 3 | migrate5 == 4 | migrate5 == 8), clear
	
	g all = 1
	gen black=(race==2) // Create race dummy variable 
	gen white=(race==1)
	replace city = 3540 if city == 3521
	collapse (sum) all black white, by(city)
	tempfile all_migrants
	save `all_migrants'
	
	
	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear

	keep if dest_sample == 1
	g all = 1
	collapse (sum) all white black, by(city)
	
	ren all all_southern
	ren white white_southern
	ren black black_southern
	
	merge 1:1 city using `all_migrants', keep(3) nogen
	
	g citycode = city
	merge 1:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset.dta", keepusing(citycode) keep(3) nogen
	
	foreach t in all white black{
		g prop_`t' = 100*`t'_southern / `t'
	}
	merge 1:1 using 
/* Keep southerners */
	decode migplac5, gen(origin_state)
	g origin_sample=(origin_state=="Alabama" | origin_state=="Arkansas" | origin_state=="Florida" | origin_state=="Georgia" | origin_state=="Kentucky"| origin_state=="Louisiana" | origin_state=="Mississippi" | origin_state=="North Carolina" | origin_state=="Oklahoma" | origin_state=="South Carolina" | origin_state=="Tennessee" | origin_state=="Texas" | origin_state=="Virginia" | origin_state=="West Virginia")

	replace origin_sample = 0 if migcounty==9999
	
	
	tostring migplac5, gen(southstatefip_str) 
	replace southstatefip_str=southstatefip_str+"0"
	gen southcounty=migcounty 
	replace southcounty=southcounty+20 if migplac5==24 & southcounty!=5100 & southcounty>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits
	tostring southcounty, gen(southcountyicp_str)  
	replace southcountyicp_str="00"+southcountyicp_str if length(southcountyicp_str)==2 
	replace southcountyicp_str="0"+southcountyicp_str if length(southcountyicp_str)==3
	replace southcountyicp_str=substr(southcountyicp_str,1,length(southcountyicp_str)-2)+ "10" if migplac5==41 & southcountyicp_str=="0605" // Union county in Oregon is 605 in IPUMS census extract but 610 in NHGIS file
	replace southcountyicp_str =substr(southcountyicp_str,1,length(southcountyicp_str)-1)+ "0" if(regexm(southcountyicp_str, "[0-9][0-9][0-9][5]")) // IPUMS Census extract notes county code changes with 0 or 5 but all county codes end in 0 in NHGIS file
	replace southcountyicp_str="1860" if southcountyicp_str=="1930" & migplac5==29 // Discrepancy between Missouri county St Genevieve county code in IPUMS Census extract vs. NHGIS file
	replace southcountyicp_str="7805" if southcounty==7850 & southstatefip_str=="510" // Possible typo with Greenbrier county coded as 785 instead of 775 in IPUMS Census extract. Reassigned to South Norfolk's code from NHGIS file because both are part of Chesapeak (independent city) today.
	replace southcountyicp_str="0050" if southcountyicp_str=="0053" & migplac5==22 // Possible typo with Jefferson Davis county coded as 53 instead of 50 in IPUMS Census extract. Recoded as 50.
	gen gisjoin2_str = southstatefip_str + southcountyicp_str
	
	merge m:1 gisjoin2_str using "$XWALKS/county1940_crosswalks.dta", keepusing(fips state_name county_name)
	drop if _merge==2 // Drop counties that had no 1935-1940 migrants (1,162 total).
	rename fips origin_fips
	rename state_name origin_state_name
	rename county_name origin_county_name 
	drop gisjoin2
	drop _merge