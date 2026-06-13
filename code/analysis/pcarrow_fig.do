use "$CLEANDATA/pcarrow_fig_data", clear
drop if mi(cz_new_prop_white1970)
gsort -cz_prop_white1970
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white1970, cz_new_prop_white1970)

keep if cz_new_prop_white1970 < .

// Want above median split for this sample
drop above_x_med
su GM_raw_pp, d
g above_x_med = GM_raw_pp >= r(p50)

g pctile_diff = 100*(cz_new_prop_white1970 - cz_prop_white1970)/cz_prop_white1970
su pctile_diff if above_x_med == 0 
local belowdif : di %5.2f r(mean)
su pctile_diff if above_x_med == 1
local abovediff : di %5.2f r(mean)

local base tw (pcarrow order cz_prop_white1970 order cz_new_prop_white1970,  mcol(black) lcol(black)) (scatter order cz_prop_white1970, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof above_x_med, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local ll = mod(`l'+1,2)
	local rgb = "`: di 255*`l'' 0 `: di `ll'*255'"
	local base `base' (pcarrow order cz_prop_white1970 order cz_new_prop_white1970 if above_x_med==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white1970 if above_x_med==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if above_x_med==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Below Median Values of GM" 5 "Above Median Values of GM") position(7) ring(0) symxsize(2.5) size(2.8)) ///
		 xtitle("Proportion of Population White, 1970") ysize(12) xscale(range(65 100)) xla(65(5)100) graphregion(color(white)) note("Above median average difference: `abovediff'%" "Below median average difference: `belowdif'%")
graph export "$FIGS/F3a.pdf", replace as(pdf)

	
// 1970 Incomes
use "$CLEANDATA/pcarrow_fig_data", clear
keep if !mi(cz_new_inc1970) & !mi(cz_new_prop_white1970)
gsort -cz_inc1970
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_inc1970, cz_new_inc1970)

// Want above median split for this sample
drop above_x_med
keep if cz_new_prop_white1970 < .
su GM_raw_pp, d
g above_x_med = GM_raw_pp >= r(p50)


g pctile_diff = 100*(cz_new_inc1970 - cz_inc1970)/cz_inc1970
su pctile_diff if above_x_med == 0
local belowdif : di %5.2f r(mean)
su pctile_diff if above_x_med == 1
local abovediff : di %5.2f r(mean)

local base tw (pcarrow order cz_inc1970 order cz_new_inc1970,  mcol(black) lcol(black)) (scatter order cz_inc1970, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2))  (function y=80, ra(7000 7000) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(7000 7000) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof above_x_med, local(levels)
local i 0

foreach l of local levels{
	local i = `i'+1
	local ll = mod(`l'+1,2)
	local rgb = "`: di 255*`l'' 0 `: di `ll'*255'"
	local base `base' (pcarrow order cz_inc1970 order cz_new_inc1970 if above_x_med==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_inc1970 if above_x_med==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if above_x_med==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("")  ///
		 xtitle("Average Household Income, 1970") ysize(12) xscale(range(6900 15000)) xla(7500(2500)15000) graphregion(color(white)) note("Above median average difference: `abovediff'%" "Below median average difference: `belowdif'%") legend(off)
graph export "$FIGS/F3b.pdf", replace as(pdf)
