/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

5. Produce main figures and tables.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*I. Set specs for baseline analysis. 
	*II. Figures.
	*III. Tables.
	*IV. Appendix figures and tables.
	*V. Estimates cited in text.
*first created: 12/31/2019
*last updated: 02/23/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/		
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*I. Set specs for baseline analysis.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	global x_ols GM
	global x_iv GM_hat2	
	global baseline_controls frac_all_upm1940 mfg_lfshare1940  v2_blackmig3539_share1940 reg2 reg3 reg4

	run $code/programs/PrintEst.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*II. Figures.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 1: Black upward mobility in 1940 and 2015
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* (a) Percentage of black teens from median-educated families with 9-plus years of schooling, 1940
	use ${mobdata}/clean_cz_mobility_1900_2015.dta, clear
	replace kfr_black_pooled_p50 = kfr_black_pooled_p50*100
	maptile frac_black_upm1940 if black_n>=10 & kfr_black_pooled_n>=10 & frac_black_upm1940!=. & kfr_black_pooled_p50!=., geo(cz1990) rangecolor(jmpgreen*.15 jmpgreen*1.75) ndfcolor(myslate*1.25) conus 
	cd "$figtab"
	graph export black_edu_mobility_1940_map.png, replace

	* (b) Household income rank of black men and women from below-median-income families, 2015	
	maptile kfr_black_pooled_p50 if black_n>=10 & kfr_black_pooled_n>=10 & frac_black_upm1940!=. & kfr_black_pooled_p50!=., geo(cz1990) rangecolor(jmpgreen*.15 jmpgreen*1.75) ndfcolor(myslate*1.25) conus
	cd "$figtab"
	graph export black_p50_mobility_2015_map.png, replace
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 2: Quantiles of urban black share increases, 1940-1970
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	use ${data}/GM_cz_final_dataset.dta, clear
	gen mylabel=cz_name+"                  " if regexm(cz_name, "Steubenville") | regexm(cz_name, "Milwaukee") ///
	| regexm(cz_name, "Washington") | regexm(cz_name, "Gary") | regexm(cz_name, "Detroit") 
	replace mylabel="Washington, D.C." if regexm(cz_name, "Washington")
	replace mylabel="Detroit, MI" if regexm(cz_name, "Detroit")
	replace mylabel="Gary, IN" if regexm(cz_name, "Gary")
	replace mylabel="Steubenville, OH" if regexm(cz_name, "Steubenville")
	replace mylabel="Milwaukee, WI" if regexm(cz_name, "Milwaukee")
	graph twoway (scatter bpopchange1940_1970 GM if mylabel!="", legend(off) mcolor(jmporange) msymbol(circle_hollow) ///
	msize(vlarge) mlabel(mylabel) mlabcolor(black) mlabposition(11) graphregion(color(white)) plotregion(ilcolor(white)) ///
	ylabel(,nogrid))  || (scatter bpopchange1940_1970 GM, xtitle("Percentile of urban Black pop increase 40-70") ///
	ytitle("Incr. in urban Black pop '40-70 as ppt of 1940 urban pop") legend(off) mcolor(jmpgreen) graphregion(color(white)) plotregion(ilcolor(white))) 
	cd "$figtab"
	graph export bpopchange_percentiles.png, replace
	
	* Point estimates cited in text:
	
		* median
		summ bpopchange1940_1970, d
		local p50_bpopchng4070 = `r(p50)'
		PrintEst `p50_bpopchng4070' "p50_bpopchng4070" "" " percentage points%" "3.1"
	
		xtile pctbpopchange1940_1970 = bpopchange1940_1970, nq(100)
		
		*Pittsburgh
		summ bpopchange1940_1970 if cz_name=="Pittsburgh, PA"
		local pitt_bpopchng4070 = `r(mean)'
		PrintEst `pitt_bpopchng4070' "pitt_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Pittsburgh, PA"
		local pitt_pctbpopchng4070 = `r(mean)'
		PrintEst `pitt_pctbpopchng4070' "pitt_pctbpopchng4070" "" "rd percentile%" "2.0"
		
		*Detroit
		summ bpopchange1940_1970 if cz_name=="Detroit, MI"
		local detr_bpopchng4070 = `r(mean)'
		PrintEst `detr_bpopchng4070' "detr_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Detroit, MI"
		local detr_pctbpopchng4070 = `r(mean)'
		PrintEst `detr_pctbpopchng4070' "detr_pctbpopchng4070" "" "th percentile%" "2.0"
		
		*Salt Lake City
		summ bpopchange1940_1970 if cz_name=="Salt Lake City, UT"
		local slc_bpopchng4070 = `r(mean)'
		PrintEst `slc_bpopchng4070' "slc_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Salt Lake City, UT"
		local slc_pctbpopchng4070 = `r(mean)'
		PrintEst `slc_pctbpopchng4070' "slc_pctbpopchng4070" "" "th percentile%" "2.0"
		
		*Washington, DC
		summ bpopchange1940_1970 if cz_name=="Washington DC, DC"
		local wadc_bpopchng4070 = `r(mean)'
		PrintEst `wadc_bpopchng4070' "wadc_bpopchng4070" "" " percentage points%" "3.1"

		summ pctbpopchange1940_1970 if cz_name=="Washington DC, DC"
		local wadc_pctbpopchng4070 = `r(mean)'
		PrintEst `wadc_pctbpopchng4070' "wadc_pctbpopchng4070" "" "th percentile%" "2.0"
		
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 3: Relationship between 1940-1970 Black population change and upward mobility in 2012
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	local x_ols GM 
	local x_iv GM_hat2
	local y perm_res_p25_kr26
	qui: reg `y' `x_ols' 
	local coeff : di %4.3f _b[`x_ols']
	local coeff_se : di %4.3f _se[`x_ols']
	binscatter `y' `x_ols',  ///
	reportreg lcolor(myslate*1.5) ylabel(,nogrid) mcolor(jmpgreen) xtitle("Percentile of Black pop change 40-70") ///
	ytitle("Avg. Adult HH Inc. Rank in 2012, Parents 25p") caption("Slope = `coeff' (`coeff_se')", ring(0) pos(8))
	PrintEst `coeff' "permres_GM_nocontrols" "" " percentiles" "4.2"
	graph export $figtab/permres_GM_nocontrols.png, replace 
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 4: Shift-share instrument for Great Migration
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
* Uses data shared only with the author and not contained in the replication files.
/*
	* (a) Composition of recent 1935-1940 black southern migrants in Detroit vs. Baltimore 
	use ${migshares}/2_blackorigin_fips1940.dta, clear
	decode(city), gen(city_str)
	keep if (regexm(city_str, "Detroit")==1 | regexm(city_str, "Baltimore")==1)
	keeporder city_str city blackorigin_fips51760 blackorigin_fips1073 blackorigin_fips5093 blackorigin_fips12031 blackorigin_fips13051 ///
	blackorigin_fips22071 blackorigin_fips28027 blackorigin_fips37119 blackorigin_fips45091 blackorigin_fips48113 ///
	blackorigin_fips21111 blackorigin_fips40109 blackorigin_fips47157 blackorigin_fips54047
	g id=_n
	g citytag=lower(substr(city_str,1,strpos(city_str,",")-1))
	reshape long blackorigin_fips, i(id) j(code)
	g space=0
	gen id_order = .
	replace id_order = 1 if code == 51760 & citytag == "detroit"
	replace id_order = 2 if code == 1073 & citytag == "detroit"
	replace id_order = 3 if code == 5093 & citytag == "detroit"
	replace id_order = 4 if code == 12031 & citytag == "detroit"
	replace id_order = 5 if code == 13051 & citytag == "detroit"
	replace id_order = 6 if code == 22071 & citytag == "detroit"
	replace id_order = 7 if code == 28027 & citytag == "detroit"
	replace id_order = 8 if code == 37119 & citytag == "detroit"
	replace id_order = 9 if code == 45091 & citytag == "detroit"
	replace id_order = 10 if code == 48113 & citytag == "detroit"
	replace id_order = 11 if code == 21111 & citytag == "detroit"
	replace id_order = 12 if code == 40109 & citytag == "detroit"
	replace id_order = 13 if code == 47157 & citytag == "detroit"
	replace id_order = 14 if code == 54047 & citytag == "detroit"
	replace id_order = 15 if code == 51760 & citytag == "baltimore"
	replace id_order = 16 if code == 1073 & citytag == "baltimore"
	replace id_order = 17 if code == 5093 & citytag == "baltimore"
	replace id_order = 18 if code == 12031 & citytag == "baltimore"
	replace id_order = 19 if code == 13051 & citytag == "baltimore"
	replace id_order = 20 if code == 22071 & citytag == "baltimore"
	replace id_order = 21 if code == 28027 & citytag == "baltimore"
	replace id_order = 22 if code == 37119 & citytag == "baltimore"
	replace id_order = 23 if code == 45091 & citytag == "baltimore"
	replace id_order = 24 if code == 48113 & citytag == "baltimore"
	replace id_order = 25 if code == 21111 & citytag == "baltimore"
	replace id_order = 26 if code == 40109 & citytag == "baltimore"
	replace id_order = 27 if code == 47157 & citytag == "baltimore"
	replace id_order = 28 if code == 54047 & citytag == "baltimore"
	twoway (bar blackorigin_fips id_order if id_order == 1,  bcolor(navy) ) ///
	(bar blackorigin_fips id_order if id_order == 2,  bcolor(maroon) text(.12 2 "Alabama", color(black))) ///
	(bar blackorigin_fips id_order if id_order > 2 & id_order < 16,  bcolor(dimgray)) ///
	(bar blackorigin_fips id_order if id_order == 15,  bcolor(navy) text(.115 15 "Virginia", color(black))) ///
	(bar blackorigin_fips id_order if id_order == 16,  bcolor(maroon)) ///
	(bar blackorigin_fips id_order if id_order > 16,  bcolor(dimgray)) ///
	(pcarrowi 0.05 6 .00367647 1 (3), lcolor(gray) mcolor(gray) text(0.053 6 "Virginia", color(black)) ) ///
	(pcarrowi 0.03 19 .00093041 16 (3), lcolor(gray) mcolor(gray) text(0.033 19 "Alabama", color(black)) ) ///
	,legend(off) ysc(r(0(.02).14)) xtitle("") xlabel("") ytitle("") graphregion(color(white)) ///
	ylabel(0 "0%" .02 "2%" .04 "4%" .06 "6%" .08 "8%" .10 "10%" .12 "12%" .14 "14%", angle(horizontal) nogrid) ///
	caption("      Detroit                                    Baltimore          ", ring(0) position(12) size(large)) xsize(8)
	cd "$figtab"
	graph export "detroit_baltimore_migrant_composition.png", replace
	
	* (b) Southern state net-migration, 1940-1970 
	use ${migdata}/raw/south_county.dta, clear
	drop _merge 
	keep  netbmig bpop_l year state
	g mig = (netbmig/100)*bpop_l
	cd "$xwalks"
	statastates, fips(state)
	replace state_name=strlower(state_name)
	keep if (state_name=="alabama" | state_name=="arkansas" | state_name=="florida" | state_name=="georgia" | state_name=="kentucky" ///
	| state_name=="louisiana" | state_name=="mississippi" | state_name=="north carolina" | state_name=="oklahoma" | state_name=="south carolina" ///
	| state_name=="tennessee" | state_name=="texas" | state_name=="virginia" | state_name=="west virginia")
	collapse (sum)  mig , by(state_name year)
	g origin_state_name = upper(state_name)
	
	merge 1:1 origin_state_name year using ${instrument}/3_lasso_boustan_predict_mig_state.dta, keepusing(proutmig) nogenerate
	
	replace origin_state_name = lower(origin_state_name)
	drop state_name
	rename origin_state_name state_name
	
	replace proutmig=mig if proutmig==.
	replace proutmig=proutmig/1000

	append using ${migdata}/raw/fmt_net_migration_south.dta
	
	replace state_name=subinstr(state_name, " ", "", .)

	preserve
	keep if year==1930
	sort mig
	restore
	
	preserve
	keep if year==1970
	sort mig
	restore
		
	reshape wide mig proutmig, i(year) j(state_name) string
	tsset year, delta(10)
	
	keep if year>=1940
	
	foreach var in "migalabama" "migarkansas" "migflorida" "miggeorgia" "migkentucky" "miglouisiana" "migmississippi" "migoklahoma" "migtennessee" "migtexas" "migvirginia"{
	replace `var'=`var'/1000
	gen label_`var' = proper(subinstr("`var'", "mig","",.)) if year==1970
	}
	
	gen label_proutmigalabama = proper(subinstr("proutmigalabama", "proutmig", "Pred Mig ",.)) if year==1970
	gen label_proutmigvirginia = proper(subinstr("proutmigvirginia", "proutmig", "Pred Mig ",.)) if year==1970

	twoway (tsline migalabama , recast(connected) msymbol(none) lcolor(maroon%50) mlabel(label_migalabama) mlabcolor(black)) ///
	(tsline proutmigalabama , recast(connected) msymbol(none) lcolor(maroon)  lwidth(thick) mlabel(label_proutmigalabama) mlabcolor(black))   ///
	(tsline migarkansas , recast(connected) msymbol(none) lcolor(myslate))   ///
	(tsline migflorida , recast(connected) msymbol(none) lcolor(myslate))  ///
	(tsline miggeorgia , recast(connected) msymbol(none)  lcolor(myslate))  ///
	(tsline migkentucky , recast(connected) msymbol(none) lcolor(myslate))  ///
	(tsline miglouisiana , recast(connected) msymbol(none) lcolor(myslate)) ///
	(tsline migmississippi , recast(connected) msymbol(none) lcolor(myslate)) ///
	(tsline migoklahoma , recast(connected) msymbol(none) lcolor(myslate)) ///
	(tsline migtennessee , recast(connected) msymbol(none) lcolor(myslate)) ///
	(tsline migtexas , recast(connected) msymbol(none) lcolor(myslate)) ///
	(tsline migvirginia , recast(connected) msymbol(none)  lcolor(jmpdarkblue%50)   mlabel(label_migvirginia) mlabcolor(black)) /// 	 
	(tsline proutmigvirginia , recast(connected) msymbol(none)  lcolor(jmpdarkblue) lwidth(thick) mlabel(label_proutmigvirginia) mlabcolor(black)), /// 
	xlabel(1940(10)1980) graphregion(color(white)) plotregion(ilcolor(white)) ysc(range(-350 100)) ///
	ytitle("Thousands") xtitle("") ylabel( ,nogrid) yline(0, lcolor(black)) legend(off) 
	cd "$figtab"
	graph export "southern_netmig_1940_1970_2.png", replace	

