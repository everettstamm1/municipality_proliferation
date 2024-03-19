use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white, cz_new_prop_white)

qui sum GM_hat_raw, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_hat_raw - `cmin')/(`cmax' - `cmin'))

local base tw (pcarrow order cz_prop_white order cz_new_prop_white,  mcol(black) lcol(black)) (scatter order cz_prop_white, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof c255, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local rgb = "`: di 255-`l'' 0 `: di `l''"
	local base `base' (pcarrow order cz_prop_white order cz_new_prop_white if c255==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white if c255==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if c255==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Above Median Values of Instrument" 5 "Below Median Values of Instrument")) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))
graph export "$FIGS/pcarrow_figure_GM.pdf", replace as(pdf)

	
use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white, cz_new_prop_white)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_raw_pp - `cmin')/(`cmax' - `cmin'))

local base tw (pcarrow order cz_prop_white order cz_new_prop_white,  mcol(black) lcol(black)) (scatter order cz_prop_white, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof c255, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local rgb = "`: di 255-`l'' 0 `: di `l''"
	local base `base' (pcarrow order cz_prop_white order cz_new_prop_white if c255==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white if c255==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if c255==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Above Median Values of GM" 5 "Below Median Values of GM")) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))

		 	graph export "$FIGS/pcarrow_figure_GM_hat.pdf", replace as(pdf)

	
	
		 
/*
twoway (pcarrow order cz_prop_white order cz_new_prop_white)  ///
		(scatter order cz_prop_white, ms(oh) barbsize(2))  ///
		(scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol(black)),  ///
		yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities" 2 "CZ Total" )) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))
graph export "$FIGS/pcarrow_figure.pdf", replace as(pdf)

sysuse auto, clear
tw (scatter price mpg, mco(orange) leg(order(2) label(2 "Price"))) ///
   (function y=5000, ra(20 20) lco(orange) lw(*5) lpat(solid))
*/