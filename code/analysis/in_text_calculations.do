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

// OLS
use "$CLEANDATA/cz_pooled", clear
	
summarize GM_raw_pp
local est1 = r(sd)
reg n_cgoodman_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban transpo_cost_1920 coastal [aw = popc1940], r

su b_cgoodman_cz1940_pc [aw=popc1940]
local d = r(mean)

di ((_b[GM_raw_pp] * `est1')) /`d'


summarize GM_raw_pp
local est1 = r(sd)
reg n_gen_muni_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r

su b_gen_muni_cz1940_pc [aw=popc1940]
local d = r(mean)

di ((_b[GM_raw_pp] * `est1')) /`d'

	summarize GM_raw_pp
local est1 = r(sd)
reg n_schdist_ind_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_schdist_ind_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d'

summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_gen_town_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_gen_town_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d'



// IV

use "$CLEANDATA/cz_pooled", clear
	
summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban transpo_cost_1920 coastal [aw = popc1940], r

su b_cgoodman_cz1940_pc [aw=popc1940]
local d = r(mean)

di ((_b[GM_raw_pp] * `est1')) /`d'


summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r

su b_gen_muni_cz1940_pc [aw=popc1940]
local d = r(mean)

di ((_b[GM_raw_pp] * `est1')) /`d'

	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_schdist_ind_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d'


	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_gen_town_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_gen_town_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d'


	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_spdist_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_spdist_cz1940_pc [aw=popc1940]
local d = r(mean)
di ((_b[GM_raw_pp] * `est1')) /`d' 


