

// Controls
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls mean_income_1940 mfg_lfshare1940 cz_popdens1940 

// White controls
local w_b_controls reg2 reg3 reg4 sumshare_base_white 
local w_extra_controls growth1930 mean_income_1940 hsgrad_25 unigrad_25 frac_total mfg_lfshare1940 coastal



use "$CLEANDATA/cz_pooled", clear

 
lab var shift_share_base "$\widehat{GM}$"
lab var GM "Percentile GM"
lab var GM_hat "Percentile $\widehat{GM}$"

lab var GM_raw_pp "GM"

g GM_raw_pp_2 = GM_raw_pp^2
lab var GM_raw_pp_2 "$\text{GM}^2$"




g GM_X_above_med_enclosed = GM_raw_pp * above_med_enclosed



g GM_X_prop_enclosed1940 = GM_raw_pp * prop_enclosed1940

replace n_streams = -1 if mi(n_streams)
g mi_n_streams = n_streams == -1 



// Table 2: Black Migration Effect
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_ssaggregate_long.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")



// Table 3: White Migration Effect
//main_table_long_ssaggregate, endog(WM_raw_pp) exog(shift_share_base_white) controls(`b_controls' ) weight(popc1940) path("$TABS/final/white_ssaggregate_long.tex") 	version("base_white")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

main_table_long_ssaggregate, endog(WM_raw_pp) exog(shift_share_base_white) controls(reg2 reg3 reg4 sumshare_base_white growth1930 mean_income_1940 hsgrad_25 unigrad_25 frac_total mfg_lfshare1940 coastal) weight(popc1940) path("$TABS/final/white_ssaggregate_long.tex") 	version("base_white")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")



// Table A5: Townships
main_table_towns_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_ssaggregate_towns.tex")  version("base") share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Table A6: 1950 base year
main_table_long_ssaggregate2, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_ssaggregate_5070.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// Table A7: No imbalanced controls
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' ) weight(popc1940) path("$TABS/final/black_ssaggregate_nobal.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Table A8: Percentile Transformation
main_table_long_ssaggregate, endog(GM) exog(GM_hat) controls(`b_controls' ) weight(popc1940) path("$TABS/final/black_ssaggregate_pctile_noctrl_ss.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


main_table_long, endog(GM) exog(GM_hat) controls(`b_controls' mfg_lfshare1940 frac_all_upm1940 sumshare_base) weight(popc1940) path("$TABS/final/main_effect_pctile_wt.tex")
g dumwt = 1
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls' mfg_lfshare1940 frac_all_upm1940 sumshare_base) weight(dumwt) path("$TABS/final/main_effect_pctile.tex")
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls') weight(popc1940) path("$TABS/final/main_effect_pctile_noctrl.tex")
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls') weight(dumwt) path("$TABS/final/main_effect_pctile_noctrl_nowt.tex")
main_table_long, endog(GM) exog(GM_hat) controls(reg2 reg3 reg4) weight(popc1940) path("$TABS/final/main_effect_pctile_noctrl_nowt.tex")
main_table_long, endog(GM) exog(GM_hat) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_effect_pctile_ourctrl.tex")



main_table_long_ssaggregate, endog(GM) exog(GM_hat) controls(reg2 reg3 reg4 sumshare_base avg_precip transpo_cost_1920 frac_total mean_income_1940 cz_popdens1940 ) weight(popc1940) path("$TABS/final/black_ssaggregate_pctile_imbal_ss.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


main_table_long, endog(GM) exog(GM_hat) controls(reg2 reg3 reg4 sumshare_base avg_precip transpo_cost_1920 frac_total mean_income_1940 cz_popdens1940) weight(popc1940) path("$TABS/final/main_effect_pctile_imbal.tex")
// Table A9: European Migration Control

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' wt_instmig_avg) weight(popc1940) path("$TABS/final/black_ssaggregate_eurmig.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

g wt_instmig_avg_raw = wt_instmig_avg * popc1940
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' wt_instmig_avg_raw) weight(popc1940) path("$TABS/final/black_ssaggregate_eurmig_raw.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// Main Table, all controls
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(reg2 reg3 reg4 sumshare_base avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total transpo_cost_1920 frac_total hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930 mi_n_streams) weight(popc1940) path("$TABS/final/black_ssaggregate_long_allctrls.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// Main Table, fragmech
fragmech_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(reg2 reg3 reg4 sumshare_base  mfg_lfshare1940      mean_income_1940 cz_popdens1940 ) weight(popc1940) path("$TABS/final/fragmech_ssaggregate_long.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


	