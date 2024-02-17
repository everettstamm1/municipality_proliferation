

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
		 


preserve
	import delimited using "$CLEANDATA/corelogic/censusplace_clogic_ptile.csv", clear
	replace ptile = ptile*100
	ren land_square_footage sfr_p
	drop acres name
	reshape wide sfr_p, i(geoid) j(ptile)
	g STATEFP = floor(geoid/100000)
	g PLACEFP = mod(geoid,100000)
	tempfile new_corelogic
	save `new_corelogic'
restore
merge 1:1 STATEFP PLACEFP using `new_corelogic', keep(1 3) nogen

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
	keep cz popc1940 GM_raw_pp GM_hat_raw_pp blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
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

/*
drop if yr_incorp>1970
g time = 1 if yr_incorp <1940
replace time = 2 if yr_incorp>=1940 & yr_incorp<=1970

g treat = 2*above_inst_med
 


foreach w in none pop{ 
    local wlab: variable label weight_`w'  
	eststo clear
		
	foreach covar of varlist landuse_sfr landuse_sfr_plus landuse_nonsfr landuse_apartment {
		eststo `covar' : didregress `covar' i.region [weight=weight_`w'], time(time) gvar(treat)
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


*/


ren STATEFP fips_state
ren PLACEFP fips_place_2002
merge 1:1 fips_state fips_place_2002 using "$INTDATA/census/IndFin12", keep(1 3) nogen

g pct_rev_ff = 100*finesandforfeits/totalrevenue
g pct_rev_sa = 100*specialassessments/totalrevenue
g pct_rev_debt = 100*totaldebtoutstanding/totalrevenue

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

replace landuse_sfr = 100*landuse_sfr
replace landuse_apartment = 100*landuse_apartment 

forv iv=0/1{
	if "`iv'"=="0" local mod "Reduced Form"
	if "`iv'"=="1" local mod "IV"
	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt {
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


	esttab using "$TABS/land_use_index/muni_outcomes_`iv'.tex", booktabs compress label replace lines se frag ///
				starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(above_*_med samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{5}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 



}


forv iv=0/1{
	if "`iv'"=="0" local mod "Reduced Form"
	if "`iv'"=="1" local mod "IV"
	eststo clear
	foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt {
		local mname = subinstr("`covar'","landuse_", "",.)
		lab var `covar' "`mname'"
		di "`covar'"
		if "`iv'"=="1"{
			 eststo `covar' : ivreghdfe `covar' samp_dest (above_x_med samp_destXabove_x_med = above_inst_med samp_destXabove_z_med) blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total [aw=weight_pop], absorb(region) cl(cz)

		}
		else{
			 eststo `covar' : reghdfe `covar' above_inst_med samp_destXabove_z_med samp_dest blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total [aw=weight_pop], vce(cl cz) absorb(region)
		}
	}


	esttab using "$TABS/land_use_index/muni_outcomes_`iv'_new_ctrls.tex", booktabs compress label replace lines se frag ///
				 starlevels( * 0.10 ** 0.05 *** 0.01) ///
				mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}") ///
				mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(above_*_med samp_*) b(%04.3f) se(%04.3f) ///
				prehead( \begin{tabular}{l*{5}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 

}


// Continuous DID model
drop if yr_incorp>1970
g time = 1 if yr_incorp <1940
replace time = 2 if yr_incorp>=1940 & yr_incorp<=1970

g treat = cond(time==1,GM_hat_raw_pp,0)

eststo clear
foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt {
	local mname = subinstr("`covar'","landuse_", "",.)
	lab var `covar' "`mname'"
	di "`covar'"
	eststo `covar' : didregress (`covar' i.region blackmig3539_share) (treat, continuous) [aw=weight_pop], group(cz) time(time) vce(cl cz)


	
}


esttab using "$TABS/land_use_index/muni_outcomes_continuous_did.tex", booktabs compress label replace lines se frag ///
			 starlevels( * 0.10 ** 0.05 *** 0.01) ///
			mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}") ///
			mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(treat) b(%04.3f) se(%04.3f) ///
			prehead( \begin{tabular}{l*{5}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 
			
			

eststo clear
foreach covar of varlist landuse_sfr landuse_apartment pct_rev_ff pct_rev_sa pct_rev_debt {
	local mname = subinstr("`covar'","landuse_", "",.)
	lab var `covar' "`mname'"
	di "`covar'"
	eststo `covar' : didregress (`covar' i.region blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total) (treat, continuous) [aw=weight_pop], group(cz) time(time) vce(cl cz)


	
}


esttab using "$TABS/land_use_index/muni_outcomes_continuous_did_new_ctrls.tex", booktabs compress label replace lines se frag ///
			 starlevels( * 0.10 ** 0.05 *** 0.01) ///
			mtitles("Single Family" "Apartments" "Fines/Forfeits" "\shortstack{Special \\ Assessments}" "\shortstack{Outstanding \\ Debt}") ///
			mgroups("\shortstack{Percentage of \\ Municipal Land Uses}" "\shortstack{Percentage of \\ Municipal Revenues}", pattern(1 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(treat) b(%04.3f) se(%04.3f) ///
			prehead( \begin{tabular}{l*{5}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) 



