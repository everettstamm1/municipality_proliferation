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


set graphics off



use "$INTDATA/cog/2_county_counts.dta", clear
drop if fips_state == "02" | fips_state=="15"

labmask msapmsa2000, values(msapmsa_name)

foreach level in msa{
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
	else if "`level'" == "sample_msas"{
		local levelvar = "msapmsa2000"
		local leveldb = "msapmsa2000"
		local levellab = "MSA"
	}
	foreach var of varlist gen_subcounty gen_muni gen_town spdist spdist_tax schdist_ind schdist_dep schdist int_* subcty_tax all_local_tax all_local {
		preserve
		
			local lab: variable label `var'

			destring fips_state, gen(statefips)
			
			g county = fips_state+fips_county_2002
			drop if fips_state=="" | fips_county_2002==""
			destring county, replace
			
			rename czone cz
			
			bys `levelvar' year : egen n_`var' = total(`var'), missing
			keep `levelvar' year n_`var'
			duplicates drop
			
			
			bys `levelvar' (year) : g change_`var' = n_`var' - n_`var'[_n-1]
			bys `levelvar' (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))

			bys `levelvar' (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

			drop if year==1942 | `levelvar'==. | regexm(decade_lab,"\.") | n_`var'==. | change_`var'==. 
	
			// Bar Graphs
			g change_`var'_pos = change_`var' if change_`var'>0
			g p_change_`var'_pos = p_change_`var' if change_`var'>0
			
			if "`level'"!="sample_msas"{
				graph bar change_`var'  change_`var'_pos, over(decade_lab, label(angle(45))) ///
								legend(cols(1) order(1 "Mean {&Delta} `lab'" 2 "Mean {&Delta} `lab', Positive Values Only")) ///
								title("Mean {&Delta} `lab', `levellab' Level") ///
								note("Data From CoG 2: County Gov't Counts") 
								
				graph export "$FIGS/2_county_counts/`level'/`level'_change_`var'.png", as(png) replace

				graph bar change_`var'  change_`var'_pos, over(decade_lab, label(angle(45))) ///
								legend(cols(1) order(1 "Mean %{&Delta} `lab'" 2 "Mean %{&Delta} `lab', Positive Values Only")) ///
								title("Mean %{&Delta} in `lab', `levellab' Level") ///
								note("Data From CoG 2: County Gov't Counts") 
				
				graph export "$FIGS/2_county_counts/`level'/`level'_p_change_`var'.png", as(png) replace
					
				drop *_pos
				
				// get all decade and year labels
				levelsof decade_lab, local(decades)
				levelsof year, local(years)
				// Get second year for base legend or first if only one year (first year really negative skewed so it doesn't make very good graphs)
				qui su year,d
				if `r(min)'!=`r(max)'{
					qui su year if year>`r(min)'
				}
				local base = `r(min)'

				drop n_`var'
				reshape wide decade_lab p_change_`var' change_`var', i(`levelvar') j(year)
				pctile breaks = change_`var'`base', n(9)
				pctile breaks_p = p_change_`var'`base', n(9)

				local i = 1
				foreach y in `years'{
					local geoid = cond("`level'"=="state","geoid(statefips)","")
					local conus = cond("`level'"=="state","mapif(statefips!=2 & statefips!=15)","conus")

					local decade_lab  = decade_lab`y'[_N]
					
					qui unique breaks_p
					local keys = `r(unique)'+1
					numlist  "`keys'[-1]1",descending
					maptile p_change_`var'`y', ///
									geo(`leveldb') `geoid' cutp(breaks_p) legd(0) ///
									twopt(title("`levellab' Percent Change in `lab', `decade_lab'") ///
									legend(title("% Change") position(6) cols(5) ring(5) order(`r(numlist)' "No Data")) ///
									note("Data From CoG 2: County Gov't Counts")) `conus'
					graph export "$MAPS/2_county_counts/`level'/images/`level'_p_change_`var'_`i'.png", as(png) replace
					
					qui unique breaks
					local keys = `r(unique)'+1
					numlist  "`keys'[-1]1", descending
					maptile change_`var'`y', ///
									geo(`leveldb') `geoid' cutp(breaks) legd(0) ///
									twopt(title("`levellab' Change in `lab', `decade_lab'") ///
									legend(title("Change") position(6) cols(5) ring(5) order(`r(numlist)' "No Data")) ///
									note("Data From CoG 2: County Gov't Counts")) `conus'
					graph export "$MAPS/2_county_counts/`level'/images/`level'_change_`var'_`i'.png", as(png) replace
					local i=`i'+1

				}
			}
			else if "`level'"=="sample_msas"{
				keep if msapmsa2000 == 1600 | /// Chicago
								msapmsa2000 == 1680 | /// Cleveland-Lorain-Elyria
								msapmsa2000 == 2160 | /// Detroit
								msapmsa2000 == 3280 | /// Hartford
								msapmsa2000 == 4480 | /// Los Angeles-Long Beach
								msapmsa2000 == 7360  // San Francisco
				
				levelsof msapmsa2000, local(msas)
				local lbe : value label msapmsa2000
				foreach msa in `msas'{
					local msa_lab : label `lbe' `msa'

					graph bar change_`var' if msapmsa2000 == `msa', over(decade_lab, label(angle(45))) ///
									legend(cols(1) order(1 "Mean New `lab'")) ///
									title("Mean {&Delta} `lab' in `msa_lab'") ///
									note("Data From CoG 2: County Gov't Counts") 
					graph export "$FIGS/2_county_counts/`level'/`level'_`msa'_change_`var'.png", as(png) replace
					
					graph bar p_change_`var' if msapmsa2000 == `msa', over(decade_lab, label(angle(45))) ///
									legend(cols(1) order(1 "Mean New `lab'")) ///
									title("Mean %{&Delta} `lab' in `msa_lab'") ///
									note("Data From CoG 2: County Gov't Counts") 
					graph export "$FIGS/2_county_counts/`level'/`level'_`msa'_p_change_`var'.png", as(png) replace
				}
			}
		restore
	}
}


use "$INTDATA/cog/4_1_general_purpose_govts.dta", clear
drop if fips_code_state == "02" | fips_code_state=="15"

keep if ID_type == 2 | ID_type == 3 // keeping only municipal and town/township observations
g incorp_date1 = original_incorporation_date
g incorp_date2 = year_home_rule_adopted
g incorp_date3 = cond(original_incorporation_date<.,original_incorporation_date,year_home_rule_adopted)

lab var incorp_date1 "Incorporations"
lab var incorp_date2 "Home Rule Adoptions"
lab var incorp_date3 "Incorporations or Home Rule Adoptions"

destring incorp_date*, replace
drop if incorp_date3==.

rename fips_code_msa msapmsa2000
labmask msapmsa2000, values(msapmsa_name)

keep id fips_code_state fips_code_county msapmsa2000 czone incorp_date*
duplicates drop

g county = fips_code_state + fips_code_county

destring county, replace
destring fips_code_state, gen(statefips)
rename czone cz

foreach level in state county cz msa sample_msas {
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
	else if "`level'" == "sample_msas"{
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

			bys `levelvar' year : egen n_`var' = total(`var'), missing
			keep `levelvar' year n_`var'
			
			duplicates drop
			
			

			bys `levelvar' (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

			drop if year==1942 | `levelvar'==. | regexm(decade_lab,"\.") | n_`var'==. | decade_lab==""

			if "`level'"!="sample_msas"{
				// Bar Graphs
				graph bar n_`var'  , over(decade_lab, label(angle(45))) ///
								legend(cols(1) order(1 "Mean New `lab'")) ///
								title("Mean New `lab', `levellab' Level") ///
								note("Data From CoG 4: Gov't Org Directory Surveys") 
				graph export "$FIGS/4_1_general_purpose_govts/`level'/`level'_new_`var'.png", as(png) replace
			
							
				
				// get all decade and year labels
				levelsof decade_lab, local(decades)
				levelsof year, local(years)
				
				// Get second year for base legend or first if only one year (first year really negative skewed so it doesn't make very good graphs)
				qui su year,d
				if `r(min)'!=`r(max)'{
					qui su year if year>`r(min)'
				}
				local base = `r(min)'
				
				
				reshape wide decade_lab n_`var', i(`levelvar') j(year)
				pctile breaks = n_`var'`base', n(9)

				// The reshape drops decade lab when that state is missing, which isn't really what we want here.
				foreach d of varlist decade_lab*{
					sort `d'
					replace `d' = `d'[_N] 
				}
				
				
				local i =1
				foreach y in `years'{
					local geoid = cond("`level'"=="state","geoid(statefips)","")
					local conus = cond("`level'"=="state","mapif(statefips!=2 & statefips!=15)","conus")

					local decade_lab  = decade_lab`y'[_N]
					
					qui unique breaks
					local keys = `r(unique)'+1
					numlist  "`keys'[-1]1",descending
					maptile n_`var'`y', /// 
									geo(`leveldb') `geoid' cutp(breaks) legd(0) ///
									twopt(title("`levellab' New `lab', `decade_lab'") ///
									legend(title("Number") position(6) cols(5) ring(5) order(`r(numlist)' ///
									"No Data")) note("Data From CoG 4: Gov't Org Directory Surveys")) `conus'
					graph export "$MAPS/4_1_general_purpose_govts/`level'/images/`level'_new_`var'_`i'.png", as(png) replace
					local i=`i'+1
				}
			}
			else if "`level'"=="sample_msas"{
				keep if msapmsa2000 == 1600 | /// Chicago
								msapmsa2000 == 1680 | /// Cleveland-Lorain-Elyria
								msapmsa2000 == 2160 | /// Detroit
								msapmsa2000 == 3280 | /// Hartford
								msapmsa2000 == 4480 | /// Los Angeles-Long Beach
								msapmsa2000 == 7360  // San Francisco

				levelsof msapmsa2000, local(msas)
				local lbe : value label msapmsa2000
				foreach msa in `msas'{
					local msa_lab : label `lbe' `msa'

					graph bar n_`var' if msapmsa2000 == `msa', over(decade_lab, label(angle(45))) ///
									legend(cols(1) order(1 "Mean New `lab'")) ///
									title("Mean New `lab' in `msa_lab'") ///
									note("Data From CoG 4: Gov't Org Directory Surveys") 
					graph export "$FIGS/4_1_general_purpose_govts/`level'/`level'_`msa'_new_`var'.png", as(png) replace
				}
			}
		restore
	}
}

// Animating them

// Need a palatte or else shadows will be messed up
winexec "$FFMPEG" -y -i "${MAPS}/2_county_counts/state/images/state_change_all_local_%d.png"  -vf palettegen "${MAPS}/palette.png"

foreach level in state county cz msa{
	foreach var in all_local_tax gen_subcounty gen_muni gen_town spdist spdist_tax schdist_ind schdist_dep schdist int_muni_else int_schdis_else int_spdist_else int_muni_here int_schdis_here int_spdist_here subcty_tax all_local{
				
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_change_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_change_`var'.gif"
							
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_p_change_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_p_change_`var'.gif"

	}
}


foreach level in state county cz msa{
	foreach var in 1 2 3{
				
		winexec ///
				"$FFMPEG" -y -r 1 -i "${MAPS}/4_1_general_purpose_govts/`level'/images/`level'_new_incorp_date`var'_%d.png" ///
				-i "${MAPS}/palette.png" -lavfi paletteuse  ///
				"${MAPS}/4_1_general_purpose_govts/`level'/animations/`level'_new_incorp_date`var'.gif"
							
			winexec ///
				"$FFMPEG" -y -r 1 -i "${MAPS}/4_1_general_purpose_govts/`level'/images/`level'_new_incorp_date`var'_%d.png" ///
				-i "${MAPS}/palette.png" -lavfi paletteuse  ///
				"${MAPS}/4_1_general_purpose_govts/`level'/animations/`level'_new_incorp_date`var'.gif"
	}
}
