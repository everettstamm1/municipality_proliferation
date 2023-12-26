// Baseline Covariate Tables

foreach outcome in cgoodman schdist_ind  gen_subcounty spdist gen_town gen_muni{
	eststo clear
	use "$CLEANDATA/cz_pooled", clear
	
	// Column 1: No controls
	local controls = ""
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "N"
	estadd local blackmig = "N"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 2: Census Region Controls
	local controls  reg2 reg3 reg4
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "N"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 3: Census Region Controls and blackmig3539_share
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	

	// Column 4: Census Region Controls, blackmig3539_share, and frac_land
	local controls  reg2 reg3 reg4 blackmig3539_share frac_land
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "Y"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 5: Census Region Controls, blackmig3539_share, and totfrac_in_main_city
	local controls  reg2 reg3 reg4 blackmig3539_share totfrac_in_main_city
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "Y"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 6: Census Region Controls, blackmig3539_share, and m_rr_sqm_total
	local controls  reg2 reg3 reg4 blackmig3539_share m_rr_sqm_total
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="Y"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 7: Census Region Controls, blackmig3539_share, and popc1940
	local controls  reg2 reg3 reg4 blackmig3539_share popc1940
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "Y"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 8: Census Region Controls, blackmig3539_share, and pop1940
	local controls  reg2 reg3 reg4 blackmig3539_share pop1940
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "Y"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 9: Census Region Controls, blackmig3539_share, and mfg_lfshare
	local controls  reg2 reg3 reg4 blackmig3539_share mfg_lfshare1940
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "Y"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "N"
	
	// Column 10: Census Region Controls, blackmig3539_share, and baseline value of dep var
	local controls  reg2 reg3 reg4 blackmig3539_share b_`outcome'_cz1940_pc
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "Y"
	estadd local dens = "N"
	estadd local urban_share = "N"

	
	// Column 11: Census Region Controls, blackmig3539_share, and ln pop density
	local controls  reg2 reg3 reg4 blackmig3539_share ln_pop_dens1940
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "Y"
	estadd local urban_share = "N"

	// Column 12: Census Region Controls, blackmig3539_share, and baseline value of dep var
	local controls  reg2 reg3 reg4 blackmig3539_share urban_share1940
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "N"
	estadd local totfrac_in_main_city = "N"
	estadd local m_rr_sqm_total ="N"
	estadd local popc1940 = "N"
	estadd local pop1940 = "N"
	estadd local mfg_lfshare = "N"
	estadd local base = "N"
	estadd local dens = "N"
	estadd local urban_share = "Y"
	
	// Column 13: Census Region Controls, blackmig3539_share, and all baseline
	local controls  reg2 reg3 reg4 blackmig3539_share pop1940 popc1940 m_rr_sqm_total mfg_lfshare1940 frac_land totfrac_in_main_city mfg_lfshare1940 b_`outcome'_cz1940_pc ln_pop_dens1940 urban_share1940
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local reg = "Y"
	estadd local blackmig = "Y"
	estadd local frac_land = "Y"
	estadd local totfrac_in_main_city = "Y"
	estadd local m_rr_sqm_total ="Y"
	estadd local popc1940 = "Y"
	estadd local pop1940 = "Y"
	estadd local mfg_lfshare = "Y"
	estadd local base = "Y"
	estadd local dens = "Y"
	estadd local urban_share = "Y"
	// Export to tables
			esttab 	using "$TABS/exogeneity_tests/`outcome'_table.tex", ///
							replace label nomtitles se booktabs num noconstant frag ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(Fstat ols_b ols_r2 N  reg blackmig frac_land totfrac_in_main_city m_rr_sqm_total popc1940 pop1940 mfg_lfshare base dens urban_share, labels( ///
							"First stage F-Stat"	///
							"GM (OLS)" ///
							"R2 (OLS)" ///
							"Observations" ///
							"Census region FEs" ///
							"Fraction of recent southern Black migrants" ///
							"Fraction of land incorporated, 1940" ///
							"Fraction of CZ population in largest city" ///
							"Meters of railroad per square meter of land" ///
							"1940 urban population" ///
							"1940 total population" ///
							"1940 manufacturing share" ///
							"1940 baseline outcome" ///
							"Log 1940 population density" ///
							"1940 urban fraction" ///
							) fmt(%6.2f %6.2f %6.2f %6.0f)) ///
							title("Outcome: `outcome', `title'") ///
							keep(GM_raw_pp) b(%6.2f) ///
							modelwidth(6) ///
							prehead( \begin{tabular}{l*{15}{c}} \toprule) ///
							postfoot(\bottomrule \end{tabular})
}

