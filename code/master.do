
// ADD AN IF ELSE BLOCK WITH YOUR COMPUTER'S ABSOLUTE PATH TO THE MUNICIPALITY PROLIFERATION DROPBOX FOLDER
if "`c(username)'"=="Everett Stamm"{
	gl DROPBOX "/Users/Everett Stamm/Dropbox/municipality_proliferation/"
	gl REPO "/Users/Everett Stamm/Documents/Github/municipality_proliferation/"
}

gl DATA "$DROPBOX/data"
gl CODE "$REPO/code"
gl DCOURT "$DROPBOX/derenoncourt_opportunity/replication_AER"

gl RAWDATA "$DATA/raw"
gl INTDATA "$DATA/interim"

gl XWALKS "$DATA/xwalks"

gl FIGS "$REPO/exhibits/figures"
gl TABS "$REPO/exhibits/tables"
gl MAPS "$REPO/exhibits/maps"
// Settings
set maxvar 30000