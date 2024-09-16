
// Basic municipal variables
use "$CLEANDATA/other/municipal_shapefile_attributes.dta", clear
drop if ak_hi == 1

replace GEOID = 100000*STATEFP +PLACEFP if GEOID==.

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

ren GEOID temp
merge m:1 cz using "$INTDATA/census/maxcitypop", keep(1 3) keepusing(GEOID) nogen
ren GEOID GEOID_main
ren temp GEOID
destring GEOID_main, replace
g main_city = GEOID == GEOID_main

// Dropping noncomparables
/*
drop if FUNCSTAT=="S" | /// "Statistical entities"
		 FUNCSTAT=="F" | /// Fictitious entity created to fill the Census Bureau geographic hierarch
		 FUNCSTAT=="N" | /// Nonfunctioning legal entity	
		 FUNCSTAT=="I" // Inactive governmental unit that has the power to provide primary special-purpose functions
*/	 

g badmuni = (FUNCSTAT=="S" | /// "Statistical entities"
		 FUNCSTAT=="F" | /// Fictitious entity created to fill the Census Bureau geographic hierarch
		 FUNCSTAT=="N" | /// Nonfunctioning legal entity
		 FUNCSTAT=="I" | /// Inactive governmental unit that has the power to provide primary special-purpose functions
		 CLASSFP == "M2") & /// Military bases
		 regexm(NAME,"(balance)") == 0  & /// Need to keep consolidated city governments, classified as "F"
		 GEOID != 1150000 // Washington DC, classified as "N"

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
	keep cz cz_name popc1940 GM_raw_pp GM_hat_raw v2_sumshares_urban transpo_cost_1920 coastal n_schdist_ind_cz_pc pop1940
	g schoolflag = n_schdist_ind_cz_pc < .
	drop n_schdist_ind_cz_pc
	qui su GM_raw_pp, d
	g above_x_med = GM_raw_pp >= `r(p50)'

	qui su GM_hat_raw, d
	g above_inst_med = GM_hat_raw >= `r(p50)'
	tempfile inst
	save `inst'
restore

merge m:1 cz using `inst', keep(3) nogen



// Interactions
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
merge 1:1 fips_state fips_place_2002 using "$INTDATA/census/IndFin12", keep(1 3) nogen keepusing(policeprottotalexp parksrectotalexp transitsubtotalexp librariestotalexpend totalrevenue finesandforfeits specialassessments totaldebtoutstanding totalexpenditure)

g pct_rev_ff = 100*finesandforfeits/totalrevenue
g pct_rev_sa = 100*specialassessments/totalrevenue
g pct_rev_debt = 100*totaldebtoutstanding/totalrevenue
g pct_exp_parks = 100* parksrectotalexp/ totalexpenditure
g pct_exp_transit = 100*transitsubtotalexp / totalexpenditure
g pct_exp_lib = 100*librariestotalexpend / totalexpenditure
g pct_exp_pol = 100*policeprottotalexp / totalexpenditure

g pc_ff = 100*finesandforfeits/population
g pc_sa = 100*specialassessments/population
g pc_debt = 100*totaldebtoutstanding/population
g pc_parks = 100* parksrectotalexp/ population
g pc_transit = 100*transitsubtotalexp / population
g pc_lib = 100*librariestotalexpend / population
g pc_pol = 100*policeprottotalexp / population

ren fips_state STATEFP
ren fips_place_2002 PLACEFP

// To get place level mean school district offerings
merge 1:1 STATEFP PLACEFP using "$INTDATA/nces/place_offerings", keep(1 3) nogen

// To get school  offerings (expands dataset to school district level (crdc_id))
merge 1:m STATEFP PLACEFP using "$INTDATA/nces/offerings", keep(1 3) nogen keepusing(leaid crdc_id totenroll blenroll wtenroll wtasenroll n_ap n_ap_w75 gt de ap ncessch school_level)
merge m:1 leaid using "$INTDATA/nces/leaid_offerings", keep(1 3) nogen 

