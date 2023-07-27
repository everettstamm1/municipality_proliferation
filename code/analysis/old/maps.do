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


foreach level in county state cz msa sample_msas{
	use "$INTDATA/cog/2_county_counts.dta", clear
	drop if fips_state == "02" | fips_state=="15"

	labmask msapmsa2000, values(msapmsa_name)
	if "`level'" == "state"{
		local levelvar = "statefips"
		local leveldb = "state"
		local levellab = "State"
		
		ren year cog_year
		g year = cog_year-2
		ren fips_state statefip
		merge m:1 year statefip using "$INTDATA/census/state_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys statefip (use) : replace use = use[_N]
		drop year
		ren cog_year year
				ren statefip fips_state

	}
	else if "`level'" == "cz"{
		local levelvar = "cz"
		local leveldb = "cz1990"
		local levellab = "CZ"
		
		ren year cog_year
		g year = cog_year-2
		ren czone cz
		merge m:1 year cz using "$INTDATA/census/cz_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys cz (use) : replace use = use[_N]
		drop year
		ren cog_year year
		ren cz czone
	}
	else if "`level'" == "county"{
		local levelvar = "county"
		local leveldb = "county2000"
		local levellab = "County"
		
		ren year cog_year
		g year = cog_year-2
		ren fips_state statefip
		ren fips_county_2002 countyfip
		merge m:1 year statefip countyfip using "$INTDATA/census/county_race_data.dta", keep(1 3)
		//drop if year<1940 | year>2010
		//replace cog_year = year+2 if _merge==2
		g use = 1
		//bys countyfip statefip (use) : replace use = use[_N]
		drop year
		ren cog_year year
		ren statefip fips_state
		ren countyfip fips_county_2002
	}
	else if "`level'" == "msa"{
		local levelvar = "msapmsa2000"
		local leveldb = "msapmsa2000"
		local levellab = "MSA"
		
		ren year cog_year
		tostring msapmsa2000, gen(smsa)
		g year = cog_year-2
		merge m:1 year smsa using "$INTDATA/census/msa_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys smsa (use) : replace use = use[_N]
		drop year smsa
		ren cog_year year
	}
	else if "`level'" == "sample_msas"{
		local levelvar = "msapmsa2000"
		local leveldb = "msapmsa2000"
		local levellab = "MSA"
		
		ren year cog_year
		tostring msapmsa2000, gen(smsa)
		g year = cog_year-2
		
		merge m:1 year smsa using "$INTDATA/census/msa_race_data.dta"
		drop if year<1940 | year>2010

		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys smsa (use) : replace use = use[_N]
		drop year smsa
		ren cog_year year
	}
	
	foreach var of varlist schdist_ind gen_muni all_local  {
		preserve
			local lab: variable label `var'

			destring fips_state, gen(statefips)
			replace fips_state = "" if fips_state=="."
			replace fips_county_2002 = "" if fips_county_2002=="."

			drop if  fips_state=="" | fips_county_2002==""
			g county = fips_state+fips_county_2002
			destring county, replace
			
			rename czone cz
			
			bys `levelvar' year : egen n_`var' = total(`var'), missing
			keep `levelvar' year n_`var' black_share use Pop
			duplicates drop
			
			
			bys `levelvar' (year) : g change_`var' = n_`var' - n_`var'[_n-1]
			bys `levelvar' (year) : g p_change_`var' = 100*(log(n_`var') - log(n_`var'[_n-1]))
			bys `levelvar' (year) : replace p_change_`var' = 0 if n_`var' == 0 | n_`var'[_n-1] == 0
			
			bys `levelvar' (year) : g decade_lab = string(year[_n-1])+"-"+string(year)

			//drop if year==1942 | `levelvar'==. | regexm(decade_lab,"\.") | n_`var'==. | change_`var'==. 
	
			// Bar Graphs
			g change_`var'_pos = change_`var' if change_`var'>0
			g p_change_`var'_pos = p_change_`var' if change_`var'>0
			
			if "`level'"!="sample_msas"{
				g year1 = year-2
				g year2 = year-6.25 if year==1952
				g year3 = year-3.75 if year==1952
				replace year2 = year-3.75 if year>1952
				replace year3 = year-1.25 if year>1952
				
				egen mean = mean(change_`var'), by(year)
				egen mean_pos = mean(change_`var'_pos), by(year)
				egen p_mean = mean(p_change_`var'), by(year)
				egen p_mean_pos = mean(p_change_`var'_pos), by(year)
				egen mean_black_share = mean(black_share), by(year1)
				replace mean_black_share = mean_black_share*100
				
				twoway (bar mean year2 if use==1, barwidth(2.5) sort xaxis(1) yaxis(1) xtitle("CoG Year") ytitle("Mean {&Delta} `lab'") ///
				) || (bar mean_pos year3 if use==1, barwidth(2.5) sort xaxis(1) yaxis(1)) || (connected mean_black_share year1 if use==1, ///
				sort xaxis(2) xlabel(1940(10)2010) xtitle("Census Year", axis(2)) yaxis(2) ytitle("`levellab' Pct Share Black", axis(2)) yline(0, lp(dash))) ///
				|| , xlabel(1940 "" 1947 "1942-1952" 1954.5 "1952-1957" 1959.5 "1957-1962" 1964.5 "1962-1967" 1969.5 "1967-1972" 1974.5 "1972-1977" ///
				1979.5 "1977-1982" 1984.5 "1982-1987" 1989.5 "1987-1992" 1994.5 "1992-1997" 1999.5 "1997-2002" 2004.5 "2002-2007" 2009.5 "2007-2012"  ///
				, angle(45) axis(1)) xlabel(1940(10)2010, axis(2)) legend(cols(1) order(1 "Mean {&Delta} `lab'" 2 "Mean {&Delta} `lab', Positive Values Only" 3 "Mean Black Population Share")) title("Mean {&Delta} `lab', `levellab' Level")
				
				graph export "$FIGS/2_county_counts/`level'/`level'_change_`var'.png", as(png) replace

				
				twoway (bar p_mean year2 if use==1, barwidth(2.5) sort xaxis(1) yaxis(1) xtitle("CoG Year") ytitle("Mean {&Delta} `lab'") ///
				) || (bar p_mean_pos year3 if use==1, barwidth(2.5) sort xaxis(1) yaxis(1)) || (connected mean_black_share year1 if use==1, ///
				sort xaxis(2) xlabel(1940(10)2010) xtitle("Census Year", axis(2)) yaxis(2) ytitle("`levellab' Pct Share Black", axis(2)) yline(0, lp(dash))) ///
				|| , xlabel(1940 "" 1947 "1942-1952" 1954.5 "1952-1957" 1959.5 "1957-1962" 1964.5 "1962-1967" 1969.5 "1967-1972" 1974.5 "1972-1977" ///
				1979.5 "1977-1982" 1984.5 "1982-1987" 1989.5 "1987-1992" 1994.5 "1992-1997" 1999.5 "1997-2002" 2004.5 "2002-2007" 2009.5 "2007-2012"  ///
				, angle(45) axis(1)) xlabel(1940(10)2010, axis(2)) legend(cols(1) order(1 "Mean %{&Delta} `lab'" 2 "Mean %{&Delta} `lab', Positive Values Only" 3 "Mean Black Population Share")) title("Mean %{&Delta} `lab', `levellab' Level")
				
				graph export "$FIGS/2_county_counts/`level'/`level'_p_change_`var'.png", as(png) replace
					
				drop *_pos *mean* year? black_share
				
				drop if year<=1942 | `levelvar'==. | regexm(decade_lab,"\.") | n_`var'==. | change_`var'==. 

				// get all decade and year labels
				levelsof decade_lab, local(decades)
				levelsof year, local(years)
				// Get second year for base legend or first if only one year (first year really negative skewed so it doesn't make very good graphs)
				qui su year,d
				if `r(min)'!=`r(max)'{
					qui su year if year>`r(min)'
				}
				local base = `r(min)'
				
				g change_`var'_pc = 1000*(change_`var'/Pop)
				g n_`var'_pc = 1000*(n_`var'/Pop)
				drop Pop
				reshape wide decade_lab p_change_`var' change_`var' change_`var'_pc n_`var' n_`var'_pc, i(`levelvar') j(year)
				
				pctile breaks = change_`var'`base', n(9)
				pctile breaks_p = p_change_`var'`base', n(9)
				pctile breaks_pc = change_`var'_pc`base', n(9)
				pctile breaks_n = n_`var'`base', n(9)
				pctile breaks_n_pc = n_`var'_pc`base', n(9)
				
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
					
					
					qui unique breaks_pc
					local keys = `r(unique)'+1
					numlist  "`keys'[-1]1", descending
					maptile change_`var'_pc`y', ///
									geo(`leveldb') `geoid' cutp(breaks_pc) legd(0) ///
									twopt(title("`levellab' Change in `lab' Per Capita (1000), `decade_lab'") ///
									legend(title("Change") position(6) cols(5) ring(5) order(`r(numlist)' "No Data")) ///
									note("Data From CoG 2: County Gov't Counts")) `conus'
					graph export "$MAPS/2_county_counts/`level'/images/`level'_change_pc_`var'_`i'.png", as(png) replace
					
					qui unique breaks_n
					local keys = `r(unique)'+1
					numlist  "`keys'[-1]1", descending
					maptile n_`var'`y', ///
									geo(`leveldb') `geoid' cutp(breaks_n) legd(0) ///
									twopt(title("`levellab' Number of `lab', `y'") ///
									legend(title("Change") position(6) cols(5) ring(5) order(`r(numlist)' "No Data")) ///
									note("Data From CoG 2: County Gov't Counts")) `conus'
					graph export "$MAPS/2_county_counts/`level'/images/`level'_n_`var'_`i'.png", as(png) replace

					
					qui unique breaks_n_pc
					local keys = `r(unique)'+1
					numlist  "`keys'[-1]1", descending
					maptile n_`var'_pc`y', ///
									geo(`leveldb') `geoid' cutp(breaks_n_pc) legd(0) ///
									twopt(title("`levellab' Number of `lab' (Per Capita), `y'") ///
									legend(title("Change") position(6) cols(5) ring(5) order(`r(numlist)' "No Data")) ///
									note("Data From CoG 2: County Gov't Counts")) `conus'
					graph export "$MAPS/2_county_counts/`level'/images/`level'_n_pc_`var'_`i'.png", as(png) replace
					local i=`i'+1

				}
			}
			else if "`level'"=="sample_msas"{
				keep if msapmsa2000 == 1600 | /// Chicago
								msapmsa2000 == 1680 | /// Cleveland-Lorain-Elyria
								msapmsa2000 == 2160 | /// Detroit
								msapmsa2000 == 3280 | /// Hartford
								msapmsa2000 == 4480 | /// Los Angeles-Long Beach
								msapmsa2000 == 7360 | /// San Francisco
								msapmsa2000 == 8240 | /// Now the white ones Tallahasse 
								msapmsa2000 == 1440 | /// Charleston 
								msapmsa2000 == 6520 | /// Provo-Orem
								msapmsa2000 == 6480 | /// Providence 
								msapmsa2000 == 7080 | /// Salem 
								msapmsa2000 == 2400 | /// Eugene Springfield
								msapmsa2000 == 7160 | /// SLC
								msapmsa2000 == 7500 | /// Santa Rosa
								msapmsa2000 == 6440 | /// Portland Vancouver
								msapmsa2000 == 7600 // Seattle
				
				levelsof msapmsa2000, local(msas)
				local lbe : value label msapmsa2000
				
				g year1 = year-2
				g year2 = year-5 if year==1952
				replace year2 = year-2.5 if year>1952
				
				egen mean = mean(change_`var'), by(year msapmsa2000)
				egen mean_pos = mean(change_`var'_pos), by(year msapmsa2000)
				egen p_mean = mean(change_`var'), by(year msapmsa2000)
				egen p_mean_pos = mean(change_`var'_pos), by(year msapmsa2000)
				egen mean_black_share = mean(black_share), by(year1 msapmsa2000)
				replace mean_black_share = mean_black_share*100
				
				
					
				foreach msa in `msas'{
					local msa_lab : label `lbe' `msa'
					
					// harmonizing y axes
					qui su mean if msapmsa2000 == `msa'
					local min1 = `r(min)'
					local max1 = `r(max)'
					qui su mean_black_share if msapmsa2000 == `msa'
					local min2 = `r(min)'
					local max2 = `r(max)'

					local min = round(cond(`min1'<`min2',`min1',`min2') - 2.5,5)
					local max = round(cond(`max1'>`max2',`max1',`max2') + 2.5,5)

					local step = (`max' - `min')/5
					
					twoway (bar mean year2 if msapmsa2000 == `msa', barwidth(5) sort xaxis(1) yaxis(1) ytick(`min'(`step')`max') yla(`min'(`step')`max')  xtitle("CoG Year") ytitle("")  ///
					) || (connected mean_black_share year1 if msapmsa2000 == `msa', ///
					sort xaxis(2) xlabel(1940(10)2010) xtitle("Census Year", axis(2)) yaxis(2) ytitle("")  yscale(off range(`min'(`step')`max') axis(2))  yline(0, lp(dash))) ///
					|| , xlabel(1947 "1942-1952" 1954.5 "1952-1957" 1959.5 "1957-1962" 1964.5 "1962-1967" 1969.5 "1967-1972" 1974.5 "1972-1977" ///
					1979.5 "1977-1982" 1984.5 "1982-1987" 1989.5 "1987-1992" 1994.5 "1992-1997" 1999.5 "1997-2002" 2004.5 "2002-2007" 2009.5 "2007-2012"  ///
					, axis(1) angle(45))  xlabel(1940(10)2010, axis(2)) legend(cols(1) order(1 "Mean New `lab'" 2 "Mean Black Population Share")) ///
					note("Data From CoG 2: County Gov't Counts") 	title("Mean {&Delta} `lab'" "in `msa_lab'") 
			
	
	
					graph export "$FIGS/2_county_counts/`level'/`level'_`msa'_change_`var'.png", as(png) replace

					su p_mean
					local min1 = `r(min)'
					local max1 = `r(max)'
					su mean_black_share
					local min2 = `r(min)'
					local max2 = `r(max)'
					
					local min = round(cond(`min1'<`min2',`min1',`min2') - 2.5,5)
					local max = round(cond(`max1'>`max2',`max1',`max2') + 2.5,5)
					
					local step = (`max' - `min')/5
					
					twoway (bar p_mean year2 if use==1 & msapmsa2000 == `msa', barwidth(5) sort xaxis(1) yaxis(1) ytick(`min'(`step')`max') yla(`min'(`step')`max') xtitle("CoG Year") ytitle("") ///
					) || (connected mean_black_share year1 if use==1 & msapmsa2000 == `msa',  ///
					sort xaxis(2) xlabel(1940(10)2010) xtitle("Census Year", axis(2)) yaxis(2) yscale(off range(`min'(`step')`max') axis(2)) ytitle("") yline(0, lp(dash))) ///
					|| , xlabel(1940 "" 1947 "1942-1952" 1954.5 "1952-1957" 1959.5 "1957-1962" 1964.5 "1962-1967" 1969.5 "1967-1972" 1974.5 "1972-1977" ///
					1979.5 "1977-1982" 1984.5 "1982-1987" 1989.5 "1987-1992" 1994.5 "1992-1997" 1999.5 "1997-2002" 2004.5 "2002-2007" 2009.5 "2007-2012"  ///
					, angle(45) axis(1))  xlabel(1940(10)2010, axis(2)) legend(cols(1) order(1 "Mean New `lab'" 2 "Mean Black Population Share")) ///
					note("Data From CoG 2: County Gov't Counts") 	title("Mean %{&Delta} `lab'" "in `msa_lab'") 

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

/* NOT CURRENTLY FUNCTIONAL, DON'T USE
//foreach level in state county cz msa sample_msas {
local level = "msa"
	if "`level'" == "state"{
		local levelvar = "statefips"
		local leveldb = "state"
		local levellab = "State"
		
		ren year cog_year
		g year = cog_year-2
		ren fips_state statefip
		merge m:1 year statefip using "$INTDATA/census/state_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys statefip (use) : replace use = use[_N]
		drop year
		ren cog_year year
				ren statefip fips_state

	}
	else if "`level'" == "cz"{
		local levelvar = "cz"
		local leveldb = "cz1990"
		local levellab = "CZ"
		
		ren year cog_year
		g year = cog_year-2
		ren czone cz
		merge m:1 year cz using "$INTDATA/census/cz_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys cz (use) : replace use = use[_N]
		drop year
		ren cog_year year
		ren cz czone
	}
	else if "`level'" == "county"{
		local levelvar = "county"
		local leveldb = "county2000"
		local levellab = "County"
		
		ren year cog_year
		g year = cog_year-2
		ren fips_state statefip
		ren fips_county_2002 countyfip
		merge m:1 year statefip countyfip using "$INTDATA/census/county_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys countyfip statefip (use) : replace use = use[_N]
		drop year
		ren cog_year year
		ren statefip fips_state
		ren countyfip fips_county_2002
	}
	else if "`level'" == "msa"{
		local levelvar = "msapmsa2000"
		local leveldb = "msapmsa2000"
		local levellab = "MSA"
		
		ren year cog_year
		tostring msapmsa2000, gen(smsa)
		g year = cog_year-2
		merge m:1 year smsa using "$INTDATA/census/msa_race_data.dta"
		drop if year<1940 | year>2010
		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys smsa (use) : replace use = use[_N]
		drop year smsa
		ren cog_year year
	}
	else if "`level'" == "sample_msas"{
		local levelvar = "msapmsa2000"
		local leveldb = "msapmsa2000"
		local levellab = "MSA"
		
		ren year cog_year
		tostring msapmsa2000, gen(smsa)
		g year = cog_year-2
		merge m:1 year smsa using "$INTDATA/census/msa_race_data.dta"
				drop if year<1940 | year>2010

		replace cog_year = year+2 if _merge==2
		g use = _merge==3
		bys smsa (use) : replace use = use[_N]
		drop year smsa
		ren cog_year year
	}
	local var = "incorp_date1"
	//foreach var of varlist  incorp_date*{
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
				g year1 = year-2
				g year2 = year-5 if year==1952
				replace year2 = year-2.5 if year>1952
				
				egen mean = mean(n_`var'), by(year msapmsa2000)
				egen mean_black_share = mean(black_share), by(year1 msapmsa2000)
				replace mean_black_share = mean_black_share*100
				
				
				twoway (bar mean year2 if msapmsa2000 == `msa', barwidth(5) sort xaxis(1) yaxis(1) xtitle("CoG Year") ytitle("Mean New `lab'") ///
					) || (connected mean_black_share year1 if msapmsa2000 == `msa', ///
					sort xaxis(2) xlabel(1940(10)2010) xtitle("Census Year", axis(2)) yaxis(2) ytitle("Mean Black Population Share", axis(2)) yline(0, lp(dash))) ///
					|| , xlabel(1947 "1942-1952" 1954.5 "1952-1957" 1959.5 "1957-1962" 1964.5 "1962-1967" 1969.5 "1967-1972" 1974.5 "1972-1977" ///
					1979.5 "1977-1982" 1984.5 "1982-1987" 1989.5 "1987-1992" 1994.5 "1992-1997" 1999.5 "1997-2002" 2004.5 "2002-2007" 2009.5 "2007-2012"  ///
					, axis(1) angle(45))  xlabel(1940(10)2010, axis(2)) legend(cols(1) order(1 "Mean New `lab'" 2 "Mean Black Population Share")) note("Data From CoG 4: Gov't Org Directory Surveys") 	title("Mean New `lab' in `levellab' Level")

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
*/
// Animating them

// Need a palatte or else shadows will be messed up
winexec "$FFMPEG" -y -i "${MAPS}/2_county_counts/state/images/state_change_all_local_%d.png"  -vf palettegen "${MAPS}/palette.png"

foreach level in county{
	foreach var in all_local_tax gen_subcounty gen_muni gen_town spdist spdist_tax schdist_ind schdist_dep schdist int_muni_else int_schdis_else int_spdist_else int_muni_here int_schdis_here int_spdist_here subcty_tax all_local{
				
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_change_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_change_`var'.gif"
							
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_p_change_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_p_change_`var'.gif"
							
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_change_pc_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_change_pc_`var'.gif"
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_n_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_n_`var'.gif"
			winexec "$FFMPEG" -y -r 1 -i "${MAPS}/2_county_counts/`level'/images/`level'_n_pc_`var'_%d.png" ///
							-i "${MAPS}/palette.png" -lavfi paletteuse  ///
							"${MAPS}/2_county_counts/`level'/animations/`level'_n_pc_`var'.gif"

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
