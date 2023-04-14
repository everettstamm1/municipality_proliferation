// Crossswalk Construction
// Creating an xwalk for msa-pmsa codes to their names since it doesn't exist in the cog data.
// source: https://www2.census.gov/programs-surveys/metro-micro/geographies/reference-files/1999/historical-delineation-files/99mfips.txt

import delimited using "$RAWDATA/census/99mfips.txt", clear rowr(21:2173) delim("@")

g fips_msa_cmsa = substr(v1,1,4)
g fips_pmsa = substr(v1,9,4)
g fips_cmsa_alt = substr(v1,17,2)
g fips_state = substr(v1,25,2)
g fips_county = substr(v1,27,3)
g central_outlying = substr(v1,33,1)
g fips_entity = substr(v1,41,4)
g name = substr(v1,49,.)

drop v1
foreach var of varlist _all{
	replace `var' = strtrim(`var')
}

g is_cmsa = regexm(name,"CMSA")==1
g is_pmsa = regexm(name,"PMSA")==1
g is_msa = regexm(name,"MSA")==1 & regexm(name,"CMSA")==0 & regexm(name,"PMSA")==0

bys fips_msa_cmsa (is_cmsa) : g in_cmsa = is_cmsa[_N]
bys fips_pmsa (is_pmsa) : g in_pmsa = is_pmsa[_N]
bys fips_msa_cmsa (is_msa) : g in_msa = is_msa[_N]

g name_cmsa = name if is_cmsa==1
g name_pmsa = name if is_pmsa==1
g name_msa = name if is_msa==1

bys fips_msa_cmsa (is_cmsa) : replace name_cmsa = name_cmsa[_N]
bys fips_pmsa (is_pmsa) : replace name_pmsa = name_pmsa[_N]
bys fips_msa_cmsa (is_msa) : replace name_msa = name_msa[_N]

g msapmsa_name = cond(name_pmsa!="",name_pmsa,name_msa)
g fips_msapmsa = cond(fips_pmsa!="",fips_pmsa,fips_msa_cmsa)
// county-pmsa/msa xwalk
preserve
	keep if fips_state!="" &  fips_county!=""
	destring fips_msapmsa, gen(msapmsa2000)
	g county = fips_state + fips_county
	destring county, replace
	keep msapmsa2000 county msapmsa_name
	duplicates drop
	
	// Some counties repeated between MSAs. Forcing a random drop for now, come up with better solution later
	duplicates drop county, force
	rename county cty_fips
	save "$XWALKS/county_pmsa_xwalk.dta", replace
restore

// pmsa names xwalk

destring fips_msapmsa, gen(fips_code_msa)
keep fips_code_msa msapmsa_name
duplicates drop
save "$XWALKS/pmsa_names.dta", replace


// Crosswalking to 2002 Place FIPS codes
import excel using "$RAWDATA/cog/4_Govt_Org_Directory_Surveys/GOVS_ID_to_FIPS_Place_Codes_2002.xls",  cellrange(B17) firstrow clear
rename C census_id
rename digit ID
rename code ID_state
rename E ID_type
rename F ID_county
rename Name name
rename AreaName county_name
rename I fips_state
rename J fips_county_2002
rename K fips_place_2002

g ID_unit = substr(ID,7,9)
drop ID
drop if census_id==""
duplicates drop
save "$XWALKS/cog_ID_fips_place_xwalk_02.dta", replace

// Crosswalking 2002 and 2007 county FIPS codes

import excel using "$RAWDATA/cog/1-3_Govt_Org_Nat_CoArea_ElecOff/GOVS_to_FIPS_Codes_State_&_County_2007.xls", sheet(County Codes) cellrange(A15) firstrow clear
drop A
drop if _n>3223
rename code ID_state
rename D ID_county
rename Name name
rename F fips_state
rename CoG fips_county_2002
rename H fips_county_2007

// Dropping states and US total
drop if ID_county=="000"

