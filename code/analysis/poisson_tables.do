use "$CLEANDATA/cz_pooled", clear

g GM_raw_pp_2 = GM_raw_pp^2
g GM_hat_raw_2 = GM_hat_raw^2

qui su prop_enclosed, d
g above_med_enclosed = prop_enclosed >= `r(p50)'

g GM_X_above_med_enclosed = GM_raw_pp * above_med_enclosed
g GM_hat_X_above_med_enclosed = GM_hat_raw * above_med_enclosed


foreach controls in reg2 reg3 reg4 v2_sumshares_urban coastal transpo_cost_1920 mfg_lfshare1940{
		g `controls'_X_ame = `controls' * above_med_enclosed
}


poisson_table, endog(GM_raw_pp) exog(GM_hat_raw) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban) weight(popc1940) path("$TABS/poisson/poisson_table.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940) startyr("1940") endyr("1970")

poisson_table, endog(GM_raw_pp) exog(GM_hat_raw) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban wt_instmig_avg_pp) weight(popc1940) path("$TABS/poisson/poisson_table_eurmig.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940) startyr(1940) endyr(1970)


// Not converging
poisson_table, endog(GM_raw_pp) exog(GM_hat_raw) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban) weight(popc1940) path("$TABS/poisson/poisson_table_ld.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940)  startyr(1940) endyr(2010)


poisson_table, endog(GM) exog(GM_hat) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban) weight(popc1940) path("$TABS/poisson/poisson_table_pctile.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940)  startyr(1940) endyr(1970)


// Not converging
poisson_table, endog(WM_raw_pp) exog(GM_8_hat_raw) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban) weight(popc1940) path("$TABS/poisson/poisson_table_white.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940)  startyr(1940) endyr(1970)


poisson_table, endog(GM_raw_pp) exog(GM_hat_raw) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban) weight(popc1940) path("$TABS/poisson/poisson_table_1950.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940)  startyr(1950) endyr(1970)


poisson_table, endog(GM_raw_pp GM_raw_pp_2) exog(GM_hat_raw GM_hat_raw_2) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban) weight(popc1940) path("$TABS/poisson/poisson_table_quad.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940)  startyr(1950) endyr(1970)


poisson_table, endog(GM_raw_pp GM_X_above_med_enclosed) exog(GM_hat_raw GM_hat_X_above_med_enclosed) type("manual") controls(reg2 reg3 reg4 v2_sumshares_urban reg2_X_ame reg3_X_ame reg4_X_ame v2_sumshares_urban_X_ame) weight(popc1940) path("$TABS/poisson/poisson_table_ame.tex") schdist_ind(coastal transpo_cost_1920 mfg_lfshare1940 coastal_X_ame transpo_cost_1920_X_ame mfg_lfshare1940_X_ame)  startyr(1940) endyr(1970)
