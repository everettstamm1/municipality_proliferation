capture program drop _oneboot_ivp_cf
program define _oneboot_ivp_cf, rclass
    syntax, depvar(varname) endog(varname) exog(varlist) exposure(varname) controls(varlist) weight(varname)

    tempname bhold
    preserve
        bsample
        capture ivpoisson cfunction `depvar' ///
            (`endog' = `exog') `controls' ///
            [aw=`weight'], nolog exposure(`exposure')

        local rc = _rc
        if (`rc' == 0) {
            scalar `bhold' = _b[`endog']
        }
    restore

    if (`rc' == 0) {
        return scalar b = `bhold'
    }
    else {
        return scalar b = .
        return scalar rc = `rc'
    }
end
