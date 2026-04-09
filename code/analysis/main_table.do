
local use_sumshare = 1
local use_pct_inst = 1


// Controls
if `use_sumshare' == 0 local b_controls reg2 reg3 reg4 blackmig3539_share 
if `use_sumshare' == 1 local b_controls reg2 reg3 reg4 sumshare_base


if `use_sumshare' == 0 & `use_pct_inst' == 0 local extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local extra_controls transpo_cost_1920 cz_popdens1940
if `use_sumshare' == 1 & `use_pct_inst' == 1 local extra_controls mean_income_1940 mfg_lfshare1940 cz_popdens1940 

// Inst
if `use_pct_inst' == 0 local inst GM_hat_raw_pp
if `use_pct_inst' == 1 local inst GM_hat_raw

// White inst
if `use_pct_inst' == 0 local winst GM_2w_hat_raw_pp
if `use_pct_inst' == 1 local winst GM_2w_hat_raw

// White controls
if `use_sumshare' == 0 local w_b_controls reg2 reg3 reg4 v2w_whitemig3539_share1940 
if `use_sumshare' == 1 local w_b_controls reg2 reg3 reg4 v2w_sumshares_urban 

if `use_sumshare' == 0 & `use_pct_inst' == 0 local w_extra_controls mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total
if `use_sumshare' == 0 & `use_pct_inst' == 1 local w_extra_controls mfg_lfshare1940
if `use_sumshare' == 1 & `use_pct_inst' == 0 local w_extra_controls coastal transpo_cost_1920 cz_popdens1940
if `use_sumshare' == 1 & `use_pct_inst' == 1 local w_extra_controls coastal transpo_cost_1920 cz_popdens1940



use "$CLEANDATA/cz_pooled", clear

keep if dcourt == 1

lab var shift_share_base "$\widehat{GM}$"
lab var `inst' "$\widehat{GM}$"
lab var GM_hat "Percentile $\widehat{GM}$"
lab var GM "Percentile GM"

lab var GM_raw_pp "GM"
lab var WM_raw_pp "WM"
lab var GM_8_hat_raw "$\widehat{WM}$"
qui su GM_raw_pp, d
g GM_raw_pp_recentered = GM_raw_pp - `r(mean)'

g GM_raw_pp_2 = GM_raw_pp^2
g GM_hat_raw_2 = GM_hat_raw^2
lab var GM_raw_pp_2 "$\text{GM}^2$"
lab var GM_hat_raw_2 "$\widehat{GM}^2$"

g order = frac_total^2



g GM_X_above_med_enclosed = GM_raw_pp * above_med_enclosed
g GM_hat_X_above_med_enclosed = `inst' * above_med_enclosed



g GM_X_prop_enclosed1940 = GM_raw_pp * prop_enclosed1940
g GM_hat_X_prop_enclosed1940 = `inst' * prop_enclosed1940


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
replace mean_income_1940_bmig = 0 if mi(mean_income_1940_bmig)
g mi_bmig_income = mean_income_1940_bmig == 0
replace bmig_income_diff = 0 if mi(bmig_income_diff)
g mi_bmig_income_diff = bmig_income_diff == 0
replace bmig_income_diff_cz = 0 if mi(bmig_income_diff_cz)
g mi_bmig_income_diff_cz = bmig_income_diff_cz == 0
replace occscore_black_3040_linked = 0 if mi(occscore_black_3040_linked)
g mi_occscore_black_3040_linked = occscore_black_3040_linked == 0

