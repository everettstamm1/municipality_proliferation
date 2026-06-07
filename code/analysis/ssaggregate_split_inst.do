use "$CLEANDATA/cz_pooled", clear
g GM_raw_ppXco = GM_raw_pp * court_order
g shift_share_baseXco = shift_share_base * court_order
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 [aw=popc1940], r
ivreg2 n_cgoodman_cz_pc (GM_raw_pp GM_raw_ppXco= shift_share_base shift_share_baseXco) court_order reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 [aw=popc1940], r

g popgrowth = log(pop1970) - log(pop1940)
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 [aw=popc1940], r

ssaggregate b_schdist_ind_cz1970 GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 b_schdist_ind_cz1940 popgrowth") s(share)

merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
replace shift = 0 if mi(shift)

ivreg2 b_schdist_ind_cz1970 (GM_raw_pp = shift) [aw = s_n]






// Benchmark: Uninteracted version (close to BHJ Table 4 col.3 except slightly different controls)
global intvar any_court_order
global controls reg2 reg3 reg4 mfg_lfshare1940 cz_popdens1940 mean_income_1940 sumshare_base sumshare_base_int court_order

t2##c.Lsh_manuf##$intvar reg* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource 
use location_level, clear
ivreg2 y (x=z) $controls [aw=popc1940], cluster(clus) partial($controls)

* And its shift-level IV equivalent
ssaggregate y x [aw=wei], n(sic87dd) s(ind_share) t(year) sfilename(Lshares) l(czone) controls("$controls") 
merge 1:1 sic87dd year using shocks, assert(3) nogen keepusing(g)
merge m:1 sic87dd using industries, assert(1 3) nogen keepusing(sic3)
ivreg2 y (x=g) [aw=s_n], cluster(sic3)

/* Now interacted with the chosen variable */
// Generate interacted shares
use "$INTDATA/ssaggregate_prep/shares_base.dta", clear
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(frac_court_ordered)
g any_court_order = frac_court_ordered>0

gen share_int = share * $intvar
drop share $intvar
save "$INTDATA/ssaggregate_prep/shares_base_int.dta", replace

// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
g any_court_order = frac_court_ordered>0
g y = n_totfrac_cz_pc
g x = GM_raw_pp
g z = GM_hat_raw

gen x_int = x * $intvar 
gen z_int = z * $intvar
gen sumshare_base_int = sumshare_base * $intvar

ivreg2 y (x x_int=z z_int) $controls [aw=popc1940], r
predict eps, residuals

// Aggregate it to the industry (=shift) level with each set of shares: in this case, original and interacted
* First with original shares
preserve
	ssaggregate y x x_int eps [aw=popc1940], n(origin_fips) s(share) sfilename("$INTDATA/ssaggregate_prep/shares_base.dta") l(cz) controls("$controls") 
	rename (y x x_int eps s_n) (y1 x1 x_int1 eps1 s_n1)
	tempfile f1
	save `f1'
restore

* Now with interacted shares
ssaggregate y x x_int eps [aw=popc1940], n(origin_fips) s(share_int) sfilename("$INTDATA/ssaggregate_prep/shares_base_int.dta") l(cz) controls("$controls") 
rename (y x x_int eps s_n) (y2 x2 x_int2 eps2 s_n2)
merge 1:1 origin_fips using `f1', nogen // note: if all interacted shares are zero for some industry, the industry will be dropped from *_2, and the merge will not be perfect
order *2, after(x_int1)


	// Bring the industry shifts and also industry clustering variable
	merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(3) nogen
	g g = shift
	//merge m:1 sic87dd using industries, assert(1 3) nogen keepusing(sic3)
	g sic3 = _n
	// Generate the relevant shift-level variables for GMM estimation as in Appendix B.1 of the practical guide (and with similar notation)
	* g_tilde indexed by r (set of weights)
	g year = 1
	qui reg g year [aw=s_n1]
	predict g_res1, resid
	qui reg g year [aw=s_n2]
	predict g_res2, resid

	* Elements of the Omega and M matrices: sums of (g_gilde*x_tilde) and (g_tilde*y_tilde)
	* Also psi_k = epsilon_tilde * g_tilde
	* We use the output of ssaggregate: x_tilde1=s_n1*x1, and similar for all other variables
	gen sxg11 = s_n1 * x1 * g_res1 // first index = r (set of weights), second index = j (endog.var)
	gen sxg12 = s_n1 * x_int1 * g_res1 
	gen sxg21 = s_n2 * x2 * g_res2
	gen sxg22 = s_n2 * x_int2 * g_res2 
	gen sy1 = s_n1 * y1 * g_res1
	gen sy2 = s_n2 * y2 * g_res2
	gen psi1 =s_n1 * eps1 * g_res1
	gen psi2 =s_n2 * eps2 * g_res2
	foreach v of varlist sxg* sy* psi* {
		replace `v' = 0 if mi(`v') // missing values may happen if not all industries merged
	}

	* To compute sic3-clustered exposure-robust SE, add up psi by sic3 code
	egen tag_sic3 = tag(sic3)
	egen psi1_sic3 = total(psi1), by(sic3)
	egen psi2_sic3 = total(psi2), by(sic3)

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
	matrix accum Psi = psi1_sic3 psi2_sic3 if tag_sic3, nocon

	// Compute the coefficient estimates (to double check they match those from the regional regression) and the variance matrix
	matrix b = inv(Omega) * M // coefficient estimates (matches regional level)
	matrix V = inv(Omega) * Psi * inv(Omega)' // variances, without the degree-of-freedom adjustment -- matches ivreg2 but not ivreg


// Report the coefficients and standard errors (without the degree-of-freedom adjustment that can be added)
matrix list b
di V[1,1]^0.5 " " V[2,2]^0.5

local b_combined = b[1,1] + b[2,1]
local se_combined = sqrt(V[1,1] + V[2,2] + 2*V[1,2])
di `b_combined'
di `se_combined'
mat list V