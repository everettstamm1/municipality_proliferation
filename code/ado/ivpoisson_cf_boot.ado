

capture program drop ivpoisson_cf_boot
program define ivpoisson_cf_boot, eclass
    syntax, depvar(varname) endog(varname) exog(varlist) controls(varlist) ///
        weight(varname) reps(integer) seed(integer) exposure(varname)

		
	//local depvar b_cgoodman_cz1970
	//local endog GM_raw_pp
	//local exog shift_share_base 
	//local controls reg2 reg3 reg4 sumshare_base mean_income_1940 mfg_lfshare1940 cz_popdens1940 b_cgoodman_cz1940
	//local weight popc1940
	//local reps 20
	//local seed 20260409

    tempvar touse
    tempname b V

    quietly ivpoisson cfunction `depvar' ///
        (`endog' = `exog') `controls' ///
        [aw=`weight'], nolog exposure(`exposure')

    gen byte `touse' = e(sample)
    local N = e(N)

    matrix `b' = J(1,1,_b[`endog'])
    matrix colnames `b' = `endog'
    preserve
        quietly simulate b = r(b) rc = r(rc), ///
				reps(`reps') seed(`seed') nodots: ///
				_oneboot_ivp_cf, ///
					depvar(`depvar') ///
					endog(`endog') ///
					exog(`exog') ///
					exposure(`exposure') ///
					controls(`controls') ///
					weight(`weight')

        count if !missing(b)
        local reps_ok = r(N)

        count if missing(b)
        local reps_fail = r(N)

        if (`reps_ok' == 0) {
            restore
            error 2000
        }

        quietly summarize b if !missing(b)
        matrix `V' = J(1,1,r(Var))

    restore
    matrix colnames `V' = `endog'
    matrix rownames `V' = `endog'

    ereturn post `b' `V', esample(`touse')
    ereturn scalar N = `N'
    ereturn scalar reps = `reps'
    ereturn scalar reps_ok = `reps_ok'
    ereturn scalar reps_fail = `reps_fail'
    ereturn local cmd "ivpoisson_cf_boot"
    ereturn local vcetype "Bootstrap"
    ereturn local vce "bootstrap"
    ereturn local depvar "`depvar'"
end