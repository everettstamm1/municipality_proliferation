
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

g lpopgrowth = l_pop1970 - l_pop1940




// Main Table, level outcome
drop n_*_cz_pc ld_*_cz_pc
rename n_*_cz n_*_cz_pc
rename ld_*_cz ld_*_cz_pc
rename growth4070 n_totfrac_cz_pc
rename growth4010 ld_totfrac_cz_pc
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/RR/black_levels_outcome.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")



// Main Table, log outcome
drop n_*_cz_pc ld_*_cz_pc
rename logdiff_long_*_cz ld_*_cz_pc
rename logdiff_*_cz n_*_cz_pc
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/RR/black_logdiff_outcome.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' pop1940) weight(popc1940) path("$TABS/RR/black_logdiff_outcome_popctrl.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")



main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' pop1940 pop1970) weight(popc1940) path("$TABS/RR/black_logdiff_outcome_popctrl_both.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' lpopgrowth) weight(popc1940) path("$TABS/RR/black_logdiff_outcome_popgrowth.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")
g b1940_cgoodman_cz = b1940_cgoodman_cz * (pop1940/10000)

// Main Table, Pct outcome
drop n_*_cz_pc ld_*_cz_pc
rename pct_long_*_cz_pc ld_*_cz_pc
rename pct_*_cz_pc n_*_cz_pc
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/black_pct_outcome.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Main table, 

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_table_occscore_link_sample.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

// Table with only 1930-40 links

keep if !mi(occscore_black_3040_linked)
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls') weight(popc1940) path("$TABS/final/main_table_occscore_link_sample.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


