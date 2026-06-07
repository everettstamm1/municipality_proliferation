

// Example of how to use ssaggregate directly
use "cz_pooled.dta"
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940

// Our main spec at the CZ level. Should return a point estimate of X with the "wrong" SEs
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = shift_share_base) `b_controls' `extra_controls' [aw = popc1940], r

// Command to transform to the shift level
ssaggregate n_cgoodman_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("shares_base.dta") controls("`b_controls' `extra_controls'") s(share)

// Merge in shifts
merge 1:1 origin_fips using "shock_instrument_base.dta", keep(1 3) nogen
replace shift = 0 if mi(shift)

// Run shift level IV. SHould have same point estimate as before with correct SEs

ivreg2 n_cgoodman_cz_pc (GM_raw_pp = shift) [aw=s_n]