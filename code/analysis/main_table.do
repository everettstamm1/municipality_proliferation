
local use_sumshare = 1
local use_pct_inst = 1


// Controls
if `use_sumshare' == 0 local b_controls reg2 reg3 reg4 blackmig3539_share 
if `use_sumshare' == 1 local b_controls reg2 reg3 reg4 v2_sumshares_urban 


if `use_sumshare' == 0 & `use_pct_inst' == 0 local extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local extra_controls coastal transpo_cost_1920  
if `use_sumshare' == 1 & `use_pct_inst' == 1 local extra_controls coastal transpo_cost_1920  

// Inst
if `use_pct_inst' == 0 local inst GM_hat_raw_pp
if `use_pct_inst' == 1 local inst GM_hat_raw

// White inst
if `use_pct_inst' == 0 local winst GM_8_hat_raw
if `use_pct_inst' == 1 local winst GM_8_hat_raw_pp

// White controls
if `use_sumshare' == 0 local w_b_controls reg2 reg3 reg4 v8_whitemig3539_share1940 
if `use_sumshare' == 1 local w_b_controls reg2 reg3 reg4 v8_sumshares_urban 

if `use_sumshare' == 0 & `use_pct_inst' == 0 local w_extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local w_extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local w_extra_controls coastal transpo_cost_1920  
if `use_sumshare' == 1 & `use_pct_inst' == 1 local w_extra_controls coastal transpo_cost_1920  



use "$CLEANDATA/cz_pooled", clear

keep if dcourt == 1
lab var `inst' "$\widehat{GM}$"
lab var GM_raw_pp "GM"

qui su GM_raw_pp, d
g GM_raw_pp_recentered = GM_raw_pp - `r(mean)'

g GM_raw_pp_2 = GM_raw_pp^2
g GM_hat_raw_2 = GM_hat_raw^2
qui su GM_hat_raw_pp, d
g GM_hat_raw_pp_recentered = GM_hat_raw_pp - `r(mean)'
lab var GM_hat_raw_pp_recentered "$\widehat{GM}$, recentered"
lab var GM_raw_pp_recentered "GM, recentered"
g order = frac_total^2

qui su prop_enclosed, d
g above_med_enclosed = prop_enclosed >= `r(p50)'
g below_med_enclosed = -above_med_enclosed

g GM_X_above_med_enclosed = GM_raw_pp * above_med_enclosed
g GM_hat_X_above_med_enclosed = `inst' * above_med_enclosed

g GM_X_below_med_enclosed = GM_raw_pp * below_med_enclosed
g GM_hat_X_below_med_enclosed = `inst' * below_med_enclosed


g GM_X_prop_enclosed = GM_raw_pp * prop_enclosed
g GM_hat_X_prop_enclosed = `inst' * prop_enclosed


local b_controls_X `b_controls'
local extra_controls_X `extra_controls'
local w_b_controls_X `w_b_controls'
local w_extra_controls_X `w_extra_controls'
foreach controls in b extra w_b w_extra{
	foreach var of varlist ``controls'_controls'{
		cap confirm variable `var'_X_ame
		if _rc!= 0 {
			g `var'_X_ame = `var' * above_med_enclosed
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_ame
	}
}
	
// Core Result
main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect.tex") deplab(n)

main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_new_ctrl.tex") deplab(n)

// European Migration Control
main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' wt_instmig_avg_pp) weight(popc1940) path("$TABS/final/main_effect_eurmig.tex") deplab(n)

main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls' wt_instmig_avg_pp) weight(popc1940) path("$TABS/final/main_effect_eurmig_new_ctrl.tex") deplab(n)

// 1950-70
main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_1950_1970.tex") deplab(n2)

main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_1950_1970_new_ctrl.tex") deplab(n2)

// Long differences
main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_ld.tex") deplab(ld)

main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_ld_new_ctrl.tex") deplab(ld)


// Original intrument
main_table, endog(GM) exog(GM_hat) controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_pctile.tex") deplab(n)

main_table, endog(GM) exog(GM_hat) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_pctile_new_ctrl.tex") deplab(n)


