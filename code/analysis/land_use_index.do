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
	
	foreach s of varlist samp_*{
		preserve
			eststo clear
			local lab: variable label `s'  		
			eststo est0: quietly estpost summarize *I18 if `s' == 0  [aw=weight_`w']
			eststo est1: quietly estpost summarize *I18 if `s' == 1  [aw=weight_`w']			

			di "here"

			foreach covar of varlist LPPI18 SPII18 LPAI18 LZAI18 SRI18 DRI18 EI18 AHI18 ADI18 WRLURI18 {
				local clab: variable label `covar'  		
				g `covar'_temp = `covar'
				lab var `covar'_temp "`clab'"
				replace `covar' = `s'
				qui eststo `covar': reg `covar'_temp `covar' [aw=weight_`w'], r
				local p = 2*ttail(e(df_r),abs(_b[`covar']/_se[`covar']))
				di "`covar' p value : `p'"
				
			}

			eststo tests : appendmodels LPPI18 SPII18 LPAI18 LZAI18 SRI18 DRI18 EI18 AHI18 ADI18 WRLURI18
			esttab est1 est0 tests using "$TABS/land_use_index/`s'_weight_`w'.tex", booktabs nonumber label replace lines ///
				title("`s'"\label{tab1}) ///
				mtitles("Munis Incorporated 1940-70" "Else" "Test for difference") ///
				cells("mean(pattern(1 1 0) fmt(2)) sd(pattern(1 1 0)) b(star pattern(0 0 1) fmt(2)) t(pattern(0 0 1) par fmt(2))") ///
				note("`wlab'") keep(*I18)
		restore
			
	}
	
}
