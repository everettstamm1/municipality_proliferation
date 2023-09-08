/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file cleans 1940 complete count census file for constructing 1935-1940 southern county migrant shift share instrument change in the black population in northern locations between 1940 and 1970.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Clean 1940 complete count census 1935-1940 migrants extract file, perform preliminaries for bartik and save intermediate file.
*first created: 09/11/2018
*last updated:  11/23/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Clean 1940 complete count census 1935-1940 migrants extract file.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	/* Input data set and keep if origin state five years ago is in the south. 
	
	South is defined as:
	Alabama, Arkansas, Florida, Georgia, Kentucky, Louisiana, Mississippi, North 
	Carolina, Oklahoma, South Carolina, Tennessee, Texas, Virginia, and West 
	Virginia. Maryland and Delaware are excluded because they on net receive 
	southern migrants during this period.*/	
	
	use "$RAWDATA/dcourt/IPUMS_1940_extract_to_construct_migration_weights.dta", clear
	
	/* Keep southerners */
	decode migplac5, gen(origin_state)
	g origin_sample=(origin_state=="Alabama" | origin_state=="Arkansas" | origin_state=="Florida" | origin_state=="Georgia" | origin_state=="Kentucky"| origin_state=="Louisiana" | origin_state=="Mississippi" | origin_state=="North Carolina" | origin_state=="Oklahoma" | origin_state=="South Carolina" | origin_state=="Tennessee" | origin_state=="Texas" | origin_state=="Virginia" | origin_state=="West Virginia")
	
	g origin_sample_rural = origin_sample==1 & migcity5==0
	g origin_sample_notx = origin_sample==1 | origin_state=="Texas"
	g origin_sample_rural_notx = (origin_sample==1 | origin_state=="Texas") & migcity5==0

	drop if migcounty==9999
	
	/* Generate an origin state icp code variable. Note that MIGPLAC5 appears to 
	be the state FIPS code (compare 
	https://usa.ipums.org/usa-action/variables/MIGPLAC5#codes_section to 
	https://usa.ipums.org/usa-action/variables/STATEFIP#codes_section, 
	so I do not use MIGPLAC5 here. To get the ICP codes, see: 
	https://usa.ipums.org/usa-action/variables/STATEICP#codes_section */
	
	/* Merge in county 1940 crosswalks to get the origin county fips 
	code into the dataset. Clean the data first as there are discrepancies 
	between IPUMS extract codes and NHGIS codes */
	
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

	/* Merge in county 1940 crosswalks to get the destination county fips 
	code into the dataset. Clean the data first as there are discrepancies 
	between IPUMS extract codes and NHGIS codes */
	
	tostring statefip, gen(statefip_str) 
	replace statefip_str=statefip_str+"0"
	replace county=county+20 if county==24 & county!=5100 & county>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits
	tostring county, gen(countyicp_str)  
	replace countyicp_str="00"+countyicp_str if length(countyicp_str)==2 
	replace countyicp_str="0"+countyicp_str if length(countyicp_str)==3
	replace countyicp_str=substr(countyicp_str,1,length(countyicp_str)-2)+ "10" if county==41 & countyicp_str=="0605" // Union county in Oregon is 605 in IPUMS census extract but 610 in NHGIS file
	replace countyicp_str =substr(countyicp_str,1,length(countyicp_str)-1)+ "0" if(regexm(countyicp_str, "[0-9][0-9][0-9][5]")) // IPUMS Census extract notes county code changes with 0 or 5 but all county codes end in 0 in NHGIS file
	replace countyicp_str="1860" if countyicp_str=="1930" & county==29 // Discrepancy between Missouri county St Genevieve county code in IPUMS Census extract vs. NHGIS file
	replace countyicp_str="7805" if county==7850 & statefip_str=="510" // Possible typo with Greenbrier county coded as 785 instead of 775 in IPUMS Census extract. Reassigned to South Norfolk's code from NHGIS file because both are part of Chesapeak (independent city) today.
	replace countyicp_str="0050" if countyicp_str=="0053" & statefip==22 // Possible typo with Jefferson Davis county coded as 53 instead of 50 in IPUMS Census extract. Recoded as 50.
	gen gisjoin2_str = statefip_str + countyicp_str
	
	merge m:1 gisjoin2_str using "$XWALKS/county1940_crosswalks.dta", keepusing(fips state_name county_name)
	drop if _merge==2 // Drop counties that had no 1935-1940 migrants (1,162 total).
	rename fips dest_fips
	rename state_name dest_state_name
	rename county_name dest_county_name 
	drop gisjoin2
	drop _merge
	
	/* Create flag to drop southern destinations later. */
	replace dest_state_name=proper(dest_state_name)
	g dest_sample=1
	replace dest_sample=0  if (dest_state_name=="Alabama" | dest_state_name=="Arkansas" | dest_state_name=="Florida" | dest_state_name=="Georgia" | dest_state_name=="Kentucky"| dest_state_name=="Louisiana" | dest_state_name=="Mississippi" | dest_state_name=="North Carolina" | dest_state_name=="Oklahoma" | dest_state_name=="South Carolina" | dest_state_name=="Tennessee" | dest_state_name=="Texas" | dest_state_name=="Virginia" | dest_state_name=="West Virginia")
	replace dest_sample=0 if city==9999
	
	g dest_sample_allcities = city!=9999 // Use with origin_sample_rural and origin_sample_rural_notx
	g dest_sample_tx = dest_sample==1 | dest_state_name=="Texas" // Use with origin_sample_notx
	
	/* Create clean grade variable */
	g grade_completed=.
	replace grade_completed=0 if educd==2  
	replace grade_completed=1 if educd==14
	replace grade_completed=2 if educd==15
	replace grade_completed=3 if educd==16
	replace grade_completed=4 if educd==17
	replace grade_completed=5 if educd==22
	replace grade_completed=6 if educd==23
	replace grade_completed=7 if educd==25
	replace grade_completed=8 if educd==26
	replace grade_completed=9 if educd==30
	replace grade_completed=10 if educd==40
	replace grade_completed=11 if educd==50
	replace grade_completed=12 if educd==60
	replace grade_completed=13 if educd==70
	replace grade_completed=14 if educd==80
	replace grade_completed=15 if educd==90
	replace grade_completed=16 if educd==100
	replace grade_completed=17 if educd==110
	replace grade_completed=. if educd==999
	la var grade_completed "Grade completed"
	
	/* Generate different group types */
	gen black=(race==2) // Create race dummy variable 
	gen white=(race==1)
	gen male=(sex==1)
	gen female=(sex==2)
	gen age25plus=(age>=25)
	
	g abfh=(black==1 & female==1 & age25plus==1 & grade_completed>=9)
	g abfl=(black==1 & female==1 & age25plus==1 & grade_completed<9)
	g abmh=(black==1 & male==1 & age25plus==1 & grade_completed>=9)
	g abml=(black==1 & male==1 & age25plus==1 & grade_completed<9)
	g awfh=(white==1 & female==1 & age25plus==1 & grade_completed>=9)
	g awfl=(white==1 & female==1 & age25plus==1 & grade_completed<9)
	g awmh=(white==1 & male==1 & age25plus==1 & grade_completed>=9)
	g awml=(white==1 & male==1 & age25plus==1 & grade_completed<9)
	g abh=(black==1 & age25plus==1 & grade_completed>=9)
	g abl=(black==1 & age25plus==1 & grade_completed<9)
	g awh=(white==1 & age25plus==1 & grade_completed>=9)
	g awl=(white==1 & age25plus==1 & grade_completed<9)	
	
	save "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", replace
