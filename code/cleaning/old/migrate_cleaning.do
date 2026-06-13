import delimited "$RAWDATA/dcourt/replication_AER/data/instrument/migration/raw/ICPSR_00020/DS0001/00020-0001-Data.txt", clear

g level = substr(v1,1,1)
g countyicp = substr(v1,3,4)
g statename = strtrim(substr(v1,11,20))
g countyname = strtrim(substr(v1,27,27))
g netbmig = substr(v1,3435,6) 
g netwmig = substr(v1,3399,6) 
g totwmig = substr(v1,3327,7)
g totbmig = substr(v1,3362,7)
g bpop_l = substr(v1,3341,7)
g bpop = substr(v1,3348,7)
g wpop_l = substr(v1, 3306,7)
g wpop = substr(v1, 3313,7)

destring netbmig netwmig bpop_l wpop_l totbmig totwmig wpop bpop, replace

replace netbmig = netbmig / 100
replace netwmig = netwmig / 100
drop if netbmig == .

g netmig = ((bpop_l*netbmig/100) + (wpop_l * netwmig/100) )/ (bpop_l + wpop_l)
g pop_l = bpop_l + wpop_l
keep statename countyname netbmig netwmig countyicp bpop_l wpop_l wpop bpop totbmig totwmig netmig pop_l

duplicates drop

g year = 1950
replace countyname = "MONONGALIA" if countyname == "MONOGALIA"
replace countyname = subinstr(countyname," COUNTY","",.)
//replace countyname = subinstr(countyname," CITY","",.) if statename == "VIRGINIA"

tempfile mig1950
save `mig1950'

keep statename countyname countyicp
tempfile namexwalk
save `namexwalk'

use "$RAWDATA/dcourt/replication_AER/data/instrument/migration/raw/ICPSR_08493/DS0001/08493-0001-Data.dta", clear

rename NAME statename
rename CNTYNAME countyname 
rename V685 netmig
rename V688 netwmig 
rename V691 netbmig
rename V535 totwmig
rename V538 totbmig
rename V22 wpop_l
//rename V202 wpop // the "real" total population, but not used
rename V25 bpop_l
//rename V205 bpop // the "real" total population, but not used
rename V19 pop_l

rename V382 wpop // actually expected, but what was used to calculate migration rates
rename V385 bpop // actually expected, but what was used to calculate migration rates
keep statename countyname netwmig netbmig wpop_l bpop_l wpop bpop totbmig totwmig netmig pop_l

drop if countyname == ""

g year = 1960

replace statename = "LOUISIANA" if statename == "LOUISANA" // lol c'mon now
replace countyname = subinstr(countyname,".","",.)
replace countyname = subinstr(countyname," COUNTY","",.)

merge 1:1 statename countyname using `namexwalk', keep(1 3) nogen
sort statename countyname
tempfile mig1960
save `mig1960'


use "$RAWDATA/dcourt/replication_AER/data/instrument/migration/raw/ICPSR_08493/DS0002/08493-0002-Data.dta", clear

rename NAME statename
rename CNTYNAME countyname 
rename V685 netmig
rename V688 netwmig 
rename V691 netbmig
rename V535 totwmig
rename V538 totbmig
rename V19 pop_l
rename V22 wpop_l
//rename V202 wpop // the "real" total population, but not used
rename V25 bpop_l
//rename V205 bpop // the "real" total population, but not used
rename V382 wpop // actually expected, but what was used to calculate migration rates
rename V385 bpop // actually expected, but what was used to calculate migration rates
keep statename countyname netwmig netbmig wpop_l bpop_l wpop bpop totbmig totwmig netmig pop_l

drop if countyname == ""
replace statename = "LOUISIANA" if statename == "LOUISANA" // lol c'mon now
replace countyname = subinstr(countyname,".","",.)
replace countyname = subinstr(countyname," COUNTY","",.)

g year = 1970
merge 1:1 statename countyname using `namexwalk', keep(1 3) nogen

append using `mig1960'
append using `mig1950'


statastates, name(statename)
/*
drop _merge
destring countyicp, replace
replace countyicp = 890 if countyname == "HENRY COUNTY" & state_abbrev == "VA"
replace countyicp = 7000 if countyname == "NEWPORT NEWS CITY" & state_abbrev == "VA"
replace countyicp = 360 if countyname == "CHARLES CITY" & state_abbrev == "VA"
replace countyicp = 1290 if countyname == "NORFOLK" & state_abbrev == "VA" & year == 1950 & countyicp == 290
replace countyicp = 7600 if countyname == "RICHMOND CITY" & state_abbrev == "VA" & year == 1950 & countyicp == 600
tostring netbmig, gen(netbmig_str) force format(%4.1f)

// I HATE FLOATING POINTS
replace netbmig_str = "-19.0" if countyname == "ALBEMARLE" & year == 1950 & state_abbrev == "VA" & countyicp == 30
replace netbmig_str = "8.9" if netbmig_str == "8.8" & state_abbrev == "VA" & countyicp == 950
replace netbmig_str = "15.9" if netbmig_str == "15.8" & state_abbrev == "FL" & countyicp == 950
replace netbmig_str = "-15.4" if year == 1950 & state_abbrev == "FL" & countyicp == 530
replace countyname = "OCHILTREE" if countyname == "OCHILTRES"
*/

drop if state_abbrev == "AK" 
destring countyicp, replace

replace countyicp = 3570 if countyname == "OCHILTREE"
replace countyicp = 1510 if countyname == "PRINCE WILLIAM" & year > 1950


preserve
	use "$XWALKS/consistent_1990", clear
	keep if inlist(year, 1950,1960,1970)
	ren nhgiscty countyfips 
	ren nhgisst state
	ren icpsrst stateicp 
	ren icpsrcty countyicp
	keep countyfips state year stateicp countyicp statenam nhgisnam
	statastates, name(statenam) nogen
	
	// Looks like some data entry errors
	replace countyicp = 1570 if stateicp == 44 & countyicp == 1510 & nhgisnam == "Jackson"
	replace countyicp = 1350 if stateicp == 32 & countyicp == 1370 & nhgisnam == "Ness" & year == 1970
	replace countyicp = 1330 if stateicp == 32 & countyicp == 1350 & nhgisnam == "Neosho" & year == 1970
	duplicates drop
	tempfile xwalk
	save `xwalk'
restore

drop if mi(countyicp)
drop _merge
merge 1:1 year countyicp state_abbrev using `xwalk', keep(1 3) nogen

save "$INTDATA/south_migrate", replace


