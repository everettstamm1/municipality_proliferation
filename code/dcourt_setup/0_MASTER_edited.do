/* Notes for Shattered Metropolis: 

This is a minimally edited master file for the Derenoncourt (2022) replication package that our project builds off of. We limit to running the 1_build.do and 2_lasso.do files. The edits are solely to reduce the scope of the code to what we use from this project, as well as reduce the dependency on outside software (namely, SAS). The outputs created should mirror those in the original replication files.


*/

*********************************************************************************************************************************************************************************************************************************
************************************************************************ GREAT MIGRATION AND MOBILITY MASTER DO-FILE ************************************************************************************************************
*********************************************************************************************************************************************************************************************************************************
/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

0. This is the master do-file for "Can you move to opportunity? Evidence from the Great Migration", which calls all the individual do-files required to replicate the analysis conducted in this paper.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*0. Set preconditions and directory definitions. 
	*1. Build geographic crosswalks.
	*2. Post-LASSO prediction of southern county net-migration.
	*3. Shift-share instrument for Great Migration into northern cities.
	*4. Build final analysis dataset.
	*5. Produce main tables and figures.
	*6. Produce appendix tables and figures.
	*7. Produce additional figures and slides for slide deck.
	*8. Keeps only vars that are used in analysis datasets and labels them.
*first created: 12/30/2019
*last updated: 8/12/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*0. Set preconditions and directory definitions.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	
	/* Clear all and set max matsize. */
	capture log close
	clear all
	set more off
	set matsize 11000
	set maxvar 30000
	
	/* Action required: Change to path to the replication folder on your home directory. */
	global XXX 		"$RAWDATA/dcourt/replication_AER"	
	
	* Package dependencies are installed by the parent replication package via
	* code/setup_stata_packages.do before this edited Derenoncourt master runs.
	local missing_dependency = 0
	foreach command in esttab maptile spmap shp2dta parmby ivreg2 ranktest statastates mdesc coefplot rsource binscatter keeporder lincomest _gends distinct unique {
		capture which `command'
		if _rc {
			local missing_dependency = 1
		}
	}
	if `missing_dependency' {
		if "$CODE" != "" {
			do "$CODE/setup_stata_packages.do"
		}
		else {
			display as error "Run code/setup_stata_packages.do before this file."
			exit 499
		}
	}
						
	/* Action required: Install .style files (customized color palette). */
						*i. copy the .style files (located in 'color_palette' folder) to the top of your SITE or PERSONAL directory 
						*-->to get the path for either your SITE or PERSONAL directory, type in "adopath" in Stata. 
						*ii.type "discard" OR restart Stata to make sure STATA loads the new colors. 

	/* Action required: copy the ado file ri_pvalue.ado (located in `data/randomization_inference' folder) to your PERSONAL directory.
	*-->to get the path for either your PERSONAL directory, type in "adopath" in Stata.
	
	*/
	
	/* For instructions on using these replication files, see replication_aer/ReadMe.pdf. */
	/* For a list of the figures and tables  replication_aer/derenoncourt_2021_list_tables_figures.xlsx". */
		
	/* Code dir and sub-dirs. */
	global code "${XXX}/code"
	global lasso "$code/lasso"
	global bartik "$code/bartik"
	
	/* Data dir and sub-dirs. */
	global data "$XXX/data"
	global xwalks "$data/crosswalks"
	global urbrural "$xwalks/documentation/urban_rural_county_classification"
	global msanecma "$xwalks/documentation/msanecma_1999_codes_names"
	global city_sample "$data/city_sample"
	global mobdata "$data/mobility"
	global instrument "$data/instrument"
	global migshares "$instrument/shares"
	global migdata "$instrument/migration"
	global mechanisms "$data/mechanisms"
	global jobs "$mechanisms/jobs"
	global pf "$mechanisms/public_finance"
	global political "$mechanisms/political"
	global nbhds "$mechanisms/neighborhoods"
	global incarceration "$mechanisms/incarceration"
	global schools "$mechanisms/schools"
	global population "$mechanisms/population"
	global ri "$data/randomization_inference"
		
	/* Paper and slides dirs and sub-dirs. */
	global paper "$XXX/paper"
	global figtab "$XXX/figures_tables"
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Build intermediate datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	 do $code/1_build_edited.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*2. Predict netmigration from the South between 1940 and 1970.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	do $code/2_lasso_edited.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3. Construct versions of shift-share instrument.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	 do $code/3_instrument_edited.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*4. Assemble final dataset.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	do $code/4_final_dataset_edited.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*5. Generate main figures and tables.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	//do $code/5_main_figures_tables.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*6. Generate appendix figures and tables.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	//do $code/6_appendix_figures_tables.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*7. Keeps only vars that are used in analysis datasets and labels them.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	 //do "$code/7_keep_and_label_analysis_vars.do"
