// Balance table

	

	foreach samp in urban total total_dcourt{
		if "`samp'"=="urban" local poptab ""
		if "`samp'"=="total" local poptab "_totpop"
		if "`samp'"=="total_dcourt" local poptab "_totpop"

		if "`samp'"=="urban" local popname "c"
		if "`samp'"=="total" local popname ""
		if "`samp'"=="total_dcourt" local popname ""

		if "`samp'"=="urban" local poplab "Urban Population"
		if "`samp'"=="total" local poplab "Total Population"		
		if "`samp'"=="total_dcourt" local poplab "Total Population"		

		
		eststo clear

			use "$CLEANDATA/cz_pooled", clear
			if "`samp'"=="total_dcourt" keep if dcourt==1
			forv v = 1/2{
				
				if "`v'"=="1" local controls =  "reg2 reg3 reg3"
				if "`v'"=="2" local controls = "blackmig3539_share`poptab' reg2 reg3 reg3"

				foreach covar in frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2 {
				

					eststo `covar': reg `covar' GM_hat_raw_pp`poptab' `controls' [aw=pop`popname'1940], r
					
				}
				esttab frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city urbfrac_in_main_city m_rr m_rr_sqm2, se replace keep(GM_hat_raw_pp`poptab')
				mat list r(coefs)
				mat rename r(coefs) `samp'`v'
				mat list `samp'`v'
				esttab matrix(`samp'`v', transpose) ///
										using "$TABS/balancetables/cz_`samp'_`v'.tex", ///
										replace label se booktabs noconstant noobs compress nonumber ///
										b(%03.2f) se(%03.2f) ///
										starlevels( * 0.10 ** 0.05 *** 0.01) 
										
				mat drop `samp'`v'
	}
			
			
			
		}