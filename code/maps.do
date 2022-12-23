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

foreach var of varlist all_local all_local_tax gen_subcounty gen_muni gen_town spdist spdist_tax schdist_ind schdist_dep schdist int_* subcty_tax{
	
	local lab: variable label `var'

	use "$INTDATA/cog/2_county_counts.dta", clear
	destring fips_state, gen(statefips)
	bys statefips year : egen n_`var' = total(`var')
	keep statefips year n_`var'
	duplicates drop
	bys statefips (year) : g change_`var' = n_`var' - n_`var'[_n-1]
	bys statefips (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))

	bys statefips (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

	drop if year==1942 | statefips==. | regexm(decade_lab,"\.")

	levelsof decade_lab, local(decades)
	foreach d in `decades'{
		preserve
			keep if decade_lab=="`d'" 
			
			maptile p_change_`var', geo(state) geoid(statefips) n(10) legd(0) twopt(title("State Percent Change in `lab', `d'") legend(title("% Change")) note("Data From CoG 2: County Gov't Counts"))
			graph export "$MAPS/state/state_p_change_`var'_`d'.pdf", as(pdf) replace
			
			maptile change_`var', geo(state) geoid(statefips) n(10) legd(0) twopt(title("State Change in `lab', `d'") legend(title("Change")) note("Data From CoG 2: County Gov't Counts")) 
			graph export "$MAPS/state/state_change_`var'_`d'.pdf", as(pdf) replace
		restore
			
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

	drop if year==1942 | county==. | regexm(decade_lab,"\.")

	levelsof decade_lab, local(decades)
	foreach d in `decades'{
		preserve
			keep if decade_lab=="`d'" 
			
			maptile p_change_`var', geo(county2000)  legd(0) n(10) twopt(title("County Percent Change in `lab', `d'") legend(title("% Change")) note("Data From CoG 2: County Gov't Counts"))
			graph export "$MAPS/county/county_p_change_`var'_`d'.pdf", as(pdf) replace
			
			maptile change_`var', geo(county2000) legd(0) n(10) twopt(title("County Change in `lab', `d'") legend(title("Change")) note("Data From CoG 2: County Gov't Counts"))
			graph export "$MAPS/county/county_change_`var'_`d'.pdf", as(pdf) replace
		restore
			
	}


	use "$INTDATA/cog/2_county_counts.dta", clear
	rename czone cz
	drop if cz==.
	bys cz year : egen n_`var' = total(`var')

	keep cz year n_`var'
	duplicates drop
	bys cz (year) : g change_`var' = n_`var' - n_`var'[_n-1]
	bys cz (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))

	bys cz (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

	drop if year==1942 | regexm(decade_lab,"\.")

	levelsof decade_lab, local(decades)
	foreach d in `decades'{
		preserve
			keep if decade_lab=="`d'" 
			
			maptile p_change_`var', geo(cz1990)  legd(0) n(10) twopt(title("CZ Percent Change in `lab', `d'") legend(title("% Change")) note("Data From CoG 2: County Gov't Counts"))
			graph export "$MAPS/cz/cz_p_change_`var'_`d'.pdf", as(pdf) replace
			
			maptile change_`var', geo(cz1990) legd(0) n(10) twopt(title("CZ Change in `lab', `d'") legend(title("Change")) note("Data From CoG 2: County Gov't Counts"))
			graph export "$MAPS/cz/cz_change_`var'_`d'.pdf", as(pdf) replace
		restore
	}
}
