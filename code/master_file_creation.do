// Merging different data sources into the census master file

// CoG directory surveys mostly easy as 
use "$INTDATA/cog/4_1_general_purpose_govts.dta", clear

g incorp_date1 = original_incorporation_date
g incorp_date2 = year_home_rule_adopted

// Documentation notes some inconsistencies in incorporation dates and home rule charters, so we'll take the earliest reported
bys id (incorp_date1) : replace incorp_date1 = incorp_date1[1] 
bys id (incorp_date2) : replace incorp_date2 = incorp_date2[1] 

g incorp_date3 = cond(incorp_date1<.,incorp_date1,incorp_date2)
drop if incorp_date3==.

// Observations that are duplicated for id and incorp_date*, but not name are pretty much all misspellings/obvious renamings. Forcing a drop.
bys id (name) : replace name = name[1]

keep id incorp_date* name
duplicates drop

ren name name_genpurp

g source = "cog_4_1"
g type = 1 

tempfile genpurp
save `genpurp'

use "$INTDATA/cog/4_2_special_districts.dta", clear

g incorp_date1 = incorporation_date
g incorp_date2 = .

// Documentation notes some inconsistencies in incorporation dates, so we'll take the earliest reported
bys id (incorp_date1) : replace incorp_date1 = incorp_date1[1] 

g incorp_date3 = cond(incorp_date1<.,incorp_date1,incorp_date2)
drop if incorp_date3==.


// Observations that are duplicated for id and incorp_date*, but not name are pretty much all misspellings/obvious renamings. Forcing a drop.
bys id (name) : replace name = name[1]

keep id incorp_date* name
duplicates drop

ren name name_spdist

g source = "cog_4_2"
g type = 2 

tempfile spdist
save `spdist'


use "$INTDATA/cog/master_2021.dta", clear

rename GID id
merge 1:1 id type using `genpurp', keep(1 3) nogen

