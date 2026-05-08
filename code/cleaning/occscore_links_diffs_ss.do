

foreach int in links diff{
	if "`int'"=="links" local intvar above_med_occscore_3040
	if "`int'"=="diff" local intvar above_med_occscore_diff

	local controls reg2 reg3 reg4 mfg_lfshare1940 cz_popdens1940 mean_income_1940 sumshare_base sumshare_base_int `intvar'
	/* Now interacted with the chosen variable */
	// Generate interacted shares
	use "$INTDATA/ssaggregate_prep/shares_base.dta", clear
	merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(`intvar')

	gen share_int = share * `intvar'
	drop share `intvar'
	save "$INTDATA/ssaggregate_prep/shares_base_int.dta", replace

	// Run the interacted regression
	use "$CLEANDATA/cz_pooled", clear


	g x = GM_raw_pp
	g z = shift_share_base

	gen x_int = x * `intvar' 
	gen z_int = z * `intvar'
	gen sumshare_base_int = sumshare_base * `intvar'


	g y = .


	foreach outcome in cgoodman  spdist gen_muni totfrac schdist_ind{
		replace y = n_`outcome'_cz_pc
		su y if `intvar' == 0
		local mean70_`int'_`outcome' = string(r(mean),"%9.3f")
		local nobs_`int'_`outcome' = string( e(N),"%9.0f")
		ivreg2 y (x x_int=z z_int) `controls' [aw=popc1940], r
		cap drop eps
		predict eps, residuals

		preserve
			ssaggregate y x x_int eps [aw=popc1940], n(origin_fips) s(share) sfilename("$INTDATA/ssaggregate_prep/shares_base.dta") l(cz) controls("`controls'") 
			rename (y x x_int eps s_n) (y1 x1 x_int1 eps1 s_n1)
			tempfile f1
			save `f1'
		restore
	// Aggregate it to the industry (=shift) level with each set of shares: in this case, original and interacted
	* First with original shares

		preserve
		* Now with interacted shares
			ssaggregate y x x_int eps [aw=popc1940], n(origin_fips) s(share_int) sfilename("$INTDATA/ssaggregate_prep/shares_base_int.dta") l(cz) controls("`controls'") 
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
			
			local b_iv70_x_`int'_`outcome' = b[1,1]
			local b_iv70_x_int_`int'_`outcome' = b[2,1]
			local se_iv70_x_`int'_`outcome' = V[1,1]^0.5
			local se_iv70_x_int_`int'_`outcome' = V[2,2]^0.5
		restore
		
		// Long differences 
		replace y = ld_`outcome'_cz_pc
		// OLS 1940-70
		reg y x x_int `controls' [aw = popc1940], r
		su y if `intvar' == 0
		local mean10_`int'_`outcome' = string(r(mean),"%9.3f")
		
		ivreg2 y (x x_int=z z_int) `controls' [aw=popc1940], r
		cap drop eps
		predict eps, residuals

		preserve
			ssaggregate y x x_int eps [aw=popc1940], n(origin_fips) s(share) sfilename("$INTDATA/ssaggregate_prep/shares_base.dta") l(cz) controls("`controls'") 
			rename (y x x_int eps s_n) (y1 x1 x_int1 eps1 s_n1)
			tempfile f1
			save `f1'
		restore
	// Aggregate it to the industry (=shift) level with each set of shares: in this case, original and interacted
	* First with original shares

		preserve
		* Now with interacted shares
			ssaggregate y x x_int eps [aw=popc1940], n(origin_fips) s(share_int) sfilename("$INTDATA/ssaggregate_prep/shares_base_int.dta") l(cz) controls("`controls'") 
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
			
			local b_iv10_x_`int'_`outcome' = b[1,1]
			local b_iv10_x_int_`int'_`outcome' = b[2,1]
			local se_iv10_x_`int'_`outcome' = V[1,1]^0.5
			local se_iv10_x_int_`int'_`outcome' = V[2,2]^0.5
		restore
	}
	
		
	foreach m in iv70 iv10{
		foreach v in x x_int{
			foreach outcome in cgoodman spdist gen_muni totfrac schdist_ind{
				di "HERE"
				local z = abs(scalar(`b_`m'_`v'_`int'_`outcome'') / scalar(`se_`m'_`v'_`int'_`outcome''))
				di "`z'"
				local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
				di "`n_stars'"
				local b_`m'_`v'_`int'_`outcome' = string(`b_`m'_`v'_`int'_`outcome'',"%9.3f") + "`n_stars'"
				local se_`m'_`v'_`int'_`outcome' = string(`se_`m'_`v'_`int'_`outcome'',"%9.3f") 
			}
		}
	}
}




capture file close fh
file open fh using "$TABS/final/occscore_links_diffs_ss.tex", write replace
file write fh "\begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}" _n

 
file write fh "&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" _n
file write fh "\cmidrule[1pt](lr){1-6}" _n
file write fh "\multicolumn{6}{c}{Black Migrant Differences \textit{Relative to other Black Migrants}}\\" _n
file write fh "\cmidrule[1pt](lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Panel A: IV 1940-1970}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "GM  &    `b_iv70_x_links_cgoodman' &    `b_iv70_x_links_gen_muni' &    `b_iv70_x_links_schdist_ind' &    `b_iv70_x_links_spdist' &    `b_iv70_x_links_totfrac' \\" _n
file write fh "                &  (`se_iv70_x_links_cgoodman')  &  (`se_iv70_x_links_gen_muni')  &  (`se_iv70_x_links_schdist_ind')  &  (`se_iv70_x_links_spdist')  &  (`se_iv70_x_links_totfrac')  \\" _n
file write fh  "GM X Above Median  &    `b_iv70_x_int_links_cgoodman' &    `b_iv70_x_int_links_gen_muni' &    `b_iv70_x_int_links_schdist_ind' &    `b_iv70_x_int_links_spdist' &    `b_iv70_x_int_links_totfrac' \\" _n
file write fh "                &  (`se_iv70_x_int_links_cgoodman')  &  (`se_iv70_x_int_links_gen_muni')  &  (`se_iv70_x_int_links_schdist_ind')  &  (`se_iv70_x_int_links_spdist')  &  (`se_iv70_x_int_links_totfrac')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Panel B: IV 1940-2010}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "GM  &    `b_iv10_x_links_cgoodman' &    `b_iv10_x_links_gen_muni' &    `b_iv10_x_links_schdist_ind' &    `b_iv10_x_links_spdist' &    `b_iv10_x_links_totfrac' \\" _n
file write fh "                &  (`se_iv10_x_links_cgoodman')  &  (`se_iv10_x_links_gen_muni')  &  (`se_iv10_x_links_schdist_ind')  &  (`se_iv10_x_links_spdist')  &  (`se_iv10_x_links_totfrac')  \\" _n
file write fh  "GM X Above Median  &    `b_iv10_x_int_links_cgoodman' &    `b_iv10_x_int_links_gen_muni' &    `b_iv10_x_int_links_schdist_ind' &    `b_iv10_x_int_links_spdist' &    `b_iv10_x_int_links_totfrac' \\" _n
file write fh "                &  (`se_iv10_x_int_links_cgoodman')  &  (`se_iv10_x_int_links_gen_muni')  &  (`se_iv10_x_int_links_schdist_ind')  &  (`se_iv10_x_int_links_spdist')  &  (`se_iv10_x_int_links_totfrac')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n

file write fh "Below Median 1940-70 Avg. &      `mean70_links_cgoodman'   &      `mean70_links_gen_muni'   &      `mean70_links_schdist_ind'   &      `mean70_links_spdist'   &      `mean70_links_totfrac'   \\" _n
file write fh "Below Median 1940-2010 Avg. &      `mean10_links_cgoodman'   &      `mean10_links_gen_muni'   &      `mean10_links_schdist_ind'   &      `mean10_links_spdist'   &      `mean10_links_totfrac'   \\" _n
file write fh "Observations    &      `nobs_links_cgoodman'   &      `nobs_links_gen_muni'   &      `nobs_links_schdist_ind'   &      `nobs_links_spdist'   &      `nobs_links_totfrac'   \\" _n

file write fh "\cmidrule[1pt](lr){1-6}" _n
file write fh "\multicolumn{6}{c}{Black Migrant Differences \textit{Relative to Destination Residents}}\\" _n
file write fh "\cmidrule[1pt](lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Panel C: IV 1940-1970}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "GM  &    `b_iv70_x_diff_cgoodman' &    `b_iv70_x_diff_gen_muni' &    `b_iv70_x_diff_schdist_ind' &    `b_iv70_x_diff_spdist' &    `b_iv70_x_diff_totfrac' \\" _n
file write fh "                &  (`se_iv70_x_diff_cgoodman')  &  (`se_iv70_x_diff_gen_muni')  &  (`se_iv70_x_diff_schdist_ind')  &  (`se_iv70_x_diff_spdist')  &  (`se_iv70_x_diff_totfrac')  \\" _n
file write fh  "GM X Above Median  &    `b_iv70_x_int_diff_cgoodman' &    `b_iv70_x_int_diff_gen_muni' &    `b_iv70_x_int_diff_schdist_ind' &    `b_iv70_x_int_diff_spdist' &    `b_iv70_x_int_diff_totfrac' \\" _n
file write fh "                &  (`se_iv70_x_int_diff_cgoodman')  &  (`se_iv70_x_int_diff_gen_muni')  &  (`se_iv70_x_int_diff_schdist_ind')  &  (`se_iv70_x_int_diff_spdist')  &  (`se_iv70_x_int_diff_totfrac')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Panel D: IV 1940-2010}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "GM  &    `b_iv10_x_diff_cgoodman' &    `b_iv10_x_diff_gen_muni' &    `b_iv10_x_diff_schdist_ind' &    `b_iv10_x_diff_spdist' &    `b_iv10_x_diff_totfrac' \\" _n
file write fh "                &  (`se_iv10_x_diff_cgoodman')  &  (`se_iv10_x_diff_gen_muni')  &  (`se_iv10_x_diff_schdist_ind')  &  (`se_iv10_x_diff_spdist')  &  (`se_iv10_x_diff_totfrac')  \\" _n
file write fh  "GM X Above Median  &    `b_iv10_x_int_diff_cgoodman' &    `b_iv10_x_int_diff_gen_muni' &    `b_iv10_x_int_diff_schdist_ind' &    `b_iv10_x_int_diff_spdist' &    `b_iv10_x_int_diff_totfrac' \\" _n
file write fh "                &  (`se_iv10_x_int_diff_cgoodman')  &  (`se_iv10_x_int_diff_gen_muni')  &  (`se_iv10_x_int_diff_schdist_ind')  &  (`se_iv10_x_int_diff_spdist')  &  (`se_iv10_x_int_diff_totfrac')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n

file write fh "Below Median 1940-70 Avg. &      `mean70_diff_cgoodman'   &      `mean70_diff_gen_muni'   &      `mean70_diff_schdist_ind'   &      `mean70_diff_spdist'   &      `mean70_diff_totfrac'   \\" _n
file write fh "Below Median 1940-2010 Avg. &      `mean10_diff_cgoodman'   &      `mean10_diff_gen_muni'   &      `mean10_diff_schdist_ind'   &      `mean10_diff_spdist'   &      `mean10_diff_totfrac'   \\" _n
file write fh "Observations    &      `nobs_diff_cgoodman'   &      `nobs_diff_gen_muni'   &      `nobs_diff_schdist_ind'   &      `nobs_diff_spdist'   &      `nobs_diff_totfrac'   \\" _n
file write fh "\bottomrule \end{tabularx}" _n


file close fh