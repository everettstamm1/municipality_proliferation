
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1
g one_school = n_schools == 1
g no_school = n_schools == 0
g prop_white_students = wtenroll_place / totenroll_place

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot
duplicates drop

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
