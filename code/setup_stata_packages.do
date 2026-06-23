/*******************************************************************************
Project: Municipality Proliferation
Purpose: Install user-written Stata packages needed by code/master.do.

Run from the repository root before running code/master.do:

    do code/setup_stata_packages.do

This script requires internet access to SSC. It is intentionally separate from
master.do so package installation is an explicit setup step for replication.
*******************************************************************************/

version 17.0
set more off

display as text "Checking user-written Stata package dependencies..."

local packages ///
    estout ///
    maptile ///
    spmap ///
    shp2dta ///
    parmest ///
    ivreg2 ///
    ranktest ///
    statastates ///
    mdesc ///
    coefplot ///
    rsource ///
    binscatter ///
    keeporder ///
    lincomest ///
    distinct ///
    unique ///
    reghdfe ///
    ftools ///
    labutil ///
    gzsave ///
    egenmore

local probes ///
    esttab ///
    maptile ///
    spmap ///
    shp2dta ///
    parmest ///
    ivreg2 ///
    ranktest ///
    statastates ///
    mdesc ///
    coefplot ///
    rsource ///
    binscatter ///
    keeporder ///
    lincomest ///
    distinct ///
    unique ///
    reghdfe ///
    ftools ///
    labmask ///
    gzuse ///
    _gends

local failures ""
local n_packages : word count `packages'

forvalues i = 1/`n_packages' {
    local pkg : word `i' of `packages'
    local probe : word `i' of `probes'

    capture which `probe'
    if _rc {
        display as result "Installing `pkg' from SSC..."
        capture noisily ssc install `pkg', replace
        if _rc {
            display as error "  Failed to install `pkg'."
            local failures "`failures' `pkg'"
        }
    }
    else {
        display as text "`pkg' already available; skipping."
    }
}

if trim("`failures'") != "" {
    display as error "The following packages could not be installed:`failures'"
    display as error "Check internet access, SSC availability, or install them manually."
    exit 499
}

display as result "Stata package setup complete."
display as text "Note: R package setup is separate; see README_template.tex."