// CZ level achievement gaps
// Own school district
preserve
	keep STATEFP PLACEFP leaid school_level 
	duplicates drop // Drops repeated elementary middle
	drop if leaid==.
	duplicates tag leaid school_level, gen(dups)
	g exclusive_district = dups == 0
	bys STATEFP PLACEFP : egen exclusive_district_place = max(exclusive_district)
	keep STATEFP PLACEFP exclusive_district_place
	duplicates drop
	tempfile exclusive_district
	save `exclusive_district' 
restore

merge m:1 STATEFP PLACEFP using `exclusive_district', assert(1 3) nogen

replace exclusive_district_place = 0 if mi(exclusive_district_place)

preserve
	use "$CLEANDATA/other/muni_district_overlap.dta", clear
	keep if dist >= 1
	keep GEOID_muni
	duplicates drop 
	ren GEOID_muni GEOID
	tempfile exclusive_district_shapes
	save `exclusive_district_shapes'
restore
merge m:1 GEOID using `exclusive_district_shapes', keep(1 3) 
g exclusive_district_shape = _merge == 3
drop _merge

// Muni school district congruence
preserve
	use "$CLEANDATA/other/muni_district_overlap.dta", clear
	collapse (max) dist, by(GEOID_dist)
	ren GEOID_dist leaid
	ren dist dist_max_int
	tempfile dist_max_int
	save `dist_max_int'
restore

merge m:1 leaid using `dist_max_int', keep(1 3) nogen


merge m:1 leaid using `dist_max_int', keep(1 3) nogen
preserve
	keep GEOID samp_dest
	keep if samp_dest == 1
	ren GEOID GEOID_muni
	duplicates drop
	tempfile incorps
	save `incorps'
	use "$CLEANDATA/other/muni_district_overlap.dta", clear
	merge m:1 GEOID_muni using `incorps', keep(3)
	collapse (sum) dist, by(GEOID_dist)
	ren GEOID_dist leaid
	ren dist dist_int_4070
	tempfile  dist_int_4070
	save `dist_int_4070'
restore

merge m:1 leaid using `dist_int_4070', keep(1 3) nogen

// Equivalence Index
preserve
	keep GEOID leaid cz
	duplicates drop
	tempfile xwalk
	save `xwalk'
	use "$CLEANDATA/other/muni_district_overlap.dta", clear
	drop if dist == 0 | muni == 0
	g EI = 2*((dist^(-1) + muni^(-1))^(-1))
	ren GEOID_muni GEOID
	ren GEOID_dist leaid
	merge 1:1 GEOID leaid using `xwalk', keep(3) nogen
	collapse (mean) EI, by(cz)
	replace EI = 1 if EI > 1
	tempfile EI
	save `EI'
restore

merge m:1 cz using `EI', keep(1 3) nogen


preserve
	use "$CLEANDATA/other/similarity_dist_munis.dta", clear
	// Average min Hausdorff distance, average max muni-schdist shared boundary
	collapse (min) hausdorff, by(GEOID_i)
	ren hausdorff min_hausdorff_muni
	ren GEOID_i GEOID
	tempfile muni_similarity
	save `muni_similarity'
restore

merge m:1 GEOID using `muni_similarity', keep(1 3) nogen

preserve
	use "$CLEANDATA/other/similarity_dist_munis.dta", clear
	// Average min Hausdorff distance, average max muni-schdist shared boundary
	collapse (min) hausdorff, by(GEOID_j)
	ren hausdorff min_hausdorff_dist
	ren GEOID_j leaid
	tempfile dist_similarity
	save `dist_similarity'
restore

