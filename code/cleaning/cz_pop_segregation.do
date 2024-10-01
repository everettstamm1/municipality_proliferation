
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname

duplicates drop


makeDissimilarity , gen(pop_diss_bl_cz) mingroup(place_bpop2010) majgroup(place_pop2010) id(GEOID) agg_id(cz) onegroup

makeDissimilarity , gen(pop_diss_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) id(GEOID) agg_id(cz)

makeVR , gen(pop_vr_bl_cz) mingroup(place_bpop2010) majgroup(place_pop2010) id(GEOID) agg_id(cz) onegroup

makeVR , gen(pop_vr_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) id(GEOID) agg_id(cz)

makeRCO, gen(pop_RCO_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) id(GEOID) area(place_land) agg_id(cz) 

makeAtkinson, gen(pop_A_05_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) agg_id(cz) id(GEOID) b(0.5)

makeAtkinson, gen(pop_A_09_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) agg_id(cz) id(GEOID) b(0.9)

makeAtkinson, gen(pop_A_01_blwt_cz) mingroup(place_bpop2010) majgroup(place_wpop2010) agg_id(cz) id(GEOID) b(0.1)


makeSP, gen(pop_SP_touch_blwt_cz)  mingroup(place_bpop2010) majgroup(place_wpop2010) agg_id(cz) distances("$CLEANDATA/other/touching_dist_munis.dta") id(GEOID)

makeSP, gen(pop_SP_nexpd_blwt_cz)  mingroup(place_bpop2010) majgroup(place_wpop2010) agg_id(cz) distances("$CLEANDATA/other/touching_dist_munis.dta") id(GEOID) nexpd



keep cz pop_*
duplicates drop 
drop if pop_RCO_blwt_cz == .
save "$INTDATA/cz_pop_segregation", replace