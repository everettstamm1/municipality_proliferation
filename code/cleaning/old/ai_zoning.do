// Cleaning AI zoning data

import excel using "$RAWDATA/other/ai_zoning/ai_zoning.xlsx", clear first
ren FIPS_STATE STATEFP 
ren FIPS_PLACE PLACEFP

ren Question2 n_zoning_districts
ren Question4 mf
ren Question5 mixed_use
ren Question6 mf_conversion_allowed
ren Question8 attached_sfr
ren Question9 age_restrictions
ren Question11 adu
ren Question13 flex_zoning_br // good
ren Question14 flex_zoning_sp
ren Question17 inclusionary_zoning // good
ren Question17w inclusionary_zoning_comply
ren Question20 permit_cap_phasing // good
ren Question21 lot_size_nature_restriction
ren Question22 max_frontage_req_sfr
ren Question28Mean min_lot_size_mean
ren Question28Max min_lot_size_max // one of these
ren Question28Min min_lot_size_min
ren Question30 n_steps_mf
ren Question31 n_approving_agencies
ren Question32 mf_public_hearing
ren Question34 max_review_days
drop Source CENSUS_ID_PID6 FIPS_COUNTY
save "$INTDATA/other/ai_zoning.dta", replace

