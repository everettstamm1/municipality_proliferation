

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)

duplicates drop
unique STATEFP PLACEFP
assert _N == r(N)

// Rescale
replace place_land = place_land/1000000 
replace prop_black2010 = 100*prop_black2010
replace prop_white2010 = 100*prop_white2010
replace mean_hh_inc_place = mean_hh_inc_place / 1000

eststo clear
foreach covar of varlist prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_school_district {
	local mname = subinstr("`covar'","landuse_", "",.)
	lab var `covar' "`mname'"



	su `covar' if above_x_med == 0 & samp_dest == 0 [aw = weight_pop]
	local bdvw : di %6.2f r(mean)
	eststo `covar' : reghdfe `covar' samp_destXabove_x_med above_x_med  samp_dest  reg2 reg3 reg4 [aw=weight_pop], vce(cl cz) 
	estadd scalar bdvw = `bdvw'

}

esttab prop_white2010 place_land mean_hh_inc_place  pct_rev_sa  pct_rev_ff landuse_sfr landuse_apartment  exclusive_school_district ///
			using "$TABS/T5.tex", booktabs compress label replace lines se frag ///
			 starlevels( * 0.10 ** 0.05 *** 0.01) ///
			mtitles("\shortstack{Percentage \\ White}" "\shortstack{Land Area}" "\shortstack{2010 Household \\ Income}" "\shortstack{Special \\ Assessments}" "\shortstack{Fines and \\ Forfeitures}" "\shortstack{Single \\ Family}" "Apartments" "\shortstack{Exclusive \\ District}") ///
			mgroups("2010 Muni Characteristics" "\shortstack{Percentage of \\ Municipal Revenues}" "\shortstack{Percentage of \\ Municipal Land Uses}"  "\shortstack{Muni-District \\ Similarity}" ,pattern(1 0 0 1 0 1 0 1) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) keep(samp_destXabove_?_med above_?_med samp_dest) b(%5.3f) se(%5.3f) ///
			prehead( \begin{tabularx}{\linewidth}{l*{8}{>{\centering\arraybackslash}X}} \toprule) postfoot(	\bottomrule \end{tabularx}) stats(  bdvw N, labels( "Omitted Category Avg." "Observations") fmt(2 0))