// Spot change for one misbehaving alaskan census area
replace name  = "SKAGWAY-HOONAH-ANGOON CENSUS AREA [changed for 2007]" + ", " + "HOONAH-ANGOON CENSUS AREA [new for 2007]" if ID == "02018"
replace fips_county_2002 = "232" if ID == "02018"
replace fips_county_2007 = "105" if ID == "02018"
duplicates drop
drop ID
save "$XWALKS/cog_ID_fips_xwalk_02_07.dta", replace

// Crosswalking 2012 county FIPS codes
import excel using "$RAWDATA/cog/1-3_Govt_Org_Nat_CoArea_ElecOff/2012_GOVS_COUNTY_to_FIPS_COUNTY.xls",  firstrow clear
rename GOVS_STATE ID_state
rename GOVS_COUNTY ID_county
rename COUNTY_NAME name
rename FIPS_STATE fips_state
rename FIPS_COUNTY fips_county_2012

save "$XWALKS/cog_ID_fips_xwalk_12.dta", replace


/*
// Cleaning COG 1 State counts
import excel using "$RAWDATA/cog/1-3_Govt_Org_Nat_CoArea_ElecOff/1_Govt_Org_Nat_State_Counts.xls", sheet(Table 1) clear



local tabs  1 2 3 4 5 6 7 8 9 10 11 12a 12b 13 14 15 16 17a 17b 17c 18 19a ///
							19b 19c 20 21 22 23 24a 24b 24c Exhibit1 Exhibit2 Exhibit3 "Resp Rates"

foreach tab in `tabs'{
	local tabname = cond(regexm("`tab'","Exhibit|Resp"),"`tab'","Table "+"`tab'")
	import excel using  "$RAWDATA/cog/1-3_Govt_Org_Nat_CoArea_ElecOff/1_Govt_Org_Nat_State_Counts.xls", sheet("`tabname'") clear
}	
*/
// Cleaning COG 2 county counts

import excel using "$RAWDATA/cog/1-3_Govt_Org_Nat_CoArea_ElecOff/2_Govt_Org_County_Area_Counts.xls", sheet(Data) cellrange(A14) firstrow clear

drop A SortCode Notes Blank1

// Changing to names I like
rename Name name
rename Source source
rename Year4 year
rename YrPop year_pop
rename Level level
rename Locals all_local
rename Locals_PropTaxPower all_local_tax
rename County gen_county
rename SubcountyGenPurp gen_subcounty
rename City gen_muni
rename Twp gen_town
rename SpDist spdist
rename SpDist_PropTaxPower spdist_tax
rename SchDists schdist_ind
rename Intercnty_City_CtrHere_SrvOth int_muni_here
rename Intercnty_SpDis_CtrHere_SrvOth int_spdist_here
rename Intercnty_SchDis_CtrHere_SrvOth int_schdis_here
rename Intercnty_City_SrvHere_Ctr_Oth int_muni_else
rename Intercnty_SpDis_SrvHere_Ctr_Oth int_spdist_else
rename Intercnty_SchDis_SrvHere_Ctr_Oth int_schdis_else
rename DepSchSys schdist_dep
rename Subord_County_Tax_Area subcty_tax

