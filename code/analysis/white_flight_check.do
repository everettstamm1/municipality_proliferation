

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)

duplicates drop

lab var wf_cc1970 "Moved From Central City"
lab var wf_smsa1970 "Moved Within SMSA"
lab var wf_smsarev1970 "Non-Movers"

eststo clear
foreach covar of varlist wf_smsarev1970 wf_smsa1970 wf_cc1970 {
	
	su `covar' if above_x_med == 0
	local bdv : di %6.2f r(mean)
	su `covar' if above_x_med == 0 [aw = weight_pop]
	local bdvw : di %6.2f r(mean)
	eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest reg2 reg3 reg4  [aw=weight_pop], vce(cl cz) 
	estadd scalar bdv = `bdv'
	estadd scalar bdvw = `bdvw'
}



esttab  wf_smsarev1970 wf_smsa1970 wf_cc1970 ///
			using "$TABS/TA25.tex", booktabs compress label replace lines se frag ///
			 starlevels( * 0.10 ** 0.05 *** 0.01) ///
			mtitles("\shortstack{Share \\ Non-Movers}" "\shortstack{Share Moved  \\ Within SMSA}" "\shortstack{Share Moved From \\ SMSA Central City}") ///
			keep(samp_destXabove_x_med above_x_med samp_dest) b(%05.3f) se(%05.3f) ///
			prehead( \begin{tabular}{l*{4}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats(  bdvw N, labels( "Below Median Avg." "Observations") fmt(3 0))



