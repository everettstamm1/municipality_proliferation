
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1 | mi(cz)

duplicates drop
unique STATEFP PLACEFP
assert _N == r(N)

replace len_edge_edge = len_edge_edge/1610
replace len_center_edge = len_center_edge/1610
lab var len_edge_edge "Length to Edge of Principle City (Miles)"
lab var len_center_edge "Length to Center of Principle City (Miles)"

twoway (hist len_edge_edge if samp_dest == 1 & above_x_med == 1, start(0) width(10) col(red%30) freq) ///
(hist len_edge_edge if samp_dest == 1 & above_x_med == 0, col(blue%30) start(0) width(10) freq), legend(order(1 "Above Median GM" 2 "Below Median GM")) 

graph export "$FIGS/FA5a.pdf", as(pdf) replace

twoway (hist len_center_edge if samp_dest == 1 & above_x_med == 1, start(0) width(10) col(red%30) freq) ///
(hist len_center_edge if samp_dest == 1 & above_x_med == 0, col(blue%30) start(0) width(10) freq), legend(order(1 "Above Median GM" 2 "Below Median GM")) 

graph export "$FIGS/FA5b.pdf", as(pdf) replace
