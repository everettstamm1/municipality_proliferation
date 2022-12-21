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
rename Locals_PropTaxPower all_locals_tax
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

// Local Govts only
keep if level == 2

// Crosswalking to FIPS codes
preserve
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
	
	save "$XWALKS/cog_ID_fips_xwalk_02_07.dta", replace
restore


// Crosswalking to FIPS codes
preserve
	import excel using "$RAWDATA/cog/1-3_Govt_Org_Nat_CoArea_ElecOff/2012_GOVS_COUNTY_to_FIPS_COUNTY.xls",  firstrow clear
	rename GOVS_STATE ID_state
	rename GOVS_COUNTY ID_county
	rename COUNTY_NAME name
	rename FIPS_STATE fips_state
	rename FIPS_COUNTY fips_county_2012
	
	// Dropping states and US total
	//drop if ID_county=="000"
	
	g ID = ID_state + ID_count
	
	save "$XWALKS/cog_ID_fips_xwalk_12.dta", replace
restore

merge m:1 ID using "$XWALKS/cog_ID_fips_xwalk_12.dta", nogen

merge m:1 ID using "$XWALKS/cog_ID_fips_xwalk_02_07.dta", nogen

save "$INTDATA/cog/2_county_counts.dta"
