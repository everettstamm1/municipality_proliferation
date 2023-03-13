
foreach inst in og full{
	forv drop=0/1{
		foreach x in rank raw{
			foreach level in county{
				if "`level'"=="cz"{
					local levelvar cz
					local levellab "CZ"
				}
				else if "`level'"=="county"{
					local levelvar fips
					local levellab "County"
				}
				else if "`level'"=="msa"{
					local levelvar msapmsa2000
					local levellab "MSA"
				}
				use "$CLEANDATA/`level'_`ds'_stacked_`inst'.dta", clear
				if "`drop'"=="1"{
					drop if decade == 1940
				}
				local startyr = cond("`drop'"=="1","1950","1940") 

				forv lag = 0/0{
					if `lag'==0{
						local labl "no lags"
					}
					else if `lag'==1{
						local labl "lagged once"
					}
					else if `lag'==2{
						local labl "lagged twice"
					}
					global y n_muni_`level'_L`lag'
					
					global x_ols = cond("`x'"=="rank","GM","GM_raw")
					global x_iv  = cond("`x'"=="rank","GM_hat","GM_hat_raw")

					la var $x_iv "$\hat{GM}$ (`x')"
					la var $x_ols "GM  (`x')"
						
					label var $y "y_L`lag'"
					
				

					global C3 base_muni_`level'_L`lag' reg2 reg3 reg4 i.decade
					global C5 base_muni_`level'_L`lag' reg2 reg3 reg4 mfg_lfshare i.decade

					global C6 base_muni_`level'_L`lag' reg2 reg3 reg4 blackmig3539_share i.decade

					global C4 base_muni_`level'_L`lag' reg2 reg3 reg4 mfg_lfshare blackmig3539_share i.decade

									
					forv i=3/4{
						if `i'==3{
							local lab1 "baseline y and division FEs"
						}
						else if `i'==5{
							local lab1 "baseline y, division FEs, and mfg share"

						}
						else if `i'==6{
							local lab1 "baseline y, division FEs, and black mig share"

						}
						else if `i'==4{
							local lab1 "baseline y, division FEs, and mfg and black mig share"
						} 
						local sample = cond("`x'"=="og","Original Dererencourt Sample","Full Sample")
						binscatter $x_ols $x_iv , controls(${C`i'}) ///
						xtitle("Predicted Black Migrant Share") ytitle("Actual Black Migrant Share") title("First Stage for `x' values") note("Data at county-decade level, `startyr'-70 sample, with `lab1' controls. `sample'") ///
						savegraph("$FIGS/binscatter/binscatter_ctrls`i'_stacked_L`lag'_`level'_`x'_`drop'_`inst'.pdf") replace
					}
				}
			}
		}
	}
}
							