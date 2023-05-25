global C3 base_muni_county_L0 reg2 reg3 reg4 i.decade
global C4 base_muni_county_L0 reg2 reg3 reg4 mfg_lfshare blackmig3539_share i.decade


foreach medvar in co_2020 above_med_land above_med_unusable above_med_total_00 above_med_ub_1 above_med_ub_2{
	estimates clear
	eststo clear
	forv weight = 0/1{
		if "`weight'"=="0" local w = 1
		if "`weight'"=="1" local w ="countypop1940"
		
		foreach ds in schdist_ind all_local_nosch gen_muni{
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
			foreach inst in og full{
				local sample = cond("`inst'"=="og","Original","Full")
				forv pc=0/1{
					use "$CLEANDATA/county_`ds'_stacked_`inst'.dta", clear

					global y n_muni_county_L0

					global x_ols = "GM"
					global x_iv  = "GM_hat"
					global x_olsX = "GM_X_`medvar'"
					global x_ivX = "GM_hat_X_`medvar'"

					la var $x_iv "$\hat{GM}$ (rank)"
					la var $x_ols "GM  (rank)"
					
					if "`medvar'" == "above_med_land" la var $x_ivX "$\hat{GM}$ X Above Median Land Incorp"
					if "`medvar'" == "above_med_land" la var $x_olsX "GM X Above Median Land Incorp"
					if "`medvar'" == "above_med_unusable" la var $x_ivX "$\hat{GM}$ X Above Median Area Unusable"
					if "`medvar'" == "above_med_unusable" la var $x_olsX "GM X Above Median Area Unusable"
					if "`medvar'" == "co_2020" la var $x_ivX "$\hat{GM}$ X Desegregation Order"
					if "`medvar'" == "co_2020" la var $x_olsX "GM X Desegregation Order"
					if "`medvar'" == "above_med_total_00" la var $x_ivX "$\hat{GM}$ X Above Median Naturally Unbuildable"
					if "`medvar'" == "above_med_total_00" la var $x_olsX "GM X Above Median County Unbuildable"
					if "`medvar'" == "above_med_ub_1" la var $x_ivX "$\hat{GM}$ X Above Median Total Unbuildable"
					if "`medvar'" == "above_med_ub_1" la var $x_olsX "GM X Above Median Total Unbuildable"
					local ylab: variable label $y

					label var $y "y_L0"

					if `pc'==1{
						replace $y = 100000*$y / countypop1940
						local pclab ", Per Capita (100,000)"
					}
					
					foreach i in 3 4{
						local controls = cond("`i'"=="3","No","Yes")
						eststo ss_`ds'_`pc'_`inst'_`i'_p : ///
									ivreg2 $y ($x_ols = $x_iv) ${C`i'} [aw=`w'], r first savefprefix(fs)
									
						// Saving some locals			
						local F_1 : di %04.2f e(first)[4,1] 
						local F_2 : di %04.2f e(first)[4,2] 
						local SWF_1 : di %04.2f e(first)[8,1] 
						local SWF_2 : di %04.2f e(first)[8,2] 
						local KPF : di %04.2f e(widstat)			
						
						estimates restore fs$x_ols
						if _rc==0{
							eststo fs_`ds'_`pc'_`inst'_`i'_p
							estadd local F1 = "`F_1'"
						}
						
						qui ivreg2 $y ($x_ols $x_olsX = $x_iv $x_ivX) ${C`i'} [aw=`w'], r						
						margins, expression(_b[$x_ols ] + _b[$x_olsX ]) post
						mat r = r(table)
						qui su $y [aw=`w']
						local mean : di %04.2f r(mean)
						
						eststo ss_`ds'_`pc'_`inst'_`i'_s : ///
									ivreg2 $y ($x_ols $x_olsX = $x_iv $x_ivX) ${C`i'} [aw=`w'], r first savefprefix(fs)
						// Saving some locals			
						local F_1 : di %04.2f e(first)[4,1] 
						local F_2 : di %04.2f e(first)[4,2] 
						local SWF_1 : di %04.2f e(first)[8,1] 
						local SWF_2 : di %04.2f e(first)[8,2] 
						local KPF : di %04.2f e(widstat)
						estadd local combined_coef = ///
												cond(r[4,1]<0.01,"`:di %5.2f `=r[1,1]''***", ///
												cond(r[4,1]<0.05,"`:di %5.2f `=r[1,1]''**", ///
												cond(r[4,1]<0.1,"`:di %5.2f `=r[1,1]''*", ///
												"`:di %5.2f `=r[1,1]''")))
						estadd local combined_se = "(`:di %5.2f `=r[2,1]'')"
						// Adding summary stats and informational label
						estadd local dep_mean = "`mean'"
						estadd local sample = "`sample'"		
						estadd local ctrls = "`controls'"
							
						 estimates restore fs$x_ols
						if _rc==0{
							eststo fs_`ds'_`pc'_`inst'_`i'_s
							estadd local F1 = "`F_1'"
							estadd local SWF1 = "`SWF_1'"
							estadd local KPF1 = "`KPF'"
							
						}
						cap estimates restore fs$x_olsX
						if _rc==0{
							eststo fsi_`ds'_`pc'_`inst'_`i'_s
							estadd local F2 = "`F_2'"
							estadd local SWF2 = "`SWF_2'"
							estadd local KPF2 = "`KPF'"
						}
					}
				}
			}
			// Panel A
			esttab 	fs_`ds'_0_og_3_p ///
							fs_`ds'_0_og_4_p ///
							fs_`ds'_0_full_3_p ///
							fs_`ds'_0_full_4_p ///
							fs_`ds'_1_og_3_p ///
							fs_`ds'_1_og_4_p ///
							fs_`ds'_1_full_3_p ///
							fs_`ds'_1_full_4_p ///
							using "$TABS/stacked/stacked_`ds'_`weight'_`medvar'.tex", ///
							replace label se booktabs noconstant noobs compress nomtitle frag ///
							b(%03.2f) se(%03.2f) ///
							modelwidth(11) ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							mgroups("Raw" "Per Capita (100,000)", ///
							pattern(1 0 0 0 1 0 0 0) prefix(\multicolumn{@span}{c}{) suffix(}) ///
							span erepeat(\cmidrule(lr){@span})) ///
							posthead("\cmidrule(lr){1-9}" "\multicolumn{8}{l}{Panel A: Dependent Variable GM}\\" "\cmidrule(lr){1-9}" ) ///
							prehead( \begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}  \begin{threeparttable} \caption{`reweightlab'Effects of change in Black Migration on `ylab'}  \begin{tabular}{l*{10}{c}} \toprule) ///
							stats(F1, labels("F-Stat")) ///
							keep($x_iv)
			// Panel B			
			esttab 	ss_`ds'_0_og_3_p ///
							ss_`ds'_0_og_4_p ///
							ss_`ds'_0_full_3_p ///
							ss_`ds'_0_full_4_p ///
							ss_`ds'_1_og_3_p ///
							ss_`ds'_1_og_4_p ///
							ss_`ds'_1_full_3_p ///
							ss_`ds'_1_full_4_p ///
							using "$TABS/stacked/stacked_`ds'_`weight'_`medvar'.tex", ///
							label se booktabs noconstant compress nomtitle frag append noobs nonum ///
							posthead("\cmidrule[\heavyrulewidth](lr){1-9} \\ \cmidrule[\heavyrulewidth](lr){1-9}" "\multicolumn{8}{l}{Panel B: Dependent Variable `ylab'}\\" "\cmidrule(lr){1-9}" ) ///
							b(%03.2f) se(%03.2f) ///
							modelwidth(11) ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							keep($x_ols )
							
			esttab 	fs_`ds'_0_og_3_s ///
							fs_`ds'_0_og_4_s ///
							fs_`ds'_0_full_3_s ///
							fs_`ds'_0_full_4_s ///
							fs_`ds'_1_og_3_s ///
							fs_`ds'_1_og_4_s ///
							fs_`ds'_1_full_3_s ///
							fs_`ds'_1_full_4_s ///
							using "$TABS/stacked/stacked_`ds'_`weight'_`medvar'.tex", ///
								label se booktabs noconstant compress nomtitle frag append nonum ///
								posthead("\cmidrule[\heavyrulewidth](lr){1-9} \\ \cmidrule[\heavyrulewidth](lr){1-9}" "\multicolumn{8}{l}{Panel C: Dependent Variable GM}\\" "\cmidrule(lr){1-9}" ) ///
								b(%03.2f) se(%03.2f) ///
								modelwidth(11) ///
								stats(F1 SWF1 KPF1, labels("F-Stat" "S.W. F-Stat" "K.P. F-Stat")) ///
								starlevels( * 0.10 ** 0.05 *** 0.01) ///
								keep($x_iv $x_ivX )
				esttab 	fsi_`ds'_0_og_3_s ///
							fsi_`ds'_0_og_4_s ///
							fsi_`ds'_0_full_3_s ///
							fsi_`ds'_0_full_4_s ///
							fsi_`ds'_1_og_3_s ///
							fsi_`ds'_1_og_4_s ///
							fsi_`ds'_1_full_3_s ///
							fsi_`ds'_1_full_4_s ///
							using "$TABS/stacked/stacked_`ds'_`weight'_`medvar'.tex", ///
								label se booktabs noconstant compress nomtitle frag append nonum ///
								posthead("\cmidrule[\heavyrulewidth](lr){1-9} \\ \cmidrule[\heavyrulewidth](lr){1-9}" "\multicolumn{8}{l}{Panel D: Dependent Variable GM X Above median land Incorp}\\" "\cmidrule(lr){1-9}" ) ///
								b(%03.2f) se(%03.2f) ///
								modelwidth(11) ///
								stats(F2 SWF2 KPF2, labels("F-Stat" "S.W. F-Stat" "K.P. F-Stat")) ///
								starlevels( * 0.10 ** 0.05 *** 0.01) ///
								keep($x_iv $x_ivX )
				esttab 	ss_`ds'_0_og_3_s ///
								ss_`ds'_0_og_4_s ///
								ss_`ds'_0_full_3_s ///
								ss_`ds'_0_full_4_s ///
								ss_`ds'_1_og_3_s ///
								ss_`ds'_1_og_4_s ///
								ss_`ds'_1_full_3_s ///
								ss_`ds'_1_full_4_s ///
								using "$TABS/stacked/stacked_`ds'_`weight'_`medvar'.tex", ///
								label se booktabs noconstant compress nomtitle frag append nonum ///
								posthead("\cmidrule[\heavyrulewidth](lr){1-9} \\ \cmidrule[\heavyrulewidth](lr){1-9}" "\multicolumn{8}{l}{Panel E: Dependent Variable `ylab'}\\" "\cmidrule(lr){1-9}" ) ///
								b(%03.2f) se(%03.2f) ///
								modelwidth(11) ///
								stats(combined_coef combined_se dep_mean sample ctrls N, labels( ///
								"Combined Coeff" "Combined SE" "Dep var mean" "Sample" "Mfg/Black Mig Controls" "Observations") ///
								fmt(%03.2f %03.2f %03.2f %04.2f %4.0f)) ///
								starlevels( * 0.10 ** 0.05 *** 0.01) ///
								keep($x_ols $x_olsX ) ///
								postfoot(	\hline\hline \end{tabular}{\caption*{\begin{scriptsize} "\(p<0.10\), ** \(p<0.05\), *** \(p<0.01\)"\end{scriptsize}}} \end{threeparttable} \end{table})
								
							}
	}
}