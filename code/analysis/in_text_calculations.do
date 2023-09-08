/// Introduction

// Decline in number of local governments
use "$INTDATA/cog/2_county_counts.dta", clear

collapse (sum) all_local schdist_ind spdist, by(year)