// Baseline Covariate Tables

foreach outcome in cgoodman schdist_ind  gen_subcounty spdist gen_town gen_muni{
	eststo clear
	use "$CLEANDATA/cz_pooled", clear
	
	

	// Column 1: Census Region Controls and blackmig3539_share
	local controls reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 2: Census Region Controls, blackmig3539_share, and all significant baseline controls
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 3: Census Region and blackmig3539_share controls, urban population outcome
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pcc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pcc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "Y"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 4: Census Region and blackmig3539_share controls, Resid State FEs instrument
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_7r_hat_raw_pp `controls' [aw=popc1940], r
	test GM_7r_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_7r_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "Y"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 5: Census Region and blackmig3539_share controls, Top Urban Dropped instrument
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_r_hat_raw_pp `controls' [aw=popc1940], r
	test GM_r_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_r_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "Y"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"
	
	// Column 6: Census Region and blackmig3539_share controls, Southern State of Birth Instrument
	local controls  reg2 reg3 reg4 blackmig3539_share 
	qui reg GM_raw_pp GM_1940_hat_raw_pp `controls' [aw=popc1940], r
	test GM_1940_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_1940_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "Y"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 7: Census Region and blackmig3539_share controls, Southern White Instrument
	drop GM_raw_pp
	ren WM_raw_pp GM_raw_pp
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_8_hat_raw_pp `controls' [aw=popc1940], r
	test GM_8_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_8_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="Y"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2 == 1
	// Column 8: Census Region and blackmig3539_share controls, Full Southern Sample
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "N"
	estadd local rm = "N"
	
	// Column 9: Census Region and blackmig3539_share controls, Full Southern Sample, Northern Texas
	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2nt == 1
	
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_nt_hat_raw_pp `controls' [aw=popc1940], r
	test GM_nt_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_nt_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "Y"
	estadd local rm = "N"
	
	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2rm == 1
	// Column 10: Census Region and blackmig3539_share controls, Full Southern Sample, Rural Migrants Only
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_rm_hat_raw_pp `controls' [aw=popc1940], r
	test GM_rm_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %006.3f _b[GM_raw_pp]
	local ols_r2 : di %006.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_rm_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "N"
	estadd local rm = "Y"
	
	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2rmnt == 1
	// Column 9: Census Region and blackmig3539_share controls, Full Southern Sample, Rural Migrants Only
	local controls  reg2 reg3 reg4 blackmig3539_share
	qui reg GM_raw_pp GM_rmnt_hat_raw_pp `controls' [aw=popc1940], r
	test GM_rmnt_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_rmnt_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "Y"
	estadd local rm = "Y"
	
	// Export to tables
			esttab 	using "$TABS/exogeneity_tests/`outcome'_table_insts.tex", ///
							replace label nomtitles se booktabs num noconstant frag ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
														modelwidth(9) ///
							stats(Fstat ols_b ols_r2 N  baseline ///
																					tpy ///
																					state ///
																					urbdrp ///
																					ssb ///
																					swhite ///
																					ssamp ///
																					nt ///
																					rm ///
																					, labels( ///
							"First stage F-Stat"	///
							"GM (OLS)" ///
							"R2 (OLS)" ///
							"Observations" ///
							"Baseline Controls" ///
							"Urban population outcome" ///
							"State FE Inst." ///
							"Top Urban Dropped Inst." ///
							"State of Birth Inst." ///
							"Southern White Inst." ///
							"IPUMS Sample" ///
							"Northern Texas" ///
							"Rural Migrants Only" ///
							) fmt(%6.2f %6.2f %6.2f %6.0f)) ///
							title("Alt Inst Tests Outcome: `outcome'") ///
							keep(GM_raw_pp) b(%6.2f) ///
							prehead( \begin{tabular}{l*{11}{c}} \toprule) ///
							postfoot(\bottomrule \end{tabular})

}