*/
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 5: First stage on Black population change
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	local x_ols GM 
	local x_iv GM_hat2

	qui: reg `x_ols' `x_iv' ${baseline_controls} 
	test `x_iv' = 0
	local first_stage_fstat : di %4.2f `r(F)'
	PrintEst `first_stage_fstat' "first_stage_fstat" "" "%" "4.1"

	local first_stage : di %4.3f _b[`x_iv']
	local first_stage_se : di %4.3f _se[`x_iv']
	
	PrintEst `first_stage' "first_stage" "" " percentile" "4.2"

	binscatter `x_ols' `x_iv', controls( ${baseline_controls}) ///
	reportreg lcolor(myslate*1.5) ylabel(,nogrid) mcolor(jmpgreen) ///
	xtitle("Percentile of predicted Black pop change 40-70") ytitle("Percentile of Black pop change 40-70") ///
	caption("F Stat = `first_stage_fstat'", ring(0) pos(7))
	graph export $figtab/first_stage_GM_GM_hat2.png, replace 

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 6: Great Migration reduced average upward mobility in northern commuting zones
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	local x_ols GM 
	local x_iv GM_hat2
	local y perm_res_p25_kr26
	qui: reg `y' `x_iv' ${baseline_controls} 
	local coeff : di %4.3f _b[`x_iv']
	local coeff_se : di %4.3f _se[`x_iv']
	binscatter `y' `x_iv' , controls(${baseline_controls}) ///
	reportreg lcolor(myslate*1.5) ylabel(,nogrid) mcolor(jmpgreen) ///
	xtitle("Percentile of predicted Black pop change 40-70") ytitle("Expected Mean Adult HH Inc. Rank, Parents 25p") ///
	caption("Slope = `coeff' (`coeff_se')", ring(0) pos(7)) 
	graph export $figtab/permres_GM_hat2.png, replace 

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 7: Childhood in Great Migration CZ lowers adult income of children from low income families
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	local x_ols GM 
	local x_iv GM_hat2
	local y causal_p25_czkr26
	qui: reg `y' `x_iv' ${baseline_controls} [aw=1/(`y'_se^2)]
	local coeff : di %12.4f _b[`x_iv']
	local coeff_se : di %5.4f _se[`x_iv']
	binscatter `y' `x_iv' [aw= 1/(`y'_se^2)], controls(${baseline_controls}) ///
	reportreg lcolor(myslate*1.5) ylabel(,nogrid) mcolor(jmpgreen) ///
	xtitle("Percentile of predicted Black pop change 40-70") ytitle("CZ Expos Effect on HH Inc. Rank, Parents 25p") ///
	caption( "Slope = `coeff' (`coeff_se')", ring(0) pos(7))
	graph export $figtab/causal_GM_hat2.png, replace 

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 8: Race and gender heterogeneity in impact of Great Migration on Upward Mobility
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	use ${data}/GM_cz_final_dataset.dta, clear
		
	local outcomes kfr_black_pooled_p252015 kfr_black_pooled_p752015 kir_black_male_p252015 kir_black_male_p752015 kir_black_female_p252015 kir_black_female_p752015 kfr_white_pooled_p252015 kfr_white_pooled_p752015 kir_white_male_p252015 kir_white_male_p752015 kir_white_female_p252015 kir_white_female_p752015
	foreach y in `outcomes'{
	replace `y'=`y'*100
	}
	
	* Rescale treatment in terms of standard deviations
	qui sum GM_hat2
	replace GM_hat2=GM_hat2/`r(sd)'	
	qui sum GM
	replace GM=GM/`r(sd)'

	foreach y of varlist `outcomes'{
	ivreg2 `y' ($x_ols =$x_iv ) ${baseline_controls} if `y'!=., first 	
	eststo `y'_iv
	}	

	local xvar "GM"
	local type "_iv"
	local scale "xsc(r(-8 8))"
	local xlabel "xla(-8(2)8)"	

	coefplot (kir_black_male_p252015`type', mlabels(`xvar' = 12 "Black men, low inc ") keep(`xvar') ciopts(lcolor(jmpgreen)) mcolor(jmpgreen) mlabcolor(jmpgreen)) ///
	(kir_black_male_p752015`type', mlabels(`xvar' = 12 "Black men, high inc ") keep(`xvar') ciopts(lcolor(jmpgreen)) mcolor(jmpgreen) mlabcolor(jmpgreen)) ///
	(kir_black_female_p252015`type', mlabels(`xvar' = 12 "Black women,  low inc  ") keep(`xvar') xline(0, lcolor(gs8)) ciopts(lcolor(myslate*1.5)) mcolor(myslate*1.5) mlabcolor(myslate*1.5)) ///
	(kir_black_female_p752015`type',mlabels(`xvar' = 12 "Black women,  high inc  ") keep(`xvar') ciopts(lcolor(myslate*1.5)) mcolor(myslate*1.5) mlabcolor(myslate*1.5)) ///
	(kir_white_male_p252015`type', mlabels(`xvar' = 12 "White men, low inc ")  keep(`xvar') ciopts(lcolor(myslate*1.5)) mcolor(myslate*1.5) mlabcolor(myslate*1.5)) ///
	(kir_white_male_p752015`type', mlabels(`xvar' = 12 "White men, high inc ") keep(`xvar') ciopts(lcolor(myslate*1.5)) mcolor(myslate*1.5) mlabcolor(myslate*1.5))  ///
	(kir_white_female_p252015`type', mlabels(`xvar' = 12 "White women,  low inc  ")keep(`xvar') ciopts(lcolor(myslate*1.5)) mcolor(myslate*1.5) mlabcolor(myslate*1.5)) ///
	(kir_white_female_p752015`type', mlabels(`xvar' = 12 "White women,  high inc  ") keep(`xvar') ciopts(lcolor(myslate*1.5)) mcolor(myslate*1.5) mlabcolor(myslate*1.5)), ///
	`scale' `xlabel' graphregion(color(white)) plotregion(ilcolor(white)) ylabel(none,nogrid)  legend(off) ytitle("") ///
	ylabel(none) xtitle("Percentile Change in Average Adult Income Rank in CZ")	
	cd "$figtab"
	graph export GM_race_kir_mobility`type'_coefplot.png, replace	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Figure 9: Great Migration CZs have higher segregation, crime, and policing
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	cap mkdir "$figtab/tempgraphs"

	use ${data}/GM_cz_final_dataset.dta, clear
	eststo clear
	
	* Rescale treatment in terms of standard deviations
	qui sum GM_hat2
	replace GM_hat2=GM_hat2/`r(sd)'	
	qui sum GM
	replace GM=GM/`r(sd)'

	* Government spending
	foreach cat in "pol" "edu"{
	reg `cat'share1932_st GM_hat2 ${baseline_controls}
	eststo `cat'
	}
	
	foreach cat in "pol"{		
	reg `cat'exppc1932_st GM_hat2 ${baseline_controls}	
	eststo pc`cat'
	}	

	foreach cat in "edu"{		
	reg `cat'expps1932_st GM_hat2 ${baseline_controls}	
	eststo pc`cat'
	}	
	
	* Murder
	reg murder_mean1931_1943_st GM_hat2 ${baseline_controls}
	eststo murder

	* Incarceration
	reg jail_rate1940_st GM_hat2 ${baseline_controls}	
	eststo prison

	* Private school
	reg prv_elemhs_share1920_st GM_hat2 ${baseline_controls}
	eststo prvschl

	local xvar GM_hat2
	
	coefplot (prvschl, mlabels(`xvar' = 12 "Private School")  keep(`xvar')) ///
	(murder, mlabels(`xvar' = 12 "Murder")  keep(`xvar')) ///
	(pol, mlabels(`xvar' = 12 "Police Exp Share") keep(`xvar')) ///
	(pcpol, mlabels(`xvar' = 12 "Police Exp Per Cap")  keep(`xvar')) ///
	(prison, mlabels(`xvar' = 12 "Incarceration") keep(`xvar')) ///
	(edu,mlabels(`xvar' = 12 "Education Exp Share") keep(`xvar')) ///
	(pcedu,mlabels(`xvar' = 12 "Education Exp Per Pupil")  keep(`xvar')), ///
	graphregion(color(white)) plotregion(ilcolor(white)) ylabel(none,nogrid)  legend(off) ytitle("")  ///
	ylabel(none) xtitle("(a) Effects on pre-1940 mechanisms") caption ("Units are standard deviations.", ring(0) pos(4) size(small)) xline(0, lcolor(gs8)) xsc(range(-.5 1)) xlabel(-.5 .5 1) name(p1,replace)
	cd "$figtab"
	graph export GM_locgov_coefplot_pretrends.png, replace	
	
	use ${data}/GM_cz_final_dataset.dta, clear
	eststo clear
	
	* Rescale treatment in terms of standard deviations
	qui sum GM_hat2
	replace GM_hat2=GM_hat2/`r(sd)'	
	qui sum GM
	replace GM=GM/`r(sd)'
	
	* Government spending
	foreach cat in "pol" "fire" "hlthhosp" "sani" "rec" "edu"{	
	reg `cat'share_mean1972_2002_st GM_hat2 ${baseline_controls}
	eststo `cat'
	}
	
	* Murder
	reg murder_mean1977_2002_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo murder
	
	* Incarceration
	reg total_prison_mean1983_2000_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo prison

	* Private school
	reg w_prv_mean1970_2000_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo prvschl
	
	* Black Private school
	reg b_prv_mean1970_2000_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo prvschl2

	* Racial segregation
	reg cs_race_theil2000_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo rseg
	
	* Income segregation
	reg cs00_seg_inc_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo iseg
	
	* Commute times
	reg frac_traveltime_lt15_st GM_hat2 ${baseline_controls} murder_mean1931_1943_st
	eststo ct	

	local xvar GM_hat2

	coefplot (prvschl, mlabels(`xvar' = 12 "   White Private School")  keep(`xvar')) ///
	(prvschl2, mlabels(`xvar' = 12 "Black Private School   ") keep(`xvar')) ///	
	(rseg, mlabels(`xvar' = 12 "Residential Racial Segregation") keep(`xvar')) ///
	(iseg, mlabels(`xvar' = 12 "  Residential Income Segregation") keep(`xvar')) ///
	(ct, mlabels(`xvar' = 12 "Frac w/ short commutes    ") keep(`xvar') ) ///		
	(murder, mlabels(`xvar' = 12 "Murder")  keep(`xvar')) ///	
	(pol, mlabels(`xvar' = 12 "   Police")  keep(`xvar')) ///			
	(prison, mlabels(`xvar' = 12 "Incarceration") keep(`xvar')) ///		
	(edu,mlabels(`xvar' = 12 "Education") keep(`xvar')) ///
	(fire, mlabels(`xvar' = 12 "Fire") keep(`xvar')) ///
	(hlthhosp, mlabels(`xvar' = 12 "Health & Hospitals") keep(`xvar')) ///
	(sani, mlabels(`xvar' = 12 "Sanitation") keep(`xvar')) ///
	(rec, mlabels(`xvar' = 12 "Recreation") keep(`xvar') xline(0, lcolor(gs8))), ///
	graphregion(color(white)) plotregion(ilcolor(white)) ylabel(none,nogrid)  legend(off) ytitle("")  ///
	ylabel(none) xtitle("(b) Effects on post-1970 mechanisms") caption("Units are standard deviations." "Controls for pre-1940 murder rates.", ring(0) pos(4) size(small))  xsc(range(-.5 1)) xlabel(-.5 .5 1) name(p2,replace)
	cd "$figtab"
	graph export GM_locgov_coefplot.png, replace	

	cd $figtab/tempgraphs
	graph combine p1 p2 , rows(1)  graphregion(color(white)) iscale(.75)
	
	graph export $figtab/GM_locgov_coefplot_prepost.png, replace 

	cap rmdir $figtab/tempgraphs
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*2. Tables.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 1: Contribution of location versus selection in Great Migration effects
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	use ${data}/GM_cz_final_dataset.dta, clear
	
	* Rescale treatment in terms of standard deviations
	qui sum GM_hat2 
	replace GM_hat2=GM_hat2/`r(sd)'	
	qui sum GM 
	replace GM=GM/`r(sd)'
	local ols_SD_wt= `r(sd)'
	di %4.0f `ols_SD_wt'
	PrintEst `ols_SD_wt' "ols_SD_wt" "" "%" "4.0"
	
	qui: ivreg2 perm_res_p25_kr26 ($x_ols = $x_iv )  ${baseline_controls} , first
	local GM_imp_upm = _b[$x_ols]
	di %4.1f `GM_imp_upm'
	PrintEst `GM_imp_upm' "GM_imp_upm" "" "" "4.1"
	
	use ${data}/GM_cz_final_dataset.dta, clear
	
	* Rescale treatment in terms of standard deviations
	qui sum GM_hat2 [aw=1/(causal_p25_czkr26_se^2)]
	replace GM_hat2=GM_hat2/`r(sd)'	
	qui sum GM [aw=1/(causal_p25_czkr26_se^2)]
	replace GM=GM/`r(sd)'
	local causal_SD= `r(sd)'
	di %4.0f `causal_SD'
	PrintEst `causal_SD' "causal_SD" "" "%" "4.0"

	qui: ivreg2 causal_p25_czkr26 ($x_ols = $x_iv )  ${baseline_controls} [aw=1/(causal_p25_czkr26_se^2)], first
	local causal = _b[$x_ols]
	
	local GM_imp_loc_20 = `causal' *20
	local GM_imp_loc_15_53 = `causal'  *15.53
	local GM_imp_loc_14_52 = `causal'  *14.52
	
	PrintEst `GM_imp_loc_20' "GM_imp_loc_20" "" "" "4.1"
	PrintEst `GM_imp_loc_15_53' "GM_imp_loc_15_53" "" "" "4.1"
	PrintEst `GM_imp_loc_14_52' "GM_imp_loc_14_52" "" "" "4.1"

	* Ratio	
	local loc_upm_ratio_20 = (`causal'*20/`GM_imp_upm')*100 
	local loc_upm_ratio_15_53 = (`causal'*15.53/`GM_imp_upm')*100 
	local loc_upm_ratio_14_52 = (`causal'*14.52/`GM_imp_upm')*100 
	
	PrintEst `loc_upm_ratio_20' "loc_upm_ratio_20" "" "%" "4.0"
	PrintEst `loc_upm_ratio_15_53' "loc_upm_ratio_15_53" "" "%" "4.0"
	PrintEst `loc_upm_ratio_14_52' "loc_upm_ratio_14_52" "" "%" "4.0"

	* Percent income (for p25, 1 percentile corresponds to 3.14% of income, see Chetty & Hendren (2018b): https://opportunityinsights.org/wp-content/uploads/2018/03/movers_paper2.pdf)
	local pct_income_permres = abs(`GM_imp_upm')*3.14
	PrintEst `pct_income_permres' "pct_income_permres" "" "%" "4.1"	
	
	* Absolute value of effect for in-text citation
	local GM_imp_upm_abs = abs(`GM_imp_upm')
	PrintEst `GM_imp_upm_abs' "GM_imp_upm_abs" "" "%" "4.1"
	
	local GM_imp_loc_14_52 = abs(`causal'  *14.52)
	PrintEst `GM_imp_loc_14_52' "GM_imp_loc_14_52_abs" "" "%" "4.1"

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 2: Great Migration contribution to northern racial upward mobility gap
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	use ${data}/GM_cz_final_dataset.dta, clear

	* Multiply outcomes by 100 to be in percentile units
	foreach var of varlist kfr_white_pooled* kfr_black_pooled*{
	replace `var'=100*`var'
	}

	* Calculate mean of Black upward mobility in the sample
	foreach p in "p25" "p50" "p75"{
	sum kfr_black_pooled_`p', d
	local black_mean_`p'=r(mean)	
	}

	* Create a counterfactual dataset where GM is lowest percentile across all CZs in sample
	replace GM_hat2=1
	replace GM=1
	g id=_n+130
	
	* Replace Black upward mobility as missing in the counterfactual dataset
	foreach r in "black"{
	foreach p in "p25" "p50" "p75"{
	replace kfr_`r'_pooled_`p'=.
	}
	}

	* Calculate racial gap (which will be missing for all values) in the counterfactual dataset
	foreach p in "p25" "p50" "p75"{
	g racegap2015_`p' = kfr_white_pooled_`p'-kfr_black_pooled_`p'
	}
	
	tempfile GM_cf
	
	save `GM_cf'

	* Open a new copy of the original dataset for generating the fitted values
	use ${data}/GM_cz_final_dataset.dta, clear
	
	* Multiply outcomes by 100 to be in percentile units	
	foreach var of varlist kfr_white_pooled* kfr_black_pooled*{
	replace `var'=100*`var'
	}

	* Calculate racial gap in upward mobility in each CZ
	foreach p in "p25" "p50" "p75"{
	g racegap2015_`p' = kfr_white_pooled_`p'-kfr_black_pooled_`p'
	}
	
	g id=_n
	append using `GM_cf'
	
	* 2SLS regression of Black upward mobility on GM; generate fitted vaues
	foreach r in "black" {
	foreach p in "p25" "p50" "p75"{
	ivreg2 kfr_`r'_pooled_`p' ($x_ols = $x_iv) ${baseline_controls}	if kfr_`r'_pooled_`p' !=.  // Only uses original sample in the 2SLS regression
	predict kfr_`r'_pooled_`p'_pred, xb // Generates fitted values of Black upward mobility for all obs using X vars & regression coefficients from step above
	predict kfr_`r'_pooled_`p'_pred_se, stdp	 // Generates standard errors for above fitted values 
	}
	}
	
	* Calculate actual average racial gap in sample CZs
	foreach p in "p25" "p50" "p75"{
	sum racegap2015_`p' if id<131, d           // Only calculate on original sample (not counterfactual sample)
	local rgp_mean_`p'=r(mean)					// Store mean in original sample

	* Compute counterfactual gap by predicting Black outcomes if lowest percentile of GM
	g racegap2015_`p'_pred = kfr_white_pooled_`p'-kfr_black_pooled_`p'_pred  // Calculate racial gap using fitted values	
	sum racegap2015_`p'_pred if id>130, d
	g rgpcf_mean_`p'=r(mean)
	local rgpcf_mean_`p'=r(mean)
	sum kfr_black_pooled_`p'_pred, d
	local blackcf_north_`p'=r(mean)
	}

	* Generate standard errors for counterfactual racial gap
	keep if id>130

	* Variance of counterfactual racial gaps
	foreach p in "p25" "p50" "p75"{	
	egen var_rg_cf_`p'=sum((racegap2015_`p'_pred - rgpcf_mean_`p')^2)
	replace var_rg_cf_`p'=(var_rg_cf_`p')/(_N-1)
	g sqrt_var_rg_cf_`p' = sqrt(var_rg_cf_`p')
	local sqrt_var_rg_cf_`p' = sqrt_var_rg_cf_`p'
	}

	tempname sample
	file open `sample' using "$figtab/text/samplesize.txt", text write replace
	file write `sample' `"`r(N)'"' 
    file close `sample'
	
	foreach p in "p25" "p50" "p75"{
	local text_`p' : di%4.2f `rgp_mean_`p''
	tempname number
	file open `number' using "$figtab/text/rg`p'.txt", text write replace
	file write `number' `"`text_`p''"' 
    file close `number'	
	local text_`p' : di%4.2f `rgpcf_mean_`p''	
	file open `number' using "$figtab/text/rgcf`p'.txt", text write replace
	file write `number' `"`text_`p''"' 
    file close `number'	
	local text_`p' : di%4.2f `sqrt_var_rg_cf_`p''
	file open `number' using "$figtab/text/rg_se`p'.txt", text write replace
	file write `number' `"`text_`p''"' 
    file close `number'	
	local change`p' = (`rgp_mean_`p''-`rgpcf_mean_`p'')*100/`rgp_mean_`p''
	local text_`p' : di %4.0f `change`p''
	file open `number' using "$figtab/text/change`p'.txt", text write replace
	file write `number' `"`text_`p''%"' 
    file close `number'		
	}
	
	foreach p in "p25" "p50" "p75"{
	di ""
	di %4.2f `rgp_mean_`p''
	di %4.2f `rgpcf_mean_`p''	
	di %4.2f `sqrt_var_rg_cf_`p''
	di  %4.0f (`rgp_mean_`p''-`rgpcf_mean_`p'')*100/`rgp_mean_`p''
	di ""
	di %4.2f `black_mean_`p''
	di %4.2f `blackcf_mean_`p''
	}

	* Alternative calculation not assuming zero effect of GM on white upward mobility

	use ${data}/GM_cz_final_dataset.dta, clear

	* Multiply outcomes by 100 to be in percentile units
	foreach var of varlist kfr_white_pooled* kfr_black_pooled*{
	replace `var'=100*`var'
	}

	* Calculate mean of Black upward mobility in the sample
	foreach p in "p25" "p50" "p75"{
	sum kfr_black_pooled_`p', d
	local black_mean_`p'=r(mean)	
	}

	* Create a counterfactual dataset where GM is lowest percentile across all CZs in sample
	replace GM_hat2=1
	replace GM=1
	g id=_n+130
	
	* Replace Black upward mobility as missing in the counterfactual dataset
	foreach r in "black" "white"{
	foreach p in "p25" "p50" "p75"{
	replace kfr_`r'_pooled_`p'=.
	}
	}

	* Calculate racial gap (which will be missing for all values) in the counterfactual dataset
	foreach p in "p25" "p50" "p75"{
	g racegap2015_`p' = kfr_white_pooled_`p'-kfr_black_pooled_`p'
	}
	
	tempfile GM_cf
	
	save `GM_cf'

	* Open a new copy of the original dataset for generating the fitted values
	use ${data}/GM_cz_final_dataset.dta, clear
	
	* Multiply outcomes by 100 to be in percentile units	
	foreach var of varlist kfr_white_pooled* kfr_black_pooled*{
	replace `var'=100*`var'
	}

	* Calculate racial gap in upward mobility in each CZ
	foreach p in "p25" "p50" "p75"{
	g racegap2015_`p' = kfr_white_pooled_`p'-kfr_black_pooled_`p'
	}
	
	g id=_n
	append using `GM_cf'
	
	* 2SLS regression of Black upward mobility on GM; generate fitted vaues
	foreach r in "black" "white"{
	foreach p in "p25" "p50" "p75"{
	ivreg2 kfr_`r'_pooled_`p' ($x_ols = $x_iv) ${baseline_controls}	if kfr_`r'_pooled_`p' !=.  // Only uses original sample in the 2SLS regression
	predict kfr_`r'_pooled_`p'_pred, xb // Generates fitted values of Black upward mobility for all obs using X vars & regression coefficients from step above
	predict kfr_`r'_pooled_`p'_pred_se, stdp	 // Generates standard errors for above fitted values 
	}
	}
	
	* Calculate actual average racial gap in sample CZs
	foreach p in "p25" "p50" "p75"{
	sum racegap2015_`p' if id<131, d           // Only calculate on original sample (not counterfactual sample)
	local rgp_mean_`p'=r(mean)					// Store mean in original sample

	* Compute counterfactual gap by predicting Black outcomes if lowest percentile of GM
	g racegap2015_`p'_pred = kfr_white_pooled_`p'_pred-kfr_black_pooled_`p'_pred  // Calculate racial gap using fitted values	
	sum racegap2015_`p'_pred if id>130, d
	g rgpcf_mean_`p'=r(mean)
	local rgpcf_mean_`p'=r(mean)
	sum kfr_black_pooled_`p'_pred, d
	local blackcf_north_`p'=r(mean)
	}

	* Generate standard errors for counterfactual racial gap
	keep if id>130

	* Variance of counterfactual racial gaps
	foreach p in "p25" "p50" "p75"{	
	egen var_rg_cf_`p'=sum((racegap2015_`p'_pred - rgpcf_mean_`p')^2)
	replace var_rg_cf_`p'=(var_rg_cf_`p')/(_N)
	g sqrt_var_rg_cf_`p' = sqrt(var_rg_cf_`p')
	}

	foreach p in "p25" "p50" "p75"{
	local text_`p' : di%4.2f `rgp_mean_`p''
	tempname number
	file open `number' using "$figtab/text/rg`p'_alt.txt", text write replace
	file write `number' `"`text_`p''"' 
    file close `number'	
	local text_`p' : di%4.2f `rgpcf_mean_`p''	
	file open `number' using "$figtab/text/rgcf`p'_alt.txt", text write replace
	file write `number' `"`text_`p''"' 
    file close `number'	
	local text_`p' : di%4.2f `sqrt_var_rg_cf_`p''
	file open `number' using "$figtab/text/rg_se`p'_alt.txt", text write replace
	file write `number' `"`text_`p''"' 
    file close `number'	
	local change`p' = (`rgp_mean_`p''-`rgpcf_mean_`p'')*100/`rgp_mean_`p''
	local text_`p' : di %4.0f `change`p''
	file open `number' using "$figtab/text/change`p'_alt.txt", text write replace
	file write `number' `"`text_`p''%"' 
    file close `number'		
	}
	
	foreach p in "p25" "p50" "p75"{
	di ""
	di %4.2f `rgp_mean_`p''
	di %4.2f `rgpcf_mean_`p''	
	di %4.2f sqrt_var_rg_cf_`p'
	di  %4.0f (`rgp_mean_`p''-`rgpcf_mean_`p'')*100/`rgp_mean_`p''
	di ""
	di %4.2f `black_mean_`p''
	di %4.2f `blackcf_mean_`p''
	}
	
	* Remove any tempfiles and temp folders 
	cd "$figtab"
	
	local datafiles: dir "$figtab" files "*.dta"
	foreach datafile of local datafiles {
			rm `datafile'
	}

	shell rmdir $figtab/temp
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 3: Placebo test of identification strategy using pre-1940 upward mobility and educational attainment
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	local outcomes "enrolled_occs1900 enrolled_occs1910 enrolled_occs1920 enrolled_occs1930 enrolled_occs1940  avg_wt_med_educ1940"
	eststo clear
	foreach outcome in `outcomes'{
		use ${data}/GM_cz_final_dataset.dta, clear
		qui sum GM if `outcome'!=.
		local ols_SD=`r(sd)'
		qui: reg `outcome' $x_iv ${baseline_controls}
		sum `outcome' if e(sample)
		estadd scalar basemean=r(mean)
		estadd scalar sd=r(sd)
		eststo `outcome'           
		estadd local hascontrols 	"Y"
		estadd scalar gm_sd=`ols_SD'
		}
	esttab `outcomes' using $figtab/table1.tex, tex replace label nonote nocons nonum  ///
	posthead("&\multicolumn{5}{c}{}&\multicolumn{1}{c}{Median}\\" ///
	"&\multicolumn{5}{c}{Percentage of teens with low}&\multicolumn{1}{c}{adult}\\" ///
	"&\multicolumn{5}{c}{occ. score fathers attending school}&\multicolumn{1}{c}{education}\\" ///
	 "&\multicolumn{1}{c}{1900}&\multicolumn{1}{c}{1910}&\multicolumn{1}{c}{1920}&\multicolumn{1}{c}{1930}&\multicolumn{1}{c}{1940}&\multicolumn{1}{c}{1940}\\" )  ///
	se(%8.3f) b(%8.3f) nostar nofloat nonum nomtitles ///
	keep(GM_hat2) stats(basemean sd gm_sd N hascontrols,fmt(%8.3f %8.3f %8.3f %15.0gc  ) label("Baseline mean" "SD Dep Var" "SD GM" "Observations" "Baseline Controls")) 

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 4: Lower average upward mobility today for low income families in Great Migration CZs 
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	use ${data}/GM_cz_final_dataset_split.dta, clear
	
	foreach p in "25" {
	local inc_level "Lower Inc"	
	if "`p'"=="75"{
	local inc_level "Higher Inc"
	}
	
	local outcomes perm_res_p`p'_kr26 perm_res_p`p'_kr26_f perm_res_p`p'_kr26_m perm_res_p`p'_kir26 perm_res_p`p'_kir26_f perm_res_p`p'_kir26_m

	* First Stage	split
	eststo clear
	foreach d in _1940_1950 _1950_1960 _1960_1970{
		local base = substr("`d'",2,4)
		global x_ols GM`d'
		global x_iv GM_hat2`d'	
		global baseline_controls frac_all_upm`base' mfg_lfshare`base'  v2_blackmig3539_share`base' reg2 reg3 reg4

		la var $x_iv "$\hat{GM}$"
		la var $x_ols "GM"
		
		foreach y in `outcomes'{
			use ${data}/GM_cz_final_dataset_split.dta, clear
			la var $x_iv "$\hat{GM}$"
			la var $x_ols "GM"
			qui sum $x_ols if `y'!=.
			local ols_SD=`r(sd)'
			local ols_SD= `r(sd)'
			di %4.0f `ols_SD'
			PrintEst `ols_SD' "ols_SD" "" "%" "4.0"
			

			reg $x_ols $x_iv  ${baseline_controls}
			eststo `y'
			test $x_iv = 0
			estadd scalar fstat=`r(F)'
		}
		cd "$figtab"
		esttab `outcomes' using "permres_table_p`p'`d'.tex", frag replace  varwidth(25) label se ///
		stats(fstat, labels(  F-Stat)) keep($x_iv) mgroups("\textit{First Stage on GM}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
		nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
		
		* OLS 	
		eststo clear
		foreach y in `outcomes'{
			use ${data}/GM_cz_final_dataset_split.dta, clear
			la var $x_iv "$\hat{GM}$"
			la var $x_ols "GM"
			qui sum $x_ols if `y'!=.
			local ols_SD=`r(sd)'
			reg `y' $x_ols  ${baseline_controls}
			local olsLB`y'=_b[$x_ols] -1.96*_se[$x_ols]
			local olsUB`y'=_b[$x_ols] +1.96*_se[$x_ols]		
			PrintEst `olsLB`y'' "olsLB`y'" "" "%" "4.3"
			PrintEst `olsUB`y'' "olsUB`y'" "" "%" "4.3"		
			eststo `y'
		}
		cd "$figtab"
		esttab `outcomes' using "permres_table_p`p'`d'.tex", frag append  varwidth(25) label se ///
		prehead("\\" "&\multicolumn{3}{c}{Household Income Rank}&\multicolumn{3}{c}{Individual Income Rank}\\" ///
		"&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men}&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men} \\\cmidrule(lr){2-7}")  ///
		stats( r2, labels( R-squared)) keep($x_ols) mgroups("\textit{Ordinary Least Squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
		nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 

		* RF 	
		eststo clear
		foreach y in `outcomes'{
			use ${data}/GM_cz_final_dataset_split.dta, clear
			la var $x_iv "$\hat{GM}$"
			la var $x_ols "GM"
			qui sum $x_ols if `y'!=.
			local ols_SD=`r(sd)'
			reg `y' $x_iv  ${baseline_controls}
			eststo `y'
		}
		cd "$figtab"
		esttab `outcomes' using "permres_table_p`p'`d'.tex", frag append  varwidth(25) label se ///
		stats( r2, labels( R-squared)) keep($x_iv) mgroups("\textit{Reduced Form}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber  ///
		nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
		
		* 2SLS 
		eststo clear
		foreach y in `outcomes'{
			use ${data}/GM_cz_final_dataset_split.dta, clear
			la var $x_iv "$\hat{GM}$"
			la var $x_ols "GM"
			qui sum $x_ols if `y'!=.
			local ols_SD=`r(sd)'
			ivreg2 `y' ($x_ols = $x_iv )  ${baseline_controls}, first
			local GM_`y' = _b[$x_ols]
			local GM_`y'_abs = abs(_b[$x_ols])
			local GM_`y'_se : di %4.3f _se[$x_ols]
			local ivLB`y'=_b[$x_ols] -1.96*_se[$x_ols]
			local ivUB`y'=_b[$x_ols] +1.96*_se[$x_ols]		
			PrintEst `ivLB`y'' "ivLB`y'" "" "%" "4.3"
			PrintEst `ivUB`y'' "ivUB`y'" "" "%" "4.3"	
			PrintEst `GM_`y'' "GM_`y'" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
			PrintEst `GM_`y'_abs' "GM_`y'_abs" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
			eststo `y'
			sum `y' if e(sample) 
			estadd scalar basemean=r(mean)
			estadd scalar sd=r(sd)	
			estadd scalar gm_sd=`ols_SD'
		}
		
		cd "$figtab"
		esttab `outcomes' using "permres_table_p`p'`d'.tex", frag append  varwidth(25) label se ///
		stats(none, labels(" ")) keep($x_ols) mgroups("\textit{Two-stage least squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
		nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
		
		* Footer
		cd "$figtab"
		esttab `outcomes' using "permres_table_p`p'`d'.tex", frag append  varwidth(25) label se ///
		stats( N  basemean sd gm_sd, labels(N "Mean Rank" "SD Rank" "SD GM")) drop(*) nonumber ///
		nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
		}
	}
	
	// Stacked
	use ${data}/GM_cz_final_dataset_split.dta, clear
	foreach p in "25" {
		local inc_level "Lower Inc"	
		if "`p'"=="75"{
			local inc_level "Higher Inc"
		}
		local outcomes perm_res_p`p'_kr26 perm_res_p`p'_kr26_f perm_res_p`p'_kr26_m perm_res_p`p'_kir26 perm_res_p`p'_kir26_f perm_res_p`p'_kir26_m

	rename *1940_1950 *1940
	rename *1950_1960 *1950
	rename *1960_1970 *1960
	
	keep GM_???? GM_hat2_???? frac_all_upm* mfg_lfshare* v2_blackmig3539_share* cz reg2 reg3 reg4  `outcomes'
	reshape long GM_ GM_hat2_ frac_all_upm mfg_lfshare v2_blackmig3539_share, i(cz) j(decade)
	drop if decade == 1970
	ren GM_ GM
	ren GM_hat2_ GM_hat2
	
	global x_ols GM
	global x_iv GM_hat2	
	global baseline_controls frac_all_upm mfg_lfshare v2_blackmig3539_share reg2 reg3 reg4 i.decade
	
	la var $x_iv "$\hat{GM}$"
	la var $x_ols "GM"
		
	tempfile stacked
	save `stacked'
	

	
	eststo clear
	foreach y in `outcomes'{
		use `stacked', clear
		qui sum $x_ols if `y'!=.
		local ols_SD=`r(sd)'
		local ols_SD= `r(sd)'
		di %4.0f `ols_SD'
		PrintEst `ols_SD' "ols_SD" "" "%" "4.0"
		

		reg $x_ols $x_iv  ${baseline_controls}
		eststo `y'
		test $x_iv = 0
		estadd scalar fstat=`r(F)'
	}
	cd "$figtab"
	esttab `outcomes' using "permres_table_p`p'_stacked.tex", frag replace  varwidth(25) label se ///
	stats(fstat, labels(  F-Stat)) keep($x_iv) mgroups("\textit{First Stage on GM}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* OLS 	
	eststo clear
	foreach y in `outcomes'{
		use `stacked', clear
		qui sum $x_ols if `y'!=.
		local ols_SD=`r(sd)'
		reg `y' $x_ols  ${baseline_controls}
		local olsLB`y'=_b[$x_ols] -1.96*_se[$x_ols]
		local olsUB`y'=_b[$x_ols] +1.96*_se[$x_ols]		
		PrintEst `olsLB`y'' "olsLB`y'" "" "%" "4.3"
		PrintEst `olsUB`y'' "olsUB`y'" "" "%" "4.3"		
		eststo `y'
	}
	cd "$figtab"
	esttab `outcomes' using "permres_table_p`p'_stacked.tex", frag append  varwidth(25) label se ///
	prehead("\\" "&\multicolumn{3}{c}{Household Income Rank}&\multicolumn{3}{c}{Individual Income Rank}\\" ///
	"&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men}&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men} \\\cmidrule(lr){2-7}")  ///
	stats( r2, labels( R-squared)) keep($x_ols) mgroups("\textit{Ordinary Least Squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 

	* RF 	
	eststo clear
	foreach y in `outcomes'{
		use `stacked', clear
		qui sum $x_ols if `y'!=.
		local ols_SD=`r(sd)'
		reg `y' $x_iv  ${baseline_controls}
		eststo `y'
	}
	cd "$figtab"
	esttab `outcomes' using "permres_table_p`p'_stacked.tex", frag append  varwidth(25) label se ///
	stats( r2, labels( R-squared)) keep($x_iv) mgroups("\textit{Reduced Form}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber  ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* 2SLS 
	eststo clear
	foreach y in `outcomes'{
		use `stacked', clear
		qui sum $x_ols if `y'!=.
		local ols_SD=`r(sd)'
		ivreg2 `y' ($x_ols = $x_iv )  ${baseline_controls}, first
		local GM_`y' = _b[$x_ols]
		local GM_`y'_abs = abs(_b[$x_ols])
		local GM_`y'_se : di %4.3f _se[$x_ols]
		local ivLB`y'=_b[$x_ols] -1.96*_se[$x_ols]
		local ivUB`y'=_b[$x_ols] +1.96*_se[$x_ols]		
		PrintEst `ivLB`y'' "ivLB`y'" "" "%" "4.3"
		PrintEst `ivUB`y'' "ivUB`y'" "" "%" "4.3"	
		PrintEst `GM_`y'' "GM_`y'" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
		PrintEst `GM_`y'_abs' "GM_`y'_abs" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
		eststo `y'
		sum `y' if e(sample) 
		estadd scalar basemean=r(mean)
		estadd scalar sd=r(sd)	
		estadd scalar gm_sd=`ols_SD'
	}
	
	cd "$figtab"
	esttab `outcomes' using "permres_table_p`p'_stacked.tex", frag append  varwidth(25) label se ///
	stats(none, labels(" ")) keep($x_ols) mgroups("\textit{Two-stage least squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* Footer
	cd "$figtab"
	esttab `outcomes' using "permres_table_p`p'_stacked.tex", frag append  varwidth(25) label se ///
	stats( N  basemean sd gm_sd, labels(N "Mean Rank" "SD Rank" "SD GM")) drop(*) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	}

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 5: Childhood exposure to Great Migration CZs lowers upward mobility for low income families 
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	use ${data}/GM_cz_final_dataset.dta, clear
	
	foreach p in "25" {
	local inc_level "Lower Inc"	
	if "`p'"=="75"{
	local inc_level "Higher Inc"
	}
	
	local outcomes causal_p`p'_czkr26 causal_p`p'_czkr26_f causal_p`p'_czkr26_m causal_p`p'_czkir26 causal_p`p'_czkir26_f causal_p`p'_czkir26_m

	* First Stage	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	g `y'_wt=1/(`y'_se^2)
	qui sum GM if `y'!=. [aw=`y'_wt]
	local ols_SD=`r(sd)'
	reg $x_ols $x_iv   ${baseline_controls} [aw=`y'_wt]
	eststo `y'
	test $x_iv = 0
	estadd scalar fstat=`r(F)'
	}
	cd "$figtab"
	esttab `outcomes' using "main_table_p`p'.tex", frag replace  varwidth(25) label se ///
	stats(fstat, labels(  F-Stat)) keep($x_iv) mgroups("\textit{First Stage on GM}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* OLS 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	g `y'_wt=1/(`y'_se^2)
	qui sum GM if `y'!=. [aw=`y'_wt]
	local ols_SD=`r(sd)'
	reg `y' $x_ols  ${baseline_controls} [aw=`y'_wt]
	local olsLB`y'=_b[$x_ols] -1.96*_se[$x_ols]
	local olsUB`y'=_b[$x_ols] +1.96*_se[$x_ols]		
	PrintEst `olsLB`y'' "olsLB`y'" "" "%" "12.4"
	PrintEst `olsUB`y'' "olsUB`y'" "" "%" "12.4"		
	eststo `y'
	}
	cd "$figtab"
	esttab `outcomes' using "main_table_p`p'.tex", frag append  varwidth(25) label se ///
	prehead("\\" "&\multicolumn{3}{c}{Household Income Rank}&\multicolumn{3}{c}{Individual Income Rank}\\" ///
	"&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men}&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men} \\\cmidrule(lr){2-7}")  ///
	stats( r2, labels( R-squared)) keep($x_ols) mgroups("\textit{Ordinary Least Squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 

	* RF 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	g `y'_wt=1/(`y'_se^2)
	qui sum GM if `y'!=. [aw=`y'_wt]
	local ols_SD=`r(sd)'
	reg `y' $x_iv  ${baseline_controls} [aw=`y'_wt]
	eststo `y'
	}
	cd "$figtab"
	esttab `outcomes' using "main_table_p`p'.tex", frag append  varwidth(25) label se ///
	stats( r2, labels( R-squared)) keep($x_iv) mgroups("\textit{Reduced Form}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber  ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* 2SLS 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	g `y'_wt=1/(`y'_se^2)
	qui sum GM if `y'!=. [aw=`y'_wt]
	local ols_SD=`r(sd)'
	ivreg2 `y' ($x_ols = $x_iv )  ${baseline_controls} [aw=`y'_wt], first
	local GM_`y' = _b[$x_ols]
	local GM_`y'_abs = abs(_b[$x_ols])
	local GM_`y'_se : di %6.4f _se[$x_ols]
	local ivLB`y'=_b[$x_ols] -1.96*_se[$x_ols]
	local ivUB`y'=_b[$x_ols] +1.96*_se[$x_ols]		
	PrintEst `ivLB`y'' "ivLB`y'" "" "%" "12.4"
	PrintEst `ivUB`y'' "ivUB`y'" "" "%" "12.4"	
	PrintEst `GM_`y'' "GM_`y'" "" " percentile points (s.e. = `GM_`y'_se')%" "6.4"
	PrintEst `GM_`y'_abs' "GM_`y'_abs" "" " percentile points (s.e. = `GM_`y'_se')%" "6.4"
	eststo `y'
	sum `y' if e(sample) [aw=`y'_wt]
	estadd scalar basemean=r(mean)
	estadd scalar sd=r(sd)	
	estadd scalar gm_sd=`ols_SD'
	estadd local precisionwt "Y" 
	}
	
	cd "$figtab"
	esttab `outcomes' using "main_table_p`p'.tex", frag append  varwidth(25) label se ///
	stats(none, labels(" ")) keep($x_ols) mgroups("\textit{Two-stage least squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* Footer
	cd "$figtab"
	esttab `outcomes' using "main_table_p`p'.tex", frag append  varwidth(25) label se ///
	stats( N precisionwt basemean sd gm_sd, labels(N "Precision Wt" "Mean Expos FX" "SD Expos FX" "SD GM")) drop(*) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	}


*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 6: Lower average upward mobility today for black households in Great Migration CZs 
	* &
	* Table 7: No Great Migration impact on average upward mobility of white households today
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	foreach r in "black" "white"{
	local race "Black"	
	if "`r'"=="black"{
	local race "White"
	}
	
	local outcomes kfr_`r'_pooled_p252015 kir_`r'_female_p252015 kir_`r'_male_p252015 kfr_`r'_pooled_p752015 kir_`r'_female_p752015 kir_`r'_male_p752015

	* First Stage	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	* Rescale treatment in terms of standard deviations
	qui sum GM
	local ols_SD=`r(sd)'
	* Rescale outcome in percentile ranks
	replace `y'=100*`y'
	reg $x_ols $x_iv   ${baseline_controls} if `y'!=.
	eststo `y'
	test $x_iv = 0
	estadd scalar fstat=`r(F)'
	}
	cd "${figtab}"
	esttab `outcomes' using "`r'_hh_table.tex", frag replace  varwidth(25) label se ///
	stats(fstat, labels(  F-Stat)) keep($x_iv) mgroups("\textit{First Stage on GM}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* OLS 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	* Rescale treatment in terms of standard deviations
	qui sum GM
	local ols_SD=`r(sd)'
	* Rescale outcome in percentile ranks
	replace `y'=100*`y'
	reg `y' $x_ols  ${baseline_controls}  if `y'!=.
	eststo `y'
	}
	cd "${figtab}"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	prehead("\\" "&\multicolumn{3}{c}{Low Income}&\multicolumn{3}{c}{High Income}\\" ///
	"&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men}&\multicolumn{1}{c}{Pooled}&\multicolumn{1}{c}{Women}&\multicolumn{1}{c}{Men} \\\cmidrule(lr){2-7}")  ///
	stats( r2, labels( R-squared)) keep($x_ols) mgroups("\textit{Ordinary Least Squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 

	* RF 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	* Rescale treatment in terms of standard deviations
	qui sum GM
	local ols_SD=`r(sd)'
	* Rescale outcome in percentile ranks
	replace `y'=100*`y'
	reg `y' $x_iv  ${baseline_controls} if `y'!=.
	eststo `y'
	}
	cd "${figtab}"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	stats( r2, labels( R-squared)) keep($x_iv) mgroups("\textit{Reduced Form}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber  ///
	nostar nomtitle nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) postfoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* 2SLS 	
	eststo clear
	foreach y in `outcomes'{
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	* Rescale treatment in terms of standard deviations
	qui sum GM
	local ols_SD=`r(sd)'
	* Rescale outcome in percentile ranks
	replace `y'=100*`y'
	ivreg2 `y' ($x_ols = $x_iv )  ${baseline_controls}  if `y'!=., first
	local GM_`y' = _b[$x_ols]
	local GM_`y'_abs = abs(_b[$x_ols])
	local GM_`y'_se : di %4.3f _se[$x_ols]
	PrintEst `GM_`y'' "GM_`y'" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
	PrintEst `GM_`y'_abs' "GM_`y'_abs" "" " percentile points (s.e. = `GM_`y'_se')%" "4.3"
	eststo `y'
	use ${data}/GM_cz_final_dataset.dta, clear
	keep if `y'!=.
	sum `y' 
	estadd scalar basemean=r(mean)
	estadd scalar sd=r(sd)	
	estadd scalar gm_sd=`ols_SD'
	}
	
	cd "${figtab}"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	stats(none, labels(" ")) keep($x_ols) mgroups("\textit{Two-stage least squares}", pattern(1 0) prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	
	* Footer
	cd "${figtab}"
	esttab `outcomes' using "`r'_hh_table.tex", frag append  varwidth(25) label se ///
	stats( N  basemean sd gm_sd, labels(N  "Mean Rank" "SD Rank" "SD GM")) drop(*) nonumber ///
	nostar nomtitle  nonotes nolines nogaps prefoot(\cmidrule(lr){2-7}) substitute({table} {threeparttable}) 
	}
	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 8: Robustness of effects of childhood exposure to Great Migration CZs
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	global nocon "v2_blackmig3539_share1940"
	global divfe "v2_blackmig3539_share1940 reg2 reg3 reg4"	
	global baseline "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4"
	global emp "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4 emp_hat"
	global flexbpop40 "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4 i.bpopquartile"		
	global swmig "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  GM_hat8"
	global eurmig "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  eur_mig"
	global supmob "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  vm_blacksmob1940"

	local y  causal_p25_czkr26 	

	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	g `y'_wt=1/(`y'_se^2)	

	reg $x_ols $x_iv $nocon [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'
	
	reg `y' $x_ols $nocon  [aw=`y'_wt]
	eststo nocon_ols
	estadd local hasdivfe 		"N"
	estadd local hasbaseline 	"N"
	estadd local hasemp		 	"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $nocon  [aw=`y'_wt]
	eststo nocon
	estadd scalar fstat=`fstat'
		
	reg $x_ols $x_iv $divfe [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $divfe    [aw=`y'_wt]
	eststo divfe_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"N"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv )  $divfe    [aw=`y'_wt]
	eststo divfe
	estadd scalar fstat=`fstat'
	
	reg $x_ols $x_iv $baseline [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $baseline [aw=`y'_wt]
	eststo baseline_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $baseline [aw=`y'_wt]
	eststo baseline
	estadd scalar fstat=`fstat'
	
	reg $x_ols $x_iv $emp [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $emp  [aw=`y'_wt]
	eststo emp_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"Y"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $emp  [aw=`y'_wt]
	eststo emp
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $flexbpop40 [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $flexbpop40  [aw=`y'_wt]
	eststo flexbpop40_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"Y"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y"

	ivreg2 `y' ($x_ols = $x_iv ) $flexbpop40  [aw=`y'_wt]
	eststo flexbpop40
	estadd scalar fstat=`fstat'
	
	reg $x_ols $x_iv $swmig [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $swmig  [aw=`y'_wt]
	eststo swmig_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"Y"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $swmig  [aw=`y'_wt]
	eststo swmig
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $eurmig [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $eurmig  [aw=`y'_wt]
	eststo eurmig_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig	 	"N"
	estadd local haseurmig		"Y"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv )  $eurmig  [aw=`y'_wt]
	eststo eurmig
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $supmob [aw=`y'_wt]
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $supmob  [aw=`y'_wt]
	eststo supmob_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp			"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"Y"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv ) $supmob  [aw=`y'_wt]
	eststo supmob
	estadd scalar fstat= `fstat'
	
	cd "$figtab"
	esttab nocon divfe baseline flexbpop40 supmob  swmig eurmig emp using "main_robust_table_p25.tex", frag replace varwidth(25) label se ///
	stats( fstat, labels("First Stage F-Stat")) keep($x_ols) coeflabel(GM "GM (2SLS)")  nonumber ///
	nostar nomtitle nonotes nolines nogaps  substitute({table} {threeparttable}) prefoot(\cmidrule(lr){2-9})
	
	esttab nocon_ols divfe_ols baseline_ols flexbpop40_ols supmob_ols  swmig_ols eurmig_ols emp_ols  using "main_robust_table_p25.tex", frag append  varwidth(25) label se ///
	prehead("\\") coeflabel(GM "GM (OLS)") ///
	stats( r2  N  precisionwt hasdivfe hasbaseline hasflexbpop40 hassupmob hasswmig haseurmig hasemp , ///
	labels( "R-squared (OLS)" N "Precision Wt" "Census Div FE" "Baseline Controls"  "1940 Black Share Quartile FEs" "Southern Mob" ///
	"White South Mig" "Eur Mig"  "Emp Bartik" )) keep($x_ols)  nonumber  ///
	nostar nomtitle nonotes nolines prefoot(\cmidrule(lr){2-9}) postfoot(\cmidrule(lr){2-9})  substitute({table} {threeparttable}) 

	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	* Table 9: Robustness of Great Migration's effects on black men's upward mobility
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	global nocon "v2_blackmig3539_share1940"
	global divfe "v2_blackmig3539_share1940 reg2 reg3 reg4"	
	global baseline "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4"
	global emp "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4 emp_hat"
	global flexbpop40 "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4 i.bpopquartile"		
	global swmig "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  GM_hat8"
	global eurmig "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  eur_mig"
	global supmob "frac_all_upm1940 mfg_lfshare1940 v2_blackmig3539_share1940 reg2 reg3 reg4  vm_blacksmob1940"

	local y  kir_black_male_p252015 	
	
	eststo clear
	use ${data}/GM_cz_final_dataset.dta, clear
	replace `y'=100*`y'
	
	reg $x_ols $x_iv $nocon 
	test $x_iv = 0
	local fstat=`r(F)'
	
	reg `y' $x_ols $nocon  
	eststo nocon_ols
	estadd local hasdivfe 		"N"
	estadd local hasbaseline 	"N"
	estadd local hasemp		 	"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $nocon  
	eststo nocon
	estadd scalar fstat=`fstat'
		
	reg $x_ols $x_iv $divfe 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $divfe    
	eststo divfe_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"N"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv )  $divfe    
	eststo divfe
	estadd scalar fstat=`fstat'
	
	reg $x_ols $x_iv $baseline 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $baseline 
	eststo baseline_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $baseline 
	eststo baseline
	estadd scalar fstat=`fstat'
	
	reg $x_ols $x_iv $emp 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $emp  
	eststo emp_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"Y"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $emp  
	eststo emp
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $flexbpop40 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $flexbpop40  
	eststo flexbpop40_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"Y"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y"

	ivreg2 `y' ($x_ols = $x_iv ) $flexbpop40  
	eststo flexbpop40
	estadd scalar fstat=`fstat'
	
	reg $x_ols $x_iv $swmig 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $swmig  
	eststo swmig_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"Y"
	estadd local haseurmig		"N"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 

	ivreg2 `y' ($x_ols = $x_iv ) $swmig  
	eststo swmig
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $eurmig 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $eurmig  
	eststo eurmig_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp 		"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig	 	"N"
	estadd local haseurmig		"Y"
	estadd local hassupmob		"N"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv )  $eurmig  
	eststo eurmig
	estadd scalar fstat=`fstat'

	reg $x_ols $x_iv $supmob 
	test $x_iv = 0
	local fstat=`r(F)'

	reg `y' $x_ols $supmob  
	eststo supmob_ols
	estadd local hasdivfe 		"Y"
	estadd local hasbaseline 	"Y"
	estadd local hasemp			"N"
	estadd local hasflexbpop40	"N"
	estadd local hasswmig		"N"
	estadd local haseurmig		"N"
	estadd local hassupmob		"Y"	
	estadd local precisionwt 	"Y" 
	
	ivreg2 `y' ($x_ols = $x_iv ) $supmob  
	eststo supmob
	estadd scalar fstat= `fstat'
	
	cd "$figtab"
	esttab nocon divfe baseline flexbpop40 supmob  swmig eurmig emp using "main_robust_table_bmp25.tex", frag replace varwidth(25) label se ///
	stats( fstat, labels("First Stage F-Stat")) keep($x_ols) coeflabel(GM "GM (2SLS)")  nonumber ///
	nostar nomtitle nonotes nolines nogaps  substitute({table} {threeparttable}) prefoot(\cmidrule(lr){2-9})
	
	esttab nocon_ols divfe_ols baseline_ols flexbpop40_ols supmob_ols  swmig_ols eurmig_ols emp_ols  using "main_robust_table_bmp25.tex", frag append  varwidth(25) label se ///
	prehead("\\") coeflabel(GM "GM (OLS)") ///
	stats( r2  N  precisionwt hasdivfe hasbaseline hasflexbpop40 hassupmob hasswmig haseurmig hasemp , ///
	labels( "R-squared (OLS)" N "Precision Wt" "Census Div FE" "Baseline Controls"  "1940 Black Share Quartile FEs" "Southern Mob" ///
	"White South Mig" "Eur Mig"  "Emp Bartik" )) keep($x_ols)  nonumber  ///
	nostar nomtitle nonotes nolines prefoot(\cmidrule(lr){2-9}) postfoot(\cmidrule(lr){2-9})  substitute({table} {threeparttable}) 
			
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*V. Estimates cited in text.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------% 
	
	* Share of non-southern continental US total and Black population in sample CZs
	use $data/GM_cz_final_dataset.dta, clear
	merge 1:1 cz using $population/clean_bpopshare_1870_2000_cz.dta, keepusing(cz totpop2000 bpop2000 stateabbrv)
	g original_sample=(_merge==3)
	drop _merge
	g south= (stateabbrv == "AL" |stateabbrv == "AR" |stateabbrv == "FL" |stateabbrv == "GA" |stateabbrv == "KY" |stateabbrv == "LA" |stateabbrv == "MS" |stateabbrv == "NC" | ///
	stateabbrv == "OK" |stateabbrv == "SC" |stateabbrv == "TN" |stateabbrv == "TX" |stateabbrv == "WV" |stateabbrv == "VA" )
	drop if south==1
	
	g no_cz=1
	
	collapse (sum) totpop2000 bpop2000 no_cz, by(original_sample)
	g id=1
	reshape wide totpop2000 bpop2000 no_cz, i(id) j(original_sample)
	
	g share_pop_original_sample = totpop20001/(totpop20001+totpop20000)
	g share_bpop_original_sample = bpop20001/(bpop20001+bpop20000)
	
	local share_pop_original_sample = share_pop_original_sample *100
	local share_bpop_original_sample = share_bpop_original_sample *100
	PrintEst `share_pop_original_sample' "share_pop_original_sample" "" "%" "4.0"	
	PrintEst `share_bpop_original_sample' "share_bpop_original_sample" "" "%" "4.0"	
	
	* Correlation between 1940 upward mobility and 2015 upward mobility for continental US (where both measures are available--721 CZs)
	use $mobdata/clean_cz_mobility_1900_2015.dta, clear
	corr frac_all_upm1940 kfr_pooled_pooled_p252015
	local mobmeasurecorr : di r(rho)
	PrintEst `mobmeasurecorr' "mobmeasurecorr" "" "%" "4.2"
	
	* Correlation between 2015 income and educational upward mobility for continental US
	use $mobdata/clean_cz_mobility_1900_2015.dta, clear
	corr kfr_pooled_pooled_p252015 hs_pooled_pooled_p25
	local incedumobcorr : di r(rho)
	PrintEst `incedumobcorr' "incedumobcorr" "" "%" "4.2"

	* Correlation between Great Migration and baseline 1940 covariates
	use ${data}/GM_cz_final_dataset.dta, clear
	corr GM frac_all_upm1940
	local gmeduupmcorr: di r(rho)
	PrintEst `gmeduupmcorr' "gmeduupmcorr" "" "%" "4.2"
	
	corr GM mfg_lfshare1940
	local gmmfgsharcorr: di r(rho)
	PrintEst `gmmfgsharcorr' "gmmfgsharcorr" "" "%" "4.2"
	
	corr GM v2_blackmig3539_share1940
	local gmrecblkmig: di r(rho)
	PrintEst `gmrecblkmig' "gmrecblkmig" "" "%" "4.2"	
	
	corr bpopchange1940_1970 bpopshare1940
	local bpopchangebpopshare1940: di r(rho)
	PrintEst `bpopchangebpopshare1940' "bpopchangebpopshare1940" "" "%" "4.2"	
	
	
	*Correlation between years of manufacturing share
	use ${data}/GM_cz_final_dataset.dta, clear
	
	corr mfg_lfshare1950 mfg_lfshare1940
	local mfgshar4050corr: di r(rho)
	PrintEst `mfgshar4050corr' "mfgshar4050corr" "" "%" "4.2"
	
	corr mfg_lfshare1970 mfg_lfshare1940
	local mfgshar4070corr: di r(rho)
	PrintEst `mfgshar4070corr' "mfgshar4070corr" "" "%" "4.2"
	
