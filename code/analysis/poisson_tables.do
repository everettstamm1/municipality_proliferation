
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls mean_income_1940 cz_popdens1940 mfg_lfshare1940
use "$CLEANDATA/cz_pooled", clear
lab var GM_raw_pp "GM"
g popgrowth4070 = (pop1970 - pop1940)/pop1940





// Two ref requests
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	drop n_`outcome'_cz_pc ld_`outcome'_cz_pc
	ren n_`outcome'_cz_ld n_`outcome'_cz_pc
	ren ld_`outcome'_cz_ld ld_`outcome'_cz_pc
	
}
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' ) weight(popc1940) path("$TABS/final/refspec_1.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' popgrowth4070) weight(popc1940) path("$TABS/final/refspec_1_popgrowth.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	drop n_`outcome'_cz_pc ld_`outcome'_cz_pc
	ren pct_`outcome'_cz_pc n_`outcome'_cz_pc
	ren  pct_ld_`outcome'_cz_pc ld_`outcome'_cz_pc
	
}
main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' ) weight(popc1940) path("$TABS/final/refspec_2.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")

main_table_long_ssaggregate, endog(GM_raw) exog(shift_share_base) controls(`b_controls' `extra_controls' ) weight(popc1940) path("$TABS/final/refspec_2_pct.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// Raw Differences
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	drop n_`outcome'_cz_pc ld_`outcome'_cz_pc
	ren n_`outcome'_cz1970 n_`outcome'_cz_pc
	ren  n_`outcome'_cz2010 ld_`outcome'_cz_pc
	
}


main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' ) weight(popc1940) path("$TABS/final/rawdiff.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips")


// 1970 p.c. base outcome
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	drop n_`outcome'_cz_pc ld_`outcome'_cz_pc
	ren b_`outcome'_cz1970_pc n_`outcome'_cz_pc
	ren  b_`outcome'_cz2010_pc ld_`outcome'_cz_pc
	
}

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' ) weight(popc1940) path("$TABS/final/b70_pc.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips") cgoodman("b_cgoodman_cz1940_pc") gen_muni("b_gen_muni_cz1940_pc") schdist_ind("b_schdist_ind_cz1940_pc") spdist("b_spdist_cz1940_pc") totfrac("b_totfrac_cz1940_pc")

// 1970 base outcome
foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni totfrac {
	drop n_`outcome'_cz_pc ld_`outcome'_cz_pc
	ren b_`outcome'_cz1970 n_`outcome'_cz_pc
	ren  b_`outcome'_cz2010 ld_`outcome'_cz_pc
	
}


main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' ) weight(popc1940) path("$TABS/final/b70.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips") cgoodman("b_cgoodman_cz1940") gen_muni("b_gen_muni_cz1940") schdist_ind("b_schdist_ind_cz1940") spdist("b_spdist_cz1940") totfrac("b_totfrac_cz1940")

main_table_long_ssaggregate, endog(GM_raw_pp) exog(shift_share_base) controls(`b_controls' `extra_controls' popgrowth4070) weight(popc1940) path("$TABS/final/b70_growth.tex") 	version("base")	share_folder("$INTDATA/ssaggregate_prep/") origin_id("origin_fips") cgoodman("b_cgoodman_cz1940") gen_muni("b_gen_muni_cz1940") schdist_ind("b_schdist_ind_cz1940") spdist("b_spdist_cz1940") totfrac("b_totfrac_cz1940")

use "$CLEANDATA/cz_pooled", clear
lab var GM_raw_pp "GM"
g popgrowth4070 = (pop1970 - pop1940)/pop1940

// Poisson Versions
replace b_schdist_ind_cz1940 = . if region == 3
replace b_schdist_ind_cz1970 = . if region == 3
replace b_schdist_ind_cz2010 = . if region == 3




replace pop1970 = pop1970/10000
// Poisson, baseline control, no exposure 
g noexposure = 1
poisson_table_long, endog(GM_raw_pp) exog(shift_share_base) exposure(noexposure) controls(reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940) weight(popc1940) path("$TABS/poisson/poisson_table_base.tex")cgoodman(b_cgoodman_cz1940) gen_muni(b_gen_muni_cz1940)  schdist_ind(b_schdist_ind_cz1940)  spdist(b_spdist_cz1940)

// Poisson, baseline and pop growth control, no exposure
poisson_table_long, endog(GM_raw_pp) exog(shift_share_base) exposure(noexposure) controls(reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 popgrowth4070) weight(popc1940) path("$TABS/poisson/poisson_table_base_popgrowth.tex") cgoodman(b_cgoodman_cz1940) gen_muni(b_gen_muni_cz1940)  schdist_ind(b_schdist_ind_cz1940)  spdist(b_spdist_cz1940)

// Poisson, baseline P.C. control, 1970 pop exposure

foreach spec in cgoodman gen_muni schdist_ind spdist{
	g basepos_`spec' = b_`spec'_cz1940_pc > 0 if !mi(b_`spec'_cz1940_pc)
	gen ln_`spec'_base = cond(basepos_`spec', ln(b_`spec'_cz1940_pc), -5)
}

poisson_table_long, endog(GM_raw_pp) exog(shift_share_base) exposure(pop1970) controls(reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940) weight(popc1940) path("$TABS/poisson/poisson_table_exposure.tex")  cgoodman(ln_cgoodman_base basepos_cgoodman) gen_muni(ln_gen_muni_base basepos_gen_muni)  schdist_ind(ln_schdist_ind_base basepos_schdist_ind)  spdist(ln_spdist_base basepos_spdist)


ivreg2  n_schdist_ind_cz_pc (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940  [aw = popc1940] , r partial(reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 )



ivpoisson gmm b_cgoodman_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 b_cgoodman_cz1940  [aw = popc1940], vce(r) 
ivpoisson gmm b_gen_muni_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 b_gen_muni_cz1940  [aw = popc1940], vce(r) 
ivpoisson gmm b_schdist_ind_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 b_schdist_ind_cz1940  [aw = popc1940] if region != 3, vce(r) 
ivpoisson gmm b_spdist_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 b_spdist_cz1940  [aw = popc1940], vce(r) 

ivpoisson gmm b_cgoodman_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 ln_cgoodman_base basepos_cgoodman [aw = popc1940], vce(r) exposure(pop1970)
ivpoisson gmm b_gen_muni_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 ln_gen_muni_base basepos_gen_muni [aw = popc1940], vce(r) exposure(pop1970)
ivpoisson gmm b_schdist_ind_cz2010 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 ln_schdist_ind_base basepos_schdist_ind [aw = popc1940] if region != 3 , vce(r) exposure(pop1970) 
ivpoisson cfunction b_spdist_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 ln_spdist_base basepos_spdist [aw = popc1940], vce(r) exposure(pop1970)

ivpoisson gmm b_schdist_ind_cz1970 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 ln_schdist_ind_base basepos_schdist_ind [aw = popc1940] if region != 3, vce(r) exposure(pop1970) 

g r1  = b_schdist_ind_cz1940 / (pop1940/10000)
g r2 = b_schdist_ind_cz1970 / (pop1940/10000)
g dr = r2 - r1 
ivreg2  dr (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940  [aw = popc1940] , r 
ivreg2  r2 (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 r1 [aw = popc1940] , r 
