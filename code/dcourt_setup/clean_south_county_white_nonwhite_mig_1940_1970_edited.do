/*-----------------------------------------------------------------------------------------
SUMMARY: 
	This do file constructs white and nonwhite net migration rates from 1940-1970.
-----------------------------------------------------------------------------------------*/

* 1930-1950
import delimited using $migdata/raw/ICPSR_00020/DS0001/00020-0001-Data.txt, ///
    clear ///
    varnames(nonames) ///
    delimiters("§") ///
    stringcols(_all) ///
    bindquote(nobind)

	g state_name = strtrim(substr(v1,11,20))
	g countyname = strtrim(substr(v1,27,27))
	cd "$xwalks"
	statastates, name(state_name)

	keep if _merge==3
	drop _merge

	replace state_name = proper(state_name)
	gen south=(state_name=="Alabama" | state_name=="Arkansas" | state_name=="Florida" | state_name=="Georgia" | state_name=="Kentucky"| state_name=="Louisiana" | state_name=="Mississippi" | state_name=="North Carolina" | state_name=="Oklahoma" | state_name=="South Carolina" | state_name=="Tennessee" | state_name=="Texas" | state_name=="Virginia" | state_name=="West Virginia")

	drop if south==0

	g county_name = proper(countyname) + " County, " + state_abbrev

	g whitemig1940=substr(v1,3320,7)
	g whitemig1950=substr(v1,3327,7)

	g blackmig1940=substr(v1,3355,7)
	g blackmig1950=substr(v1,3362,7)
	
	// Edit: What I need for white instrument
	g wpop_l1950 = substr(v1, 3306,7)
	g netbmig1950 = substr(v1,3435,6) 
	g netwmig1950 = substr(v1,3399,6) 

	
	keep county_name whitemig* blackmig* wpop_l* netbmig* netwmig*
	destring whitemig* blackmig* wpop_l* netbmig* netwmig*, replace
	replace netbmig1950 = netbmig1950 / 100
	replace netwmig1950 = netwmig1950 / 100
	drop if netbmig1950 == .
	
	merge 1:1 county_name using $xwalks/county1940_crosswalks.dta, keep (3) nogenerate

	tempfile white_black_mig_1930_1950
	save `white_black_mig_1930_1950'

	* 1950-1970
	use $migdata/raw/ICPSR_08493/DS0002/08493-0002-Data.dta, clear
	cap rename v* V*

	g whitemig1970=V535
	g nonwhitemig1970=V538
	
	// Edit: What I need for white instrument
	rename V688 netwmig1970 
	rename V691 netbmig1970
	rename V22 wpop_l1970

	replace CNTYNAME="ORMSBY" if CNTYNAME == "CARSON CITY CITY"
	replace CNTYNAME="NORFOLK COUNTY" if CNTYNAME=="NORFOLK CITY"

	keep NAME CNTYNAME whitemig1970 nonwhitemig1970 netwmig* netbmig* wpop_l*

	merge 1:1 NAME CNTYNAME using $migdata/raw/ICPSR_08493/DS0001/08493-0001-Data.dta, keep (3) nogenerate keepusing(V535 V538 V688 V691 V22)

	g whitemig1960=V535
	g nonwhitemig1960=V538

	// Edit: What I need for white instrument
	rename V688 netwmig1960 
	rename V691 netbmig1960
	rename V22 wpop_l1960


	keep NAME CNTYNAME whitemig* nonwhitemig* netwmig* netbmig* wpop_l*
 
	g state_name = proper(NAME)
	replace state_name= "Louisiana" if state_name=="Louisana"

	cd "$xwalks"
	statastates, name(state_name)

	keep if _merge==3
	drop _merge

	replace state_name = proper(state_name)
	gen south=(state_name=="Alabama" | state_name=="Arkansas" | state_name=="Florida" | state_name=="Georgia" | state_name=="Kentucky"| state_name=="Louisiana" | state_name=="Mississippi" | state_name=="North Carolina" | state_name=="Oklahoma" | state_name=="South Carolina" | state_name=="Tennessee" | state_name=="Texas" | state_name=="Virginia" | state_name=="West Virginia")

	drop if south==0

	drop if CNTYNAME==""

	g county_name = proper(CNTYNAME) + " County, " + state_abbrev

	replace county_name = subinstr(county_name, " County", "", 1) if regexm(county_name,"County County")==1
	replace county_name=subinstr(county_name, "St.", "St",.) 

	replace county_name="Baltimore County, MD" if county_name == "Baltimore County County, MD"
	replace county_name="Arlington/Alexand County, VA" if county_name=="Arlington County, VA"
	replace county_name="Bartow/Cass County, GA" if county_name=="Bartow County, GA"
	replace county_name="Bradford/New Rive County, FL" if county_name=="Bradford County, FL"
	replace county_name="Brevard/St Lucie County, FL" if county_name=="Brevard County, FL"
	replace county_name="Calhoun/Benton County, AL" if county_name=="Calhoun County, AL"
	replace county_name="Cass/Davis County, TX" if county_name=="Cass County, TX"
	replace county_name="Chilton/Baker County, AL" if county_name=="Chilton County, AL"
	replace county_name="Hampton County, VA" if county_name=="Hampton City County, VA"
	replace county_name="Hernando/Benton County, FL" if county_name=="Hernando County, FL"
	replace county_name="Lamar/Sanford County, AL" if county_name=="Lamar County, AL"
	replace county_name="Morgan/Cotaco County, AL" if county_name=="Morgan County, AL"
	replace county_name="Muscogee County, GA" if county_name=="Muscogee-Chattahoochee County, GA"
	replace county_name="Newport News County, VA" if county_name=="Newport News City County, VA"
	replace county_name="Orange/Mosquito County, FL" if county_name=="Orange County, FL"
	replace county_name="St John The Bapti County, LA" if county_name=="St John The Baptist County, LA"
	replace county_name="Stephens/Buchanan County, TX" if county_name=="Stephens County, TX"
	replace county_name="Vermillion County, LA" if county_name=="Vermilion County, LA"
	replace county_name="Winston/Hancock County, AL" if county_name=="Winston County, AL"
	replace county_name="Norfolk City County, VA" if county_name == "Norfolk County, VA"

	merge 1:1 county_name using $xwalks/county1940_crosswalks.dta, keep (3) nogenerate

	merge 1:1 county_name using `white_black_mig_1930_1950', keep (3) nogenerate

	order blackmig* whitemig* nonwhitemig*

	rename blackmig1950 nonwhitemig1950
	drop *1940 black* 
	
	keep whitemig* nonwhitemig* state_name state_abbrev state_fips county_name fips_str fips netbmig* netwmig* wpop_l*  countyicp stateicp

	reshape long whitemig nonwhitemig netbmig netwmig wpop_l , i(countyicp stateicp state_name state_abbrev state_fips county_name fips_str fips) j(year)

	save $migdata/clean_south_county_white_nonwhite_mig_1940_1970.dta, replace


