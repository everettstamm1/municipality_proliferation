use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white1970
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white1970, cz_new_prop_white1970)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_hat_raw - `cmin')/(`cmax' - `cmin'))

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
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Below Median Values of Instrument" 5 "Above Median Values of Instrument")) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))
graph export "$FIGS/pcarrow_figure_GM.pdf", replace as(pdf)

	
use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white1970
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white1970, cz_new_prop_white1970)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_raw_pp - `cmin')/(`cmax' - `cmin'))

local base tw (pcarrow order cz_prop_white1970 order cz_new_prop_white1970,  mcol(black) lcol(black)) (scatter order cz_prop_white1970, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof c255, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local rgb = "`: di 255-`l'' 0 `: di `l''"
	local base `base' (pcarrow order cz_prop_white1970 order cz_new_prop_white1970 if c255==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white1970 if c255==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if c255==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Above Median Values of GM" 5 "Below Median Values of GM")) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))

		 	graph export "$FIGS/pcarrow_figure_GM_hat.pdf", replace as(pdf)

	
	
// 2010



use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white2010
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white2010, cz_new_prop_white2010)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_raw_pp - `cmin')/(`cmax' - `cmin'))

local base tw (pcarrow order cz_prop_white2010 order cz_new_prop_white2010,  mcol(black) lcol(black)) (scatter order cz_prop_white2010, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof c255, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local rgb = "`: di 255-`l'' 0 `: di `l''"
	local base `base' (pcarrow order cz_prop_white2010 order cz_new_prop_white1970 if c255==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white2010 if c255==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if c255==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Above Median Values of GM" 5 "Below Median Values of GM")) ///
		 xtitle("Proportion of Population White, 2010") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))

		 	graph export "$FIGS/pcarrow_figure_GM_hat_2010.pdf", replace as(pdf)

/*
twoway (pcarrow order cz_prop_white1970 order cz_new_prop_white1970)  ///
		(scatter order cz_prop_white1970, ms(oh) barbsize(2))  ///
		(scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol(black)),  ///
		yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities" 2 "CZ Total" )) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))
graph export "$FIGS/pcarrow_figure.pdf", replace as(pdf)

sysuse auto, clear
tw (scatter price mpg, mco(orange) leg(order(2) label(2 "Price"))) ///
   (function y=5000, ra(20 20) lco(orange) lw(*5) lpat(solid))
*/



// White

use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white1970
g order = _n
labmask order, values(cz_name)

g namepos = max(cz_prop_white2010, cz_new_prop_white2010)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_raw_pp - `cmin')/(`cmax' - `cmin'))

local base tw (pcarrow order cz_prop_white2010 order cz_new_prop_white2010,  mcol(black) lcol(black)) (scatter order cz_prop_white2010, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof c255, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local rgb = "`: di 255-`l'' 0 `: di `l''"
	local base `base' (pcarrow order cz_prop_white2010 order cz_new_prop_white2010 if c255==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white2010 if c255==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if c255==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Above Median Values of GM" 5 "Below Median Values of GM")) ///
		 xtitle("Proportion of Population White, 2010") ysize(9) xscale(range(0 100)) xla(30(10)100) graphregion(color(white))

		 	graph export "$FIGS/pcarrow_figure_GM_hat_2010.pdf", replace as(pdf)


// Asian (SWITCH DATA)
use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_prop_white2010
g order = _n
labmask order, values(cz_name)

g namepos = max(cz_prop_white2010, cz_new_prop_white2010)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
g c255 = round(255*(GM_raw_pp - `cmin')/(`cmax' - `cmin'))

local base tw (pcarrow order cz_prop_white2010 order cz_new_prop_white2010,  mcol(black) lcol(black)) (scatter order cz_prop_white2010, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(3) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof c255, local(levels)
local i 0
foreach l of local levels{
	local i = `i'+1
	local rgb = "`: di 255-`l'' 0 `: di `l''"
	local base `base' (pcarrow order cz_prop_white2010 order cz_new_prop_white2010 if c255==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_prop_white2010 if c255==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if c255==`l', ms(none) mlabel(cz_name) mlabpos(3) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Above Median Values of GM" 5 "Below Median Values of GM")) ///
		 xtitle("Proportion of Population Asian, 2010") ysize(9) xscale(range(0 50)) xla(0(10)50) graphregion(color(white))

		 	graph export "$FIGS/pcarrow_figure_GM_hat_2010_asian.pdf", replace as(pdf)
			
// 2010 Incomes
use "$CLEANDATA/pcarrow_fig_data", clear
gsort -cz_inc2010
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_inc2010, cz_new_inc2010)

qui sum GM_raw_pp, d
local cmin = r(min)
local cmax = r(max)
//g c255 = round(255*(GM_raw_pp - `cmin')/(`cmax' - `cmin'))

g pctile_diff = 100*(cz_new_inc2010 - cz_inc2010)/cz_inc2010
su pctile_diff if above_x_med == 0
local belowdif : di %5.2f r(mean)
su pctile_diff if above_x_med == 1
local abovediff : di %5.2f r(mean)

local base tw (pcarrow order cz_inc2010 order cz_new_inc2010,  mcol(black) lcol(black)) (scatter order cz_inc2010, ms(oh) barbsize(2) mlcol(black) mfcol(black)) (scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2)) (function y=80, ra(80 80) lcol("`: di 0' 0 `: di 255'") lpat(solid) lw(*5)) (function y=80, ra(80 80) lcol("`: di 255' 0 `: di 0'") lpat(solid) lw(*5))
levelsof above_x_med, local(levels)
local i 0

foreach l of local levels{
	local i = `i'+1
	local ll = mod(`l'+1,2)
	local rgb = "`: di 255*`l'' 0 `: di `ll'*255'"
	local base `base' (pcarrow order cz_inc2010 order cz_new_inc2010 if above_x_med==`l', mcol("`rgb'") lcol("`rgb'")) ///
						(scatter order cz_inc2010 if above_x_med==`l', ms(oh) barbsize(2) mlcol("`rgb'") mfcol("`rgb'")) ///
						(scatter order namepos if above_x_med==`l', ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol("`rgb'"))
}
local colpos = `i'*3+1
 `base', yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities"  2 "CZ Total" 4 "Below Median Values of Instrument" 5 "Above Median Values of Instrument")) ///
		 xtitle("Average Household Income, 2010") ysize(9) xscale(range(0 150000)) xla(0(25000)150000) graphregion(color(white)) note("Above Median Average Difference: `abovediff'%" "Below Median Average Difference: `belowdif'%")
graph export "$FIGS/pcarrow_figure_inc2010.pdf", replace as(pdf)
