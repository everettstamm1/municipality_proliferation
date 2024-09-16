
import delimited using "$RAWDATA/census/nhgis0019_csv/nhgis0019_ds94_1970_county.csv", clear
drop if statea == 2 | statea == 15 // drop alaska hawaii

replace statea = statea*10
replace countya = countya*10

egen pop = rowtotal(cbw*) 
g wpop = cbw001
g bpop = cbw002

keep year statea countya pop bpop wpop

ren statea nhgisst
ren countya nhgiscty

merge 1:m year nhgisst nhgiscty using "$XWALKS/consistent_1940_1970", keep(3) nogen
g cz_pop1970 = pop*weight
g cz_bpop1970 = bpop*weight
g cz_wpop1970 = wpop*weight


collapse (sum) cz_pop1970 cz_bpop1970 cz_wpop1970, by(year nhgisst_1990 nhgiscty_1990)
ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
ren cty_fips fips
ren czone cz

drop if cz_pop1970 ==.
collapse (sum) cz_pop1970 cz_bpop1970 cz_wpop1970, by(cz)
g cz_prop_white1970 = 100*(cz_wpop1970 / cz_pop1970)
su cz_prop_white1970 ,d
save "$INTDATA/census/cz_race_pop1970", replace

import delimited "$RAWDATA/census/county_race_1950_2020/nhgis0017_ts_nominal_county.csv", clear
drop if statefp == 2 | statefp == 15 // drop alaska hawaii

egen cz_pop = rowtotal(b18*) 
g cz_wpop = b18aa
g cz_bpop = b18ab
g cz_apop = b18ad
g cty_fips = 1000*statefp+countyfp
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen
keep year cty_fips czone  cz_pop cz_wpop cz_apop cz_bpop

collapse (sum) cz_pop cz_bpop cz_wpop cz_apop, by(czone year)
g cz_prop_white = 100*(cz_wpop / cz_pop)
g cz_prop_asian = 100*(cz_apop / cz_pop)

//drop cz_pop cz_wpop cz_apop
drop if year == 1970

reshape wide cz_prop_white cz_prop_asian cz_pop cz_wpop cz_apop cz_bpop, i(czone) j(year)
ren czone cz

save "$INTDATA/census/cz_race_pop.dta", replace



use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear

destring statefips countyfips placefips, replace
drop if statefips == 02 | statefips==15
g cty_fips = 1000*statefips+countyfips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen
keep statefips placefips czone yr_incorp
replace yr_incorp = yr_incorp-2

tempfile incorps
save `incorps'

import delimited using "$RAWDATA/census/nhgis0027_csv/nhgis0027_csv/nhgis0027_ts_nominal_place.csv", clear
egen place_pop1970 = rowtotal(b18aa1970 b18ab1970 b18ac1970 b18ad1970)
g place_wpop1970 = b18aa1970
g place_bpop1970 = b18ab1970

egen place_pop2010 = rowtotal(b18aa2010 b18ab2010 b18ac2010 b18ad2010)
g place_wpop2010 = b18aa2010
g place_bpop2010 = b18ab2010

// Dropping duplicated unincorporated towns
duplicates tag placea statefp, gen(dup)
drop if dup == 1 & regexm(name1970,"(U)")
drop if placea == 625 & statefp == 12 // duplicate, from Florida so not used for us anyway
drop if placea == 3052 & statefp == 27 & name1970 == "" // duplicate, dropping the one missing the name in 1970
drop if placea== 1990 & statefp == 34 & name1980 == "GORDON@S CORNER %CDP<"
keep place_* placea statefp
ren placea placefips
ren statefp statefips

merge 1:1 placefips statefips using `incorps', keep(1 3) 
g in_cgoodman_data = _merge == 3
drop _merge

save "$CLEANDATA/place_race_pop.dta", replace

keep if in_cgoodman_data == 1

ren czone cz
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(above_x_med dcourt cz cz_name GM_hat_raw_pp GM_raw_pp)
keep if dcourt == 1

bys cz : egen cz_new_pop1970 = total(place_pop1970) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_bpop1970 = total(place_bpop1970) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_wpop1970 = total(place_wpop1970) if yr_incorp >=1940 & yr_incorp<=1970

bys cz (cz_new_pop1970): replace cz_new_pop1970 = cz_new_pop1970[1]
bys cz (cz_new_bpop1970): replace cz_new_bpop1970 = cz_new_bpop1970[1]
bys cz (cz_new_wpop1970): replace cz_new_wpop1970 = cz_new_wpop1970[1]


bys cz : egen cz_new_pop2010 = total(place_pop2010) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_bpop2010 = total(place_bpop2010) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_wpop2010 = total(place_wpop2010) if yr_incorp >=1940 & yr_incorp<=1970

bys cz (cz_new_pop2010): replace cz_new_pop2010 = cz_new_pop2010[1]
bys cz (cz_new_bpop2010): replace cz_new_bpop2010 = cz_new_bpop2010[1]
bys cz (cz_new_wpop2010): replace cz_new_wpop2010 = cz_new_wpop2010[1]


g cz_new_prop_white1970 = 100*(cz_new_wpop1970 / cz_new_pop1970)
g cz_new_prop_white2010 = 100*(cz_new_wpop2010 / cz_new_pop2010)


preserve
	keep statefips placefips cz yr_incorp
	tempfile incorps
	save `incorps'
	
	use "$INTDATA/census/2010_hh_incomes", clear
	ren PLACEFP placefips
	ren STATEFP statefips
	merge 1:1 cz statefips placefips using `incorps', keep(1 3) nogen
	bys cz : egen cz_new_inc2010 = mean(mean_hh_inc_place) if (yr_incorp >= 1940 & yr_incorp <= 1970)
	bys cz (cz_new_inc2010): replace cz_new_inc2010 = cz_new_inc2010[1]
	ren mean_hh_inc_cz cz_inc2010
	keep cz cz_inc2010 cz_new_inc2010
	duplicates drop
	tempfile economic
	save `economic'
restore 

merge m:1 cz using `economic', keep(1 3) nogen
keep cz cz_name cz_* GM_* above_x_med
duplicates drop

merge 1:1 cz using "$INTDATA/census/cz_race_pop1970", keep(3) nogen
merge 1:1 cz using "$INTDATA/census/cz_race_pop", keep(3) nogen

keep if cz_new_prop_white1970 != . 
replace cz_name = "Louisville, KY/IN" if cz==13101


save "$CLEANDATA/pcarrow_fig_data", replace
