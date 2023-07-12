/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file generates the final dataset used in the analysis.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Create a measure of the causal effect of a county on upward educational mobility in 1940, separately by race and north-south region of origin.
	*2. Merge historical mobility files at the county level and read in crosswalk file.
	*3. Collapse and create measures at the CZ level.
	*4. Merge with contemporary mobility measures and save dataset.
*first created: 09/03/2018
*last updated:  10/25/2019
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

// EVERETT CHANGES: adds 1950 and 1960 census data for educational mobility (in particular frac_all_upm1950 and frac_all_upm1960) also do everyhting by county as well


*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Create a measure of county-level educational upward mobility in 1900, 1910, 1920, 1930, and 1940, separately by race and gender.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	foreach level in cz county msa{
		if "`level'"=="cz"{
			local levelvar cz
		}
		else if "`level'"=="county"{
			local levelvar fips
		}
		else if "`level'"=="msa"{
			local levelvar smsa
		}
		* Start with 1940 data
		use	$mobdata/raw/teen_school_attendance_father_data_all_1940.dta, clear // These are raw IPUMS extracts
		
		* Merge with dataset giving incwage for fathers where available
		merge 1:1 sample serial pernum using "$mobdata/raw/teen_school_attendance_father_inc_lido_data_1940.dta", keepusing(incwage_pop) nogen
		
		* Add all other years
		append using $mobdata/raw/teen_school_attendance_father_data_all_1900.dta
		append using $mobdata/raw/teen_school_attendance_father_data_all_1910.dta
		append using $mobdata/raw/teen_school_attendance_father_data_all_1920.dta
		append using $mobdata/raw/teen_school_attendance_father_data_all_1930.dta
			
		*Create Fips Code
		tostring statefip, g(state_str)
		replace state_str="0"+state_str if length(state_str)==1
		
		replace county=county+20 if statefip==24 & county!=5100 & county>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits in Maryland */
		replace county=270 if county==250 & statefip==32 // "Pershing County, Nevada is assigned FIPS code 270, while historical Ormsby County, Nevada uses FIPS code 250. In the IPUMS samples, Pershing County is instead coded as 0250 and cases from Ormsby County are coded into the Carson City county code of 0510. "
		replace county=610 if county==605 & statefip==41 //Union County Oregon
		replace county=250 if county==510 //Code carson city as part of Ormsby county, Nevada
		tostring county, g(county_str) 
		replace county_str = substr(county_str, 1, length(county_str)-1)
		replace county_str= "0" + county_str if length(county_str)==2
		replace county_str= "00" + county_str if length(county_str)==1
		
		g fips_str=state_str+county_str
		destring(fips_str), g(fips)
		//duplicates list fips //no duplicates 
			
		*Merge with County Crosswalk
		merge m:1 fips using "$data/crosswalks/county1940_crosswalks.dta", keepusing(fips fips_str county_name state_name cz cz_name smsa) keep(1 3) nogen
		//only lose counties in hawaii and alaska 

		* Merge with Saavedra and Twinam (2019) LIDO score. See more and available at: https://www2.oberlin.edu/faculty/msaavedr/lido.html
		
		
		* Merges on the following vars available in all Censuses: region, statefip, sex, age, race, occ1950, and ind1950
		local pop_lido_merge_vars region_pop statefip_pop sex_pop age_pop race_pop occ1950_pop ind1950_pop

		* prep for merging
		
			* didn't request sex variable
				gen sex_pop=1
				replace sex_pop=2 if race_pop==.
			
			* couldn't request region or statefip for parents - assume same as kids ?
		
			rename region region_pop
			rename statefip statefip_pop
			
		preserve
		use $mobdata/raw/lido_score_1950_public_use.dta, clear
		foreach var in region statefip sex age race occ1950 ind1950 lido {
			rename `var' `var'_pop
		}
		tempfile pop_lido
		save `pop_lido', replace
		restore 
			
		merge m:1 `pop_lido_merge_vars' using `pop_lido', keepusing(lido_pop)
		
		* shorten variable names to deal with tempfiles
		rename occscore_pop occs_pop
		rename incwage_pop incw_pop
		
		* Check how egen treats missing - Missing values are excluded from the calculation (https://www.statalist.org/forums/forum/general-stata-discussion/general/1420878-how-does-egen-mean-treat-missing.)
		egen med_lido_pop=median(lido_pop), by(year) // Data available all years
		egen med_incw_pop=median(incw_pop),by(year) // Data only available in 1940
		egen med_occs_pop=median(occs_pop),by(year) // Data available all years
		g attend_school=(school==2)
		replace attend_school=(schlmnth>0 & schlmnth<98) if year==1900 // Need to construct school attendance for 1900 using months of school attended. Assign 0 to those with missing data as havinig attended (values = 98 or 99)
		g teens=1

	foreach cutoff in lido incw occs {
		* All teens
		preserve
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
		
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' enrolled_`cutoff'`yr'
		rename literate`yr' literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 enrolled_`cutoff'1940
		rename literate1940 literate_`cutoff'1940
		}
		 
		tempfile all_tn_schl_1910_40_`cutoff'
		save "`all_tn_schl_1910_40_`cutoff''", replace
		restore
		
		* Black teens
		preserve
		keep if race==2
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
			
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' b_enrolled_`cutoff'`yr'
		rename literate`yr' b_literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 b_enrolled_`cutoff'1940
		rename literate1940 b_literate_`cutoff'1940
		}
		 
		tempfile black_tn_schl_1910_40_`cutoff'
		save "`black_tn_schl_1910_40_`cutoff''", replace
		restore	
		
		* Black (F) teens
		preserve
		keep if race==2
		keep if sex==2
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
			
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' bf_enrolled_`cutoff'`yr'
		rename literate`yr' bf_literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 bf_enrolled_`cutoff'1940
		rename literate1940 bf_literate_`cutoff'1940
		}
		 
		tempfile bf_tn_schl_1910_40_`cutoff'
		save "`bf_tn_schl_1910_40_`cutoff''", replace
		restore	
		
		* Black (M) teens
		preserve
		keep if race==2
		keep if sex==1
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
			
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' bm_enrolled_`cutoff'`yr'
		rename literate`yr' bm_literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 bm_enrolled_`cutoff'1940
		rename literate1940 bm_literate_`cutoff'1940
		}
		 
		tempfile bm_tn_schl_1910_40_`cutoff'
		save "`bm_tn_schl_1910_40_`cutoff''", replace
		restore	
			
		* White teens
		preserve
		keep if race==1
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
			
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' w_enrolled_`cutoff'`yr'
		rename literate`yr' w_literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 w_enrolled_`cutoff'1940
		rename literate1940 w_literate_`cutoff'1940
		}
		 
		tempfile white_tn_schl_1910_40_`cutoff'
		save "`white_tn_schl_1910_40_`cutoff''", replace
		restore	
		
		
		* White (F) teens
		preserve
		keep if race==1
		keep if sex==2
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
			
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' wf_enrolled_`cutoff'`yr'
		rename literate`yr' wf_literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 wf_enrolled_`cutoff'1940
		rename literate1940 wf_literate_`cutoff'1940
		}
		 
		tempfile wf_tn_schl_1910_40_`cutoff'
		save "`wf_tn_schl_1910_40_`cutoff''", replace
		restore	
		
		
		* White (M) teens
		preserve
		keep if race==1
		keep if sex==1
		keep if `cutoff'_pop<med_`cutoff'_pop	
		collapse (sum) attend_school lit teens [fweight=perwt], by(`levelvar' year)	
		g enrolled=100*attend_school/teens
		g literate = 100*lit/teens
		drop attend_school lit teens
		reshape wide enrolled literate, i(`levelvar') j(year)	
			
		if "`cutoff'"!="incw" {
		forval yr=1900(10)1940 {
		rename enrolled`yr' wm_enrolled_`cutoff'`yr'
		rename literate`yr' wm_literate_`cutoff'`yr'
		}
		}
		
		if "`cutoff'"=="incw" {
		rename enrolled1940 wm_enrolled_`cutoff'1940
		rename literate1940 wm_literate_`cutoff'1940
		}
		 
		tempfile wm_tn_schl_1910_40_`cutoff'
		save "`wm_tn_schl_1910_40_`cutoff''", replace
		restore	

		}
			
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*1. Create a measure of county-level educational upward mobility in 1940, 1950, 1960, separately by race and gender.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		use "$mobdata/raw/usa_00097.dta", clear
		foreach type in "head" "mom" "pop"{
			replace educd_`type'=. if educd_`type'==999
		}
		g par_educd=max(educd_head, educd_mom, educd_pop)
		
		keep if (sex==1 & age>=14 & age<=18) | (sex==2 & age>=14 & age<=16)
		keep if par_educd<=26 & par_educd>=22
		drop if educd==999
		
		g all_n=1
		g black_n=(race==2)
		g white_n=(race==1)
		g blackm_n=(race==2 & sex==1)
		g blackf_n=(race==2 & sex==2)
		g whitem_n=(race==1 & sex==1)
		g whitef_n=(race==1 & sex==2)
		
		g all_upm=(educd>=30)
		foreach cat in "black" "white" "blackm" "blackf" "whitem" "whitef"{
		g `cat'_upm=(`cat'_n==1 & educd>=30)
		}
		collapse (sum) *_n *_upm, by(stateicp county)

		/* Merge in crosswalk file */
		cd "$data/crosswalks"
		merge 1:1 stateicp countyicp using county1940_crosswalks.dta
		drop if _merge==1 // Drops a county in Hawaii
		drop _merge
		
		/* Create county-level 1940 upward mobility data */
		preserve
		foreach r in "black" "white"{
		foreach g in "" "m" "f"{
		g frac_`r'`g'_upm1940=`r'`g'_upm/`r'`g'_n
		replace frac_`r'`g'_upm1940=frac_`r'`g'_upm1940*100
		}
		}
		
		g frac_all_upm1940=all_upm/all_n
		replace frac_all_upm1940=frac_all_upm1940*100
		
		save $mobdata/clean_county_edu_upm_1940.dta, replace
		restore
		
		keep black_upm black_n blackm_upm blackm_n blackf_upm blackf_n white_upm white_n whitem_upm whitem_n whitef_upm whitef_n all_upm all_n `levelvar'
		g year = 1940
		
		tempfile mob1940
		save `mob1940'
		
		use "$data/new_data/usa_00021.dta", clear
		
		replace educd = . if educd==999
		bysort serial year: gen educd_mom=educd[momloc]
		bysort serial year: gen educd_pop=educd[poploc]
		g par_educd=max(educd_mom, educd_pop)

		keep if (sex==1 & age>=14 & age<=18) | (sex==2 & age>=14 & age<=16)
		keep if par_educd<=26 & par_educd>=22
		drop if educd==999
		
		g all_n=perwt
		g black_n= perwt if (race==2)
		g white_n=perwt if (race==1)
		g blackm_n=perwt if (race==2 & sex==1)
		g blackf_n=perwt if (race==2 & sex==2)
		g whitem_n=perwt if (race==1 & sex==1)
		g whitef_n=perwt if (race==1 & sex==2)
		
		g all_upm=(educd>=30)
		foreach cat in "black" "white" "blackm" "blackf" "whitem" "whitef"{
		g `cat'_upm=perwt if (`cat'_n==perwt & educd>=30)
		}
		collapse (sum) *_n *_upm, by(stateicp county year)

		/* Merge in crosswalk file */
		cd "$data/crosswalks"
		merge m:1 stateicp countyicp using county1940_crosswalks.dta
		drop if _merge==1 | _merge==2 // Drops a county in Hawaii
		drop _merge
		
		keep black_upm black_n blackm_upm blackm_n blackf_upm blackf_n white_upm white_n whitem_upm whitem_n whitef_upm whitef_n all_upm all_n `levelvar' year

		append using `mob1940'
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*3. Collapse and create measures at the CZ level.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		
		collapse (sum) black_upm black_n blackm_upm blackm_n blackf_upm blackf_n white_upm white_n whitem_upm whitem_n whitef_upm whitef_n all_upm all_n, by(`levelvar' year)
		foreach r in "black" "white"{
		foreach g in "" "m" "f"{
		g frac_`r'`g'_upm=`r'`g'_upm/`r'`g'_n
		replace frac_`r'`g'_upm=frac_`r'`g'_upm*100
		}
		}
		
		g frac_all_upm=all_upm/all_n
		replace frac_all_upm=frac_all_upm*100
		
		keep frac* `levelvar' *_n year

		reshape wide  black_n  blackm_n  blackf_n  white_n  whitem_n  whitef_n  all_n frac*, i(`levelvar') j(year)
		
		drop *_n1950 *_n1960
		ren *_n1940 *_n
		
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*4. Merge with pre-1940 and contemporary mobility measures and save dataset.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		
		
		global histmobdata ///
		"`all_tn_schl_1910_40_lido'" "`black_tn_schl_1910_40_lido'" "`bf_tn_schl_1910_40_lido'" "`bm_tn_schl_1910_40_lido'" ///
		"`white_tn_schl_1910_40_lido'" "`wf_tn_schl_1910_40_lido'" "`wm_tn_schl_1910_40_lido'" ///
		"`all_tn_schl_1910_40_incw'" "`black_tn_schl_1910_40_incw'" "`bf_tn_schl_1910_40_incw'" "`bm_tn_schl_1910_40_incw'" ///
		"`white_tn_schl_1910_40_incw'" "`wf_tn_schl_1910_40_incw'" "`wm_tn_schl_1910_40_incw'" ///
		"`all_tn_schl_1910_40_occs'" "`black_tn_schl_1910_40_occs'" "`bf_tn_schl_1910_40_occs'" "`bm_tn_schl_1910_40_occs'" ///
		"`white_tn_schl_1910_40_occs'" "`wf_tn_schl_1910_40_occs'" "`wm_tn_schl_1910_40_occs'"
		
		foreach dataset in "$histmobdata"{
		merge 1:1 `levelvar' using `dataset'
		drop _merge
		}	
				
		foreach dataset in "$histmobdata"{
		merge 1:1 `levelvar' using `dataset'
		drop _merge
		}
		
		cd "$mobdata/raw"
		
		preserve
		* Merge in urban and non-urban population info by census tract
		insheet using $population/raw/nhgis0068_csv/nhgis0068_ds172_2010_tract.csv, clear
		rename tracta tract
		drop state county
		rename statea state
		rename countya county
		tempfile urban_rural
		save `urban_rural', replace	
		
		use $mobdata/raw/tract_outcomes_early_dta.dta, clear	
		merge 1:1 state county tract using `urban_rural'
		
		l state county tract czname if _merge==1
		
			* drop small black and white populations among non-matches
		
			drop if _merge==1 & kfr_white_pooled_n==. & kfr_black_pooled_n==. & kfr_pooled_pooled_n==.
			tab _merge
			
			* This leaves just 9 tracts the max pop of which is 699. We drop these.
			
			keep if _merge==3
			
		g urban =(h7w001==h7w003) // Full tract pop falls into an urban areas
		
		g rural = (h7w001==h7w005)
		
		g suburban = (h7w004!=0)

		drop *_se // Drop standard errors of estimated income rank
		
		foreach r in "black" "white" "pooled"{
		rename kfr_`r'_pooled_p* kfr_`r'_pooled_p*_ct 
		rename kfr_`r'_pooled_n kfr_`r'_pooled_n_ct
		}
		drop *p1_ct *p100_ct
		g fips = state*1000 + county
		if "`level'"=="msa"{
				merge m:1 fips using $xwalks/county1940_crosswalks.dta, keepusing(smsa) keep(1 3) nogen
		}

		keep 	`levelvar' *_ct urban suburban rural
		
		* Construct census tract race gap (weighted and unweighted)
		/*	1. Average census tract race gap, unweighted (e.g., census tracts are not weighted by population).
			2. Weight the census tract gap with the population of the census tract and create the weighted 
				 average at the CZ level. This will allow large census tracts to contribute more to the CZ-level 
				 average census tract gap */

		foreach p in "25" "50" "75"{
			g racegap2015_p`p'_ct=kfr_white_pooled_p`p'_ct*100-kfr_black_pooled_p`p'_ct*100
			g wt_racegap2015_p`p'_ct = racegap2015_p`p'_ct * (kfr_black_pooled_n_ct + kfr_white_pooled_n_ct)
			g wt_kfr_pooled_pooled_u_p`p'_ct = kfr_pooled_pooled_p`p'_ct*kfr_pooled_pooled_n_ct*urban
			g wt_kfr_pooled_pooled_nu_p`p'_ct = kfr_pooled_pooled_p`p'_ct*kfr_pooled_pooled_n_ct*(1-urban)
		}	
		
		g kfr_pooled_pooled_u_n_ct=kfr_pooled_pooled_n_ct * urban
		g kfr_pooled_pooled_nu_n_ct=kfr_pooled_pooled_n_ct * (1-urban)
		
		collapse (mean) racegap2015_p25_ct racegap2015_p50_ct racegap2015_p75_ct ///
		(sum) wt_racegap2015_p25_ct wt_racegap2015_p50_ct wt_racegap2015_p75_ct  wt_kfr_pooled_pooled_u_p*_ct wt_kfr_pooled_pooled_nu_p*_ct kfr_black_pooled_n_ct kfr_white_pooled_n_ct kfr_pooled_pooled_n_ct kfr_pooled_pooled_u_n_ct kfr_pooled_pooled_nu_n_ct, by(`levelvar')		
		
		foreach p in "25" "50" "75"{
		replace wt_racegap2015_p`p'_ct = wt_racegap2015_p`p'_ct/(kfr_black_pooled_n_ct + kfr_white_pooled_n_ct)
		replace wt_kfr_pooled_pooled_u_p`p'_ct=wt_kfr_pooled_pooled_u_p`p'_ct/kfr_pooled_pooled_u_n_ct
		replace wt_kfr_pooled_pooled_nu_p`p'_ct=wt_kfr_pooled_pooled_nu_p`p'_ct/kfr_pooled_pooled_nu_n_ct
		}
		
		drop *_n_ct
		
		tempfile census_tract_outcomes
		save `census_tract_outcomes'
		restore
		
		if "`level'"=="cz"{
			local mobility_vars_ch2018b ///
					causal_p*_czkr26* causal_p*_czkr26_f* causal_p*_czkr26_m* ///
					causal_p*_czkir26* causal_p*_czkir26_f* causal_p*_czkir26_m* /// 
					perm_res_p*_kr26* perm_res_p*_kr26_f* perm_res_p*_kr26_m* ///
					perm_res_p*_kir26* perm_res_p*_kir26_f* perm_res_p*_kir26_m* ///
					causal_p*_czc1823* perm_res_p*_c1823* 
			
			merge 1:1 cz using $mobdata/raw/online_table3.dta, keepusing(`mobility_vars_ch2018b') // Chetty and Hendren (2018b) expos and permres CZ measures
			drop _merge
			
			local mobility_vars_chjp2018 ///
			k*r_pooled_pooled_p25* k*r_pooled_pooled_p50* k*r_pooled_pooled_p75* ///
			k*r_pooled_female_p25* k*r_pooled_female_p50* k*r_pooled_female_p75* ///
			k*r_pooled_male_p25* k*r_pooled_male_p50* k*r_pooled_male_p75* ///	
			k*r_black_pooled_p25* k*r_black_female_p25* k*r_black_male_p25* ///
			k*r_black_pooled_p50* k*r_black_female_p50* k*r_black_male_p50* ///
			k*r_black_pooled_p75* k*r_black_female_p75* k*r_black_male_p75* ///
			k*r_white_pooled_p25* k*r_white_female_p25* k*r_white_male_p25* ///
			k*r_white_pooled_p50* k*r_white_female_p50* k*r_white_male_p50* ///
			k*r_white_pooled_p75* k*r_white_female_p75* k*r_white_male_p75* ///
			k*r_black_*_n k*r_white_*_n par_rank_black_pooled_mean ///
			hs_pooled_pooled_p25* hs_pooled_pooled_p50* hs_pooled_pooled_p75* ///
			hs_black_pooled_p25* hs_black_pooled_p50* hs_black_pooled_p75* ///
			hs_white_pooled_p25* hs_white_pooled_p50* hs_white_pooled_p75* ///
			hs_pooled_male_p25* hs_pooled_male_p50* hs_pooled_male_p75* ///
			hs_black_male_p25* hs_black_male_p50* hs_black_male_p75* ///
			hs_white_male_p25* hs_white_male_p50* hs_white_male_p75* ///
			hs_pooled_female_p25* hs_pooled_female_p50* hs_pooled_female_p75* ///
			hs_black_female_p25* hs_black_female_p50* hs_black_female_p75* ///
			hs_white_female_p25* hs_white_female_p50* hs_white_female_p75* ///	
			hs_black_*_n hs_white_*_n hs_pooled_*_n ///
			somecoll_pooled_pooled_p25* somecoll_pooled_pooled_p50* somecoll_pooled_pooled_p75* ///
			somecoll_black_pooled_p25* somecoll_black_pooled_p50* somecoll_black_pooled_p75* ///
			somecoll_white_pooled_p25* somecoll_white_pooled_p50* somecoll_white_pooled_p75* ///
			somecoll_pooled_male_p25* somecoll_pooled_male_p50* somecoll_pooled_male_p75* ///
			somecoll_black_male_p25* somecoll_black_male_p50* somecoll_black_male_p75* ///
			somecoll_white_male_p25* somecoll_white_male_p50* somecoll_white_male_p75* ///
			somecoll_pooled_female_p25* somecoll_pooled_female_p50* somecoll_pooled_female_p75* ///
			somecoll_black_female_p25* somecoll_black_female_p50* somecoll_black_female_p75* ///
			somecoll_white_female_p25* somecoll_white_female_p50* somecoll_white_female_p75* ///	
			somecoll_black_*_n somecoll_white_*_n somecoll_pooled_*_n ///
			comcoll_pooled_pooled_p25* comcoll_pooled_pooled_p50* comcoll_pooled_pooled_p75* ///
			comcoll_black_pooled_p25* comcoll_black_pooled_p50* comcoll_black_pooled_p75* ///
			comcoll_white_pooled_p25* comcoll_white_pooled_p50* comcoll_white_pooled_p75* ///
			comcoll_pooled_male_p25* comcoll_pooled_male_p50* comcoll_pooled_male_p75* ///
			comcoll_black_male_p25* comcoll_black_male_p50* comcoll_black_male_p75* ///
			comcoll_white_male_p25* comcoll_white_male_p50* comcoll_white_male_p75* ///
			comcoll_pooled_female_p25* comcoll_pooled_female_p50* comcoll_pooled_female_p75* ///
			comcoll_black_female_p25* comcoll_black_female_p50* comcoll_black_female_p75* ///
			comcoll_white_female_p25* comcoll_white_female_p50* comcoll_white_female_p75* ///	
			comcoll_black_*_n comcoll_white_*_n comcoll_pooled_*_n ///
			coll_pooled_pooled_p25* coll_pooled_pooled_p50* coll_pooled_pooled_p75* ///
			coll_black_pooled_p25* coll_black_pooled_p50* coll_black_pooled_p75* ///
			coll_white_pooled_p25* coll_white_pooled_p50* coll_white_pooled_p75* ///
			coll_pooled_male_p25* coll_pooled_male_p50* coll_pooled_male_p75* ///
			coll_black_male_p25* coll_black_male_p50* coll_black_male_p75* ///
			coll_white_male_p25* coll_white_male_p50* coll_white_male_p75* ///
			coll_pooled_female_p25* coll_pooled_female_p50* coll_pooled_female_p75* ///
			coll_black_female_p25* coll_black_female_p50* coll_black_female_p75* ///
			coll_white_female_p25* coll_white_female_p50* coll_white_female_p75* ///	
			coll_black_*_n coll_white_*_n coll_pooled_*_n ///
			has_dad_pooled_pooled_p25* has_dad_pooled_pooled_p50* has_dad_pooled_pooled_p75* ///
			has_dad_black_pooled_p25* has_dad_black_pooled_p50* has_dad_black_pooled_p75* ///
			has_dad_white_pooled_p25* has_dad_white_pooled_p50* has_dad_white_pooled_p75* ///
			has_dad_pooled_male_p25* has_dad_pooled_male_p50* has_dad_pooled_male_p75* ///
			has_dad_black_male_p25* has_dad_black_male_p50* has_dad_black_male_p75* ///
			has_dad_white_male_p25* has_dad_white_male_p50* has_dad_white_male_p75* ///
			has_dad_pooled_female_p25* has_dad_pooled_female_p50* has_dad_pooled_female_p75* ///
			has_dad_black_female_p25* has_dad_black_female_p50* has_dad_black_female_p75* ///
			has_dad_white_female_p25* has_dad_white_female_p50* has_dad_white_female_p75* ///
			has_dad_black_*_n has_dad_white_*_n has_dad_pooled_*_n ///	
			jail_pooled_pooled_p25* jail_pooled_pooled_p50* jail_pooled_pooled_p75* ///
			jail_black_pooled_p25* jail_black_pooled_p50* jail_black_pooled_p75* ///
			jail_white_pooled_p25* jail_white_pooled_p50* jail_white_pooled_p75* ///
			jail_pooled_male_p25* jail_pooled_male_p50* jail_pooled_male_p75* ///
			jail_black_male_p25* jail_black_male_p50* jail_black_male_p75* ///
			jail_white_male_p25* jail_white_male_p50* jail_white_male_p75* ///	
			jail_pooled_female_p25* jail_pooled_female_p50* jail_pooled_female_p75* ///
			jail_black_female_p25* jail_black_female_p50* jail_black_female_p75* ///
			jail_white_female_p25* jail_white_female_p50* jail_white_female_p75* ///
			jail_black_*_n jail_white_*_n jail_pooled_*_n ///		
			pos_hours_pooled_pooled_p25* pos_hours_pooled_pooled_p50* pos_hours_pooled_pooled_p75* ///
			pos_hours_black_pooled_p25* pos_hours_black_pooled_p50* pos_hours_black_pooled_p75* ///
			pos_hours_white_pooled_p25* pos_hours_white_pooled_p50* pos_hours_white_pooled_p75* ///
			pos_hours_pooled_male_p25* pos_hours_pooled_male_p50* pos_hours_pooled_male_p75* ///
			pos_hours_black_male_p25* pos_hours_black_male_p50* pos_hours_black_male_p75* ///
			pos_hours_white_male_p25* pos_hours_white_male_p50* pos_hours_white_male_p75* ///	
			pos_hours_pooled_female_p25* pos_hours_pooled_female_p50* pos_hours_pooled_female_p75* ///
			pos_hours_black_female_p25* pos_hours_black_female_p50* pos_hours_black_female_p75* ///
			pos_hours_white_female_p25* pos_hours_white_female_p50* pos_hours_white_female_p75* ///
			pos_hours_black_*_n pos_hours_white_*_n pos_hours_pooled_*_n ///
			hours_wk_pooled_pooled_p25* hours_wk_pooled_pooled_p50* hours_wk_pooled_pooled_p75* ///
			hours_wk_black_pooled_p25* hours_wk_black_pooled_p50* hours_wk_black_pooled_p75* ///
			hours_wk_white_pooled_p25* hours_wk_white_pooled_p50* hours_wk_white_pooled_p75* ///
			hours_wk_pooled_male_p25* hours_wk_pooled_male_p50* hours_wk_pooled_male_p75* ///
			hours_wk_black_male_p25* hours_wk_black_male_p50* hours_wk_black_male_p75* ///
			hours_wk_white_male_p25* hours_wk_white_male_p50* hours_wk_white_male_p75* ///	
			hours_wk_pooled_female_p25* hours_wk_pooled_female_p50* hours_wk_pooled_female_p75* ///
			hours_wk_black_female_p25* hours_wk_black_female_p50* hours_wk_black_female_p75* ///
			hours_wk_white_female_p25* hours_wk_white_female_p50* hours_wk_white_female_p75* ///
			hours_wk_black_*_n hours_wk_white_*_n hours_wk_pooled_*_n ///
			married_pooled_pooled_p25* married_pooled_pooled_p50* married_pooled_pooled_p75* ///
			married_black_pooled_p25* married_black_pooled_p50* married_black_pooled_p75* ///
			married_white_pooled_p25* married_white_pooled_p50* married_white_pooled_p75* ///
			married_pooled_male_p25* married_pooled_male_p50* married_pooled_male_p75* ///
			married_black_male_p25* married_black_male_p50* married_black_male_p75* ///
			married_white_male_p25* married_white_male_p50* married_white_male_p75* ///	
			married_pooled_female_p25* married_pooled_female_p50* married_pooled_female_p75* ///
			married_black_female_p25* married_black_female_p50* married_black_female_p75* ///
			married_white_female_p25* married_white_female_p50* married_white_female_p75* ///
			married_black_*_n married_white_*_n married_pooled_*_n ///
			marr_32_pooled_pooled_p25* marr_32_pooled_pooled_p50* marr_32_pooled_pooled_p75* ///
			marr_32_black_pooled_p25* marr_32_black_pooled_p50* marr_32_black_pooled_p75* ///
			marr_32_white_pooled_p25* marr_32_white_pooled_p50* marr_32_white_pooled_p75* ///
			marr_32_pooled_male_p25* marr_32_pooled_male_p50* marr_32_pooled_male_p75* ///
			marr_32_black_male_p25* marr_32_black_male_p50* marr_32_black_male_p75* ///
			marr_32_white_male_p25* marr_32_white_male_p50* marr_32_white_male_p75* ///	
			marr_32_pooled_female_p25* marr_32_pooled_female_p50* marr_32_pooled_female_p75* ///
			marr_32_black_female_p25* marr_32_black_female_p50* marr_32_black_female_p75* ///
			marr_32_white_female_p25* marr_32_white_female_p50* marr_32_white_female_p75* ///
			marr_32_black_*_n marr_32_white_*_n marr_32_pooled_*_n ///
			teenbrth_pooled_female_p25* teenbrth_pooled_female_p50* teenbrth_pooled_female_p75* ///
			teenbrth_black_female_p25* teenbrth_black_female_p50* teenbrth_black_female_p75* ///
			teenbrth_white_female_p25* teenbrth_white_female_p50* teenbrth_white_female_p75* ///
			teenbrth_black_*_n teenbrth_white_*_n teenbrth_pooled_*_n ///
			working_pooled_pooled_p25* working_pooled_pooled_p50* working_pooled_pooled_p75* ///
			working_black_pooled_p25* working_black_pooled_p50* working_black_pooled_p75* ///
			working_white_pooled_p25* working_white_pooled_p50* working_white_pooled_p75* ///
			working_pooled_male_p25* working_pooled_male_p50* working_pooled_male_p75* ///
			working_black_male_p25* working_black_male_p50* working_black_male_p75* ///
			working_white_male_p25* working_white_male_p50* working_white_male_p75* ///	
			working_pooled_female_p25* working_pooled_female_p50* working_pooled_female_p75* ///
			working_black_female_p25* working_black_female_p50* working_black_female_p75* ///
			working_white_female_p25* working_white_female_p50* working_white_female_p75* ///
			working_black_*_n working_white_*_n working_pooled_*_n ///
			work_32_pooled_pooled_p25* work_32_pooled_pooled_p50* work_32_pooled_pooled_p75* ///
			work_32_black_pooled_p25* work_32_black_pooled_p50* work_32_black_pooled_p75* ///
			work_32_white_pooled_p25* work_32_white_pooled_p50* work_32_white_pooled_p75* ///
			work_32_pooled_male_p25* work_32_pooled_male_p50* work_32_pooled_male_p75* ///
			work_32_black_male_p25* work_32_black_male_p50* work_32_black_male_p75* ///
			work_32_white_male_p25* work_32_white_male_p50* work_32_white_male_p75* ///	
			work_32_pooled_female_p25* work_32_pooled_female_p50* work_32_pooled_female_p75* ///
			work_32_black_female_p25* work_32_black_female_p50* work_32_black_female_p75* ///
			work_32_white_female_p25* work_32_white_female_p50* work_32_white_female_p75* ///	
			work_32_black_*_n work_32_white_*_n work_32_pooled_*_n ///
			proginc_pooled_pooled_p25* proginc_pooled_pooled_p50* proginc_pooled_pooled_p75* ///
			proginc_black_pooled_p25* proginc_black_pooled_p50* proginc_black_pooled_p75* ///
			proginc_white_pooled_p25* proginc_white_pooled_p50* proginc_white_pooled_p75* ///
			proginc_pooled_male_p25* proginc_pooled_male_p50* proginc_pooled_male_p75* ///
			proginc_black_male_p25* proginc_black_male_p50* proginc_black_male_p75* ///
			proginc_white_male_p25* proginc_white_male_p50* proginc_white_male_p75* ///	
			proginc_pooled_female_p25* proginc_pooled_female_p50* proginc_pooled_female_p75* ///
			proginc_black_female_p25* proginc_black_female_p50* proginc_black_female_p75* ///
			proginc_white_female_p25* proginc_white_female_p50* proginc_white_female_p75* ///
			proginc_black_*_n proginc_white_*_n proginc_pooled_*_n ///
			wgflx_rk_pooled_pooled_p25* wgflx_rk_pooled_pooled_p50* wgflx_rk_pooled_pooled_p75* ///
			wgflx_rk_black_pooled_p25* wgflx_rk_black_pooled_p50* wgflx_rk_black_pooled_p75* ///
			wgflx_rk_white_pooled_p25* wgflx_rk_white_pooled_p50* wgflx_rk_white_pooled_p75* ///
			wgflx_rk_pooled_male_p25* wgflx_rk_pooled_male_p50* wgflx_rk_pooled_male_p75* ///
			wgflx_rk_black_male_p25* wgflx_rk_black_male_p50* wgflx_rk_black_male_p75* ///
			wgflx_rk_white_male_p25* wgflx_rk_white_male_p50* wgflx_rk_white_male_p75* ///	
			wgflx_rk_pooled_female_p25* wgflx_rk_pooled_female_p50* wgflx_rk_pooled_female_p75* ///
			wgflx_rk_black_female_p25* wgflx_rk_black_female_p50* wgflx_rk_black_female_p75* ///
			wgflx_rk_white_female_p25* wgflx_rk_white_female_p50* wgflx_rk_white_female_p75* ///
			wgflx_rk_black_*_n wgflx_rk_white_*_n  wgflx_rk_pooled_*_n ///
			kfr_stycz_pooled_pooled_p25* kfr_stycz_pooled_pooled_p50* kfr_stycz_pooled_pooled_p75* ///
			kfr_stycz_black_pooled_p25* kfr_stycz_black_pooled_p50* kfr_stycz_black_pooled_p75* ///
			kfr_stycz_white_pooled_p25* kfr_stycz_white_pooled_p50* kfr_stycz_white_pooled_p75* ///
			kfr_stycz_pooled_male_p25* kfr_stycz_pooled_male_p50* kfr_stycz_pooled_male_p75* ///
			kfr_stycz_black_male_p25* kfr_stycz_black_male_p50* kfr_stycz_black_male_p75* ///
			kfr_stycz_white_male_p25* kfr_stycz_white_male_p50* kfr_stycz_white_male_p75* ///	
			kfr_stycz_pooled_female_p25* kfr_stycz_pooled_female_p50* kfr_stycz_pooled_female_p75* ///
			kfr_stycz_black_female_p25* kfr_stycz_black_female_p50* kfr_stycz_black_female_p75* ///
			kfr_stycz_white_female_p25* kfr_stycz_white_female_p50* kfr_stycz_white_female_p75* ///
			kfr_stycz_black_*_n kfr_stycz_white_*_n kfr_stycz_pooled_*_n ///
			kir_stycz_pooled_pooled_p25* kir_stycz_pooled_pooled_p50* kir_stycz_pooled_pooled_p75* ///
			kir_stycz_black_pooled_p25* kir_stycz_black_pooled_p50* kir_stycz_black_pooled_p75* ///
			kir_stycz_white_pooled_p25* kir_stycz_white_pooled_p50* kir_stycz_white_pooled_p75* ///
			kir_stycz_pooled_male_p25* kir_stycz_pooled_male_p50* kir_stycz_pooled_male_p75* ///
			kir_stycz_black_male_p25* kir_stycz_black_male_p50* kir_stycz_black_male_p75* ///
			kir_stycz_white_male_p25* kir_stycz_white_male_p50* kir_stycz_white_male_p75* ///	
			kir_stycz_pooled_female_p25* kir_stycz_pooled_female_p50* kir_stycz_pooled_female_p75* ///
			kir_stycz_black_female_p25* kir_stycz_black_female_p50* kir_stycz_black_female_p75* ///
			kir_stycz_white_female_p25* kir_stycz_white_female_p50* kir_stycz_white_female_p75* ///	
			kir_stycz_black_*_n kir_stycz_white_*_n kir_stycz_pooled_*_n  ///
			kid_black_*_blw_p50_n kid_white_*_blw_p50_n kid_black_*_n kid_white_*_n 
			
			merge 1:1 cz using $mobdata/raw/cz_outcomes.dta, keepusing(`mobility_vars_chjp2018') // Chetty, Hendren, Jones, and Porter (2018) race mobility measures
			drop _merge
			local mobility_vars kfr_pooled_pooled_p25 kfr_black_pooled_p25 kfr_black_pooled_p50 ///
			kfr_black_pooled_p75 kfr_white_pooled_p25 kfr_white_pooled_p50 kfr_white_pooled_p75  ///
			kir_black_female_p25 kir_black_female_p75 kir_black_male_p25  kir_black_male_p75  ///
			kir_white_female_p25 kir_white_female_p75 kir_white_male_p25 kir_white_male_p75  ///
			kfr_black_male_p25 kfr_black_male_p50 kfr_black_male_p75 kfr_white_male_p25 kfr_white_male_p50 kfr_white_male_p75 ///
			kfr_black_female_p25 kfr_black_female_p50 kfr_black_female_p75 kfr_white_female_p25 kfr_white_female_p50 kfr_white_female_p75
			
			foreach var in `mobility_vars' {
				g  `var'2015 = `var'
				drop `var'
			}
		}
		
		merge 1:1 `levelvar' using `census_tract_outcomes'
		drop _merge

		
		
		drop k*_se  // Drop standard errors of estimated income rank
		save $mobdata/clean_cz_mobility_1900_2015_split_`level'.dta, replace
	}
