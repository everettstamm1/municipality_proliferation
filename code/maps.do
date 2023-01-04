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
foreach level in state county cz{
	if "`level'" == "state"{
		local levelvar = "statefips"
		local leveldb = "state"
		local levellab = "State"
	}
	else if "`level'" == "cz"{
		local levelvar = "cz"
		local leveldb = "cz1990"
		local levellab = "CZ"
	}
	else if "`level'" == "county"{
		local levelvar = "county"
		local leveldb = "county2000"
		local levellab = "County"
	}
	foreach var of varlist  all_local_tax gen_subcounty gen_muni gen_town spdist spdist_tax schdist_ind schdist_dep schdist int_* subcty_tax all_local{
		preserve
		
			local lab: variable label `var'

			destring fips_state, gen(statefips)
			
			g county = fips_state+fips_county_2002
			drop if fips_state=="" | fips_county_2002==""
			destring county, replace
			
			rename czone cz
			
			bys `level' year : egen n_`var' = total(`var'), missing
			keep `level' year n_`var'
			duplicates drop
			
			
			bys `level' (year) : g change_`var' = n_`var' - n_`var'[_n-1]
			bys `level' (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))

			bys `level' (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

			drop if year==1942 | `level'==. | regexm(decade_lab,"\.") | n_`var'==. | change_`var'==. 
			
			// get all decade and year labels
			levelsof decade_lab, local(decades)
			levelsof year, local(years)
			// Get first year for base legend
			qui su year,d
			local base = `r(min)'
			drop n_`var'
			reshape wide decade_lab p_change_`var' change_`var', i(`level') j(year)
			pctile breaks = change_`var'`base', n(10)
			pctile breaks_p = p_change_`var'`base', n(10)

			foreach y in `years'{
				local geoid = cond("`level'"=="state","geoid(statefips)","")
				local conus = cond("`level'"=="state","mapif(statefips!=2 & statefips!=15)","conus")

				local decade_lab  = decade_lab`y'[_N]
				
				maptile p_change_`var'`y', ///
								geo(`leveldb') `geoid' cutp(breaks_p) legd(0) ///
								twopt(title("`levellab' Percent Change in `lab', `decade_lab'") ///
								legend(title("% Change") position(6) cols(5) ring(5)) ///
								note("Data From CoG 2: County Gov't Counts")) `conus'
				graph export "$MAPS/2_county_counts/`level'/`level'_p_change_`var'_`decade_lab'.png", as(png) replace
				
				maptile change_`var'`y', ///
								geo(`leveldb') `geoid' cutp(breaks) legd(0) ///
								twopt(title("`levellab' Change in `lab', `decade_lab'") ///
								legend(title("Change") position(6) cols(5) ring(5)) ///
								note("Data From CoG 2: County Gov't Counts")) `conus'
				graph export "$MAPS/2_county_counts/`level'/`level'_change_`var'_`decade_lab'.png", as(png) replace
			}
		restore
	}
}


use "$INTDATA/cog/4_1_general_purpose_govts.dta", clear
keep if ID_type == 2 | ID_type == 3 // keeping only municipal and town/township observations
g incorp_date1 = original_incorporation_date
g incorp_date2 = year_home_rule_adopted
g incorp_date3 = cond(original_incorporation_date<.,original_incorporation_date,year_home_rule_adopted)

lab var incorp_date1 "Incorporations"
lab var incorp_date2 "Home Rule Adoptions"
lab var incorp_date3 "Incorporations or Home Rule Adoptions"

destring incorp_date*, replace
drop if incorp_date3==.
keep id fips_code_state fips_code_county fips_code_msa czone incorp_date*
duplicates drop

g county = fips_code_state + fips_code_county

destring county, replace
destring fips_code_state, gen(statefips)
rename fips_code_msa msapmsa2000
rename czone cz


foreach level in  msa {
	
	if "`level'" == "state"{
		local levelvar = "statefips"
		local leveldb = "state"
		local levellab = "State"
	}
	else if "`level'" == "cz"{
		local levelvar = "cz"
		local leveldb = "cz1990"
		local levellab = "CZ"
	}
	else if "`level'" == "county"{
		local levelvar = "county"
		local leveldb = "county2000"
		local levellab = "County"
	}
	else if "`level'" == "msa"{
		local levelvar = "msapmsa2000"
		local leveldb = "msapmsa2000"
		local levellab = "MSA"
	}
	foreach var of varlist  incorp_date*{
		
		preserve
		
			local lab: variable label `var'

			g year = .
			forv y=1942(5)1987{
				replace year = `y' if `var'-5<`y' & `var'>=`y'
			}
			replace year = 1942 if year == 1947 // Not a year in CoG County so skipping
			
			drop if year==.
			replace `var' = 1

			bys `level' year : egen n_`var' = total(`var'), missing
			keep `level' year n_`var'
			duplicates drop
			
			

			bys `level' (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

			drop if year==1942 | `level'==. | regexm(decade_lab,"\.") | n_`var'==. | decade_lab==""
			
			// get all decade and year labels
			levelsof decade_lab, local(decades)
			levelsof year, local(years)
			
			// Get first year for base legend
			su year,d
			return list
			local base = `r(min)'
			reshape wide decade_lab  n_`var', i(`level') j(year)
			
			// The reshape drops decade lab when that state is missing, which isn't really what we want here.
			foreach d of varlist decade_lab*{
				sort `d'
				replace `d' = `d'[_N] 
			}
			
			pctile breaks = n_`var'`base', n(10)
			
			foreach y in `years'{
				local geoid = cond("`level'"=="state","geoid(statefips)","")
				local conus = cond("`level'"=="state","mapif(statefips!=2 & statefips!=15)","conus")

				local decade_lab  = decade_lab`y'[_N]
				
				
				maptile n_`var'`y', /// 
								geo(`leveldb') `geoid' cutp(breaks) legd(0) ///
								twopt(title("`levellab' New `lab', `decade_lab'") ///
								legend(title("Number") position(6) cols(5) ring(5)) ///
								note("Data From CoG 2: County Gov't Counts")) `conus'
				graph export "$MAPS/4_1_general_purpose_govts/`level'/`level'_new_`var'_`decade_lab'.png", as(png) replace
			}
		restore
	}
}
