clear all

// Flag to run
local run = 1
local run_dcourt = 0
local create_paths = 1

// ADD AN IF ELSE BLOCK WITH YOUR COMPUTER'S ABSOLUTE PATH TO THE MUNICIPALITY PROLIFERATION DROPBOX FOLDER
if "`c(username)'"=="Everett Stamm"{
	gl DROPBOX "/Users/Everett Stamm/Dropbox/municipality_proliferation/"
	gl REPO "/Users/Everett Stamm/Documents/Github/municipality_proliferation/"
	gl FFMPEG "/Users/Everett Stamm/ffmpeg/bin/ffmpeg.exe"
	gl Rterm_path `"C:\Program Files\R\R-4.3.2\bin\x64\Rterm.exe"'
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

// Settings
set maxvar 30000

adopath ++ "$CODE/ado"
cd "$REPO"


// Sending global paths to CSV file so they can be read by R and Matlab programs
clear all
set obs 9
g global = ""
g path = ""
replace global = "RAWDATA" if _n == 1
replace global = "INTDATA" if _n == 2
replace global = "CLEANDATA" if _n == 3
replace global = "XWALKS" if _n == 4
replace global = "FIGS" if _n == 5
replace global = "TABS" if _n == 6
replace global = "DROPBOX" if _n == 7
replace global = "REPO" if _n == 8
replace global = "Rterm_path" if _n == 9
forv i=1/9{
	local temp = "$" + "`=global[`i']'"
	replace path =  "`temp'" if _n == `i'
}
export delimited "$REPO/paths.csv", replace


if `run_dcourt'==1{
	
	
	/* These are no longer needed
	// Files I made to create data necessary for stacked derenoncourt
	do "$CODE/dcourt_setup/A1_census_1950_1960_racepop.do"
	do "$CODE/dcourt_setup/A2_clean_cz_mobility_1900_2015.do"


	do "$CODE/dcourt_setup/4_final_dataset_split.do"
	*/
	do "$CODE/dcourt_setup/A4_clean_city_population_census_1940_full.do"
	do "$CODE/dcourt_setup/A5_clean_cz_snq_european_immigration_instrument.do"
	// Original derenoncourt final dataset, modified to drop data we don't need and reformat variables to what we need (e.g. percentage point instead of percentile instruments)
	do "$CODE/cleaning/4_final_dataset.do"
	
}




if `run'==1{
	
	// CLEANING
		
	// Cleaning CoG data
	do "$CODE/cleaning/cog_cleaning.do"
	
	// Urban populations
	do "$CODE/cleaning/census_urban_populations.do"
	
	// Race populations
	do "$CODE/cleaning/census_race_cleaning.do"
	
	// GIS work
	rsource using "$CODE/cleaning/cgoodman_place_county_geog.R"
	rsource using "$CODE/cleaning/covariates.R"

	// Fraction land incorporated geographies
	do "$CODE/cleaning/geogs.do"
	
	// Municipal Finance cleaning
	do "$CODE/cleaning/IndFin_cleaning.do"
	
	// Harmonizing datasets
	do "$CODE/cleaning/dataprep.do"

	// Figure A data
	do "$CODE/cleaning/panel_a_data.do"
	
	// PCArrow Fig Data
	do "$CODE/cleaning/pcarrow_fig_data.do"
	
	// Municipal Shapefile
	rsource using "$CODE/cleaning/municipal_shapefile.R"
	
	// Analysis
	
	// Summary table
	do "$CODE/analysis/summary_table.do"
	
	// Long term mechanisms: land use and municipal finance
	do "$CODE/analysis/long_term_mechanisms.do"
	
	// PCArrow Figure
	do "$CODE/analysis/pcarrow_fig.do"
	
	// Balance and pretrend tables
	do "$CODE/analysis/balancetables.do"
	
	// Main tables and all variants
	do "$CODE/analysis/main_table.do"
	
	// Leave one out tests
	do "$CODE/analysis/loo_test.do"
	
	// Placebo tests
	do "$CODE/analysis/placebo_test"
	
	// Alternative Instrument tests
	do "$CODE/analysis/alt_inst_tests"
	
	// In text calculations
	do "$CODE/analysis/in_text_calculations"
}