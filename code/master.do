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

adopath ++ "$CODE/ado"

// Settings
set maxvar 30000

if `run_dcourt'==1{
	
	
	// Files I made to create data necessary for stacked derenoncourt
	do "$CODE/dcourt_setup/A1_census_1950_1960_racepop.do"
	do "$CODE/dcourt_setup/A2_clean_cz_mobility_1900_2015.do"
	do "$CODE/dcourt_setup/A4_clean_city_population_census_1940_full.do"
	do "$CODE/dcourt_setup/A5_clean_cz_snq_european_immigration_instrument.do"

	do "$CODE/dcourt_setup/4_final_dataset_split.do"

	// Original derenoncourt final dataset, modified to drop data we don't need and reformat variables to what we need (e.g. percentage point instead of percentile instruments)
	do "$CODE/cleaning/4_final_dataset.do"
	
	// 1940-70 decades stacked dataset
	do "$CODE/dcourt_setup/4_final_dataset_split.do"

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