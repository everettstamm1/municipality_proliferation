
use "$CLEANDATA/cz_pooled.dta", clear 
keep cz_name popc* bpopc*
//need : bpopc1950, 60; popc1960, outcomes 1960
keep if cz_name=="Cleveland, OH" | cz_name=="Columbus, OH" 
reshape long popc bpopc, i(cz_name) j(decade)
label var decade "Year"
gen share=bpopc/popc

twoway (scatter share decade if cz_name=="Cleveland, OH", connect(direct) msymbol(square) mcolor(gold) lcolor(gold)) ///
(scatter share decade if cz_name=="Columbus, OH", connect(direct) mcolor(midgreen) lcolor(midgreen)), ///
legend(order(2 "Columbus, OH" 1 "Cleveland, OH") position(6)) scheme(s1color) ytitle("Urban Black Population Share") 

graph export "$FIGS/motivation/design_panelb_new.pdf", as(pdf) replace 

use "$CLEANDATA/cz_pooled.dta", clear

keep if cz_name=="Cleveland, OH" | cz_name=="Columbus, OH" 

keep cz_name b_gen_muni_cz*_pc b_schdist_ind_cz*_pc b_cgoodman_cz*_pc b_gen_muni_cz???? b_schdist_ind_cz???? b_cgoodman_cz????

ren *_cz????_pc *_cz_pc????

reshape long b_gen_muni_cz b_schdist_ind_cz  b_cgoodman_cz b_gen_muni_cz_pc b_schdist_ind_cz_pc  b_cgoodman_cz_pc, i(cz_name) j(decade)
keep if decade>=1940 & decade<=1970

label var b_schdist_ind_cz_pc "School Districts Per 10,000 People"
label var b_cgoodman_cz_pc "Goodman Munis Per 10,000 People"
label var b_gen_muni_cz_pc "Census Govts Munis Per 10,000 People"
label var b_schdist_ind_cz "Total School Districts"
label var b_cgoodman_cz "Total Goodman Munis"
label var b_gen_muni_cz "Total Census Govts Munis"
label var decade "Year"

twoway (scatter b_cgoodman_cz decade if cz_name=="Cleveland, OH", connect(direct) msymbol(square) mcolor(gold) lcolor(gold)) ///
(scatter b_cgoodman_cz decade if cz_name=="Columbus, OH", connect(direct) mcolor(midgreen) lcolor(midgreen)) ///
(scatter b_schdist_ind_cz decade if cz_name=="Cleveland, OH", connect(direct) msymbol(square) mcolor(gold) lcolor(gold) lpattern(dash)) ///
(scatter b_schdist_ind_cz decade if cz_name=="Columbus, OH", connect(direct) mcolor(midgreen) lcolor(midgreen) lpattern(dash)), ///
legend(off) scheme(s1color) ytitle("Count of Jurisdictions") /// 
text(157 1951 "{it:School Districts}" "{it:(Dashed Lines)}", size(.28cm)) text(71 1944 "{it:Municipalities}" "{it:Incorporated}" "{it:(Solid Lines)}", size(.28cm))

graph export "$FIGS/motivation/design_panelc_new.pdf", as(pdf) replace 