// Baseline Covariate Tables
foreach outcome in cgoodman schdist_ind  gen_subcounty spdist gen_town gen_muni{
	eststo clear
	use "$CLEANDATA/cz_pooled", clear
	
	local controls reg2 reg3 reg4 blackmig3539_share urban_share1940 frac_total transpo_cost_1920 m_rr_sqm_total


	// Column 1: Census Region Controls and blackmig3539_share
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 2: Census Region Controls, blackmig3539_share, and all significant baseline controls
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 3: Census Region and blackmig3539_share controls, urban population outcome
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pcc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pcc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "Y"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 4: Census Region and blackmig3539_share controls, Resid State FEs instrument
	qui reg GM_raw_pp GM_7r_hat_raw_pp `controls' [aw=popc1940], r
	test GM_7r_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_7r_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "Y"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 5: Census Region and blackmig3539_share controls, Top Urban Dropped instrument
	qui reg GM_raw_pp GM_r_hat_raw_pp `controls' [aw=popc1940], r
	test GM_r_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_r_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "Y"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"
	
	// Column 6: Census Region and blackmig3539_share controls, Southern State of Birth Instrument
	qui reg GM_raw_pp GM_1940_hat_raw_pp `controls' [aw=popc1940], r
	test GM_1940_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_1940_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "Y"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	// Column 7: Census Region and blackmig3539_share controls, Southern White Instrument
	drop GM_raw_pp
	ren WM_raw_pp GM_raw_pp
	qui reg GM_raw_pp GM_8_hat_raw_pp `controls' [aw=popc1940], r
	test GM_8_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_8_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="Y"
	estadd local ewhite = "N"
	estadd local ssamp = "N"
	estadd local nt = "N"
	estadd local rm = "N"

	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2 == 1
	// Column 8: Census Region and blackmig3539_share controls, Full Southern Sample
	qui reg GM_raw_pp GM_hat_raw_pp `controls' [aw=popc1940], r
	test GM_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "N"
	estadd local rm = "N"
	
	// Column 9: Census Region and blackmig3539_share controls, Full Southern Sample, Northern Texas
	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2nt == 1
	
	qui reg GM_raw_pp GM_nt_hat_raw_pp `controls' [aw=popc1940], r
	test GM_nt_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_nt_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "Y"
	estadd local rm = "N"
	
	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2rm == 1
	// Column 10: Census Region and blackmig3539_share controls, Full Southern Sample, Rural Migrants Only
	qui reg GM_raw_pp GM_rm_hat_raw_pp `controls' [aw=popc1940], r
	test GM_rm_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %006.3f _b[GM_raw_pp]
	local ols_r2 : di %006.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_rm_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "N"
	estadd local rm = "Y"
	
	use "$CLEANDATA/cz_pooled_south", clear
	keep if samp_2rmnt == 1
	// Column 9: Census Region and blackmig3539_share controls, Full Southern Sample, Rural Migrants Only
	qui reg GM_raw_pp GM_rmnt_hat_raw_pp `controls' [aw=popc1940], r
	test GM_rmnt_hat_raw_pp=0
	local F : di %6.3f `r(F)'
	qui reg n_`outcome'_cz_pc GM_raw_pp `controls' [aw=popc1940], r
	local ols_b : di %6.3f _b[GM_raw_pp]
	local ols_r2 : di %6.3f e(r2)
	eststo : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_rmnt_hat_raw_pp) `controls' [aw=popc1940], r
	estadd scalar Fstat = `F'
	estadd scalar ols_b = `ols_b'
	estadd scalar ols_r2 = `ols_r2'
	estadd local baseline = "Y"
	estadd local tpy = "N"
	estadd local state = "N"
	estadd local urbdrp = "N"
	estadd local ssb = "N"
	estadd local swhite ="N"
	estadd local ewhite = "N"
	estadd local ssamp = "Y"
	estadd local nt = "Y"
	estadd local rm = "Y"
	
	// Export to tables
			esttab 	using "$TABS/exogeneity_tests/`outcome'_table_insts_new_ctrls.tex", ///
							replace label nomtitles se booktabs num noconstant frag ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
														modelwidth(9) ///
							stats(Fstat ols_b ols_r2 N  baseline ///
																					tpy ///
																					state ///
																					urbdrp ///
																					ssb ///
																					swhite ///
																					ssamp ///
																					nt ///
																					rm ///
																					, labels( ///
							"First stage F-Stat"	///
							"GM (OLS)" ///
							"R2 (OLS)" ///
							"Observations" ///
							"Baseline Controls" ///
							"Urban population outcome" ///
							"State FE Inst." ///
							"Top Urban Dropped Inst." ///
							"State of Birth Inst." ///
							"Southern White Inst." ///
							"IPUMS Sample" ///
							"Northern Texas" ///
							"Rural Migrants Only" ///
							) fmt(%6.2f %6.2f %6.2f %6.0f)) ///
							title("Alt Inst Tests Outcome: `outcome'") ///
							keep(GM_raw_pp) b(%6.2f) ///
							prehead( \begin{tabular}{l*{11}{c}} \toprule) ///
							postfoot(\bottomrule \end{tabular})

}

