
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
g cz_prop_white = 100*(cz_wpop1970 / cz_pop1970)
tempfile cz_pops
save `cz_pops'

use "$RAWDATA/cbgoodman/muni_incorporation_date.dta", clear

destring statefips countyfips placefips, replace
drop if statefips == 02 | statefips==15
g cty_fips = 1000*statefips+countyfips
merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen
keep statefips placefips czone yr_incorp
replace yr_incorp = yr_incorp-2

tempfile incorps
save `incorps'

import delimited using "$RAWDATA/census/nhgis0022_csv/nhgis0022_ts_nominal_place.csv", clear
egen place_pop1970 = rowtotal(b18aa1970 b18ab1970 b18ac1970 b18ad1970)
g place_wpop1970 = b18aa1970
g place_bpop1970 = b18ab1970

// Dropping duplicated unincorporated towns
duplicates tag placea statefp, gen(dup)
drop if dup == 1 & regexm(name1970,"(U)")
drop if placea == 625 & statefp == 12 // duplicate, from Florida so not used for us anyway
drop if placea == 3052 & statefp == 27 & name1970 == "" // duplicate, dropping the one missing the name in 1970

keep place_* placea statefp
ren placea placefips
ren statefp statefips

merge 1:1 placefips statefips using `incorps', keep(3) nogen
ren czone cz
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(dcourt cz cz_name)
keep if dcourt == 1

bys cz : egen cz_new_pop1970 = total(place_pop1970) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_bpop1970 = total(place_bpop1970) if yr_incorp >=1940 & yr_incorp<=1970
bys cz : egen cz_new_wpop1970 = total(place_wpop1970) if yr_incorp >=1940 & yr_incorp<=1970

bys cz (cz_new_pop1970): replace cz_new_pop1970 = cz_new_pop1970[1]
bys cz (cz_new_bpop1970): replace cz_new_bpop1970 = cz_new_bpop1970[1]
bys cz (cz_new_wpop1970): replace cz_new_wpop1970 = cz_new_wpop1970[1]

g cz_new_prop_white = 100*(cz_new_wpop1970 / cz_new_pop1970)

keep cz cz_name cz_*
duplicates drop

merge 1:1 cz using `cz_pops', keep(3) nogen
keep if cz_new_prop_white != .
