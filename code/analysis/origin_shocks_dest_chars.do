	cd "$migdata"
	use clean_south_county.dta, clear
	
	/* Predict county-level net migration rate, decade by decade with southern 
	variables chosen by LASSO. Predict net migration rate ("netbmig_pred") based on 
	these vars alone. */

	reg netbmig perten perag warfac_pc percot peragtob ot perminot if year==1950
	predict netbmig_pred if year==1950
	reg netbmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1960
	predict netbmig_pred01 if year==1960
	reg netbmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1970
	predict netbmig_pred02 if year==1970	
	
	replace netbmig_pred=netbmig_pred01 if year==1960
	replace netbmig_pred=netbmig_pred02 if year==1970
	drop netbmig_pred01 netbmig_pred02
	
	/* Boustan (2016): Total number leaving/coming to county: actual and predicted. Note 
	that netbmig is a migration rate (per 100 residents). So, the range is -100 to 
	+whatever. -100 because it is impossible for more than all of the residents to 
	leave. But, on the positive side, the rate is unrestricted, because the growth 
	could be quite high (for a county with 100 blacks in 1940, could have 100,000 
	blacks in 1950 which would be a rate of 1000. */ 
	
	gen totbmig=((bpop_l/100)*netbmig)
	gen totbmig_pred=((bpop_l/100)*netbmig_pred)
	gen weight=netbmig_pred*bpop_l
	
	/* One observation per county, year. */
	
	//drop if year==year[_n-1]
	sort countyfips year
	drop if countyfips==.
	rename totbmig actoutmig
	rename totbmig_pred proutmig
	label var proutmig "predicted out migration, by county-year, south"
	drop _merge
	
	/* Merge with 1940 crosswalks data file. */

	/*  Two methods for achieving consistent fips codes between the migration data, historical census data, 
	and the crosswalks file created for this project. Using county icp and state icp to match to the 
	crosswalk file yields the best results. Then one can merge the data with the migration weights from 
	census extract located here: data/shares/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta.
	
	Alternatively, one can use state fip and county icp as used to produce the census 
	extract referenced above. The approximate code for this alternative method is below, but may need to be tweaked. 
	With either approach, a few counties (4-5) don't match and must be hand checked.
	
	tostring state, gen(southstatefip_str) 
	replace southstatefip_str=southstatefip_str+"0"
	gen southcounty=countyicp 
	replace southcounty=southcounty+20 if countyicp==24 & southcounty!=5100 & southcounty>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits
	tostring southcounty, gen(southcountyicp_str)  
	replace southcountyicp_str="00"+southcountyicp_str if length(southcountyicp_str)==2 
	replace southcountyicp_str="0"+southcountyicp_str if length(southcountyicp_str)==3
	replace southcountyicp_str=substr(southcountyicp_str,1,length(southcountyicp_str)-2)+ "10" if countyicp==41 & southcountyicp_str=="0605" // Union county in Oregon is 605 in IPUMS census extract but 610 in NHGIS file
	replace southcountyicp_str =substr(southcountyicp_str,1,length(southcountyicp_str)-1)+ "0" if(regexm(southcountyicp_str, "[0-9][0-9][0-9][5]")) // IPUMS Census extract notes county code changes with 0 or 5 but all county codes end in 0 in NHGIS file
	replace southcountyicp_str="1860" if southcountyicp_str=="1930" & countyicp==29 // Discrepancy between Missouri county St Genevieve county code in IPUMS Census extract vs. NHGIS file
	replace southcountyicp_str="7805" if southcounty==7850 & southstatefip_str=="510" // Possible typo with Greenbrier county coded as 785 instead of 775 in IPUMS Census extract. Reassigned to South Norfolk's code from NHGIS file because both are part of Chesapeake (independent city) today.
	replace southcountyicp_str="0050" if southcountyicp_str=="0053" & countyicp==22 // Possible typo with Jefferson Davis county coded as 53 instead of 50 in IPUMS Census extract. Recoded as 50.
	gen gisjoin2_str = southstatefip_str + southcountyicp_str
	cd "$xwalks"
	merge m:1 gisjoin2_str using county1940_crosswalks.dta, keepusing(fips state_name county_name)
	*/
	
	/*
	
	Virginia counties for which migration data are missing:
		  51520 |          1        5.88        5.88
		  51540 |          1        5.88       11.76
		  51560 |          1        5.88       17.65
		  51590 |          1        5.88       23.53
		  51670 |          1        5.88       29.41
		  51680 |          1        5.88       35.29
		  51690 |          1        5.88       41.18
		  51740 |          1        5.88       47.06
		  51750 |          1        5.88       52.94
		  51760 |          1        5.88       58.82
		  51770 |          1        5.88       64.71
		  51790 |          1        5.88       70.59
		  51800 |          1        5.88       76.47
		  51830 |          1        5.88       82.35
		  51840 |          1        5.88       88.24
	
	*/

	cd "$xwalks"
	merge m:1 stateicp countyicp using county1940_crosswalks.dta, keepusing(fips state_name county_name)
	drop if _merge==2 
	g origin_fips=fips
	rename state_name origin_state_name
	rename county_name origin_county_name 
	
	/* Hand correct counties that didn't match using crosswalk file and internet search. */
	
	replace origin_fips = 51067 if countyfips==51620 & _merge==1
	replace origin_fips = 48203 if countyfips==48203 & _merge==1
	replace origin_fips = 51037 if countyfips==54039 & _merge==1
	replace origin_fips = 54041 if countyfips==54041 & _merge==1
	replace origin_fips = 51189 if countyfips==189 & _merge==1
	drop _merge
		drop if netbmig_pred==. | proutmig==.

	keep year origin_fips percot perten perag peragtob tob warfac_pc permin perminot ot
	reshape wide percot perten perag peragtob tob warfac_pc permin perminot ot, i(origin_fips) j(year)
	tempfile shocks
	save `shocks'

	use $migshares/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta, clear
	
	keep if black==1 & dest_sample==1 & city!=9999
	bys origin_fips city: egen largestcitypop = total(perwt)
	bys origin_fips (largestcitypop) : keep if largestcitypop == largestcitypop[_N]
	keep city origin_fips
	duplicates drop
	duplicates tag origin_fips, gen(x)
	drop if x>0
	drop x
	ren city citycode
	decod citycode, gen(city)
	merge m:1 city using "$data/crosswalks/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name) keep(3) nogen
	merge m:1 cz using "$INTDATA/covariates/covariates", keep(3) nogen
	merge m:1 cz using "$INTDATA/census/maxcitypop", keep(1 3) nogen
	merge 1:1 origin_fips using `shocks', keep(3) nogen
	
	ren cz dest_cz
	ren cz_name dest_cz_name
	
	drop city citycode
	lab var totfrac_in_main_city "Destination Fraction of population in largest city"
	lab var urbfrac_in_main_city "Destination Fraction of urban population in largest city"
	lab var n_wells "Destination Number of Oil/Nat Gas Wells, 1940"
	lab var max_temp "Destination Maximum Temperature, 1940"
	lab var min_temp "Destination Minimum Temperature, 1940"
	lab var avg_temp "Destination Average Temperature, 1940"
	lab var avg_precip "Destination Average Precipitation, 1940"
	lab var has_port "Destination Has Port, 1940"
	lab var coastal "Destination Coastal"
	lab var transpo_cost_1920 "Destination Average Transport Cost out of CZ, 1920 (Donaldson and Hornbeck)"
	lab var m_rr "Destination Meters of Railroad, 1940"
	lab var m_rr_sqm2 "Destination Meters of Railroad per Square Meter of Land, 1940"
	
	drop permin1950 tob1950 // not used in 1950
	
	foreach d in 1950 1960 1970{
		lab var perten`d' "Origin County Percent tenant farms"
		lab var perag`d' "Origin County Percent labour force in agriculture"
		lab var percot`d' "Origin County Percent of planted acres in cotton"
		lab var peragtob`d' "Origin County Percent labour force in agriculture interacted with tobacco growing states"
		lab var tob`d' "Origin County Tobacco growing state"
		lab var ot`d' "Origin County Mineral states (OK, TX)"
		lab var permin`d' "Origin County Percent labour force in mining"
		lab var perminot`d' "Origin County Percent labour force in mining interacted with mineral states"
		lab var warfac_pc`d' "Origin County $ war industry 1940-45, per capita"

	}
	

	save "$CLEANDATA/origin_shocks_dest_chars", replace