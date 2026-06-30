clear all
gl DATA "$DROPBOX/data"
gl CODE "$REPO/code"

gl RAWDATA "$DATA/raw"
gl INTDATA "$DATA/interim"
gl CLEANDATA "$DATA/clean"

gl XWALKS "$DATA/xwalks"

gl FIGS "$REPO/exhibits/figures"
gl TABS "$REPO/exhibits/tables"



// Create subfolders
cap mkdir "$INTDATA"
cap mkdir "$INTDATA/borders"
cap mkdir "$INTDATA/census"
cap mkdir "$INTDATA/cgoodman"
cap mkdir "$INTDATA/cog"
cap mkdir "$INTDATA/corelogic"
cap mkdir "$INTDATA/counts"
cap mkdir "$INTDATA/dcourt"
cap mkdir "$INTDATA/nces"
cap mkdir "$INTDATA/nces/muni_district_overlaps"
cap mkdir "$INTDATA/nces"

cap mkdir "$INTDATA/other"
cap mkdir "$INTDATA/nces/muni_district_overlap"
cap mkdir "$INTDATA/ssaggregate_prep"
cap mkdir "$INTDATA/ssaggregate_prep/placebo"

cap mkdir "$INTDATA/temp"

cap mkdir "$CLEANDATA"
cap mkdir "$XWALKS"

cap mkdir "$REPO/exhibits"
cap mkdir "$FIGS"
cap mkdir "$TABS"


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

do "$CODE/setup_stata_packages.do"
rsource using "$CODE/setup_r_packages.R"

copy "$RAWDATA/david_dorn/cw_cty_czone/cw_cty_czone.dta" "$XWALKS/cw_cty_czone.dta"

