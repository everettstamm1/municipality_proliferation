
clear all
set seed 20260409     	

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
if "`c(username)'"=="edog9"{
	//gl DROPBOX `"F:\municipality_proliferation"'
	gl DROPBOX `"F:/munis_replication/"'

	gl REPO "C:/Users/edog9/Documents/Github/municipality_proliferation/"
	gl FFMPEG "/Users/edog9/ffmpeg/bin/ffmpeg.exe"
	gl Rterm_path `"C:/Program Files/R/R-4.3.1/bin/x64/Rterm.exe"'
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

// Which school districts version to use
// 0: Raw
// 1: CZs in Maine , Maryland , Massachusetts , North Carolina , Rhode Island , and Virginia with missing values dropped
// 2: 1 + Values imputed from dependent school districts in Tennessee, Vermont, and Connecticut
gl schdist_version = 2

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


}




if `run'==1{


	// Run dcourt replication as far as we need it
	do "$RAWDATA/dcourt/replication_AER/code/0_MASTER_edited.do"

	// CLEANING
	
	// Get Census place-CZ crosswalk
	do "$CODE/cleaning/place_county_xwalk.do"
	
	// Get Cgoodman place information
	rsource using "$CODE/cleaning/cgoodman_place_county_geog.R"
	
	// Clean migration data to get white version of south_migrate
	do "$CODE/cleaning/migrate_cleaning.do"
	
	// White lasso
	do "$CODE/cleaning/2_lasso_white.do"
	
	// Creation of shift-share instruments and ssaggregate primatives
	do "$CODE/cleaning/create_sumshare.do"
	
	// Cleaning CoG data
	do "$CODE/cleaning/cog_cleaning.do"
	
	// Creating jurisdiction counts
	do "$CODE/cleaning/muni_counts.do"
	
	// Finding principal cities
	do "$CODE/cleaning/maxcitypop.do"
	
	// Census incomes 1940, 1970, 2010
	do "$CODE/cleaning/incomes.do"
	
	// Urban Geographies
	do "$CODE/cleaning/geogs.do"
	
	// Streams
	do "$CODE/cleaning/streams.do"
	
	// Other spatial covariates
	rsource using "$CODE/cleaning/covariates.R"
	
	// Census education
	do "$CODE/cleaning/education.do"

	// Incumbent land changes 
	do "$CODE/cleaning/cz_incumbent_land_changes.do"
	
	// CZ Court Orders
	do "$CODE/cleaning/cz_court_orders.do"
	
	// Characteristics of 1930-40 linked Black migrants
	do "$CODE/cleaning/black_linked_characteristics.do"
	
	// 1900-1950 full count populations, occupation scores, and mfg shares, as well as 1980-2000 mfg shares and 2010 urban populations
	do "$CODE/cleaning/cz_pop_occscore_mfg.do"
	
	// Municipality shapefile
	rsource using "$CODE/cleaning/municipal_shapefile.R"
	
	// Central city distances 
	rsource using "$CODE/cleaning/full_touching.R"

	// Muni-District Overlap 
	rsource using "$CODE/cleaning/muni_district_overlap.R"

	// Leaid geogs
	///rsource using "$CODE/cleaning/leaid_place_xwalk.R"
	//rsource using "$CODE/cleaning/leaid_areas.R"
	
	// School info cleaning
	do "$CODE/cleaning/ncessch_cleaning.do"

	// Municipal Finance cleaning
	do "$CODE/cleaning/IndFin_cleaning.do"

	// Harmonizing datasets
	do "$CODE/cleaning/dataprep.do"

	// Figure A data
	do "$CODE/cleaning/panel_a_data.do"

	// PCArrow Fig Data
	do "$CODE/cleaning/pcarrow_fig_data.do"
	
	// Place level dataset
	do "$CODE/cleaning/mechanisms.do"
	
	// Segregation Indices
	do "$CODE/cleaning/cz_pop_segregation.do"
	
	
	// Analysis

	// Summary table
	do "$CODE/analysis/summary_table.do"
	
	// Cleveland vs. Columbus
	do "$CODE/analysis/fig_1_panels_b_c.do"

	// Balance Tables
	do "$CODE/analysis/balancetables.do"
	
	// Main 2SLS tables 
	do "$CODE/analysis/main_table.do"
	
	// Event Studies
	do "$CODE/analysis/event_studies.do"
	
	// PCArrow Figure
	do "$CODE/analysis/pcarrow_fig.do"
	
	// Linked OCCSCORE Heterogeneity
	do "$CODE/analysis/occscore_links_diffs_fs.do"
	do "$CODE/analysis/occscore_links_diffs_ss.do"

	// Court Ordered Heterogeneity
	do "$CODE/analysis/main_court_ordered.do"
	
	// Mechanisms
	do "$CODE/analysis/long_term_mechanisms.do"

	// Long term segregation
	do "$CODE/analysis/segregation_table.do"
	
	// Pretrends table
	do "$CODE/analysis/pretrends.do"
	
	// Correlation Table
	do "$CODE/analysis/corr_matrix.do"
	
	// Imbalanced controls decomposition
	do "$CODE/analysis/imbalance_decomp.do"

	// Baseline controls individual effects
	do "$CODE/analysis/balancecontrols_individualeffects.do"

	// Other Mechanisms
	do "$CODE/analysis/touching_pct_rev_debt_table.do"

	// White Flight Check
	do "$CODE/analysis/white_flight_check.do"

	// Distance to principal city graphs
	do "$CODE/analysis/dist_edge_edge.do"
	
	// Incorporations over time graph
	do "$CODE/analysis/municipal_incorporations_graph.do"

	// Leave-one-out tests
	do "$CODE/analysis/loo_test.do"

	// OverID tests
	do "$CODE/analysis/alt_inst_tests.do"
	
	// Placebo tests
	do "$CODE/analysis/placebo_test.do"
	
	
}