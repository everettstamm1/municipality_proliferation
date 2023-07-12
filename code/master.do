// Flag to run
gl run = 0
gl run_dcourt = 0

// ADD AN IF ELSE BLOCK WITH YOUR COMPUTER'S ABSOLUTE PATH TO THE MUNICIPALITY PROLIFERATION DROPBOX FOLDER
if "`c(username)'"=="Everett Stamm"{
	gl DROPBOX "/Users/Everett Stamm/Dropbox/municipality_proliferation/"
	gl REPO "/Users/Everett Stamm/Documents/Github/municipality_proliferation/"
	gl FFMPEG "/Users/Everett Stamm/ffmpeg/bin/ffmpeg.exe"
	gl Rterm_path `"C:\Program Files\R\R-4.2.2\bin\x64\Rterm.exe"'
	gl Rterm_options `"--vanilla"'
	gl use_gzuse = 0
}

gl DATA "$DROPBOX/data"
gl CODE "$REPO/code"

gl RAWDATA "$DATA/raw"
gl INTDATA "$DATA/interim"
gl CLEANDATA "$DATA/clean"

gl XWALKS "$DATA/xwalks"

gl FIGS "$REPO/exhibits/figures"
gl TABS "$REPO/exhibits/tables"
gl MAPS "$REPO/exhibits/maps"

// Path to Derenoncourt Repo
gl DCOURT "$DROPBOX/derenoncourt_opportunity/replication_AER"

adopath ++ "$CODE/ado"

// Settings
set maxvar 30000

if `run_dcourt'==1{
	// Derenoncourt Macros
	
	global XXX  "$DCOURT"
	global code "${XXX}/code_replication"
	global lasso "$code/lasso"
	global bartik "$code/bartik"
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
	global paper "$XXX/paper"
	global figtab "$XXX/figures_tables"
	
	// Files I made to create data necessary for stacked derenoncourt
	do "$CODE/cleaning/A1_census_1950_1960_racepop.do"
	do "$CODE/cleaning/A2_clean_cz_mobility_1900_2015.do"
	do "$CODE/cleaning/A4_clean_city_population_census_1940_full"
	do "$CODE/cleaning/4_final_dataset_split.do"

	// Original derenoncourt final dataset, modified to drop data we don't need and reformat variables to what we need (e.g. percentage point instead of percentile instruments)
	do "$CODE/cleaning/4_final_dataset.do"
}




if `run'==1{
	
	// CLEANING
	
		// Cleaning wikipedia scrape data  - NO LONGER USED
		//do "$CODE/cleaning/wikiscrape_cleaning.do"
		
		// Cleaning CoG data
		do "$CODE/cleaning/cog_cleaning.do"
		
		// Cleaning Census Data
		do "$CODE/cleaning/census_race_cleaning.do"
		
		// Create total population versions of derenoncourt dataset
		do "$CODE/cleaning/dcourt_cleaning.do"
		
		// Urban populations
		do "$CODE/cleaning/census_urban_populations.do"
		
		// Race populations
		do "$CODE/cleaning/census_race_cleaning.do"
		
		// GIS work
		rsource using "$CODE/cleaning/cgoodman_place_county_geog.R"
		rsource using "$CODE/cleaning/covariates.R"

		// Fraction land incorporated geographies
		do "$CODE/cleaning/geogs.do"
		
		// Creating master file (INCOMPLETE, MAY NOT BE USED)
		// do "$CODE/cleaning/master_file_creation.do"
		
		// Harmonizing datasets
		do "$CODE/cleaning/dataprep.do"
	
	
	
}