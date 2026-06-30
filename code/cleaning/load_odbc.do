if `load_odbc' == 1{

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
			
		save "$INTDATA/cog/`tablab'.dta", replace

	}
	clear
	odbc query "City_Gov_Fin"
	odbc load, table("City_Govt_Finances")

	save "$INTDATA/census/city_gov_fin.dta", replace

}