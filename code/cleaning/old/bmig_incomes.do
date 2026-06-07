	use "$RAWDATA/dcourt/IPUMS_1940_extract_to_construct_migration_weights.dta", clear
	keep if race == 2
	decode migplac5, gen(origin_state)
	g origin_sample=(origin_state=="Alabama" | origin_state=="Arkansas" | origin_state=="Florida" | origin_state=="Georgia" | origin_state=="Kentucky"| origin_state=="Louisiana" | origin_state=="Mississippi" | origin_state=="North Carolina" | origin_state=="Oklahoma" | origin_state=="South Carolina" | origin_state=="Tennessee" | origin_state=="Texas" | origin_state=="Virginia" | origin_state=="West Virginia")
	keep if origin_sample == 1

	
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
	
	merge m:1 gisjoin2_str using "$RAWDATA/dcourt/county1940_crosswalks.dta", keepusing(fips state_name county_name) nogen
	
	
	ren city citycode
	replace citycode = 3540 if citycode == 3521 // Lebanon, PA rename
	merge m:1 citycode using "$INTDATA/dcourt/GM_city_final_dataset.dta",  keep(3) keepusing(citycode cz_name cz) nogen
	
	merge m:1 cz using "$INTDATA/dcourt/original_130_czs", keep(3) nogen
	
	replace incwage = . if incwage == 999998 | incwage == 0
	
	egen mean_income_1940_bmig_all = mean(incwage)
	
	collapse (max) mean_income_1940_bmig_all (mean) mean_income_1940_bmig = incwage, by(cz)
	
	save "$INTDATA/census/bmig_incomes", replace