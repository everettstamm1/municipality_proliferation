local b_controls reg2 reg3 reg4 blackmig3539_share

use "$CLEANDATA/cz_pooled", clear

foreach inst in GM_hat_raw_pp GM_7r_hat_raw_pp GM_r_hat_raw_pp GM_1940_hat_raw_pp {
	if "`inst'" == "GM_hat_raw_pp" local title "Baseline Instrument"
	if "`inst'" == "GM_7r_hat_raw_pp" local title "Resid State FE Instrument"
	if "`inst'" == "GM_r_hat_raw_pp" local title "Top Urban Dropped Instrument"
	if "`inst'" == "GM_1940_hat_raw_pp" local title "1940 Southern State of Birth Instrument"

	lab var `inst' "`title'"
	foreach outcome in cgoodman schdist_ind spdist gen_subcounty gen_town gen_muni{
			eststo fs: reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
			test `inst'=0
			local F : di %6.3f `r(F)'
			estadd local Fstat = `F'
			eststo ols : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' [aw=popc1940], r
			eststo rf : reg n_`outcome'_cz_pc `inst' `b_controls' [aw=popc1940], r
			eststo tsls : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' [aw=popc1940], r

			// Export to tables
			esttab 	fs ///
							ols ///
							rf	///
							tsls ///
							using "$TABS/exogeneity_tests/`inst'_`outcome'_table.tex", ///
							replace label nomtitles se booktabs num noconstant ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(Fstat N, labels( ///
							"F-Stat"	///
							"Observations" ///
							)) ///
							title("Outcome: `outcome', `title'") ///
							keep(GM_raw_pp `inst') ///
							mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1)) ///
						prehead( \begin{tabular}{l*{4}{c}} \toprule) ///
						posthead(\end{tabular})
	}
}

// White and european migrant control
use "$CLEANDATA/cz_pooled", clear
foreach w in wt_instmig_avg_pp GM_8_hat_raw_pp{
	foreach outcome in cgoodman schdist_ind spdist gen_subcounty gen_town gen_muni{
		eststo fs: reg GM_raw_pp GM_hat_raw_pp `b_controls' `w' [aw=popc1940], r
		test GM_hat_raw_pp=0
		local F : di %6.3f `r(F)'
		estadd local Fstat = `F'
		eststo ols : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' `w' [aw=popc1940], r
		eststo rf : reg n_`outcome'_cz_pc GM_hat_raw_pp `b_controls' `w' [aw=popc1940], r
		eststo tsls : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls' `w' [aw=popc1940], r

		// Export to tables
		esttab 	fs ///
						ols ///
						rf	///
						tsls ///
						using "$TABS/exogeneity_tests/`w'_`outcome'_table.tex", ///
						replace label nomtitles se booktabs num noconstant ///
						starlevels( * 0.10 ** 0.05 *** 0.01) ///
						stats(Fstat N, labels( ///
						"F-Stat"	///
						"Observations" ///
						)) ///
						title("Outcome: `outcome', Baseline Instrument with european migrant control") ///
						keep(GM_raw_pp GM_hat_raw_pp) ///
						mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1)) ///
						prehead( \begin{tabular}{l*{4}{c}} \toprule) ///
						posthead(\end{tabular})
}
}

// Total Population Outcomes

use "$CLEANDATA/cz_pooled", clear

foreach inst in GM_hat_raw_pp {
	if "`inst'" == "GM_hat_raw_pp" local title "Baseline Instrument"
	if "`inst'" == "GM_7r_hat_raw_pp" local title "Resid State FE Instrument"
	if "`inst'" == "GM_r_hat_raw_pp" local title "Top Urban Dropped Instrument"
	if "`inst'" == "GM_1940_hat_raw_pp" local title "1940 Southern State of Birth Instrument"

	lab var `inst' "`title'"
	foreach outcome in cgoodman schdist_ind spdist gen_subcounty gen_town{
			eststo fs: reg GM_raw_pp `inst' `b_controls' [aw=popc1940], r
			test `inst'=0
			local F : di %6.3f `r(F)'
			estadd local Fstat = `F'
			eststo ols : reg n_`outcome'_cz_pc GM_raw_pp `b_controls' [aw=popc1940], r
			eststo rf : reg n_`outcome'_cz_pc `inst' `b_controls' [aw=popc1940], r
			eststo tsls : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = `inst') `b_controls' [aw=popc1940], r

			// Export to tables
			esttab 	fs ///
							ols ///
							rf	///
							tsls ///
							using "$TABS/exogeneity_tests/`inst'_`outcome'_table_tp.tex", ///
							replace label nomtitles se booktabs num noconstant ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(Fstat N, labels( ///
							"F-Stat"	///
							"Observations" ///
							)) ///
							title("Outcome: `outcome', `title'") ///
							keep(GM_raw_pp `inst') ///
							mgroups("First Stage" "OLS" "Reduced Form" "2SLS", pattern(1 1 1 1)) ///
						prehead( \begin{tabular}{l*{4}{c}} \toprule) ///
						posthead(\end{tabular})
	}
}