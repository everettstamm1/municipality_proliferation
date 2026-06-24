/*******************************************************************************
Project: Municipality Proliferation
Purpose: Install user-written Stata packages needed by code/master.do.

Run directly from the repository root:

    do code/setup_stata_packages.do

code/master.do also calls this script when local setup_dependencies is 1.
This script requires internet access to SSC.
*******************************************************************************/

version 17.0
set more off

display as text "Checking user-written Stata package dependencies..."

local lockfile "$CODE/dependencies/stata_packages.csv"
capture confirm file "`lockfile'"
if _rc {
    local lockfile "code/dependencies/stata_packages.csv"
}
capture confirm file "`lockfile'"
if _rc {
    display as error "Could not find code/dependencies/stata_packages.csv."
    display as error "Run this script from the repository root or define global CODE first."
    exit 601
}

local failures ""

preserve
import delimited using "`lockfile'", varnames(1) stringcols(_all) clear

foreach required in package probe source {
    capture confirm variable `required'
    if _rc {
        display as error "Stata dependency lock is missing column: `required'"
        restore
        exit 498
    }
}

forvalues i = 1/`=_N' {
    local pkg = package[`i']
    local probe = probe[`i']
    local source = lower(source[`i'])

    if trim("`pkg'") == "" {
        continue
    }
    if trim("`probe'") == "" {
        local probe "`pkg'"
    }
    if trim("`source'") != "ssc" {
        display as error "Unsupported Stata package source for `pkg': `source'"
        local failures "`failures' `pkg'"
        continue
    }

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
restore

if trim("`failures'") != "" {
    display as error "The following packages could not be installed:`failures'"
    display as error "Check internet access, SSC availability, or install them manually."
    exit 499
}

display as result "Stata package setup complete."
