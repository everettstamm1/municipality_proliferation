// Lutz and Sand cleaning

import excel "$RAWDATA/other/ZIP_COUNTY_032010.xlsx", clear firstrow

destring ZIP COUNTY, gen(zip fips)

keep zip fips *_RATIO

save "$XWALKS/zip_cnty_xwalk.dta", replace

import delimited "$RAWDATA/lu_lutz_sand/lu-raw/zip2010_with_closest_cnty_and_cbsa.csv", clear

keep zip fips
save "$XWALKS/zip_cnty_xwalk_lu.dta", replace


// Buildable land

import delimited "$RAWDATA/lu_lutz_sand/buildable-land/zip.csv", clear
ren geoid zip

merge 1:m zip using "$XWALKS/zip_cnty_xwalk_lu.dta", keep(3) nogen
collapse (sum) *land, by(fips)

g frac_unbuildable_1 = (availableland- buildableland)/availableland

keep frac_unbuildable_1 fips

tempfile frac_unbuildable_1
save `frac_unbuildable_1'


import delimited "$RAWDATA/lu_lutz_sand/buildable-land/zip.csv", clear
ren geoid zip

merge 1:m zip using "$XWALKS/zip_cnty_xwalk.dta", keep(3) nogen

g available_fips = availableland*TOT_RATIO
g buildable_fips = buildableland*TOT_RATIO

collapse (sum) *_fips, by(fips)

g frac_unbuildable_2 = (available_fips-buildable_fips)/available_fips
keep frac_unbuildable_2 fips

tempfile frac_unbuildable_2
save `frac_unbuildable_2'

// LU Instrument

import delimited "$RAWDATA/lu_lutz_sand/02-zillow_county_2002_start.csv", clear

g lu_ml_2010 =  lu_ml if index=="2010-01-01"
bys fips (lu_ml_2010): replace lu_ml_2010 = lu_ml_2010[1]

bys fips : egen lu_ml_mean = mean(lu_ml)

keep fips lu_ml_2010 lu_ml_mean
duplicates drop

ren lu_ml_* frac_lu_ml_*
tempfile lu_ml
save `lu_ml'

// Raw LU
import delimited "$RAWDATA/lu_lutz_sand/lu-raw/cnty_2010_with_closest_cbsa.csv", clear

keep fips *cnty*

ren *unavailablecntypolygon* *_*
ren *pct *
keep fips total_*
ren total* frac_total*

merge 1:1 fips using `lu_ml', nogen
merge 1:1 fips using `frac_unbuildable_1', nogen
merge 1:1 fips using `frac_unbuildable_2', nogen

lab var frac_unbuildable_1 "ZIP Code Proportion Unbuildable, LS 2019 XWALK"
lab var frac_unbuildable_2 "ZIP Code Proportion Unbuildable, HUD XWALK"
lab var frac_lu_ml_2010 "LU-ML Instrument, Jan 2010"
lab var frac_lu_ml_mean "LU-ML Instrument, mean 2002-2023"

foreach b in 00 05 10 15 20{
	lab var frac_total_`b' "County Proportion Buildable, `b'pct Buffer"
}
save "$INTDATA/lu_lutz_sand/lu_lutz_sand_indicators", replace