

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


duplicates drop
unique STATEFP PLACEFP
assert _N == r(N)

replace touching = . if main_city == 1 // Redundant

eststo clear
foreach covar of varlist touching  pct_rev_debt council_manager {

	
	su `covar' if above_x_med == 0
	local bdv : di %6.2f r(mean)
	su `covar' if above_x_med == 0 [aw = weight_pop]
	local bdvw : di %6.2f r(mean)
	eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest reg2 reg3 reg4   [aw=weight_pop], vce(cl cz) 
	 estadd scalar bdv = `bdv'
	 estadd scalar bdvw = `bdvw'
		
}
	

esttab touching  pct_rev_debt council_manager ///
			using "$TABS/TA23.tex", booktabs compress label replace lines se frag ///
			 starlevels( * 0.10 ** 0.05 *** 0.01) ///
			mtitles("\shortstack{Adjacent to \\ Principle City}" "\shortstack{Outstanding Debt as  \\ Pct of Municipal Revenues}" "\shortstack{City Manager \\ Gov't}") ///
			keep(samp_destXabove_?_med above_?_med samp_dest) b(%05.3f) se(%05.3f) ///
			prehead( \begin{tabular}{l*{4}{c}} \toprule) postfoot(	\bottomrule \end{tabular}) stats(  bdvw N, labels( "Below Median Avg." "Observations") fmt(3 0))


