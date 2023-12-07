use "$CLEANDATA/other/municipal_shapefile_attributes.dta", clear
drop if ak_hi == 1

// All cities vs cities in our 130 CZs incorporated 1940-70
g samp_full = (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
lab var samp_full "Full Sample"

g samp_nonsouthern = (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_nonsouthern = 0 if (yr_incorp <1940 | yr_incorp >1970) & sample_130_czs==1

lab var samp_nonsouthern "Nonsouthern Sample"

g samp_full_pre = (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_full_pre = 0 if (yr_incorp <1940)
lab var samp_full "Full Sample, pre-1970 only"

g samp_nonsouthern_pre = (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_nonsouthern_pre = 0 if yr_incorp <1940 & sample_130_czs==1
lab var samp_full "Nonsouthern Sample, pre-1970 only"

g weight_none = 1
lab var weight_none "Unweighted"
foreach w in none full metro{ 
    local wlab: variable label weight_`w'  
	foreach s of varlist samp_*{
	    eststo clear
		local lab: variable label `s'  
		forv j=0/1{
			preserve 
				count
				keep if `s'==`j'			
				estpost tabstat *I18 [aw=weight_`w'], ///
				statistics(mean) 
				eststo est`j' 
			restore
		}

		esttab est1 est0 using "$TABS/land_use_index/`s'_weight_`w'.tex", booktabs nonumber label replace lines noobs ///
			title("`s'"\label{tab1}) ///
			mtitles("Munis Incorporated 1940-70" "Else") ///
			cells((mean(fmt(2)))) ///
			note("`wlab'")
			
	}
}


