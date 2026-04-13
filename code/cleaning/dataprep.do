
	
	// Start from final cleaning of derenoncourt dataset
	

	
	use "$RAWDATA/dcourt/clean_city_population_census_1940.dta", clear // 711 cities in non-South
	merge 1:1 citycode using "$INTDATA/dcourt/clean_city_population_census_1940_full.dta", keepusing(wpopc1940)  // add in white urban pop
	
	keep if _merge==3 | citycode == 910 /*butte, MT, correction later */ | citycode == 170 /* Amsterdam, NY,  correction later */
	drop _merge
	
	
	merge 1:1 city using "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", keepusing(bpop1970 bpop1960 nwhtpop1950 nwhtpop1960 pop1960 whtpop1970 pop1950 pop1940 pop1970)
	ren whtpop1970 wpopc1970
	foreach var of varlist bpop1960 nwhtpop1950 nwhtpop1960  pop1960{
	ren `var' `var'_ccdb
}
		ren _merge ccdb_merge

	/*
	* Analysis of non-matches
	not matched                           789
				from master                       273  (_merge==1) // 273 cities from 1940 census city file do not match
				from using                        516  (_merge==2) // 516 cities from CCDB file do not match because they are Southern or they are non-Southern but do not appear in 1940 Census
	
	Here are the cities that do not appear in 1940 census, are non-southern, and have non-missing data for black pop in 1970: Boise city, ID; East Providence, RI: Huntington Park CA; West
	Haven CT; and Warwick, RI 
	
	Here are the cities that do not appear in 1940 census, are non-southern, and are missing data for black pop in 1970:
	Ardmore, PA
	Arlington, MA
	Arlington, VA
	Belmont, MA
	Belvedere, CA
	Bogota, NJ
	Brookline, MA
	Clarksburg, WV
	Drexel Hill, PA
	Haverford College, PA
	Newport, KY
	Secaucus, NJ
	Watertown, MA
	West Hartford, CT
	Woodbridge, NJ

		matched                               438  (_merge==3)
	
	*/
	
	
	
	/* Keep cities large enough (25k+) to appear in CCDB in 1940 and 1970. Results are 
	robust to changing this criterion.*/
	rename bpop1970 bpopc1970 // rename so it is clear these numbers correspond to city populations
	rename pop1970 popc1970 // rename so it is clear these numbers correspond to city populations
	rename pop1950 popc1950 // rename so it is clear these numbers correspond to city populations
	rename pop1960 popc1960 // rename so it is clear these numbers correspond to city populations
	rename bpop1960 bpopc1960 // rename so it is clear these numbers correspond to city populations
	/* Butte, MT and Amsterdam, NY received southern black migrants between 1935 and 1940, but are just below pop cutoff for CCDB. 
	Keep them in sample by retrieving 1970 black pop info from Census for these cities */
	replace bpopc1970=38 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
	replace popc1970=23368 if city=="Butte, MT" // see Table 27 of published 1970 Census: https://www.census.gov/content/dam/Census/library/working-papers/2005/demo/POP-twps0076.pdf
	replace wpopc1970= 23013 if city=="Butte, MT"
	
	replace bpopc1970=140 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
	replace popc1970=25524 if city=="Amsterdam, NY" // see Table 27 of published 1970 Census: https://www2.census.gov/prod2/decennial/documents/1970a_ny1-02.pdf
	replace wpopc1970= 25346 if city=="Amsterdam, NY"
	keep if  bpopc1970!=. & pop1940!=.
	/* The following non-southern cities are missing Black population data in 1970 though they have total population data for that year
	city
	Bolingbrook, IL
	Burbank, IL
	Burton, MI
	Farmington Hills, MI
	Grosse Pointe Woods, MI
	Irvine, CA
	Rancho Palos Verdes, CA
	Romulus, MI
	*/	
	
	drop if ccdb_merge==2 // Dropping cities in CCDB that do not appear in the 1940 Census list of non-southern cities, see analysis of non-matches above. 
	drop ccdb_merge
	
	keep if popc1940 >=25000 | popc1970>=25000
	
	// Save reference datasets
	preserve
		keep city citycode cz cz_name popc*
		
		forv y = 1940(10)1970{
			bys cz : egen cz_popc`y' = total(popc`y')

		}
		save "$INTDATA/dcourt/xwalk_296_city_cz.dta", replace
		keep cz cz_name
		duplicates drop
		save "$INTDATA/dcourt/original_130_czs", replace
	restore

	
	
	use "$INTDATA/dcourt/GM_city_final_dataset.dta", clear

	collapse (sum)  popc* bpopc* wpopc1940 wpopc1970, by(cz)
	
	// Merge in other cleaned derenoncourt objects
	// White migration instrument
	merge 1:1 cz using "$INTDATA/dcourt/clean_cz_snq_european_immigration_instrument.dta", keep(1 3) nogen
	/* Get state and region info from cz-to-state_id-to-region crosswalk. */
	merge 1:1 cz using "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", keepusing(state_id region cz_name) keep (3) nogenerate
	replace cz_name="Louisville, KY" if cz==13101 // Fill in Louisville, KY name, which was missing.
	tabulate region, gen(reg)	

	
	g GM_raw=100*(bpopc1970 - bpopc1940)/popc1940
	g GM_raw_pp=100*((bpopc1970/popc1970)-(bpopc1940/popc1940))
	g WM_raw=100*((wpopc1970 -wpopc1940)/popc1940)
	g WM_raw_pp=100*((wpopc1970/popc1970)-(wpopc1940/popc1940))
	
	xtile GM = GM_raw, nq(100) 
	xtile WM = WM_raw, nq(100) 
		
	
	// Merge in outcomes 
	foreach ds in gen_muni  all_local gen_subcounty spdist gen_town schdist_m2  {

		merge 1:1 cz using "$INTDATA/counts/`ds'_cz", keep(1 3) nogen keepusing(n_`ds'_cz b_`ds'_cz1970 b_`ds'_cz1960 b_`ds'_cz1940 b_`ds'_cz1950 b_`ds'_cz2010)
	}
	rename *schdist_m2* *schdist_ind*
	
	merge 1:1 cz using "$INTDATA/counts/cgoodman_cz", keep(1 3) nogen keepusing(n_cgoodman_cz b_cgoodman_cz*)
	
	merge 1:1 cz using "$INTDATA/census/maxcitypop_ccdb", keep(1 3) nogen keepusing(maxcitypop1940 maxcitypop1950 maxcitypop1960 maxcitypop1970)
	merge 1:1 cz using "$INTDATA/census/maxcitypop_2010", keep(1 3) nogen keepusing(maxcitypop2010)

	rename maxcitypop* b_totfrac_cz*
	g n_totfrac_cz = b_totfrac_cz1970 - b_totfrac_cz1940
	
	// Merge in covariates 
	
	// Incorporated land
	g decade = 1940
	merge 1:1 cz decade using "$INTDATA/cgoodman/cz_geogs.dta", keep(1 3) 
	
	replace frac_land = 0 if _merge == 1
	replace frac_total = 0 if _merge == 1
	replace land_incorp = 0 if _merge == 1
	replace total_incorp = 0 if _merge == 1
	drop _merge decade
	
	su frac_total , d
	g above_med_frac_total = frac_total >= r(p50)
		
	merge 1:1 cz using "$INTDATA/covariates/covariates.dta", keep(1 3) nogen
	merge 1:1 cz using "$INTDATA/census/maxcitypop", keep(1 3) nogen
	ren cz czone
	//merge 1:1 czone using "$INTDATA/census/home_values", keep(1 3) nogen
	//merge 1:1 czone using "$INTDATA/census/incomes", keep(1 3) nogen
	ren czone cz
	merge 1:1 cz using "$INTDATA/census/incomes_and_education_1940", keep(1 3) nogen
	//merge 1:1 czone using "$INTDATA/census/black_incomes_and_education_1940", keep(1 3) nogen
	//drop mean_urban_income_1940 mean_pos_urban_income_1940
	//merge 1:1 czone using "$INTDATA/census/urban_incomes_and_education_1940_scc", keep(1 3) nogen 

	
	// Missing dummies
	foreach var of varlist frac_land transpo_cost_1920 coastal has_port avg_precip avg_temp n_wells totfrac_in_main_city m_rr m_rr_sqm_land m_rr_sqm_total{
		g `var'_m = `var'==.
		replace `var' = 0 if `var'==.
	}
	
	
	replace n_cgoodman_cz = 0 if n_cgoodman_cz==.
	replace b_cgoodman_cz1940 = 0 if b_cgoodman_cz1940==.
	replace b_cgoodman_cz1960 = 0 if b_cgoodman_cz1960==.
	replace b_cgoodman_cz1970 = 0 if b_cgoodman_cz1970==.
	replace b_cgoodman_cz1950 = 0 if b_cgoodman_cz1950==.
	replace b_cgoodman_cz2010 = 0 if b_cgoodman_cz2010==.

	// Get population data from years outside 1940-70
	merge 1:1 cz using "$INTDATA/census/urb_pop_2010.dta", keep(1 3) nogen keepusing(pop2010)
	
	preserve
		use "$INTDATA/census/cz_pop_occscore_mfg.dta", clear
		
		//drop pop
		reshape wide pop popc bpop bpopc occscore occscorec mfg_lfshare, i(cz) j(year)
		drop pop1940 popc1940 bpop1940 bpopc1940
		tempfile oldpops
		save `oldpops'
	restore
	merge 1:1 cz using `oldpops', keep(1 3) nogen
	
	merge 1:1 cz using "$INTDATA/census/cz_mfg_1980_2000.dta", keep(1 3) nogen

	//drop pop19* 

	preserve
		import delimited using "$RAWDATA/census/nhgis0046_csv/nhgis0046_csv/nhgis0046_ts_nominal_county.csv", clear
		ren a00aa* pop*
		ren statenh nhgisst
		ren countynh nhgiscty
		//keep pop* nhgisst nhgiscty
		reshape long pop, i(nhgisst nhgiscty) j(year)
		drop if mi(pop)
		replace nhgiscty = nhgiscty / 10 if year == 2010 // Weird but ok
		merge 1:m year nhgisst nhgiscty using "$XWALKS/consistent_1990", keepusing(weight nhgisst_1990 nhgiscty_1990) keep(1 3)
		
		g fixed = 0
		// Alexandria City dropped in 1900?
		replace nhgisst_1990 = 510 if year == 1900 & gisjoin == "G5105100" 
		replace nhgiscty_1990 = 5100 if year == 1900 & gisjoin == "G5105100"
		replace weight = 1 if year == 1900 & gisjoin == "G5105100"
		replace fixed = 1 if year == 1900 & gisjoin == "G5105100"

		// Shannon dropped in 1910?
		replace nhgisst_1990 = 460 if year == 1910 & gisjoin == "G4601130"
		replace nhgiscty_1990 = 1130 if year == 1910 & gisjoin == "G4601130"
		replace weight = 1 if year == 1910 & gisjoin == "G4601130"
		replace fixed = 1 if year == 1910 & gisjoin == "G4601130"

		// Washington dropped in 1910? Becomes Shannon
		replace nhgisst_1990 = 460 if year == 1910 & gisjoin == "G4601330"
		replace nhgiscty_1990 = 1130 if year == 1910 & gisjoin == "G4601330"
		replace weight = 1 if year == 1910 & gisjoin == "G4601330"
		replace fixed = 1 if year == 1910 & gisjoin == "G4601330"

		// Armstrong dropped in 1900? Becomes Dewey
		replace nhgisst_1990 = 460 if year == 1900 & gisjoin == "G4600010"
		replace nhgiscty_1990 = 410 if year == 1900 & gisjoin == "G4600010"
		replace weight = 1 if year == 1900 & gisjoin == "G4600010"
		replace fixed = 1 if year == 1900 & gisjoin == "G4600010"

		// Apache/San Carlos Reservation misnamed.
		replace nhgisst_1990 = 40 if year == 1900 & gisjoin == "G0459155"
		replace nhgiscty_1990 = 10 if year == 1900 & gisjoin == "G0459155"
		replace weight = 1 if year == 1900 & gisjoin == "G0459155"
		replace fixed = 1 if year == 1900 & gisjoin == "G0459155"
	
	
		// All 1990 are missing as that's base year
		replace nhgisst_1990 = nhgisst if year == 1990
		replace nhgiscty_1990 = nhgiscty if year == 1990
		replace weight = 1 if year == 1990
		replace fixed = 1 if year == 1990
		
		// 2020 is missing but we don't need it anyway
		drop if year == 2020
	 
		keep if _merge == 3 | fixed == 1 
		
		foreach var of varlist pop {
			replace `var' = `var'*weight
		}
		collapse (sum) pop , by(year nhgisst_1990 nhgiscty_1990)
		
		ren nhgisst_1990 statefip
		ren nhgiscty_1990 countyfip
			
		g cty_fips = statefip*100+countyfip/10

		merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(1 3) nogen
		ren cty_fips fips
		ren czone cz
		
		collapse (sum) pop, by(year cz)
		reshape wide pop, i(cz) j(year)
			
		tempfile nhgispops
		save `nhgispops'
	restore
	merge 1:1 cz using `nhgispops', keep(1 3) nogen
		
	
	
	//merge 1:1 cz using "$INTDATA/census/cz_mfg.dta", keep(3) nogen
	//ren mfg_lfshare* new_mfg_lfshare*
	
	merge 1:1 cz using "$INTDATA/dcourt/clean_cz_industry_employment_1940_1970.dta", keep(1 3) nogen keepusing(mfg_lfshare1950 mfg_lfshare1960 mfg_lfshare1970)
	
	
	// Outcome transformations
	foreach ds in  gen_muni schdist_ind all_local gen_subcounty spdist  gen_town cgoodman  totfrac{
			local label : variable label n_`ds'_cz
			lab var n_`ds'_cz "New Govs, `label'"
			lab var b_`ds'_cz1940 "Base Govs 1940, `label'"
			lab var b_`ds'_cz1970 "Base Govs 1970, `label'"
			
			g b_`ds'_cz1940_pc = b_`ds'_cz1940/(pop1940/10000) 
			g b_`ds'_cz1950_pc = b_`ds'_cz1950/(pop1950/10000) 
			g b_`ds'_cz1960_pc = b_`ds'_cz1960/(pop1960/10000) 
			g b_`ds'_cz1970_pc = b_`ds'_cz1970/(pop1970/10000) 
			g b_`ds'_cz2010_pc = b_`ds'_cz2010/(pop2010/10000) 

			// Main outcomes
			g n_`ds'_cz_pc = b_`ds'_cz1970/(pop1970/10000) - b_`ds'_cz1940/(pop1940/10000) 
			g ld_`ds'_cz_pc = b_`ds'_cz2010/(pop2010/10000) - b_`ds'_cz1940/(pop1940/10000) 
			
			// 1950 base year 
			g n2_`ds'_cz_pc = b_`ds'_cz1970/(pop1970/10000) - b_`ds'_cz1950/(pop1950/10000) 
			g ld2_`ds'_cz_pc = b_`ds'_cz2010/(pop2010/10000) - b_`ds'_cz1950/(pop1950/10000) 
			
			// Log Differences
			g n_`ds'_cz_ld = log(b_`ds'_cz1970) - log(b_`ds'_cz1940)
			g ld_`ds'_cz_ld = log(b_`ds'_cz2010) - log(b_`ds'_cz1940)
			
			// Percentage differences
			g pct_`ds'_cz_pc = (b_`ds'_cz1970 - b_`ds'_cz1940)/(pop1940/10000)
			g pct_ld_`ds'_cz_pc = (b_`ds'_cz2010 - b_`ds'_cz1940)/(pop1940/10000)
			
			// Population dilution term
			g decomp_`ds'_cz_pc = (-1) * (b_`ds'_cz1970/(pop1970/10000)) * ((pop1970 - pop1940) / pop1940)
			g decomp_ld_`ds'_cz_pc = (-1) * (b_`ds'_cz2010/(pop2010/10000)) * ((pop2010 - pop1940) / pop1940)
			
			// Raw Differences
			g n_`ds'_cz1970 = b_`ds'_cz1970 - b_`ds'_cz1940
			g n_`ds'_cz2010 = b_`ds'_cz2010 - b_`ds'_cz1940

			// Labels
			lab var n_`ds'_cz_pc "Change in `label', P.C. 1940-1970"
			lab var ld_`ds'_cz_pc "Change in `label', P.C. 1940-2010"
			
			lab var n2_`ds'_cz_pc "Change in `label', P.C. 1950-1970"
			lab var ld2_`ds'_cz_pc "Change in `label', P.C. 1950-2010"
			
			lab var n_`ds'_cz_ld "Log difference in `label', 1940-1970"
			lab var ld_`ds'_cz_ld "Log difference in `label', 1940-2010"
			
			lab var pct_`ds'_cz_pc "New `label' 1940 P.C., 1940-1970"
			lab var pct_ld_`ds'_cz_pc "New `label' 1940 P.C., 1940-2010"
			
			lab var decomp_`ds'_cz_pc "Pop. Dilution of `label', 1940-1970"
			lab var decomp_ld_`ds'_cz_pc "Pop. Dilution of `label', 1940-2010"

	}
	
	
	// Decadal changes for cgoodman data
	
	g b1900_cgoodman_cz_pc = b_cgoodman_cz1900/(pop1900/10000)
	g b1940_cgoodman_cz_pc = b_cgoodman_cz1940/(pop1940/10000)

	forv y = 1910(10)2010{
		local y1 = `y'-10
		cap g b`y'_cgoodman_cz_pc = b_cgoodman_cz`y'/(pop`y'/10000)
		g n`y'_cgoodman_cz_pc = b`y'_cgoodman_cz_pc - b`y1'_cgoodman_cz_pc
		g diff`y'_cgoodman_cz_pc = b`y'_cgoodman_cz_pc - b1940_cgoodman_cz_pc
	}

	// Adding measure of enclosedness
	preserve	
		import delimited using "$CLEANDATA/other/length_enclosed.csv", clear
		duplicates drop
		keep cz total_length
		tempfile length
		save `length'
	restore
	
	merge 1:1 cz using `length', assert(3) nogen

	preserve 
		import delimited using "$DATA/qgis/enclosedness/enclosed_1940.csv", clear
		keep cz_2 cz_2_2 len
		g cz = cond(mi(cz_2), cz_2_2, cz_2) 
		collapse (sum) len, by(cz)
		ren len enclosed1940
		tempfile enclosed1940
		save `enclosed1940'
	restore
	
	merge 1:1 cz using `enclosed1940', keep(1 3) nogen
	replace enclosed1940 = 0 if mi(enclosed1940)
	preserve 
		import delimited using "$DATA/qgis/enclosedness/enclosed_1970.csv", clear
		keep cz_2 cz_2_2 len
		g cz = cond(mi(cz_2), cz_2_2, cz_2) 
		collapse (sum) len, by(cz)
		ren len enclosed1970
		tempfile enclosed1970
		save `enclosed1970'
	restore
	
	merge 1:1 cz using `enclosed1970', keep(1 3) nogen
	replace enclosed1970 = 0 if mi(enclosed1970)
	
	
	
	
	g prop_enclosed1940 = enclosed1940/total_length
	g prop_enclosed1970 = enclosed1970/total_length
	g change_enclosed4070 = (enclosed1970 - enclosed1940)/(total_length - enclosed1940)
	
	// New York causing problems but clearly fully enclosed by 1940
	replace prop_enclosed1940 = 1 if cz==19400
	replace prop_enclosed1970 = 1 if cz==19400
	replace change_enclosed4070 = 1 if cz == 19400
	
	
	su prop_enclosed1940, d
	g above_med_enclosed = prop_enclosed1940 >= r(p50)
	
	
	
	merge 1:1 cz using "$INTDATA/cgoodman/orig_geogs", keep(3) nogen
	
	// Population densities (relative to 2010 land size)
	
	forv y=1900(10)2010{
		g cz_popdens`y' = pop`y'/(cz_total2010/1000000)
		lab var cz_popdens`y' "Population Density, `y'"
	}
	
	g orig_popdens1940 = popc1940/(orig_total/1000000)
	g orig_popdenst1940 = popc1940/(orig_total/1000000)


	// Count of touching munis
	preserve
		import excel using "$CLEANDATA/other/touching_munis.xlsx", clear first
		keep cz GEOID_2 yr_ncrp
		duplicates drop
		g touching40 = yr_ncrp<=1940
		g touching70 = yr_ncrp<=1970
		collapse (sum) touching40 touching70, by(cz)
		g touching_diff = touching70 - touching40
		tempfile touching 
		save `touching'
	restore
	
	merge 1:1 cz using `touching', assert(1 3)
	replace touching40 = 0 if _merge == 1
	replace touching70 = 0 if _merge == 1
	replace touching_diff = 0 if _merge == 1
	drop _merge
	
	// Incorporated populations
	preserve 
		use "$CLEANDATA/place_race_pop.dta", clear
		g incpop1970 = place_pop1970 if yr_incorp <=1970
		g incpop2010 = place_pop2010 if yr_incorp <= 2010
		collapse (sum) incpop1970 incpop2010, by(cz)
		ren czone cz
		tempfile incpop
		save `incpop'
	restore
	
	merge 1:1 cz using `incpop', keep(3) nogen
	
	
	
	g frac_uninc1970 = (pop1970 - incpop1970)/pop1970
	g frac_uninc2010 = (pop2010 - incpop2010)/pop2010
	g frac_unc1970 = ((pop1970- popc1970)/pop1970) 
	g frac_unc1940 = ((pop1940 - popc1940)/pop1940)
	g change_frac_unc = frac_unc1970 - frac_unc1940
	
	// Add in new instruments and sumshares
	foreach version in base base_quad base_white base_stres black_sob base_rur{
		merge 1:1 cz using "$INTDATA/ssaggregate_prep/dest_instrument_`version'", keep(3) nogen
		ren shift_share shift_share_`version'
		ren sumshare sumshare_`version'
		replace shift_share_`version' = 100* shift_share_`version'
	}
	
	// Add in placebo instruments
	forv i=1/1000{
		merge 1:1 cz using "$INTDATA/ssaggregate_prep/placebo/dest_instrument_base_placebo_`i'", keep(3) nogen
		ren shift_share shift_share_placebo_`i'
		ren sumshare sumshare_placebo_`i'
		replace shift_share_placebo_`i' = 100* shift_share_placebo_`i'
	}
	// Panel Instrument
	preserve
		use "$INTDATA/ssaggregate_prep/dest_instrument_panel_base", clear
		ren shift_share shift_share_panel_
		ren sumshare sumshare_panel_
		reshape wide shift_share_panel_ sumshare_panel_, i(cz) j(year)
		tempfile sumshare_panel
		save `sumshare_panel'
	restore
	
	merge 1:1 cz using `sumshare_panel', keep(1 3) nogen
	
	// Repeated decadal instrument
	preserve
		foreach y in 1940 1950 1960{
			use "$INTDATA/ssaggregate_prep/dest_instrument_panel_`y'_base", clear
			ren shift_share shift_share_split_`y'
			ren sumshare sumshare_split_`y'
			tempfile sumshare_split_`y'
			save `sumshare_split_`y''
		}
	restore
	merge 1:1 cz using `sumshare_split_1940', keep(1 3) nogen
	merge 1:1 cz using `sumshare_split_1950', keep(1 3) nogen
	merge 1:1 cz using `sumshare_split_1960', keep(1 3) nogen
	
	// Court Orders
	ren cz czone
	merge 1:1 czone using "$CLEANDATA/nces/cz_court_orders", keep(1 3) nogen
	ren czone cz
	replace frac_court_ordered = 100*frac_court_ordered
	
	su frac_court_ordered, d
	g above_co_med = frac_court_ordered > r(p50)
	su frac_enroll_court_ordered, d
	g above_co_enroll_med = frac_enroll_court_ordered > r(p50)

	

	// Black linked income differences
	merge 1:1 cz using "$INTDATA/census/black_linked_chars.dta", keep(1 3) nogen keepusing(cz occscore_black_3040_linked)
	
	g bmig_occscore_diff = occscore_black_3040_linked - occscore1930 if !mi(occscore_black_3040_linked)	
	g bmig_occscorec_diff = occscore_black_3040_linked - occscorec1930 if !mi(occscore_black_3040_linked)	
	
	su occscore_black_3040_linked, d
	g above_med_occscore_3040 = occscore_black_3040_linked >= r(p50) if !mi(occscore_black_3040_linked)		
	
	su bmig_occscore_diff, d
	g above_med_occscore_diff = bmig_occscore_diff >= r(p50) if !mi(occscore_black_3040_linked)	
	g pos_occscore_diff = bmig_occscore_diff > 0 if !mi(occscore_black_3040_linked)	
	
	su bmig_occscorec_diff, d
	g above_med_occscorec_diff = bmig_occscorec_diff >= r(p50) if !mi(occscore_black_3040_linked)	
	g pos_occscorec_diff = bmig_occscorec_diff > 0 if !mi(occscore_black_3040_linked)	
	
	
	// Black mig income differences
	merge 1:1 cz using "$INTDATA/census/bmig_incomes", keep(1 3) nogen

	// Difference from CZ average
	g bmig_income_diff_cz = (mean_income_1940_bmig - mean_income_1940) / mean_income_1940
	su bmig_income_diff_cz, d
	g above_bmig_diff_cz = bmig_income_diff_cz >= r(p50) if !mi(mean_income_1940_bmig)
	
	// Difference from all black migrants
	g bmig_income_diff = (mean_income_1940_bmig - mean_income_1940_bmig_all) / mean_income_1940_bmig_all
	su bmig_income_diff, d
	g above_bmig_diff = bmig_income_diff >= r(p50)  if !mi(mean_income_1940_bmig)

	
	// Streams 
	merge 1:1 cz using "$INTDATA/other/streams", keep(1 3) nogen
	lab var n_streams "Number of Streams"
	
	
	su GM_raw_pp, d
	g above_x_med = GM_raw_pp >= r(p50)


	g GM_rawXco = GM_raw_pp * court_order
	g GM_rawXfrac_co = GM_raw_pp * frac_court_ordered
	g GM_hatXco = shift_share_base * court_order
	g GM_hatXfrac_co = shift_share_base * frac_court_ordered
	g GM_raw_pp_quad = GM_raw_pp^2
	xtile GM_hat = shift_share_base, nq(100) 
	
	lab var GM_raw_pp "Percentage Point Change in Urban Black Population"
	lab var GM_raw "Percentage Change in Urban Black Population"
	lab var shift_share_base "Predicted Percentage Change in Urban Black Population"
	lab var GM "Percentile Change in Urban Black Population"
	lab var GM_hat "Predicted Percentile Change in Urban Black Population"
	
	
	
	
	forv y=1900/2010{
		cap lab var bpop`y' "Total Black Population, `y'"
		cap lab var bpopc`y' "Urban Black Population, `y'"
		cap lab var pop`y' "Total Population, `y'"
		cap lab var popc`y' "Urban Population, `y'"
	}
	
	lab var frac_land "Fraction of CZ land incorporated"
	lab var frac_total "Fraction of CZ area incorporated"

	cap lab var cz "Commuting Zone (1990)"
	cap lab var fips "County FIPS Code"
	

	lab var totfrac_in_main_city "Fraction of population in largest city"
	lab var n_wells "Number of Oil/Nat Gas Wells, 1940"
	lab var max_temp "Maximum Temperature, 1940"
	lab var min_temp "Minimum Temperature, 1940"
	lab var avg_temp "Average Temperature, 1940"
	lab var avg_precip "Average Precipitation, 1940"
	lab var has_port "Has Port, 1940"
	lab var coastal "Coastal"
	lab var transpo_cost_1920 "Average Transport Cost out of CZ, 1920"
	lab var m_rr "Meters of Railroad, 1940"
	lab var m_rr_sqm_land "Meters of Railroad per Square Meter of Land, 1940"
	lab var m_rr_sqm_total "Meters of Railroad per Square Meter of Area, 1940"
	lab var frac_total "Fraction of area incorporated"
	lab var coastal "Coastal CZ" 
	lab var avg_precip "Average precipitation" 
	lab var avg_temp "Average temperature"
	
	
	lab var n1910_cgoodman_cz_pc  "New municipalities per capita, 1900-10"
	lab var n1920_cgoodman_cz_pc  "New municipalities per capita, 1910-20"
	lab var n1930_cgoodman_cz_pc  "New municipalities per capita, 1920-30"
	lab var n1940_cgoodman_cz_pc  "New municipalities per capita, 1930-40"
	
	
	
	lab var higrade "Average years of education"
	lab var hsgrad "Prop HS Grads"
	lab var unigrad "Prop College Grads"
	//lab var mean_urban_income_1940 "1940 Income (Urban Areas)"
	lab var mean_income_1940 "Average Income, 1940"
	//lab var growth3040 "1930-40 Population Growth Rate"
	lab var shift_share_base "$\hat{GM}$"
	
	lab var shift_share_base_white "$\hat{WM}$"

	lab var WM_raw_pp "WM"
	
	save "$CLEANDATA/cz_pooled", replace
