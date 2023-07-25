local b_controls reg2 reg3 reg4 blackmig3539_share

use "$CLEANDATA/cz_pooled", clear

reg GM_raw_pp GM_hat_raw_pp `b_controls' [aw=popc1940], r
	local coef : di %6.3f _b[GM_hat_raw_pp]
	local se : di %6.3f _se[GM_hat_raw_pp]
	qui su GM_raw_pp, d
	local ycord = `r(mean)'*0.5
	qui su GM_hat_raw_pp, d
	local xcord = `r(mean)'*2
	binscatter GM_raw_pp GM_hat_raw_pp  [aw=popc1940], controls(`b_controls') ///
									xtitle("Predicted PP Black Migrant ") ytitle("Actual PP Black Migrant") ///
									title("First Stage, Pooled") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_fs.pdf") replace
	

foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{

	
	reg n_`outcome'_cz_pcc GM_hat_raw_pp `b_controls' [aw=popc1940], r
	local coef : di %6.3f _b[GM_hat_raw_pp]
	local se : di %6.3f _se[GM_hat_raw_pp]
	qui su n_`outcome'_cz_pcc, d
	local ycord = `r(mean)'*0.5
	qui su GM_hat_raw_pp, d
	local xcord = `r(mean)'*2
	binscatter n_`outcome'_cz_pcc GM_hat_raw_pp  [aw=popc1940], controls(`b_controls') ///
									xtitle("Predicted PP Black Migrant") ytitle("`outcome'") ///
									title("Reduced Form, Pooled, outcome: `outcome'") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_`outcome'_rf.pdf") replace
						
}


foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{

	
	reg n_`outcome'_cz_pcc GM_raw_pp `b_controls' [aw=popc1940], r
	local coef : di %6.3f _b[GM_raw_pp]
	local se : di %6.3f _se[GM_raw_pp]
	qui su n_`outcome'_cz_pcc, d
	local ycord = `r(mean)'*0.5
	qui su GM_raw_pp, d
	local xcord = `r(mean)'*2
	binscatter n_`outcome'_cz_pcc GM_raw_pp  [aw=popc1940], controls(`b_controls') ///
									xtitle("Predicted PP Black Migrant") ytitle("`outcome'") ///
									title("OLS, Pooled, outcome: `outcome'") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_`outcome'_ols.pdf") replace
						
}

use "$CLEANDATA/cz_pooled", clear

reg GM_raw GM_hat_raw `b_controls' [aw=popc1940], r
	local coef : di %6.3f _b[GM_hat_raw]
	local se : di %6.3f _se[GM_hat_raw]
	qui su GM_raw, d
	local ycord = `r(mean)'*0.5
	qui su GM_hat_raw, d
	local xcord = `r(mean)'*2
	binscatter GM_raw GM_hat_raw  [aw=popc1940], controls(`b_controls') ///
									xtitle("Predicted Percent Black Migrant ") ytitle("Actual Percent Black Migrant") ///
									title("First Stage, Pooled") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_fs_percent.pdf") replace
	

foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{

	
	reg n_`outcome'_cz_pcc GM_hat_raw reg2 reg3 reg4 [aw=popc1940], r
	local coef : di %6.3f _b[GM_hat_raw]
	local se : di %6.3f _se[GM_hat_raw]
	qui su n_`outcome'_cz_pcc, d
	local ycord = `r(mean)'*0.5
	qui su GM_hat_raw, d
	local xcord = `r(mean)'*2
	binscatter n_`outcome'_cz_pcc GM_hat_raw  [aw=popc1940], controls(reg2 reg3 reg4) ///
									xtitle("Predicted Percent Black Migrant") ytitle("`outcome'") ///
									title("Reduced Form, Pooled, outcome: `outcome'") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_`outcome'_rf_percent.pdf") replace
						
}

foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{

	
	reg n_`outcome'_cz_pcc GM_raw reg2 reg3 reg4 [aw=popc1940], r
	local coef : di %6.3f _b[GM_raw]
	local se : di %6.3f _se[GM_raw]
	qui su n_`outcome'_cz_pcc, d
	local ycord = `r(mean)'*0.5
	qui su GM_raw, d
	local xcord = `r(mean)'*2
	binscatter n_`outcome'_cz_pcc GM_raw  [aw=popc1940], controls(reg2 reg3 reg4) ///
									xtitle("Predicted Percent Black Migrant") ytitle("`outcome'") ///
									title("OLS, Pooled, outcome: `outcome'") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_`outcome'_ols_percent.pdf") replace
						
}



use "$CLEANDATA/cz_pooled", clear

reg GM GM_hat reg2 reg3 reg4 [aw=popc1940], r
	local coef : di %6.3f _b[GM_hat]
	local se : di %6.3f _se[GM_hat]
	qui su GM, d
	local ycord = `r(mean)'*0.5
	qui su GM_hat, d
	local xcord = `r(mean)'*2
	binscatter GM_raw GM_hat  [aw=popc1940], controls(reg2 reg3 reg4) ///
									xtitle("Predicted Percentile Black Migrant ") ytitle("Actual Percentile Black Migrant") ///
									title("First Stage, Pooled") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_fs_percentile.pdf") replace
	

foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{

	
	reg n_`outcome'_cz_pcc GM_hat reg2 reg3 reg4 [aw=popc1940], r
	local coef : di %6.3f _b[GM_hat]
	local se : di %6.3f _se[GM_hat]
	qui su n_`outcome'_cz_pcc, d
	local ycord = `r(mean)'*0.5
	qui su GM_hat, d
	local xcord = `r(mean)'*2
	binscatter n_`outcome'_cz_pcc GM_hat  [aw=popc1940], controls(reg2 reg3 reg4) ///
									xtitle("Predicted Percentile Black Migrant") ytitle("`outcome'") ///
									title("Reduced Form, Pooled, outcome: `outcome'") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_`outcome'_rf_percentile.pdf") replace
						
}


foreach outcome in cgoodman schdist_ind gen_subcounty spdist gen_town{

	
	reg n_`outcome'_cz_pcc GM reg2 reg3 reg4 [aw=popc1940], r
	local coef : di %6.3f _b[GM]
	local se : di %6.3f _se[GM]
	qui su n_`outcome'_cz_pcc, d
	local ycord = `r(mean)'*0.5
	qui su GM, d
	local xcord = `r(mean)'*2
	binscatter n_`outcome'_cz_pcc GM  [aw=popc1940], controls(reg2 reg3 reg4) ///
									xtitle("Predicted Percentile Black Migrant") ytitle("`outcome'") ///
									title("OLS, Pooled, outcome: `outcome'") ///
									text(`ycord' `xcord' "Slope: `coef'(`se)')") ///
									savegraph("$FIGS/binscatter/pooled_`outcome'_ols_percentile.pdf") replace
						
}