// Main Table, black income diff control
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' bmig_income_diff_cz mi_bmig_income_diff_cz) weight(popc1940) path("$TABS/final/black_ssaggregate_long_bincdiff.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Main Table, 1930 black mig occscore control
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' occscore_black_3040_linked mi_occscore_black_3040_linked) weight(popc1940) path("$TABS/final/black_ssaggregate_long_b30occscore.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// White
main_table_long_ssaggregate, endog(WM_raw_pp) exog(shift_share_base_white) controls(reg2 reg3 reg4 sumshare_base_white growth3040 mean_income_1940 hsgrad frac_total mfg_lfshare1940 coastal) weight(popc1940) path("$TABS/final/white_ssaggregate_long.tex") 	version("base_white")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Main Table, levels
//main_table_long_ssagg_levels, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' mfg_lfshare1940) weight(popc1940) path("$TABS/final/black_ssaggregate_long_levels.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Main Table
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_ssaggregate_long.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// European Migration Control

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' wt_instmig_avg_pp) weight(popc1940) path("$TABS/final/black_ssaggregate_eurmig.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// 1950-70 diff
main_table_long_ssaggregate2, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_ssaggregate_5070.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// No imbalanced
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' ) weight(popc1940) path("$TABS/final/black_ssaggregate_nobal.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")




// Townships
main_table_towns_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_ssaggregate_towns.tex")  version("base") share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// Original Instrument
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls' mfg_lfshare1940 frac_all_upm1940 sumshare_base) weight(popc1940) path("$TABS/final/main_effect_pctile_wt.tex")
g dumwt = 1
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls' mfg_lfshare1940 frac_all_upm1940 sumshare_base) weight(dumwt) path("$TABS/final/main_effect_pctile.tex")
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_pctile_noctrl.tex")
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_pctile_outctrl.tex")


// Quadratic Control

main_table_long, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_quad_new_ctrl.tex")  endog2(GM_raw_pp_2) exog2(`inst'_2)





// New 1st table
main_table_long, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_long.tex")

// Long table, with income
main_table_long, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_long_income.tex")

// Townships table
//main_table_towns, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_towns.tex") deplab(n)

// Core Result
main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect.tex") deplab(n)

main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_new_ctrl.tex") deplab(n)




// Original intrument
main_table, endog(GM) exog(GM_hat) controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_pctile.tex") deplab(n)

main_table, endog(GM) exog(GM_hat) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_pctile_new_ctrl.tex") deplab(n)



// White migration - old
main_table, endog(WM_raw_pp) exog(GM_2w_hat_raw_pp) controls(`w_b_controls') weight(popc1940) path("$TABS/final/white_effect_pp.tex") deplab(n)

main_table, endog(WM_raw_pp) exog(GM_2w_hat_raw_pp) controls(`w_b_controls' `w_extra_controls') weight(popc1940) path("$TABS/final/white_effect_pp_new_ctrl.tex") deplab(n)
	





main_table, endog(GM_raw_pp) exog(`inst') controls(`b_controls' `extra_controls' frac_court_ordered) weight(popc1940) path("$TABS/final/main_effect_frac_co_new_ctrl.tex") deplab(n) endog2(GM_rawXfrac_co) exog2(GM_hatXfrac_co)
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
			g `var'_X_me = `var' * prop_enclosed1940
		}
		local `controls'_controls_X ``controls'_controls_X' `var'_X_me
	}
}

main_table, endog(GM_raw_pp) exog(`inst') controls(prop_enclosed1940 `b_controls_X') weight(popc1940) path("$TABS/final/main_effect_med_enclosed.tex") deplab(n) endog2(GM_X_prop_enclosed1940) exog2(GM_hat_X_prop_enclosed1940)

main_table, endog(GM_raw_pp) exog(`inst') controls(prop_enclosed1940 `b_controls_X' `extra_controls_X') weight(popc1940) path("$TABS/final/main_effect_med_enclosed_new_ctrl.tex") deplab(n) endog2(GM_X_prop_enclosed1940) exog2(GM_hat_X_prop_enclosed1940)

	
	
	
main_table, endog(GM_raw_pp) exog(`inst') controls(above_med_enclosed `b_controls') weight(popc1940) path("$TABS/final/main_effect_amed_enclosed_noint.tex") deplab(n) endog2(GM_X_above_med_enclosed) exog2(GM_hat_X_above_med_enclosed)

main_table, endog(GM_raw_pp) exog(`inst') controls(above_med_enclosed `b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_amed_enclosed_new_ctrl_noint.tex") deplab(n) endog2(GM_X_above_med_enclosed) exog2(GM_hat_X_above_med_enclosed)

	