// Destringing everything
foreach var of varlist *{
	cap confirm string var `var'
	if _rc==0 & inlist("`var'","name","source","ID")==0{
		replace `var' = "" if `var'=="-"
		destring `var', replace
	}
}
egen schdist = rowtotal(schdist_ind schdist_dep)

g ID_state = substr(ID,1,2)
g ID_county = substr(ID,3,3)
drop ID
// Local Govts only
keep if level == 2

merge m:1 ID_state ID_county using "$XWALKS/cog_ID_fips_xwalk_12.dta", nogen keep(1 3)

merge m:1 ID_state ID_county using "$XWALKS/cog_ID_fips_xwalk_02_07.dta", nogen keep(1 3)


// Looks like some misses
replace fips_state = "51" if ID_state=="47" & fips_state==""
replace fips_state = "46" if ID_state=="42" & fips_state==""


g cty_fips = fips_state+fips_county_2002
destring cty_fips, replace

merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", nogen keep(1 3)
merge m:1 cty_fips using "$XWALKS/county_pmsa_xwalk.dta", nogen keep(1 3)
drop cty_fips

lab var name "Name"
lab var year "CoG Year"
lab var year_pop "Census Population Year"
lab var all_local "Number of Local Govts"
lab var all_local_tax "Number of Local Govts w/Prop. Tax Power"
lab var gen_county "Number of County Govts"
lab var gen_subcounty "Number of Subcounty Govts (town, twp, muni)"
lab var gen_muni "Number of Municipal Govts"
lab var gen_town "Number of Town and Township Govts"
lab var spdist "Number of Special Purpose Districts"
lab var spdist_tax "Number of Special Purpose Districts w/Tax Power"
lab var schdist_ind "Number of Independent School Districts"
lab var int_muni_here "Number of Municipalities Centered Here, Serve Elsewhere"
lab var int_spdist_here "Number of Special Districts Centered Here, Serve Elsewhere"
lab var int_schdis_here "Number of School Districts Centered Here, Serve Elsewhere"
lab var int_muni_else "Number of Municipalities Centered Elsewhere, Serve Here"
lab var int_spdist_else "Number of Special Districts Centered Elsewhere, Serve Here"
lab var int_schdis_else "Number of School Districts Centered Elsewhere, Serve Here"
lab var schdist_dep "Number of Dependent School Districts"
lab var subcty_tax "Number of Subordinate County Taxing Areas"
lab var schdist "Number of Dependent and Independent School Districts"

g fips = fips_state+fips_county_2002
destring fips, replace
		
// Township reclassification 1952 IOWA
replace all_local = all_local - gen_town if year==1942 & fips_state=="19"
replace gen_subcounty = gen_subcounty - gen_town if year==1942 & fips_state=="19"
replace gen_town = 0  if year==1942 & fips_state=="19"

// School district reclassification 1952 Mississippi and South Carolina
bys fips (year) : g schdist_ind_impute = schdist_ind[_n+1] if year==1942 & inlist(fips_state,"28","45")
replace all_local = all_local - schdist_ind + schdist_ind_impute if year==1942 & inlist(fips_state,"28","45")
replace schdist_ind = schdist_ind_impute if year==1942 & inlist(fips_state,"28","45")

g all_local_nosch = all_local - schdist_ind
lab var all_local_nosch "Number of Local Govts (no school districts)"


save "$INTDATA/cog/2_county_counts.dta", replace


// Cleaning COG 4 Individual Gov'ts 

// Note: Need to have odbc setup and 4_Govt_Org_Directory_Surveys linked for this code to work
// FAQ for Window's setup: https://www.stata.com/support/faqs/data-management/configuring-odbc-win/


// Need to pre-clean column names as they're 1. too long and 2. contain invalid characters in stata (:)
clear
local dsnname = "4_Govt_Org_Directory_Surveys"
 odbc query "`dsnname'"
// Only need tables 2, 3, and 4
forv i=2/4{
	local tablename_i `.__ODBC_INFO.TABLE[`i']'
	qui odbc describe "`tablename_i'" , dsn("`dsnname'")
	
	local nvars `.__ODBC_INFO.VARIABLES.arrnels' 
	
	if `nvars'>_N{
		set obs `nvars'
	}
	
	local colnames
	forv j=1/`nvars'{

		local varname_i_j  `.__ODBC_INFO.VARIABLES[`j']'

		local varname_i_j = subinstr(`"`varname_i_j'"', ":","",.)
		local varname_i_j = lower(`"`varname_i_j'"')
		local varname_i_j = subinstr(`"`varname_i_j'"', " ","_",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "services","serv",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "percent","pct",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "function","fn",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "provided","prov",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "parks_&_recr","p_r",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "natural","nat",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "resource","res",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "&_","",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "#","n",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "contracted","cont",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "effort","ef",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "of_","",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "/","_",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "facilities","facil",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "public_transit","pub_trans",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "authority","auth",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "sector","sect",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "private","priv",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "electronic","elec",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "electric","elec",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "with","w",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "councils","cncl",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "other","oth",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "reported","rep",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "inland_ports","inld_prts",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "solid_waste","sol_wst",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "directly_by","dir_by",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "refuse_collect","refuse_col",.)
		local varname_i_j = subinstr(`"`varname_i_j'"', "-","_",.)

		local colnames `colnames' `varname_i_j'
		
	} 
	
	odbc load, dsn("`dsnname'") table("`tablename_i'") clear 
	
	local i 1
	foreach var of varlist _all {
			rename `var' v`i'
			rename v`i' `:word `i' of `colnames''
			local ++i
	}
	
	local tablab = lower(subinstr("4_`tablename_i'"," ","_",.))
	
	rename state_code ID_state
	rename type_code ID_type
	rename county_code ID_county
	rename unit_code ID_unit
	
	merge m:1 ID_state ID_county ID_type ID_unit using "$XWALKS/cog_ID_fips_place_xwalk_02.dta", keep(1 3) nogen
	
	// Looks like some misses
	replace fips_state = "51" if ID_state=="47" & fips_state==""
	replace fips_state = "46" if ID_state=="42" & fips_state==""

	
	g cty_fips = fips_state+fips_county_2002
	destring cty_fips, replace
	merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(1 3) nogen
	drop cty_fips
	
	// Destringing everything
	foreach var of varlist *{
		cap confirm string var `var'
		if _rc==0 & inlist("`var'","name","source","ID","fips_code_state","fips_code_county","id")==0{
			replace `var' = "" if `var'=="-"
			destring `var', replace
		}
	}
	
	merge m:1 fips_code_msa using "$XWALKS/pmsa_names.dta", keep(1 3) nogen
	
	save "$INTDATA/cog/`tablab'.dta", replace

}


// Master unit file

* describe sheets
import excel using "$RAWDATA/cog/Govt_Units_2021_Final.xlsx", describe
return list
local n_worksheet = `r(N_worksheet)'

* loop through all sheets, list data, then save
forvalues i=1/`n_worksheet' {
	import excel using "$RAWDATA/cog/Govt_Units_2021_Final.xlsx" ,sheet(`"`r(worksheet_`i')'"') firstrow clear
	keep 	CENSUS_ID_PID6	CENSUS_ID_GIDID	UNIT_NAME	UNIT_TYPE	ADDRESS1 ADDRESS2 ///
				CITY STATE ZIP ZIP4	WEB_ADDRESS	FIPS_STATE FIPS_COUNTY FIPS_PLACE ///
				COUNTY_AREA_NAME IS_ACTIVE
				
	ren CENSUS_ID_PID6 PID
	ren CENSUS_ID_GIDID GID
	ren UNIT_NAME name
	ren UNIT_TYPE subtype
	ren FIPS_STATE fips_state
	ren FIPS_COUNTY fips_county_2020
	ren FIPS_PLACE fips_place_2020
	ren COUNTY_AREA_NAME county_name
	ren IS_ACTIVE active
	
	g type = `i'
	
	tempfile sheet_`i'
	save `sheet_`i''
}
clear
forv i=1/`n_worksheet'{
	append using `sheet_`i''
}


label define type 1 "General Purpose" ///
									2 "Special District" ///
									3 "School District" ///
									4 "Dependent School District"
									
label define subtype 	1 "County" ///
											2 "Municipal" ///
											3 "Township"

replace subtype = substr(subtype,1,1)
destring subtype, replace

label values type type
label values subtype subtype

save "$INTDATA/cog/master_2021.dta", replace
