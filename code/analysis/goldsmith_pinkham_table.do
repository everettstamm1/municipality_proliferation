// Goldsmith-Pinkham table

foreach level in county{
	
	eststo clear

	foreach ds in all_local all_local_nosch gen_subcounty gen_muni schdist_ind spdist ngov3 inst{
	
		if "`ds'"=="inst"{
			use "$CLEANDATA/`level'_all_local_stacked_og.dta", clear
			local yvar = "GM_hat"
		}
		else{
			use "$CLEANDATA/`level'_`ds'_stacked_og.dta", clear
			local yvar = "`ds'"

		}

		ren n_muni_county_L0 `ds'
		ren base_muni_`level'_L0 base_outcome
		
		local xvars = "mfg_lfshare blackmig3539_share countypop reg2 reg3 reg4 i.decade"
		local xvars = cond("`ds'"=="inst","","base_outcome ") + "`xvars'"
		eststo `ds': reg `yvar' `xvars', r
		
	}
	esttab all_local all_local_nosch gen_subcounty gen_muni schdist_ind spdist ngov3 inst ///
							using "$TABS/gp/gp_`level'.tex", ///
							replace label se booktabs noconstant noobs compress nonumber ///
							b(%03.2f) se(%03.2f) ///
							modelwidth(11) ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							mgroups("County Counts Outcomes" "Directory Survey Outcomes" "Instrument", ///
							pattern(1 0 0 0 0 0 1 1) prefix(\multicolumn{@span}{c}{) suffix(}) ///
							span erepeat(\cmidrule(lr){@span})) ///
							stats(N, labels("Observations")) 
							
}