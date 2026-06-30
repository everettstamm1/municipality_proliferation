
use "$INTDATA/ssaggregate_prep//shares_base.dta", clear
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(frac_court_ordered)
g court_order = frac_court_ordered > 0
g share_int = share * court_order
drop share court_order frac_court_ordered
tempfile shares_int
save `shares_int'

use "$CLEANDATA/cz_pooled", clear
drop court_order
g court_order = frac_court_ordered > 0
g GM_raw_pp_X_co = GM_raw_pp * court_order
g shift_share_base_X_co = shift_share_base * court_order
g sumshare_base_X_co = sumshare_base * court_order
ivreg2 n_cgoodman_cz_pc (GM_raw_pp GM_raw_pp_X_co= shift_share_base shift_share_base_X_co) reg2 reg3 reg4 mean_income_1940 mfg_lfshare1940 cz_popdens1940 court_order sumshare_base sumshare_base_X_co [aw = popc1940], r
predict eps, residuals

// Aggregate to shift level with each set of shares

// First with original
preserve
	ssaggregate n_cgoodman_cz_pc GM_raw_pp GM_raw_pp_X_co eps [aw = popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("reg2 reg3 reg4 mean_income_1940 mfg_lfshare1940 cz_popdens1940  sumshare_base sumshare_base_X_co court_order") s(share)
	rename (n_cgoodman_cz_pc GM_raw_pp GM_raw_pp_X_co eps s_n) (n_cgoodman_cz_pc1 GM_raw_pp1 GM_raw_pp_X_co1 eps1 s_n1)
	tempfile f1
	save `f1'
restore

// Now with interacted shares
ssaggregate n_cgoodman_cz_pc GM_raw_pp GM_raw_pp_X_co eps [aw = popc1940], n(origin_fips) l(cz) sfile(`shares_int') controls("reg2 reg3 reg4 mean_income_1940 mfg_lfshare1940 cz_popdens1940  sumshare_base sumshare_base_X_co court_order") s(share_int)
rename (n_cgoodman_cz_pc GM_raw_pp GM_raw_pp_X_co eps s_n) (n_cgoodman_cz_pc2 GM_raw_pp2 GM_raw_pp_X_co2 eps2 s_n2)

merge 1:1 origin_fips using `f1', keep(1 3) nogen
merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
replace shift = 0 if mi(shift)
// Need to residualize on shift-level variables for GMM estimatation to get good as randomly assigned, but we don't have any shift-level variables, but still need to apply those different weights? Not sure
reg shift [aw=s_n1]
predict shift1, resid
reg shift [aw=s_n2]
predict shift2, resid

// Matrices
gen sxg11 = s_n1 * GM_raw_pp1 * shift1 // first index = r (set of weights), second index = j (endog.var)
gen sxg12 = s_n1 * GM_raw_pp_X_co1 * shift1 
gen sxg21 = s_n2 * GM_raw_pp2 * shift2
gen sxg22 = s_n2 * GM_raw_pp_X_co2 * shift2 
gen sy1 = s_n1 * n_cgoodman_cz_pc1 * shift1
gen sy2 = s_n2 * n_cgoodman_cz_pc2 * shift2
gen psi1 =s_n1 * eps1 * shift1
gen psi2 =s_n2 * eps2 * shift2
foreach v of varlist sxg* sy* psi* {
	replace `v' = 0 if mi(`v') // missing values may happen if not all industries merged
}

* To compute sclustered exposure-robust SE, add up psi by cluster (REDUNDANT BUT DONT WANNA CHANGE THEIR CODE)
egen tag_obs = tag(origin_fips)
egen psi1_obs = total(psi1), by(origin_fips)
egen psi2_obs = total(psi2), by(origin_fips)

* Fill the Omega and M matrices
matrix Omega = J(2,2,.)
qui sum sxg11
matrix Omega[1,1] = r(sum)
qui sum sxg12
matrix Omega[1,2] = r(sum)
qui sum sxg21
matrix Omega[2,1] = r(sum)
qui sum sxg22
matrix Omega[2,2] = r(sum)


matrix M = J(2,1,.)
qui sum sy1
matrix M[1,1] = r(sum)
qui sum sy2
matrix M[2,1] = r(sum)

* Compute the mean of the sandwich variance formula, equation (9) in the practical guide
matrix accum Psi = psi1_obs psi2_obs if tag_obs, nocon

// Compute the coefficient estimates (to double check they match those from the regional regression) and the variance matrix
matrix b = inv(Omega) * M // coefficient estimates (matches regional level)
matrix V = inv(Omega) * Psi * inv(Omega)' // variances, without the degree-of-freedom adjustment -- matches ivreg2 but not ivreg

matrix list b
di V[1,1]^0.5 " " V[2,2]^0.5