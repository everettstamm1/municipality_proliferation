



use "$INTDATA/census/place_race_pop.dta", clear
keep if in_cgoodman_data == 1

ren czone cz
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(GM_raw_pp above_x_med cz cz_name )


bys cz : egen cz_new_pop1970 = total(place_pop1970) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_bpop1970 = total(place_bpop1970) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_wpop1970 = total(place_wpop1970) if yr_incorp >=1940 & yr_incorp<=1970

bys cz (cz_new_pop1970): replace cz_new_pop1970 = cz_new_pop1970[1]
bys cz (cz_new_bpop1970): replace cz_new_bpop1970 = cz_new_bpop1970[1]
bys cz (cz_new_wpop1970): replace cz_new_wpop1970 = cz_new_wpop1970[1]

g cz_new_prop_white1970 = 100*(cz_new_wpop1970 / cz_new_pop1970)

preserve
	keep statefips placefips cz yr_incorp
	tempfile incorps
	save `incorps'
	
	use "$INTDATA/census/1970_hh_incomes_hv", clear
	ren PLACEFP placefips
	ren STATEFP statefips
	merge 1:1 cz statefips placefips using `incorps', keep(1 3) nogen
	replace agg_fam_inc_place1970 = . if (yr_incorp < 1940 & yr_incorp > 1970)
	replace famcount = . if (yr_incorp < 1940 & yr_incorp > 1970)
	collapse (sum) agg_fam_inc_place1970 famcount, by(cz agg_fam_inc_cz1970)
	g cz_new_inc1970 = agg_fam_inc_place1970 / famcount
	ren agg_fam_inc_cz1970 cz_inc1970
	keep cz cz_inc1970 cz_new_inc1970
	duplicates drop
	tempfile economic1970
	save `economic1970'
restore 

merge m:1 cz using `economic1970', keep(1 3) nogen


keep cz cz_name cz_* above_x_med GM_raw_pp
duplicates drop

merge 1:1 cz using "$INTDATA/census/cz_race_pop1970", keep(3) nogen

replace cz_name = "Louisville, KY/IN" if cz==13101

replace cz_new_inc1970 = . if mi(cz_new_wpop1970)
replace cz_inc1970 = . if mi(cz_new_wpop1970)
save "$CLEANDATA/pcarrow_fig_data", replace
