

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

g weight_none = 1
lab var weight_none "Unweighted"
foreach w in none full metro{ 
    local wlab: variable label weight_`w'  
	eststo clear
	forv s=1/4 {
	    if "`s'"=="1" local samp samp_full
		if "`s'"=="2" local samp samp_nonsouthern
	    if "`s'"=="3" local samp samp_full_pre
	    if "`s'"=="4" local samp samp_nonsouthern_pre

		preserve
			local lab: variable label `samp'  
			foreach covar of varlist LPPI18 SPII18 LPAI18 LZAI18 SRI18 DRI18 EI18 AHI18 ADI18 WRLURI18 {
				local clab: variable label `covar'  		
				g `covar'_t = `covar'
				lab var `covar'_t "`clab'"
				replace `covar' = `samp'
				qui eststo `covar'`s': reg `covar'_t `covar' [aw=weight_`w'], r

				
			}

			eststo tests`s' : appendmodels LPPI18`s' SPII18`s' LPAI18`s' LZAI18`s' SRI18`s' DRI18`s' EI18`s' AHI18`s' ADI18`s' WRLURI18`s'
			
		restore
			
	}
	esttab tests1 tests2 tests3 tests4 using "$TABS/land_use_index/wharton_weight_`w'.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1}) ///
				mtitles("Full Sample" "Northern Sample" "Full Sample, pre-1940" "Northern Sample, pre-1940") ///
				note("`wlab'")
	
}


// Corelogic vars

g weight_pop = population

lab var weight_pop "Weighted by population"
 
foreach w in none pop{ 
    local wlab: variable label weight_`w'  
	eststo clear
	forv s=1/4 {
	    if "`s'"=="1" local samp samp_full
		if "`s'"=="2" local samp samp_nonsouthern
	    if "`s'"=="3" local samp samp_full_pre
	    if "`s'"=="4" local samp samp_nonsouthern_pre

		preserve
			local lab: variable label `samp'  
			foreach covar of varlist landuse_* {
				local clab: variable label `covar'  		
				g `covar'_t = `covar'
				lab var `covar'_t "`clab'"
				replace `covar' = `samp'
				qui eststo `covar': reg `covar'_t `covar'  [aw=weight_`w'], r
				local p = 2*ttail(e(df_r),abs(_b[`covar']/_se[`covar']))
				di "`covar' p value : `p'"
				
			}

			eststo tests`s' : appendmodels landuse_sfr landuse_townhouse landuse_residentialnec landuse_duplex landuse_apartment landuse_condo landuse_multifam landuse_mobilehome landuse_triplex 
		restore
			
	}
	esttab tests1 tests2 tests3 tests4 using "$TABS/land_use_index/corelogic_weight_`w'.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1}) ///
				mtitles("Full Sample" "Northern Sample" "Full Sample, pre-1940" "Northern Sample, pre-1940") ///
				addnotes("`wlab'" "Each value is a regression of the share of area zoned for a specific use on a dummy" "for being a municipality incorporated between 1940-70 in one of the 130 destination CZs")
	
}

foreach w in none full metro{ 
    local wlab: variable label weight_`w'  
	eststo clear
	forv s=1/4 {
	    if "`s'"=="1" local samp samp_full
		if "`s'"=="2" local samp samp_nonsouthern
	    if "`s'"=="3" local samp samp_full_pre
	    if "`s'"=="4" local samp samp_nonsouthern_pre

		preserve
			local lab: variable label `samp'  
			foreach covar of varlist LPPI18 SPII18 LPAI18 LZAI18 SRI18 DRI18 EI18 AHI18 ADI18 WRLURI18 {
				local clab: variable label `covar'  		
				g `covar'_t = `covar'
				lab var `covar'_t "`clab'"
				replace `covar' = `samp'
				qui eststo `covar'`s': reghdfe `covar'_t `covar' [aw=weight_`w'], vce(r) absorb(cz region)

				
			}

			eststo tests`s' : appendmodels LPPI18`s' SPII18`s' LPAI18`s' LZAI18`s' SRI18`s' DRI18`s' EI18`s' AHI18`s' ADI18`s' WRLURI18`s'
			
		restore
			
	}
	esttab tests1 tests2 tests3 tests4 using "$TABS/land_use_index/wharton_weight_`w'_czfes.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1}) ///
				mtitles("Full Sample" "Northern Sample" "Full Sample, pre-1940" "Northern Sample, pre-1940") ///
				note("`wlab'")
	
}


// Corelogic vars


foreach w in none pop{ 
    local wlab: variable label weight_`w'  
	eststo clear
	forv s=1/4 {
	    if "`s'"=="1" local samp samp_full
		if "`s'"=="2" local samp samp_nonsouthern
	    if "`s'"=="3" local samp samp_full_pre
	    if "`s'"=="4" local samp samp_nonsouthern_pre

		preserve
			local lab: variable label `samp'  
			foreach covar of varlist landuse_* {
				local clab: variable label `covar'  		
				g `covar'_t = `covar'
				lab var `covar'_t "`clab'"
				replace `covar' = `samp'
				qui eststo `covar': reghdfe `covar'_t `covar'  [aw=weight_`w'], absorb(cz region) vce(r)
				local p = 2*ttail(e(df_r),abs(_b[`covar']/_se[`covar']))
				di "`covar' p value : `p'"
				
			}

			eststo tests`s' : appendmodels landuse_sfr landuse_townhouse landuse_residentialnec landuse_duplex landuse_apartment landuse_condo landuse_multifam landuse_mobilehome landuse_triplex
		restore
			
	}
	esttab tests1 tests2 tests3 tests4 using "$TABS/land_use_index/corelogic_weight_`w'_czfes.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1}) ///
				mtitles("Full Sample" "Northern Sample" "Full Sample, pre-1940" "Northern Sample, pre-1940") ///
				addnotes("`wlab'" "Each value is a regression of the share of area zoned for a specific use on a dummy" "for being a municipality incorporated between 1940-70 in one of the 130 destination CZs" "Includes census region and CZ fixed effects")
	
}

preserve
	use "$CLEANDATA/cz_pooled", clear
	keep if dcourt == 1
	keep cz popc1940 GM_raw_pp GM_hat_raw_pp
	qui su GM_raw_pp, d
	g above_x_med = GM_raw_pp >= `r(p50)'

	qui su GM_hat_raw_pp, d
	g above_inst_med = GM_hat_raw_pp >= `r(p50)'
	tempfile inst
	save `inst'
restore

merge m:1 cz using `inst', keep(3) nogen

g 



