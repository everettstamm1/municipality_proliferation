
// Basic municipal variables
use "$CLEANDATA/other/municipal_shapefile_attributes.dta", clear
drop if ak_hi == 1

replace landuse_sfr = 100*landuse_sfr
replace landuse_apartment = 100*landuse_apartment 

// Getting regions
preserve 
	use "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", clear
	keep state_id region
	rename state_id STATEFP
	duplicates drop
	tempfile regions
	save `regions'
restore 
merge m:1 STATEFP using `regions', keep(1 3) nogen
tabulate region, gen(reg)	

// Some places span multiple counties, dropping those
drop COUNTYFP cty_fips
duplicates drop


// As a result, we have duplicates in our CZ crosswalk. Force drop with tiebreak on being in sample 130 CZs
duplicates tag STATEFP PLACEFP, gen(dup)
bys STATEFP PLACEFP (sample_130_czs) : drop if dup == 1 & _n == 1
drop dup 

// Dropping noncomparables
drop if FUNCSTAT=="S" | /// "Statistical entities"
		 FUNCSTAT=="F" | /// Fictitious entity created to fill the Census Bureau geographic hierarch
		 FUNCSTAT=="N" | /// Nonfunctioning legal entity	
		 FUNCSTAT=="I" // Inactive governmental unit that has the power to provide primary special-purpose functions
		 



// All cities vs cities in our 130 CZs incorporated 1940-70

g samp_dest = .
replace samp_dest = 1 if (yr_incorp >=1940 & yr_incorp <=1970) & sample_130_czs==1
replace samp_dest = 0 if (yr_incorp <1940 | yr_incorp >1970) & sample_130_czs==1
lab var samp_dest "Incorporated 1940-70"

g weight_none = 1
lab var weight_none "Unweighted"

g weight_pop = population
lab var weight_pop "Weighted by 1940 municipal population"
 
// Getting CZ level variables
preserve
	use "$CLEANDATA/cz_pooled", clear
	keep if dcourt == 1
	keep cz popc1940 GM_raw_pp GM_hat_raw v2_sumshares_urban transpo_cost_1920 coastal
	qui su GM_raw_pp, d
	g above_x_med = GM_raw_pp >= `r(p50)'

	qui su GM_hat_raw, d
	g above_inst_med = GM_hat_raw >= `r(p50)'
	tempfile inst
	save `inst'
restore

merge m:1 cz using `inst', keep(3) nogen


g samp_destXabove_x_med = samp_dest * above_x_med
g samp_destXabove_z_med = samp_dest * above_inst_med

g samp_destXGM = samp_dest * GM_raw_pp

g samp_destXGM_hat = samp_dest * GM_hat_raw

lab var above_inst_med "Above Median $\widehat{GM}$"
lab var samp_destXabove_z_med "Above Median $\widehat{GM}$ X Inc. 1940-70"

lab var above_x_med "Above Median GM"
lab var samp_destXabove_x_med "Above Median GM X Inc. 1940-70"

// Municipal Finance Data
ren STATEFP fips_state
ren PLACEFP fips_place_2002
merge 1:1 fips_state fips_place_2002 using "$INTDATA/census/IndFin12", keep(1 3) nogen keepusing(totalrevenue finesandforfeits specialassessments totaldebtoutstanding)

g pct_rev_ff = 100*finesandforfeits/totalrevenue
g pct_rev_sa = 100*specialassessments/totalrevenue
g pct_rev_debt = 100*totaldebtoutstanding/totalrevenue



ren fips_state STATEFP
ren fips_place_2002 PLACEFP

// To get place level mean school district offerings
merge 1:1 STATEFP PLACEFP using "$INTDATA/nces/place_offerings", keep(1 3) nogen

// To get school district offerings (expands dataset to school district level (crdc_id))
merge 1:m STATEFP PLACEFP using "$INTDATA/nces/offerings", keep(1 3) nogen keepusing(crdc_id totenroll blenroll wtenroll n_ap n_ap_w75 gt de)

lab var n_ap "Number of AP Classes, NCES"
lab var n_ap_w75 "Number of AP Classes, District of 75pc white, NCES"
lab var wtenroll "White Enrollment, NCES"
lab var blenroll "Black Enrollment, NCES"
lab var totenroll "Total Enrollment, NCES"
lab var gt "Has Gifted and Talented program, NCES"
lab var de "Has dual enrollment program, NCES"

lab var ap_mean "Prop of schools with AP classes, place level, NCES"
lab var de_mean "Prop of schools with dual enrollment, place level, NCES"
lab var n_ap_mean "Mean number of AP classes, place level, NCES"
lab var n_ap_var "Variance of number of AP classes, place level, NCES"

lab var weight_full "WRLURI Weight"
lab var weight_metro "WRLURI Metro weight"

foreach land in sfr townhouse residentialnec duplex apartment condo multifam mobilehome triplex{
	lab var landuse_`land' "Percentage of land use zoned for `land', Corelogic"
}
foreach home in single_fam condo duplex apartment{
	lab var `home' "Percentage of units that are `home', Corelogic"
}

lab var land_square_footage "Place square footage, Corelogic"
lab var acres "Place acres, Corelogic"
lab var population "Place Population 1940"
lab var popc1940 "CZ Urban Population, 1940"

lab var pct_rev_ff "Percentage of revenue from fines and forfeitures"
lab var pct_rev_sa "Percentage of revenue from special assessments"
lab var pct_rev_debt "Outstanding debt as a percentage of revenues"

drop PLACENS NAMELSAD LSAD CLASSFP PCICBSA PCINECTA MTFCC FUNCSTAT ALAND AWATER INTPTLAT INTPTLON south sample_130_czs ak_hi
save "$CLEANDATA/mechanisms", replace

