// Municipal Proliferation
// This file is amended from 2_lasso.do in the Derenoncourt (2022) replication files.
// This conducts lasso shift-share covariate selection for white southern migration, as the original file did for black southern migration.





/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

2. Predict netmigration from the South between 1940 and 1970.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Create and clean the migration datasets for prediction for each decade. 
	*2. Run LASSO on each decade's migration dataset to obtain predictors.
	*3. Predict using original Boustan (2016) variables.
	*4. Run Post-LASSO to generate predicted migration figures for each county by decade.
	*5. Within state variation in migration.
	*6. Dropping urban counties.
	*7. White southern migration.
	
*first created: 12/30/2019
*last updated:  12/30/2019
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Create and clean the migration datasets for prediction for each decade.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	/* Data on black netmigration for southern counties come from Boustan (2016):
	south_county.dta. These data were downloaded from the following link: 
	https://economics.princeton.edu/dl/Boustan/Chapter4.zip. */
	
	
	use "$RAWDATA/dcourt/replication_AER/data/instrument/migration/raw/south_county.dta", clear
	statastates, fips(state) nogen


	//merge m:1 year countyicp state_abbrev using "$INTDATA/south_migrate", keep(1 3) nogen keepusing( wpop_l netwmig netbmig)
	merge m:1 year countyicp state_abbrev using "$RAWDATA/dcourt/replication_AER/data/instrument/migration//clean_south_county_white_nonwhite_mig_1940_1970.dta", keep(1 3) nogen keepusing( wpop_l netwmig netbmig)
	
	drop if netwmig == .
	/* Instructions for cleaning the data from Boustan (2016) replication files
	are prefaced with "Boustan (2016)".
	
	Boustan (2016): This data set includes all of the southern data by county, from 
	CCDB and ICPSR Great Plains project.
	
	Boustan (2016): There are 350 or so counties with missing mining or 
	manufacturing information in 1950 & 1970. In this case, replace with the 
	1960 info. */
	
	sort state countyicp year
	replace permin=permin[_n+1] if year==1950 & permin==. & countyicp==countyicp[_n+1]
	replace permin=permin[_n-1] if year==1970 & permin==. & countyicp==countyicp[_n-1]
	replace perman=perman[_n+1] if year==1950 & perman==. & countyicp==countyicp[_n+1]
	replace perman=perman[_n-1] if year==1970 & perman==. & countyicp==countyicp[_n-1]
	
	/* Note that migration data is missing for several counties in Virginia. */
	
	/* Boustan (2016): Interact variables with % cotton and % agriculture. */
	
	replace perten=perten/100
	replace perag=perag/100 if year==1950
	replace perag=perag/10 if year==1960
	
	/* Boustan (2016): Create dummy for SA (GA, FL, VA, WV, SC, NC) and interact. */
	
	gen satl=(state==12 | state==13 | state==37 | state==45 | state==51 | state==54)
	gen pertensa=perten*satl
	gen permansa=perman*satl
	
	/* Boustan (2016): Create dummy for tobacco growing states and interact with 
	agriculture (NC, KY, TN). */
	
	gen tob=(state==37 | state==21 | state==47)
	gen peragtob=perag*tob
	
	/* Boustan (2016): Create dummy for mineral region (OK, TX). */
	
	gen ot=(state==40 | state==48)
	gen perminot=permin*ot
	
	/* Save the dataset that will be used for post LASSO */
	
	save "$INTDATA/dcourt/clean_south_county_white.dta", replace
	
	/* Additional cleaning to prepare the data for R and running LASSO. */
	*local final_varlist netwmig perten perag permin perman aaa_pc warfac_pc warcon_pc avesz3 tmpav30 pcpav30 mxsw30s mxsd30s dustbowa summit swamp valley elevmax riv1120 riv2150 riv51up riv0510 elevrang awc clay kffact om perm thick minem35a Astate_5 Astate_12 Astate_13 Astate_21 Astate_22 Astate_28 Astate_37 Astate_40 Astate_45 Astate_47 Astate_48 Astate_51 Astate_54 satl pertensa permansa tob peragtob ot perminot
	local final_varlist netwmig percot perten perag peragtob tob warfac_pc permin perminot ot
	*perten perag permin perman warfac_pc satl pertensa permansa tob peragtob ot perminot
	
	/* Replace any vars that are still missing with the state-year mean value 
	for that var. */
	foreach var in `final_varlist'{
	mdesc `var'
	tab countyfips if `var'==.
	*drop if `var'==.
	egen mean_`var'=mean(`var'), by(state year)
	replace `var'=mean_`var' if `var'==.
	}
	
	keep year `final_varlist'
	
	/* Create a separate dataset for each decade. */
	preserve
	keep if year==1950
	drop year
	save "$INTDATA/dcourt/south_county_white_migration_dataset_for_prediction_1950.dta", replace
	restore
	
	preserve
	keep if year==1960
	drop year
	save "$INTDATA/dcourt/south_county_white_migration_dataset_for_prediction_1960.dta", replace
	restore
	
	preserve
	keep if year==1970
	drop year
	save "$INTDATA/dcourt/south_county_white_migration_dataset_for_prediction_1970.dta", replace
	restore
	
	clear

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*2. Run lasso on each decade's migration dataset to obtain predictors.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	/* Initiate R and run LASSO using cv glmnet. */
	

	
	rsource, terminator(END_OF_R) 
	
		require(haven)
		require(ggplot2)
		require(dplyr)
		require(tidyr)
		require(data.table)
		require(stargazer)
		require(randomForest)
		require(glmnet)
		require(rpart)
		require(parallel)
		require(stringr)
		
		rm(list = ls()) 
	
		setwd("F:/municipality_proliferation/data/interim/dcourt")
		
		runLasso = TRUE
		
		if (runLasso) {
		train = read_dta('south_county_white_migration_dataset_for_prediction_1950.dta')
	
		x = model.matrix(~., data=train %>% select(-netwmig))
		y = train$netwmig
		lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
		tmp_coeffs<-coef(lassoPred, s="lambda.min")
		lasso_list_of_vars_1950<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)
	
	write.csv(lasso_list_of_vars_1950[2:dim(lasso_list_of_vars_1950)[1],1:dim(lasso_list_of_vars_1950)[2]], file='lasso_list_of_vars_white_1950.csv')
	
		train = read_dta('south_county_white_migration_dataset_for_prediction_1960.dta')
	
		x = model.matrix(~., data=train %>% select(-netwmig))
		y = train$netwmig
		lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
		tmp_coeffs<-coef(lassoPred, s="lambda.min")
		lasso_list_of_vars_1960<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)
	
	write.csv(lasso_list_of_vars_1960[2:dim(lasso_list_of_vars_1960)[1],1:dim(lasso_list_of_vars_1960)[2]], file='lasso_list_of_vars_white_1960.csv')
	
		train = read_dta('south_county_white_migration_dataset_for_prediction_1970.dta')
	
		x = model.matrix(~., data=train %>% select(-netwmig))
		y = train$netwmig
		lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
		tmp_coeffs<-coef(lassoPred, s="lambda.min")
		lasso_list_of_vars_1970<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)
	
	write.csv(lasso_list_of_vars_1970[2:dim(lasso_list_of_vars_1970)[1],1:dim(lasso_list_of_vars_1970)[2]], file='lasso_list_of_vars_white_1970.csv')
	}
	END_OF_R


*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3. Predict using original Boustan (2016) variables.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	/* Load full clean data. */
	
	use "$INTDATA/dcourt/clean_south_county_white.dta", clear
	
	/* Predict county-level net migration rate, decade by decade with southern 
	variables chosen by LASSO. Predict net migration rate ("netwmig_pred") based on 
	these vars alone. */
	reg netwmig percot perten perag peragtob tob warfac_pc permin perminot ot [aw=wpop_l] if year==1950
	predict netwmig_pred if year==1950
	reg netwmig percot perten perag peragtob tob warfac_pc permin perminot ot [aw=wpop_l] if year==1960
	predict netwmig_pred01 if year==1960
	reg netwmig percot perten perag peragtob tob warfac_pc permin perminot ot [aw=wpop_l] if year==1970
	predict netwmig_pred02 if year==1970	
	
	replace netwmig_pred=netwmig_pred01 if year==1960
	replace netwmig_pred=netwmig_pred02 if year==1970
	drop netwmig_pred01 netwmig_pred02
	
	/* Boustan (2016): Total number leaving/coming to county: actual and predicted. Note 
	that netwmig is a migration rate (per 100 residents). So, the range is -100 to 
	+whatever. -100 because it is impossible for more than all of the residents to 
	leave. But, on the positive side, the rate is unrestricted, because the growth 
	could be quite high (for a county with 100 blacks in 1940, could have 100,000 
	blacks in 1950 which would be a rate of 1000. */ 
	
	gen totwmig=((wpop_l/100)*netwmig)
	gen totwmig_pred=((wpop_l/100)*netwmig_pred)
	gen weight=netwmig_pred*wpop_l
	
	/* One observation per county, year. */
	
	drop if year==year[_n-1]
	sort countyfips year
	drop if countyfips==.
	rename totwmig actoutmig
	rename totwmig_pred proutmig
	label var proutmig "predicted out migration, by county-year, south"
	
	/* Merge with 1940 crosswalks data file. */
	drop _merge
	merge m:1 stateicp countyicp using "$RAWDATA/dcourt/replication_AER/data/crosswalks/county1940_crosswalks.dta", keepusing(fips state_name county_name)
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
	
	tostring origin_fips, replace
	keep origin_fips year proutmig actoutmig netwmig_pred
	
	drop if netwmig_pred==. | proutmig==.
	
	bysort origin_fips year: gen dup= cond(_N==1,0,_n)
	tab dup
	
	drop dup
	
	save "$INTDATA/dcourt/1_boustan_predict_mig_white.dta", replace
	
	collapse (sum) netwmig_pred actoutmig proutmig, by(origin_fips year)
	save "$INTDATA/dcourt/1_boustan_predict_mig_collapsed_white.dta", replace
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*4. Run Post-LASSO to generate predicted migration figures for each county by decade.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	/* Load full clean data. */
	
	use "$INTDATA/dcourt/clean_south_county_white.dta", clear
	
	/* Predict county-level net migration rate, decade by decade with southern 
	variables chosen by LASSO. Predict net migration rate ("netwmig_pred") based on 
	these vars alone.
	...it's just the same vars */

	reg netwmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1950 
	predict netwmig_pred if year==1950
	reg netwmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1960 
	predict netwmig_pred01 if year==1960
	reg netwmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1970 
	predict netwmig_pred02 if year==1970	
	
	replace netwmig_pred=netwmig_pred01 if year==1960
	replace netwmig_pred=netwmig_pred02 if year==1970
	drop netwmig_pred01 netwmig_pred02
	
	/* Boustan (2016): Total number leaving/coming to county: actual and predicted. Note 
	that netwmig is a migration rate (per 100 residents). So, the range is -100 to 
	+whatever. -100 because it is impossible for more than all of the residents to 
	leave. But, on the positive side, the rate is unrestricted, because the growth 
	could be quite high (for a county with 100 blacks in 1940, could have 100,000 
	blacks in 1950 which would be a rate of 1000. */ 
	
	gen totwmig=((wpop_l/100)*netwmig)
	gen totwmig_pred=((wpop_l/100)*netwmig_pred)
	gen weight=netwmig_pred*wpop_l
	
	/* One observation per county, year. */
	
	//drop if year==year[_n-1]
	sort countyfips year
	drop if countyfips==.
	rename totwmig actoutmig
	rename totwmig_pred proutmig
	label var proutmig "predicted out migration, by county-year, south"
	
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
	drop _merge
	merge m:1 stateicp countyicp using "$RAWDATA/dcourt/replication_AER/data/crosswalks/county1940_crosswalks.dta", keepusing(fips state_name county_name)
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
	
	tostring origin_fips, replace
	keep origin_fips origin_state_name year proutmig actoutmig netwmig_pred
	
	drop if netwmig_pred==. | proutmig==.
	
	bysort origin_fips year: gen dup= cond(_N==1,0,_n)
	tab dup
	drop dup
	
	preserve
	keep origin_fips year proutmig actoutmig netwmig_pred
	
	save "$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta", replace
	restore
	
	preserve
	collapse (sum) netwmig_pred actoutmig proutmig, by(origin_fips year)
	save "$INTDATA/dcourt/2_lasso_boustan_predict_mig_collapsed_white.dta", replace
	restore
	
