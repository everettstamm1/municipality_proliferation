// Merges n_muni_cz variable with derenoncourt data, replicates table 2 using it as outcome variable with and without controls
forv weight=1/1{
	forv pc=0/1{
		foreach ds in schdist_ind gen_muni all_local_nosch{
			if "`ds'"=="wiki"{
				local filepath = "$TABS/wiki"
			}
			else if "`ds'"=="ngov1"{
				local filepath = "$TABS/4_1_general_purpose_govts"

			}
			else if "`ds'"=="ngov2"{
				local filepath = "$TABS/4_1_general_purpose_govts"
			
			}
			else if "`ds'"=="ngov3"{
				local filepath = "$TABS/4_1_general_purpose_govts"
				}
			else if "`ds'"=="cgoodman"{
				local filepath = "$TABS/cgoodman"

			}
			else{
				local filepath = "$TABS/2_county_counts"

			}
			eststo clear

			global y n_muni_`level'
			global x_ols = cond("`x'"=="rank","GM","GM_raw")
			global x_iv  = cond("`x'"=="rank","GM_hat","GM_hat_raw")

			la var $x_iv "$\hat{GM}$ (`x')"
			la var $x_ols "GM  (`x')"
				

			global C3 base_muni_county_L0 reg2 reg3 reg4
			

			global C4 base_muni_county_L0 reg2 reg3 reg4 mfg_lfshare1940  blackmig3539_share1940
						
			if "`weight'"=="0" local w = 1
			if "`weight'"=="1" local w ="countypop1940"
						
			use "$CLEANDATA/county_`ds'_stacked_full.dta", clear
			
			gl y n_muni_county_L0
			gl x_ols GM
			gl x_iv GM_hat
			
			if `pc'==1{
				replace $y = 100000*$y / countypop1940
				local pclab ", Per Capita (100,000)"
			}
		
						
			su $y
			local y_mean : di %6.3f  `r(mean)'
			eststo : ivreg2 $y ($x_ols = $x_iv) ${C3}  [aw=`w'], r
			estadd local dep_mean = `y_mean'
			estadd local sample = "Full"
			su $y if urban==1
			local y_mean : di %6.3f  `r(mean)'
			eststo : ivreg2 $y ($x_ols = $x_iv) ${C3}  [aw=`w'] if urban==1, r
			estadd local dep_mean = `y_mean'
			estadd local sample = "Urban"
			su $y if dcourt==1
			local y_mean : di %6.3f  `r(mean)'
			eststo : ivreg2 $y ($x_ols = $x_iv) ${C3}  [aw=`w'] if dcourt == 1, r
			estadd local dep_mean = `y_mean'
			estadd local sample = "DCourt"
			
			
			
			use "$CLEANDATA/cz_`ds'_stacked_full.dta", clear
			gl C3 base_muni_cz_L0 reg2 reg3 reg4
			global C4 base_muni_cz_L0 reg2 reg3 reg4 mfg_lfshare1940  blackmig3539_share1940

			if "`weight'"=="0" local w = 1
			if "`weight'"=="1" local w ="czpop1940"
			gl y n_muni_cz_L0
			gl x_ols GM
			gl x_iv GM_hat
			
			if `pc'==1{
				replace $y = 100000*$y / czpop1940
				local pclab ", Per Capita (100,000)"
			}
		
			su $y
			local y_mean : di %6.3f  `r(mean)'
			eststo : ivreg2 $y ($x_ols = $x_iv) ${C3}  [aw=`w'], r
			estadd local dep_mean = `y_mean'
			estadd local sample = "Full"
			
			su $y if urban==1
			local y_mean : di %6.3f  `r(mean)'
			eststo : ivreg2 $y ($x_ols = $x_iv) ${C3}  [aw=`w'] if urban==1, r
			estadd local dep_mean = `y_mean'
			estadd local sample = "Urban"
			
			su $y if dcourt==1
			local y_mean : di %6.3f  `r(mean)'
			eststo : ivreg2 $y ($x_ols = $x_iv) ${C3}  [aw=`w'] if dcourt == 1, r
			estadd local dep_mean = `y_mean'
			estadd local sample = "DCourt"
			
			local ylab: variable label $y

			esttab 	using "$TABS/shorttables/shorttables_`pc'_`weight'_`ds'.tex", ///
							replace label compress se booktabs nonum noconstant nomtitles ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(sample dep_mean N, labels( ///
							"Sample" /// 
							"Dep Var Mean" ///
							"Observations" ///
							)) ///
							title("TSLS Estimation Results, y=`ylab'`pclab'") ///
							keep($x_ols) ///
							mgroups("County" "CZ", pattern(1 0 0 1 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
							span erepeat(\cmidrule(lr){@span}))
		}
	}
}