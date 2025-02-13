

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll_leaid blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname area  stu_diss_bl_cz stu_diss_blwt_cz achievement_diss_blwt_cz achievement_diss_bl_cz stu_RCO_blwt_cz stu_A_05_blwt_cz stu_A_01_blwt_cz stu_A_09_blwt_cz stu_SP_touch_blwt_cz stu_SP_nexpd_blwt_cz stu_vr_bl_cz stu_vr_blwt_cz achievement_VR_blwt_cz achievement_* totenroll_*

duplicates drop

drop totexp19*  ltotexp19* ltotexp_pc19*

g l_hv_1970 = log(agg_house_value_place1970)
ren totexp_pc197* ltotexp_pc197*

reghdfe l_hv_1970 ltotexp_pc1970 samp_dest above_x_med samp_destXabove_x_med ltotexp_pc1970_above_x_med ltotexp_pc1970_samp_dest ltotexp_pc1970_both reg2 reg3 reg4  v2_sumshares_urban coastal transpo_cost_1920  mean_uninc1940 cz_popdens1940 growth3040 [aw=weight_pop], vce(cl cz)
test ltotexp_pc1970_above_x_med + ltotexp_pc1970_both = 0
local unincorp_below = _b[ltotexp_pc1970]
local unincorp_above = _b[ltotexp_pc1970] + _b[ltotexp_pc1970_above_x_med]
local incorp_below = _b[ltotexp_pc1970] + _b[ltotexp_pc1970_samp_dest]
local incorp_above = _b[ltotexp_pc1970] + _b[ltotexp_pc1970_samp_dest] + _b[ltotexp_pc1970_above_x_med] + _b[ltotexp_pc1970_both]

di "Not 1940-70 Incorporated and Below Median CZ Effect: `unincorp_below'"
di "1940-70 Incorporated and Below Median CZ Effect: `incorp_below'"
di "Not 1940-70 Incorporated and Above Median CZ Effect: `unincorp_above'"
di "1940-70 Incorporated and Above Median CZ Effect: `incorp_above'"


g ltotexp = log(totalexpenditure/place_pop2010)
g ltotexp_samp_dest = ltotexp * samp_dest
g ltotexp_above_x_med = ltotexp * above_x_med
g ltotexp_both = ltotexp * above_x_med * samp_dest
g lmed_hv_place = log(med_hv_place)

drop ltotexp_pc19*

reghdfe lmed_hv_place ltotexp samp_dest above_x_med samp_destXabove_x_med ltotexp_samp_dest ltotexp_above_x_med ltotexp_both reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 [aw=weight_pop], vce(cl cz)
test ltotexp_above_x_med + ltotexp_both = 0

local unincorp_below = _b[ltotexp]
local unincorp_above = _b[ltotexp] + _b[ltotexp_above_x_med]
local incorp_below = _b[ltotexp] + _b[ltotexp_samp_dest]
local incorp_above = _b[ltotexp] + _b[ltotexp_samp_dest] + _b[ltotexp_above_x_med] + _b[ltotexp_both]

di "Not 1940-70 Incorporated and Below Median CZ Effect: `unincorp_below'"
di "1940-70 Incorporated and Below Median CZ Effect: `incorp_below'"
di "Not 1940-70 Incorporated and Above Median CZ Effect: `unincorp_above'"
di "1940-70 Incorporated and Above Median CZ Effect: `incorp_above'"