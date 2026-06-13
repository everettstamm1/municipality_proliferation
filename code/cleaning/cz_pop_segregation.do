
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)



duplicates drop


makeDissimilarity , gen(pop_diss_bl_cz) mingroup(place_bpop2010) majgroup(place_pop2010) id(GEOID) agg_id(cz) onegroup

makeDissimilarity , gen(pop_diss_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) id(GEOID) agg_id(cz)

makeVR , gen(pop_vr_bl_cz) mingroup(place_bpop2010) majgroup(place_pop2010) id(GEOID) agg_id(cz) onegroup

makeVR , gen(pop_vr_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) id(GEOID) agg_id(cz)

keep cz pop_*
duplicates drop 
save "$INTDATA/cz_pop_segregation", replace