merge m:1 leaid using `dist_similarity', keep(1 3) nogen

merge m:1 GEOID using "$INTDATA/other/shared_boundaries_muni", keep(1 3) nogen
merge m:1 leaid using "$INTDATA/other/shared_boundaries_dist", keep(1 3) nogen

replace pmax_shared_boundary_muni = 0 if !mi(GEOID) & mi(pmax_shared_boundary_muni)
replace psum_shared_boundary_muni = 0 if !mi(GEOID) & mi(psum_shared_boundary_muni)
replace pmax_shared_boundary_dist = 0 if !mi(leaid) & mi(pmax_shared_boundary_dist)
replace psum_shared_boundary_dist = 0 if !mi(leaid) & mi(psum_shared_boundary_dist)

preserve
	keep leaid cz pmax_shared_boundary_dist psum_shared_boundary_dist min_hausdorff_dist dist_max_int
	drop if mi(leaid)
	duplicates drop
	collapse (mean) p* min_hausdorff_dist dist_max_int, by(cz)
	ren p* mean_p*
	ren min_hausdorff_dist mean_min_hausdorff_dist
	ren dist_max_int mean_dist_max_int
	tempfile dist_shared
	save `dist_shared'
restore

preserve
	keep GEOID cz pmax_shared_boundary_muni psum_shared_boundary_muni min_hausdorff_muni
	duplicates drop
	collapse (mean) p* min_hausdorff_muni, by(cz)
	ren p* mean_p*
	ren min_hausdorff_muni mean_min_hausdorff_muni
	tempfile muni_shared
	save `muni_shared'
restore

merge m:1 cz using `muni_shared', assert(3) nogen
merge m:1 cz using `dist_shared', assert(3) nogen

// Average School Size
bys PLACEFP STATEFP : egen avg_totenroll_place = mean(totenroll)

// Fraction of white kids in 40-70
g wtenroll_newmuni = wtenroll if samp_dest == 1
g wtenroll_hasap = wtenroll if ap == 1
g wtenroll_hasde = wtenroll if de == 1
g wtenroll_hasgt = wtenroll if gt == 1


lab var wtenroll_newmuni "White Enrollment if incorporated 1940-70"
lab var wtenroll_hasap "White Enrollment if has AP program"
lab var wtenroll_hasde "White Enrollment if has dual enrollment"
lab var wtenroll_hasgt "White Enrollment if has gifted and talented"

// Segregation indices
//drop if badmuni==1
egen tot =rowtotal(blenroll wtenroll), m
egen tot_a =rowtotal(blenroll wtasenroll), m

foreach t in bl wt wtas tot{
	bys cz : egen `t'enroll_cz = total(`t'enroll)
	bys STATEFP PLACEFP : egen `t'enroll_place = total(`t'enroll)
	
}

bys cz : egen tot_cz = total(tot)
bys STATEFP PLACEFP : egen tot_place = total(tot)

bys cz : egen tot_a_cz = total(tot_a)
bys STATEFP PLACEFP : egen tot_a_place = total(tot_a)

g exp1_cz = blenroll / blenroll_cz
g exp1_place = blenroll / blenroll_place

g exp2 = blenroll / tot
g exp2_a = blenroll / tot_a
g exp2_b = blenroll / totenroll

g exp3_cz = exp1_cz * exp2
g exp3_a_cz = exp1_cz * exp2_a
g exp3_b_cz = exp1_cz * exp2_b

g exp3_place = exp1_place * exp2
g exp3_a_place = exp1_place * exp2_a
g exp3_b_place = exp1_place * exp2_b

bys cz : egen iso_cz = total(exp3_cz)
bys STATEFP PLACEFP : egen iso_place = total(exp3_place)

bys cz : egen iso_a_cz = total(exp3_a_cz)
bys STATEFP PLACEFP : egen iso_a_place = total(exp3_a_place)

bys cz : egen iso_b_cz = total(exp3_b_cz)
bys STATEFP PLACEFP : egen iso_b_place = total(exp3_b_place)

g P_blwt_cz = blenroll_cz / (blenroll_cz + wtenroll_cz)
g P_blwtas_cz = blenroll_cz / (blenroll_cz + wtasenroll_cz)
g P_bl_cz = blenroll_cz / (totenroll_cz)

