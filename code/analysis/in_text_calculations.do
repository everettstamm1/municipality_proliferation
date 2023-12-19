/// Introduction

// Decline in number of local governments
use "$INTDATA/cog/2_county_counts.dta", clear

collapse (sum) all_local schdist_ind spdist, by(year)

sysuse auto, clear
summarize weight
local est1 = r(mean)
local est2 = r(mean) + r(sd)
local est3 = r(sd)

regress mpg weight
local x = _b[weight]
di ((`x' * `est2')) - ((`x' * `est1'))
di ((`x' * `est3'))


	use "$CLEANDATA/cz_pooled", clear
	
	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = GM_hat_raw_pp) reg2 reg3 reg4 blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total [aw = popc1940], r
su b_cgoodman_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d'

	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw_pp) reg2 reg3 reg4 blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total [aw = popc1940], r
su b_schdist_ind_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d'