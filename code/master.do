// Flag to run
gl run = 0


// ADD AN IF ELSE BLOCK WITH YOUR COMPUTER'S ABSOLUTE PATH TO THE MUNICIPALITY PROLIFERATION DROPBOX FOLDER
if "`c(username)'"=="Everett Stamm"{
	gl DROPBOX "/Users/Everett Stamm/Dropbox/municipality_proliferation/"
	gl REPO "/Users/Everett Stamm/Documents/Github/municipality_proliferation/"
	gl FFMPEG "/Users/Everett Stamm/ffmpeg/bin/ffmpeg.exe"
	gl use_gzuse = 0
}

gl DATA "$DROPBOX/data"
gl CODE "$REPO/code"
gl DCOURT "$DROPBOX/derenoncourt_opportunity/replication_AER"

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

if `run'==1{
	
	// CLEANING
	
		// Cleaning wikipedia scrape data
		do "$CODE/cleaning/wikiscrape_cleaning.do"
		
		// Cleaning CoG data
		do "$CODE/cleaning/cog_cleaning.do"
		
		// Cleaning Census Data
		do "$CODE/cleaning/census_race_cleaning.do"
		
		// Creating master file (INCOMPLETE, MAY NOT BE USED)
		// do "$CODE/cleaning/master_file_creation.do"
		
		// Harmonizing datasets
		do "$CODE/cleaning/dataprep.do"
	
	// ANALYSIS
	
		// Main tables
		do "$CODE/analysis/tables.do"
		
		// Maps
		do "$CODE/analysis/maps.do"
		
		// Treated vs. Control comparison tables
		do "$CODE/analysis/comparison_tables.do"
		
		// Goldsmith Pinkham Table
		do "$CODE/analysis/goldsmith_pinkham_table.do"
		
		// LA vs Chicago Comparison
		do "$CODE/analysis/la_vs_chicago.do"
		
		// Patterns of missingness (INCOMPLETE, MAY NOT BE USED)
		// do "$CODE/analysis/patterns_of_missingness.do"
	
}