g P_blwt_place = blenroll_place / (blenroll_place + wtenroll_place)
g P_blwtas_place = blenroll_place / (blenroll_place + wtenroll_place)
g P_bl_place = blenroll_place / (totenroll_place)

g vr_blwt_cz = (iso_cz - P_blwt_cz)/(1 - P_blwt_cz)
g vr_blwtas_cz = (iso_a_cz - P_blwtas_cz)/(1 - P_blwtas_cz)
g vr_bl_cz = (iso_b_cz - P_bl_cz)/(1 - P_bl_cz)

g vr_blwt_place = (iso_place - P_blwt_place)/(1 - P_blwt_place)
g vr_blwtas_place = (iso_a_place - P_blwtas_place)/(1 - P_blwtas_place)
g vr_bl_place = (iso_b_place - P_bl_place)/(1 - P_bl_place)


foreach level in cz place{
	local levelvars = cond("`level'"=="cz", "cz", "STATEFP PLACEFP") 
	foreach y in newmuni hasap hasde hasgt{
		bys `levelvars' : egen wtenroll_`y'_`level' = total(100*wtenroll_`y'/wtenroll_`level')
		
		local lb : variable label wtenroll_`y'
		lab var wtenroll_`y'_`level' "`lb', `level' percentage"

	}
}

// Dissimilarity Index
g num_blwt = tot * abs(exp2 - P_blwt_cz)
g denom_blwt = 2 *(blenroll_cz + wtenroll_cz) *P_blwt_cz*(1-P_blwt_cz)
bys cz : egen diss_blwt_cz =  total(0.5 *num_blwt/denom_blwt)

g num_blwtas = (tot_a) * abs(exp2_a - P_blwtas_cz)
g denom_blwtas = 2 *(blenroll_cz + wtasenroll_cz) *P_blwtas_cz*(1-P_blwtas_cz)
bys cz : egen diss_blwtas_cz =  total(0.5 *num_blwtas/denom_blwtas)

g num_bl = totenroll * abs(exp2_b - P_bl_cz)
g denom_bl = 2 *totenroll_cz *P_bl_cz*(1-P_bl_cz)
bys cz : egen diss_bl_cz =  total(0.5 *num_bl/denom_bl)

drop exp1* exp2* exp3* iso_* P_* tot_*  num_* denom_*

// Interactions

foreach var of varlist v2_sumshares_urban coastal transpo_cost_1920 reg2 reg3 reg4{
	local lb : variable label `var'
	g `var'_samp_dest = `var'*samp_dest
	lab var `var'_samp_dest "`lb' X Incorporated 1940-70"
}


// AP Gini
preserve
	keep if school_level == 3
	keep cz crdc_id totenroll totenroll_cz n_ap 
	drop if mi(crdc_id) | mi(totenroll) | mi(n_ap) | n_ap == 0

	expand totenroll
	
	ren n_ap y_i
	bys cz (y_i crdc_id) : g i = _n
	bys cz (y_i crdc_id) : g n = _N
	
	bys cz (y_i crdc_id ) : egen num = total( (n + 1 - i) * y_i ) 
	bys cz (y_i crdc_id) : egen denom = total( y_i )
	g innerterm = num / denom
	g ap_gini_cz = (1/n)*(n + 1 - 2 * innerterm)
	keep ap_gini_cz cz
	duplicates drop
	tempfile ap_gini_cz
	save `ap_gini_cz'
restore

merge m:1 cz using `ap_gini_cz', assert(3) nogen



merge m:1 STATEFP PLACEFP using "$INTDATA/other/alltransit_data", keep(1 3) nogen


preserve
	keep cz STATEFP PLACEFP alltransit_performance_score population
	drop if mi(alltransit_performance_score) | mi(population)
	duplicates drop
	expand population
	collapse (mean) alltransit_performance_score, by(cz)
	ren alltransit_performance_score avg_alltransit_cz
	tempfile avg_alltransit_cz
	save `avg_alltransit_cz'
restore 

merge m:1 cz using `avg_alltransit_cz', assert(3) nogen

// QGIS OUTPUT

merge m:1 STATEFP PLACEFP using "$INTDATA/other/touching_munis", keep(1 3)
g touching = _merge == 3
drop _merge

merge m:1 STATEFP PLACEFP using "$INTDATA/other/edge_edge", keep(1 3) nogen
replace touching = 1 if len_edge_edge == 0 // Manually checked these six, they all have a corner touching the principle city but QGIS doesn't notice

merge m:1 STATEFP PLACEFP using "$INTDATA/other/center_edge", keep(1 3) nogen



// Number of schools
bys STATEFP PLACEFP : egen n_schools = nvals(crdc_id) if crdc_id != ""
replace n_schools = 0 if n_schools == .


// Race popc
ren STATEFP statefips
ren PLACEFP placefips
merge m:1 statefips placefips using "$CLEANDATA/place_race_pop.dta", keep(3) nogen
ren statefips STATEFP
ren placefips PLACEFP

g prop_white1970 = place_wpop1970 / place_pop1970
g prop_white2010 = place_wpop2010 / place_pop2010
g prop_black1970 = place_bpop1970 / place_pop1970
g prop_black2010 = place_bpop2010 / place_pop2010

merge m:1 cz using "$INTDATA/census/cz_race_pop1970", keep(1 3) nogen keepusing(cz_prop_white1970)
merge m:1 cz using "$INTDATA/census/cz_race_pop", keep(1 3) nogen keepusing(cz_prop_white2010)

preserve
	use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear
	keep PLACEFP STATEFP place_land
	duplicates drop
	destring PLACEFP STATEFP, replace
	tempfile place_land
	save `place_land'
restore 

merge m:1 STATEFP PLACEFP using `place_land', keep(1 3) nogen

merge m:1 cz using "$INTDATA/cog/special_districts_employment", keep(3) nogen

merge m:1 STATEFP PLACEFP using "$INTDATA/census/2010_hh_incomes", keep(1 3) nogen
merge m:1 STATEFP PLACEFP using "$INTDATA/census/1970_hh_incomes_hv", keep(1 3) nogen
merge m:1 STATEFP PLACEFP using "$INTDATA/other/ai_zoning", keep(1 3) nogen

// Filling some missings
bys cz (mean_hh_inc_cz) : replace mean_hh_inc_cz = mean_hh_inc_cz[1] if mi(mean_hh_inc_cz)
bys cz (agg_fam_inc_cz1970) : replace agg_fam_inc_cz1970 = agg_fam_inc_cz1970[1] if mi(agg_fam_inc_cz1970)
bys cz (agg_house_value_cz1970) : replace agg_house_value_cz1970 = agg_house_value_cz1970[1] if mi(agg_house_value_cz1970)

// Labels
lab var st_ratio_leaid "Student Teacher Ratio"
lab var n_ap "Number of AP Classes, NCES"
lab var n_ap_w75 "Number of AP Classes, District of 75pc white, NCES"
lab var wtenroll "White Enrollment, NCES"
lab var blenroll "Black Enrollment, NCES"
lab var totenroll "Total Enrollment, NCES"
lab var gt "Has Gifted and Talented program, NCES"
lab var de "Has dual enrollment program, NCES"

lab var st_ratio_mean "Aggregate Student-Teacher ratio, place level"
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

lab var touching "Municipality Touches Principle City"

lab var n_schools "Number of Schools in Muni"

lab var len_edge_edge "Length to center city (edge-edge)"
lab var len_center_edge "Length to center city (center-edge)"

drop PLACENS NAMELSAD LSAD PCICBSA PCINECTA CLASSFP MTFCC FUNCSTAT ALAND AWATER INTPTLAT INTPTLON south sample_130_czs ak_hi

save "$CLEANDATA/mechanisms", replace

