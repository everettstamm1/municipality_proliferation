

import delimited using "$RAWDATA/census/_IndFin_1967-2012/IndFin12b.txt", clear bindquote(loose)
tempfile dfb
save `dfb'

import delimited using "$RAWDATA/census/_IndFin_1967-2012/IndFin12c.txt", clear bindquote(loose)
tempfile dfc
save `dfc'

import delimited using "$RAWDATA/census/_IndFin_1967-2012/IndFin12a.txt", clear bindquote(loose)
merge 1:1 id using `dfb', assert(3) nogen
merge 1:1 id using `dfc', assert(3) nogen

keep if typecode==2 // Keeping only munis
tostring id, gen(census_id)
replace census_id = "0"+census_id if strlen(census_id)==8
replace census_id = census_id + "00000"

merge 1:1 census_id using "$XWALKS/cog_ID_fips_place_xwalk_02.dta", keep(3) nogen keepusing(fips_state fips_place_2002)

destring fips_state fips_place_2002, replace
save "$INTDATA/census/IndFin12", replace