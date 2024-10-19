/// Introduction

local texfile "$TABS/sd_changes.tex"
file open myfile using "`texfile'", write replace

file write myfile "\begin{tabular}{|l|r|}" _n
file write myfile "\hline" _n
file write myfile "Name & Value \\" _n
file write myfile "\hline" _n

// Decline in number of local governments


// OLS
use "$CLEANDATA/cz_pooled", clear
	
summarize GM_raw_pp
local est1 = r(sd)
reg n_cgoodman_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban transpo_cost_1920 coastal [aw = popc1940], r

su b_cgoodman_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)

local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "cgoodman_ols & `v' \\" _n

summarize GM_raw_pp
local est1 = r(sd)
reg n_gen_muni_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r

su b_gen_muni_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)

local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "gen_muni_ols & `v' \\" _n

summarize GM_raw_pp
local est1 = r(sd)
reg n_schdist_ind_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_schdist_ind_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)
local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "schdist_ind_ols & `v' \\" _n

summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_gen_town_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_gen_town_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)
local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "gen_town_ols & `v' \\" _n


summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_spdist_cz_pc GM_raw_pp reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_spdist_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)
local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "spdist_ols & `v' \\" _n

// IV

use "$CLEANDATA/cz_pooled", clear
	
summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban transpo_cost_1920 coastal [aw = popc1940], r

su b_cgoodman_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)

local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "cgoodman_iv & `v' \\" _n

summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_gen_muni_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r

su b_gen_muni_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)

local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "gen_muni_iv & `v' \\" _n

	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_schdist_ind_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_schdist_ind_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)
local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "schdist_ind_iv & `v' \\" _n


	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_gen_town_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_gen_town_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)
local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "gen_town_iv & `v' \\" _n

	summarize GM_raw_pp
local est1 = r(sd)
ivreg2 n_spdist_cz_pc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 v2_sumshares_urban  transpo_cost_1920 coastal [aw = popc1940], r
su b_spdist_cz1940_pc [aw=popc1940]
local d = round(r(mean),0.01)
local v =  ((_b[GM_raw_pp] * `est1')) /`d'
file write myfile "spdist_iv & `v' \\" _n


file write myfile "\end{tabular}" _n

// Step 6: Close the file
file close myfile

// Total pop
use "$RAWDATA/census/usa_00055.dta", clear

drop if stateicp == 41 | ///
		stateicp == 42 | ///
		stateicp == 43 | ///
		stateicp == 44 | ///
		stateicp == 51 | ///
		stateicp == 45 | ///
		stateicp == 46 | ///
		stateicp == 47 | ///
		stateicp == 53 | ///
		stateicp == 48 | ///
		stateicp == 54 | ///
		stateicp == 49 | ///
		stateicp == 40 | ///
		stateicp == 58 | ///
		stateicp == 81 | ///
		stateicp == 82 
		
		
94.825.128 after that