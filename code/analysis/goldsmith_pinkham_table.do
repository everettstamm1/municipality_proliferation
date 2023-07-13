// Goldsmith-Pinkham table

foreach level in cz{
	
	eststo clear

	foreach samp in urban total{
		if "`samp'"=="urban" local poptab ""
		if "`samp'"=="total" local poptab "_totpop"
		
		if "`samp'"=="urban" local popname "c"
		if "`samp'"=="total" local popname ""
		
		if "`samp'"=="urban" local poplab "Urban Population"
		if "`samp'"=="total" local poplab "Total Population"		
		
		foreach t in pooled stacked{
			use "$CLEANDATA/`level'_`t'", clear
			
			g base_outcome = .
			foreach ds in schdist_ind gen_subcounty gen_muni cgoodman GM_hat_raw_pp`poptab'  {
			
				if regexm("`ds'","GM"){
					local yvar = "`ds'"
				}
				else if "`t'"=="pooled"{
					
					// Create PC outcome
					cap drop n_`ds'_cz_pc b_`ds'_cz1940_pc
					g n_`ds'_cz_pc = b_`ds'_cz1970/(pop`popname'1970/100000) - b_`ds'_cz1940/(pop`popname'1940/100000)
					g b_`ds'_cz1940_pc = b_`ds'_cz1940/(pop`popname'1940/100000)
					
					local yvar = "n_`ds'_cz_p"
					replace base_outcome = b_`ds'_cz1940_pc 
					local pooledtab = "1940" 
					local decade = ""

				}
				else if "`t'"=="stacked"{
					// Create PC dependent variables
					cap drop n_`ds'_cz_L0_pc b_`ds'_cz1940_pc
					g b_`ds'_cz_pc = b_`ds'_cz/(pop`popname'/100000)
					bys cz (decade) : g n_`ds'_cz_L0_pc = b_`ds'_cz_pc[_n+1] - b_`ds'_cz_pc
					
					local yvar = "n_`ds'_cz_L0_pc"
					replace base_outcome =  b_`ds'_cz_pc 
					local pooledtab = "" 
					local decade = "i.decade"
				}

				
				local xvars = cond(regexm("`ds'","GM"), "","base_outcome ") + " mfg_lfshare`pooledtab' blackmig3539_share`poptab' pop`c'`pooledtab' frac_land reg2 reg3 reg4 `decade'"
				eststo `ds': reg `yvar' `xvars', r
				
			}
			
			esttab schdist_ind gen_subcounty gen_muni cgoodman GM_hat_raw_pp`poptab' ///
									using "$TABS/gp/gp_`level'_`t'_`samp'.tex", ///
									replace label se booktabs noconstant nolab noobs compress nonumber ///
									b(%03.2f) se(%03.2f) ///
									modelwidth(11) ///
									starlevels( * 0.10 ** 0.05 *** 0.01) ///
									mgroups("County Counts Outcomes" "CGoodman Data" "Instrument", ///
									pattern(1 0 0 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) ///
									span erepeat(\cmidrule(lr){@span})) ///
									stats(N, labels("Observations")) 
		}
									
	}
							
}