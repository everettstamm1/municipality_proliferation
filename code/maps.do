/*

maptile_install using "http://files.michaelstepner.com/geo_county1990.zip"
maptile_install using "http://files.michaelstepner.com/geo_county2000.zip"
maptile_install using "http://files.michaelstepner.com/geo_county2010.zip"
maptile_install using "http://files.michaelstepner.com/geo_cz1990.zip"
maptile_install using "http://files.michaelstepner.com/geo_cz2000.zip"
maptile_install using "http://files.michaelstepner.com/geo_msacmsa2000.zip"
maptile_install using "http://files.michaelstepner.com/geo_msapmsa2000.zip"
maptile_install using "http://files.michaelstepner.com/geo_state.zip"
*/

// States (from county totals, should probably change)
	use "$INTDATA/cog/2_county_counts.dta", clear
foreach var of varlist  all_local_tax gen_subcounty gen_muni gen_town spdist spdist_tax schdist_ind schdist_dep schdist int_* subcty_tax all_local{
	
	use "$INTDATA/cog/2_county_counts.dta", clear
	
	local lab: variable label `var'

	destring fips_state, gen(statefips)
	bys statefips year : egen n_`var' = total(`var'), missing
	keep statefips year n_`var'
	duplicates drop
	bys statefips (year) : g change_`var' = n_`var' - n_`var'[_n-1]
	bys statefips (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))

	bys statefips (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

	drop if year==1942 | statefips==. | regexm(decade_lab,"\.") | n_`var'==. | change_`var'==. 
	
	// get all decade and year labels
	levelsof decade_lab, local(decades)
	levelsof year, local(years)
	// Get first year for base legend
	qui su year,d
	local base = `r(min)'
	drop n_`var'
	reshape wide decade_lab p_change_`var' change_`var', i(statefips) j(year)
	pctile breaks = change_`var'`base', n(10)
	pctile breaks_p = p_change_`var'`base', n(10)

	foreach y in `years'{

		local decade_lab  = decade_lab`y'[_N]
		maptile p_change_`var'`y', geo(state) geoid(statefips) cutp(breaks_p) legd(0) twopt(title("State Percent Change in `lab', `decade_lab'") legend(title("% Change") position(6) cols(5) ring(5)) note("Data From CoG 2: County Gov't Counts"))
		graph export "$MAPS/state/state_p_change_`var'_`decade_lab'.png", as(png) replace
		
		maptile change_`var'`y', geo(state) geoid(statefips) cutp(breaks) legd(0) twopt(title("State Change in `lab', `decade_lab'") legend(title("Change") position(6) cols(5) ring(5)) note("Data From CoG 2: County Gov't Counts")) 
		graph export "$MAPS/state/state_change_`var'_`decade_lab'.png", as(png) replace
	
			
	}

	use "$INTDATA/cog/2_county_counts.dta", clear
	g county = fips_state+fips_county_2002
	drop if fips_state=="" | fips_county_2002==""
	destring county, replace
	keep county year `var'
	duplicates drop
	bys county (year) : g change_`var' = `var' - `var'[_n-1]
	bys county (year) : g p_change_`var' = 100*(log(`var') - log(`var'[_n-1]))

	bys county (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

	drop if year==1942 | county==. | regexm(decade_lab,"\.") | `var'==. | change_`var'==. 
	drop  `var'
	
	// get all decade and year labels
	levelsof decade_lab, local(decades)
	levelsof year, local(years)
	// Get first year for base legend
	qui su year,d
	local base = `r(min)'
	
	reshape wide decade_lab p_change_`var' change_`var', i(county) j(year)
	pctile breaks = change_`var'`base', n(10)
	pctile breaks_p = p_change_`var'`base', n(10)

	foreach y in `years'{
		local decade_lab  = decade_lab`y'[_N]
		
		maptile p_change_`var'`y', geo(county2000)  legd(0) cutp(breaks_p) twopt(title("County Percent Change in `lab', `decade_lab'") legend(title("% Change") position(6)  cols(5) ring(5)) note("Data From CoG 2: County Gov't Counts"))
		graph export "$MAPS/county/county_p_change_`var'_`decade_lab'.png", as(png) replace
		
		maptile change_`var'`y', geo(county2000) legd(0) cutp(breaks) twopt(title("County Change in `lab', `decade_lab'") legend(title("Change") position(6) cols(5) ring(5)) note("Data From CoG 2: County Gov't Counts"))
		graph export "$MAPS/county/county_change_`var'_`decade_lab'.png", as(png) replace
		
	}


	use "$INTDATA/cog/2_county_counts.dta", clear
	rename czone cz
	drop if cz==.
	bys cz year : egen n_`var' = total(`var'), missing

	keep cz year n_`var'
	duplicates drop
	bys cz (year) : g change_`var' = n_`var' - n_`var'[_n-1]
	bys cz (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))

	bys cz (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

	drop if year==1942 | regexm(decade_lab,"\.") | n_`var'==. | change_`var'==. 
	drop n_`var'
	
	// get all decade and year labels
	levelsof decade_lab, local(decades)
	levelsof year, local(years)
	// Get first year for base legend
	qui su year,d
	local base = `r(min)'
	
	reshape wide decade_lab p_change_`var' change_`var', i(cz) j(year)
	pctile breaks = change_`var'`base', n(10)
	pctile breaks_p = p_change_`var'`base', n(10)

	foreach y in `years'{
		local decade_lab  = decade_lab`y'[_N]

		
		maptile p_change_`var'`y', geo(cz1990)  legd(0) cutp(breaks_p) twopt(title("CZ Percent Change in `lab', `decade_lab'") legend(title("% Change") position(6) cols(5) ring(5)) note("Data From CoG 2: County Gov't Counts"))
		graph export "$MAPS/cz/cz_p_change_`var'_`decade_lab'.png", as(png) replace
		
		maptile change_`var'`y', geo(cz1990) legd(0) cutp(breaks) twopt(title("CZ Change in `lab', `decade_lab'") legend(title("Change") position(6) cols(5) ring(5)) note("Data From CoG 2: County Gov't Counts"))
		graph export "$MAPS/cz/cz_change_`var'_`decade_lab'.png", as(png) replace
	}
}
