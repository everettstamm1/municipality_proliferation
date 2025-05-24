
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)


drop wtasenroll totenroll_leaid blenroll wtenroll   leaid   psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid cs_mn_* number_of_schools pct_white fips sedaleaname area  stu_diss_bl_cz stu_diss_blwt_cz achievement_diss_blwt_cz achievement_diss_bl_cz stu_RCO_blwt_cz stu_A_05_blwt_cz stu_A_01_blwt_cz stu_A_09_blwt_cz stu_SP_touch_blwt_cz stu_SP_nexpd_blwt_cz stu_vr_bl_cz stu_vr_blwt_cz achievement_VR_blwt_cz achievement_* totenroll_*

duplicates drop
unique STATEFP PLACEFP
assert _N == r(N)

replace len_edge_edge = len_edge_edge/1610
replace len_center_edge = len_center_edge/1610
lab var len_edge_edge "Length to Edge of Principle City (Miles)"
lab var len_center_edge "Length to Center of Principle City (Miles)"

twoway (hist len_edge_edge if samp_dest == 1 & above_x_med == 1, start(0) width(10) col(red%30) freq) ///
(hist len_edge_edge if samp_dest == 1 & above_x_med == 0, col(blue%30) start(0) width(10) freq), legend(order(1 "Above Median GM" 2 "Below Median GM")) 

graph export "$FIGS/implications/dist_edge_edge_4070.pdf", as(pdf) replace

twoway (hist len_center_edge if samp_dest == 1 & above_x_med == 1, start(0) width(10) col(red%30) freq) ///
(hist len_center_edge if samp_dest == 1 & above_x_med == 0, col(blue%30) start(0) width(10) freq), legend(order(1 "Above Median GM" 2 "Below Median GM")) 

graph export "$FIGS/implications/dist_center_edge_4070.pdf", as(pdf) replace