// White migration
main_table, endog(WM_raw_pp) exog(`winst') controls(`b_controls') weight(popc1940) path("$TABS/final/white_effect.tex") deplab(n)

main_table, endog(WM_raw_pp) exog(`winst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/white_effect_new_ctrl.tex") deplab(n)
	
	
// Quadratic Control
main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_quad.tex") deplab(n) endog2(GM_raw_pp_2) exog2(`inst'_2)

main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_quad_new_ctrl.tex") deplab(n) endog2(GM_raw_pp_2) exog2(`inst'_2)

// Above median enclosedness split


local b_controls_X `b_controls'
local extra_controls_X `extra_controls'
local w_b_controls_X `w_b_controls'
local w_extra_controls_X `w_extra_controls'
foreach controls in b extra w_b w_extra{
	foreach var of varlist ``controls'_controls'{
		cap confirm variable `var'_X_ame
		if _rc!= 0 {
			g `var'_X_ame = `var' * above_med_enclosed
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_ame
	}
}

main_table, endog(GM_raw_pp) exog(`inst') controls(above_med_enclosed `b_controls_X') weight(popc1940) path("$TABS/final/main_effect_amed_enclosed.tex") deplab(n) endog2(GM_X_above_med_enclosed) exog2(GM_hat_X_above_med_enclosed)

main_table, endog(GM_raw_pp) exog(`inst') controls(above_med_enclosed `b_controls_X' `extra_controls_X') weight(popc1940) path("$TABS/final/main_effect_amed_enclosed_new_ctrl.tex") deplab(n) endog2(GM_X_above_med_enclosed) exog2(GM_hat_X_above_med_enclosed)

	
	
// Below median enclosedness split

local b_controls_X `b_controls'
local extra_controls_X `extra_controls'
local w_b_controls_X `w_b_controls'
local w_extra_controls_X `w_extra_controls'
foreach controls in b extra w_b w_extra{
	foreach var of varlist ``controls'_controls'{
		cap confirm variable `var'_X_bme
		if _rc!= 0 {
			g `var'_X_bme = `var' * below_med_enclosed
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_bme
	}
}

	
main_table, endog(GM_raw_pp) exog(`inst') controls(below_med_enclosed `b_controls_X') weight(popc1940) path("$TABS/final/main_effect_bmed_enclosed.tex") deplab(n) endog2(GM_X_below_med_enclosed) exog2(GM_hat_X_below_med_enclosed)

main_table, endog(GM_raw_pp) exog(`inst') controls(below_med_enclosed `b_controls_X' `extra_controls_X') weight(popc1940) path("$TABS/final/main_effect_bmed_enclosed_new_ctrl.tex") deplab(n) endog2(GM_X_below_med_enclosed) exog2(GM_hat_X_below_med_enclosed)

	

// Enclosedness split


local b_controls_X `b_controls'
local extra_controls_X `extra_controls'
local w_b_controls_X `w_b_controls'
local w_extra_controls_X `w_extra_controls'
foreach controls in b extra w_b w_extra{
	foreach var of varlist ``controls'_controls'{
		cap confirm variable `var'_X_me
		if _rc!= 0 {
			g `var'_X_me = `var' * prop_enclosed
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_me
	}
}

main_table, endog(GM_raw_pp) exog(`inst') controls(prop_enclosed `b_controls_X') weight(popc1940) path("$TABS/final/main_effect_med_enclosed.tex") deplab(n) endog2(GM_X_prop_enclosed) exog2(GM_hat_X_prop_enclosed)

main_table, endog(GM_raw_pp) exog(`inst') controls(prop_enclosed `b_controls_X' `extra_controls_X') weight(popc1940) path("$TABS/final/main_effect_med_enclosed_new_ctrl.tex") deplab(n) endog2(GM_X_prop_enclosed) exog2(GM_hat_X_prop_enclosed)

	
	
	
main_table, endog(GM_raw_pp) exog(`inst') controls(above_med_enclosed `b_controls') weight(popc1940) path("$TABS/final/main_effect_amed_enclosed_noint.tex") deplab(n) endog2(GM_X_above_med_enclosed) exog2(GM_hat_X_above_med_enclosed)

main_table, endog(GM_raw_pp) exog(`inst') controls(above_med_enclosed `b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_amed_enclosed_new_ctrl_noint.tex") deplab(n) endog2(GM_X_above_med_enclosed) exog2(GM_hat_X_above_med_enclosed)

	