

// Wharton vars
use "$CLEANDATA/other/municipal_shapefile_attributes.dta", clear
drop if ak_hi == 1
preserve 
	use "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", clear
	keep state_id region
	rename state_id STATEFP
	duplicates drop
	tempfile regions
	save `regions'
restore 
merge m:1 STATEFP using `regions', keep(1 3) nogen
tabulate region, gen(reg)	

// Some places span multiple counties, dropping those
drop COUNTYFP cty_fips
duplicates drop

// As a result, we have duplicates in our CZ crosswalk. Force drop with tiebreak on being in sample 130 CZs
duplicates tag STATEFP PLACEFP, gen(dup)
bys STATEFP PLACEFP (sample_130_czs) : drop if dup == 1 & _n == 1
drop dup 

// Dropping noncomparables
drop if FUNCSTAT=="S" | /// "Statistical entities"
		 FUNCSTAT=="F" | /// Fictitious entity created to fill the Census Bureau geographic hierarch
		 FUNCSTAT=="N" | /// Nonfunctioning legal entity	
		 FUNCSTAT=="I" // Inactive governmental unit that has the power to provide primary special-purpose functions
		 
// All cities vs cities in our 130 CZs incorporated 1940-70
g samp_full = (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
lab var samp_full "Full Sample"

g samp_nonsouthern = .
replace samp_nonsouthern = 1 if (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_nonsouthern = 0 if (yr_incorp <1940 | yr_incorp >1970) & sample_130_czs==1

lab var samp_nonsouthern "Nonsouthern Sample"

g samp_full_pre = .
replace samp_full_pre = 1 if (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_full_pre = 0 if (yr_incorp <1940)
lab var samp_full "Full Sample, pre-1970 only"

g samp_nonsouthern_pre = .
replace samp_nonsouthern_pre = 1 if (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_nonsouthern_pre = 0 if yr_incorp <1940 & sample_130_czs==1
lab var samp_full "Nonsouthern Sample, pre-1970 only"

g samp_dest = .
replace samp_dest = 1 if (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_dest = 0 if (yr_incorp <1940 | yr_incorp >1970) & sample_130_czs==1
lab var samp_dest "Incorporated 1940-70"

g samp_dest_pre = .
replace samp_dest_pre = 1 if (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_dest_pre = 0 if (yr_incorp <1940 ) & sample_130_czs==1
lab var samp_dest_pre "Destination CZ sample, pre-1970 only"


g weight_none = 1
lab var weight_none "Unweighted"

g weight_pop = population
lab var weight_pop "Weighted by population"
 
g weight_popdens = population/ALAND
lab var weight_pop "Weighted by population density"

preserve
	use "$CLEANDATA/cz_pooled", clear
	keep if dcourt == 1
	keep cz popc1940 GM_raw_pp GM_hat_raw_pp blackmig3539_share 
	qui su GM_raw_pp, d
	g above_x_med = GM_raw_pp >= `r(p50)'

	qui su GM_hat_raw_pp, d
	g above_inst_med = GM_hat_raw_pp >= `r(p50)'
	tempfile inst
	save `inst'
restore

merge m:1 cz using `inst', keep(1 3)
g dcourt = _merge==3
drop _merge

replace above_inst_med = 0 if above_inst_med==.
replace above_x_med = 0 if above_x_med==.

g samp_dest_xabove = samp_dest if above_x_med == 1
g samp_dest_xbelow = samp_dest if above_x_med == 0

g samp_dest_zabove = samp_dest if above_inst_med == 1
g samp_dest_zbelow = samp_dest if above_inst_med == 0


g samp_dest_pre_xabove = samp_dest_pre if above_x_med == 1
g samp_dest_pre_xbelow = samp_dest_pre if above_x_med == 0

g samp_dest_pre_zabove = samp_dest_pre if above_inst_med == 1
g samp_dest_pre_zbelow = samp_dest_pre if above_inst_med == 0


egen landuse_sfr_plus = rowtotal(landuse_sfr landuse_residentialnec), m
egen landuse_nonsfr = rowtotal(landuse_apartment landuse_multifam landuse_triplex landuse_duplex landuse_townhouse landuse_condo landuse_mobilehome ), m



drop if yr_incorp>1970
g time = 1 if yr_incorp <1940
replace time = 2 if yr_incorp>=1940 & yr_incorp<=1970

g treat = 2*above_inst_med
 


foreach w in none pop{ 
    local wlab: variable label weight_`w'  
	eststo clear
		
	foreach covar of varlist landuse_sfr landuse_sfr_plus landuse_nonsfr landuse_apartment {
		eststo `covar' : csdid `covar' i.region [weight=weight_`w'], time(time) gvar(treat)
	}


	esttab using "$TABS/land_use_index/corelogic_weight_`w'_csdid_full.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1})   starlevels( * 0.10 ** 0.05 *** 0.01)
	
}

drop if dcourt==0

foreach w in none pop{ 
    local wlab: variable label weight_`w'  
	eststo clear
		
	foreach covar of varlist landuse_sfr landuse_sfr_plus landuse_nonsfr landuse_apartment {
		eststo `covar' : csdid `covar' i.region [weight=weight_`w'], time(time) gvar(treat)
	}


	esttab using "$TABS/land_use_index/corelogic_weight_`w'_csdid_within.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1})   starlevels( * 0.10 ** 0.05 *** 0.01)
	
}



g samp_destXabove_x_med = samp_dest * above_x_med
g samp_destXabove_z_med = samp_dest * above_inst_med


g samp_dest_preXabove_x_med = samp_dest_pre * above_x_med
g samp_dest_preXabove_z_med = samp_dest_pre * above_inst_med

g samp_destXGM = samp_dest * GM_raw_pp
g samp_dest_preXGM = samp_dest_pre * GM_raw_pp

g samp_destXGM_hat = samp_dest * GM_hat_raw_pp
g samp_dest_preXGM_hat = samp_dest * GM_hat_raw_pp

lab var above_inst_med "Above Median $\widehat{GM}$"
lab var samp_destXabove_z_med "Above Median $\widehat{GM}$ X Incorporated 1940-70"

lab var above_x_med "Above Median GM"
lab var samp_destXabove_x_med "Above Median GM X Incorporated 1940-70"


forv iv=0/1{
	if "`iv'"=="0" local mod "Reduced Form"
	if "`iv'"=="1" local mod "IV"
	eststo clear
	foreach covar of varlist landuse_sfr landuse_sfr_plus landuse_nonsfr landuse_apartment {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		if "`iv'"=="1"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) blackmig3539_share [aw=weight_pop], absorb(region) cl(cz)

		}
		else{
			 eststo `covar' : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest blackmig3539_share [aw=weight_pop], vce(cl cz) absorb(region)
		}
	}


	esttab using "$TABS/land_use_index/corelogic_`iv'.tex", booktabs nonumber label replace lines se ///
				title("`mod' Estimates, Region FEs, weighted by population") starlevels( * 0.10 ** 0.05 *** 0.01) ///
				addnotes("Non-Single Family land uses include apartments, multifamily, triplexes, duplexes, townhomes, condos, and mobile homes.") ///
				mtitles("Single Family" "Single Family plus N.E.C." "Non-Single Family" "Apartments") keep(above_*_med samp_*)
}



ren STATEFP fips_state
ren PLACEFP fips_place_2002
merge 1:1 fips_state fips_place_2002 using "$INTDATA/census/IndFin12", keep(1 3) nogen


foreach tax of varlist finesandforfeits totchgsandmiscrev specialassessments liquorstoresrevenue{
    g pct_rev_`tax' = `tax'/totalrevenue
}

foreach spend of varlist correcttotalexp  policeprottotalexp  publicwelftotalexp totalinterestondebt{
    g pct_spend_`spend' = `spend'/totalexpenditure
}

forv iv=0/1{
	if "`iv'"=="0" local mod "Reduced Form"
	if "`iv'"=="1" local mod "IV"
	eststo clear
	foreach covar of varlist pct_rev_finesandforfeits pct_rev_totchgsandmiscrev pct_rev_specialassessments pct_rev_liquorstoresrevenue pct_spend_correcttotalexp  pct_spend_policeprottotalexp  pct_spend_publicwelftotalexp pct_spend_totalinterestondebt{

		if "`iv'"=="1"{
			 eststo : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) blackmig3539_share [aw=weight_pop], absorb(region) cl(cz)

		}
		else{
			 eststo : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest blackmig3539_share [aw=weight_pop], vce(cl cz) absorb(region)
		}
	}


	esttab using "$TABS/land_use_index/IndFin12_`iv'.tex", label booktabs nonumber replace lines se ///
				title("`mod' Estimates, Region FEs, weighted by population") starlevels( * 0.10 ** 0.05 *** 0.01) ///
				keep(above_*_med samp_*) mgroups("Percent of Revenues" "Percent of Expenditures", pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
				mtitles("Fines/Forfeits" "Charges" "Special Assessments" "Liquor Store" "Correctional" "Police" "Welfare" "Interest on Debt")
}



preserve
	use "$INTDATA/cog/4_1_general_purpose_govts", clear
	keep if ID_type == 2 & fips_place_2002<. // Keeping only munis
	ren hous_com_dev_* hcd_*
	encode govt_body_employment_status, gen(temp)
	drop govt_body_employment_status
	ren temp govt_body_employment_status
	
	//drop if home_rule_charter == . & govt_body_employment_status == . & type_govt_body_compensation == . & law_enforce_not_prov == . & hcd_not_prov == . 
	foreach var of varlist home_rule_charter type_govt_body_compensation govt_body_employment_status law_enforce_* hcd_* {
	    bys fips_place_2002 fips_state (`var') : replace `var' = `var'[1]
	}
	keep fips_place_2002 fips_state home_rule_charter law_enforce_* hcd_* govt_body_employment_status type_govt_body_compensation
	
	duplicates drop
	
	g salaried = type_govt_body_compensation==1
	g full_time = govt_body_employment_status==1
	egen hcd_provided = rowmin(hcd_prov_directly hcd_cont_out hcd_cont_w_priv_sect hcd_cont_w_oth_govt hcd_owned_and_cont hcd_not_owned_but_cont)
	egen law_enforce_self = rowmin(law_enforce_prov_directly law_enforce_cont_w_priv_sect)
	
	keep hcd_provided hcd_not_prov law_enforce_self law_enforce_not_prov law_enforce_prov_directly law_enforce_cont_w_oth_govt full_time salaried home_rule_charter fips_state fips_place_2002
	
	foreach var of varlist home_rule_charter law_enforce_not_prov hcd_not_prov law_enforce_not_prov law_enforce_prov_directly law_enforce_cont_w_oth_govt{
		replace `var' = mod(`var',2)
	}
	ren fips_place_2002 PLACEFP 
	ren fips_state STATEFP
	
	tempfile cog_directory
	save `cog_directory'
restore

merge 1:1 STATEFP PLACEFP using `cog_directory', keep(1 3) nogen


forv iv=0/1{
	if "`iv'"=="0" local mod "Reduced Form"
	if "`iv'"=="1" local mod "IV"
	eststo clear
	foreach covar of varlist home_rule_charter hcd_provided hcd_not_prov law_enforce_self law_enforce_not_prov law_enforce_prov_directly law_enforce_cont_w_oth_govt full_time salaried  {

		if "`iv'"=="1"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) blackmig3539_share [aw=weight_pop], absorb(region) cl(cz)

		}
		else{
			 eststo `covar' : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest blackmig3539_share [aw=weight_pop], vce(cl cz) absorb(region)
		}
	}


	esttab using "$TABS/land_use_index/directory_surveys_`iv'.tex", booktabs nonumber replace lines se ///
				title("`mod' Estimates, Region FEs, weighted by population") starlevels( * 0.10 ** 0.05 *** 0.01) ///
				keep(above_*_med samp_*)
}
