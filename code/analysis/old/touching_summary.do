// What do we know about touching municipalities

// At CZ level

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot
duplicates drop

// Question: are the target munis (new munis in 1940-70) more or less likely to be touching the principle city
su touching if samp_dest == 0, d // mean = 0.077
su touching if samp_dest == 1, d // mean = 0.199

// Extension: compare to pre and post incorporations
su touching if yr_incorp > 1970, d // mean = 0.176
su touching if yr_incorp < 1940, d // mean = 0.069
// Answer: looks like it!

// Question: Are the target munis more likely to be touching in a CZ with above median levels of GM? 
// Motivation: if they're less likely, this may be white flight instead of fighting annexation
su touching if above_x_med == 0 & samp_dest == 1, d // mean = 0.209
su touching if above_x_med == 1 & samp_dest == 1, d // mean = 0.195

su touching if above_x_med == 1 & samp_dest == 0, d 
su touching if above_x_med == 1 & samp_dest == 1, d 
// Answer: seems slightly less likely, but close either way


// Question: Are the touching munis more or less white
su prop_white1970 if touching == 0, d // mean = 0.970
su prop_white1970 if touching == 1, d // mean = 0.958
// Answer: About the same in aggregate

// Extension: Does this change by being a target muni
su prop_white1970 if touching == 0 & samp_dest == 1, d // mean = 0.966
su prop_white1970 if touching == 1 & samp_dest == 1, d // mean = 0.972
// Answer: still small differences, but the sign does flip

// Extension: Does this change by being a target muni and in above median GM
su prop_white1970 if touching == 0 & samp_dest == 1 & above_x_med == 1, d // mean = 0.963
su prop_white1970 if touching == 1 & samp_dest == 1 & above_x_med == 1, d // mean = 0.972
// Answer: Gap widens!

// Question: Do these touching munis have more or less restrictive zoning
su landuse_sfr if touching == 0 , d // mean = 76.9
su landuse_sfr if touching == 1 , d // mean = 77.9
// Answer: Slightly more

// Extension: For target munis
su landuse_sfr if touching == 0 & samp_dest == 1, d // mean = 78.7
su landuse_sfr if touching == 1 & samp_dest == 1, d // mean = 80.84
// Answer: Gap widens!

// Extension: in above median GM CZs
su landuse_sfr if touching == 0 & samp_dest == 1 & above_x_med == 1, d // mean = 82.6
su landuse_sfr if touching == 1 & samp_dest == 1 & above_x_med == 1, d // mean = 85.3
// Answer: Gap widens!

// Question: Are these touching munis schools any different?
g prop_white_students = wtenroll_place / totenroll_place
su prop_white_students if touching == 0, d // mean = 0.730
su prop_white_students if touching == 1, d // mean = 0.537
// Answer: They're much less white! 

// Extension: Does this change being a target muni
su prop_white_students if touching == 0 & samp_dest == 1, d // mean = 0.567
su prop_white_students if touching == 1 & samp_dest == 1, d // mean = 0.546
// Gap closes massively

// Extension: in above median GM CZs
su prop_white_students if touching == 0 & samp_dest == 1 & above_x_med == 1, d // mean = 0.517
su prop_white_students if touching == 1 & samp_dest == 1 & above_x_med == 1, d // mean = 0.555
// Sign flips!


// Question: Are these touching munis likely to have their own school district?
g single_school = n_schools == 1

su single_school if touching == 0, d // mean = 0.351
su single_school if touching == 1, d // mean = 0.377
// Answer: Slightly!

// Extension: Does this change being a target muni
su single_school if touching == 0 & samp_dest == 1, d // mean = 0.278
su single_school if touching == 1 & samp_dest == 1, d // mean = 0.221
// Huge sign flip!

// Extension: in above median GM CZs
su single_school if touching == 0 & samp_dest == 1 & above_x_med == 1, d // mean = 0.281
su single_school if touching == 1 & samp_dest == 1 & above_x_med == 1, d // mean = 0.292
// Sign flips back!

// Question: Are these touching munis likely to send their kids elsewhere for school?

g no_school = n_schools == 0

su no_school if touching == 0, d // mean = 0.595
su no_school if touching == 1, d // mean = 0.483
// Answer: Less likely!

// Extension: Does this change being a target muni
su no_school if touching == 0 & samp_dest == 1, d // mean = 0.656
su no_school if touching == 1 & samp_dest == 1, d // mean = 0.674
// Huge sign flip!

// Extension: in above median GM CZs
su no_school if touching == 0 & samp_dest == 1 & above_x_med == 1, d // mean = 0.644
su no_school if touching == 1 & samp_dest == 1 & above_x_med == 1, d // mean = 0.593
// Sign flips back!

// Question: Are their schools smaller?
su totenroll_place if touching == 0, d // mean = 590.8
su totenroll_place if touching == 1, d // mean = 1106.15
// Answer: Much bigger!

// Extension: Does this change being a target muni
su totenroll_place if touching == 0 & samp_dest == 1, d // mean = 620.6
su totenroll_place if touching == 1 & samp_dest == 1, d // mean = 741.7
// Closes the gap

// Extension: in above median GM CZs
su totenroll_place if touching == 0 & samp_dest == 1 & above_x_med == 1, d // mean = 717.7
su totenroll_place if touching == 1 & samp_dest == 1 & above_x_med == 1, d // mean = 770.5
// Closes the gap, but still bigger


// DOUBLE/TRIPLE INTERACTIONS

// Comparing the effect of incorporation for touching munis in above median CZs 
************ TOUCHING ************
reg touching samp_dest##above_x_med
margins, dydx(samp_dest) at(above_x_med = 1) // 0.002 

// 40-70 Munis more likely to be touching in above median GM CZs

************ FIRST STAGE ************

reg prop_white1970 above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.002 

reg prop_white1970 above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.026
// More white!

************ LAND USE ************


reg landuse_sfr above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 3.84

reg landuse_sfr above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 7.56
// More restrictive land use!


************ SCHOOLS ************

reg prop_white_students above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.156

reg prop_white_students above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.064
// More white students, but only when accounting for touching
asdf

reg totenroll_place above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -19.47

reg totenroll_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -589.8
// Smaller schools!

reg no_school above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.074

reg no_school above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.225
// More without a school!

reg single_school above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.086

reg single_school above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.166
// Fewer with a single high school

reg ap_mean above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.071

reg ap_mean above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.166
// Lower proportion of schools with an AP program controlling for touching, higher otherwise

reg wtenroll_hasap_place above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -3.58

reg wtenroll_hasap_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -21.7
// Lower proportion of white students go to a school with an AP program

reg st_ratio_mean above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 3.09

reg st_ratio_mean above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.68
// Higher student teacher ratio

reg vr_blwt_place above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.112

reg vr_blwt_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.024
// Higher place level black white variance ratio (so more segregated)

reg vr_blwtas_place above_x_med##samp_dest 
margins, dydx(samp_dest) at(above_x_med = 1) // -0.118

reg vr_blwtas_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.045
// Higher place level black-whas variance ratio (so more segregated)
// Add n_schools>1 to get stronger effects (as single school munis have vr = 0 by construction)

reg vr_blwt_cz above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.005

reg vr_blwt_cz above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.018
// Higher place level black white variance ratio (so more segregated)

reg vr_blwtas_cz above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.005

reg vr_blwtas_cz above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.024
// Higher place level black-whas variance ratio (so more segregated)
// Add n_schools>1 to get stronger effects (as single school munis have vr = 0 by construction)
// RUN IN MAIN SPEC

************ POLICE ************

reg pct_exp_pol above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 6.25

reg pct_exp_pol above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 3.46
// Larger share towards police

reg pc_pol above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 2.92

reg pc_pol above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) //-9.58
// More, then less per capita towards police

reg pct_rev_ff above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 1.29

reg pct_rev_ff above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 1.21
// Larger share towards fines and forfeitures

************ AMENITIES ************

reg pct_exp_parks above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 1.44

reg pct_exp_parks above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.417
// Larger share towards parks and rec

reg pc_parks above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 4.5

reg pc_parks above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 10.13
// More per capita towards parks and rec


reg pct_exp_lib above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.309

reg pct_exp_lib above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.562
// Lower share towards libraries

reg pc_lib above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.916

reg pc_lib above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -1.27
// Less per capita towards libraries


reg pct_exp_transit above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.17

reg pct_exp_transit above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.034
// Lower share towards transit

reg pc_transit above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -1.64

reg pc_transit above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.119
// Less per capita towards transit

reg alltransit_performance_score above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 1.05

reg alltransit_performance_score above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -1.01
// Better transit score, until you account for touching

// 2/3 interactions over 
reg len_edge_edge samp_dest##above_x_med if !(len_edge_edge > 0 & touching==1) | !(len_edge_edge == 0 & touching==0) [aw=popc1940], r
asdfasd
// Comparing the effect of incorporation for touching munis in above median CZs 

************ TOUCHING ************
reg touching samp_dest##above_x_med
margins, dydx(samp_dest) at(above_x_med = 1) // 0.002 

// 40-70 Munis more likely to be touching in above median GM CZs

************ FIRST STAGE ************

reg prop_white1970 above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.002 

reg prop_white1970 above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.026
// More white!

************ LAND USE ************


reg landuse_sfr above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 3.84

reg landuse_sfr above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 7.56
// More restrictive land use!


************ SCHOOLS ************

reg prop_white_students above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.156

reg prop_white_students above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.064
// More white students, but only when accounting for touching


reg totenroll_place above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -19.47

reg totenroll_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -589.8
// Smaller schools!

reg no_school above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.074

reg no_school above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.225
// More without a school!

reg single_school above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.086

reg single_school above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.166
// Fewer with a single high school

reg ap_mean above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.071

reg ap_mean above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.166
// Lower proportion of schools with an AP program controlling for touching, higher otherwise

reg wtenroll_hasap_place above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -3.58

reg wtenroll_hasap_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -21.7
// Lower proportion of white students go to a school with an AP program

reg st_ratio_mean above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 3.09

reg st_ratio_mean above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.68
// Higher student teacher ratio

reg vr_blwt_place above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.112

reg vr_blwt_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.024
// Higher place level black white variance ratio (so more segregated)

reg vr_blwtas_place above_x_med##samp_dest 
margins, dydx(samp_dest) at(above_x_med = 1) // -0.118

reg vr_blwtas_place above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.045
// Higher place level black-whas variance ratio (so more segregated)
// Add n_schools>1 to get stronger effects (as single school munis have vr = 0 by construction)

reg vr_blwt_cz above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.005

reg vr_blwt_cz above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.018
// Higher place level black white variance ratio (so more segregated)

reg vr_blwtas_cz above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 0.005

reg vr_blwtas_cz above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.024
// Higher place level black-whas variance ratio (so more segregated)
// Add n_schools>1 to get stronger effects (as single school munis have vr = 0 by construction)
// RUN IN MAIN SPEC

************ POLICE ************

reg pct_exp_pol above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 6.25

reg pct_exp_pol above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 3.46
// Larger share towards police

reg pc_pol above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 2.92

reg pc_pol above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) //-9.58
// More, then less per capita towards police

reg pct_rev_ff above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 1.29

reg pct_rev_ff above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 1.21
// Larger share towards fines and forfeitures

************ AMENITIES ************

reg pct_exp_parks above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 1.44

reg pct_exp_parks above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 0.417
// Larger share towards parks and rec

reg pc_parks above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 4.5

reg pc_parks above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // 10.13
// More per capita towards parks and rec


reg pct_exp_lib above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.309

reg pct_exp_lib above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.562
// Lower share towards libraries

reg pc_lib above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.916

reg pc_lib above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -1.27
// Less per capita towards libraries


reg pct_exp_transit above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -0.17

reg pct_exp_transit above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.034
// Lower share towards transit

reg pc_transit above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // -1.64

reg pc_transit above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -0.119
// Less per capita towards transit

reg alltransit_performance_score above_x_med##samp_dest
margins, dydx(samp_dest) at(above_x_med = 1) // 1.05

reg alltransit_performance_score above_x_med##samp_dest##touching
margins, dydx(samp_dest) at(above_x_med = 1 touching = 1) // -1.01
// Better transit score, until you account for touching


// Muni level stuff 

use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1
g one_school = n_schools == 1
g no_school = n_schools == 0

drop wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot
duplicates drop

// Creating interactions
g samp_destXtouching = samp_dest * touching
g above_x_medXtouching = above_x_med * touching
g samp_destXabove_x_medXtouching = above_x_med * samp_dest * touching

g samp_destXlee = samp_dest * len_edge_edge
g above_x_medXlee = above_x_med * len_edge_edge
g samp_destXabove_x_medXlee = above_x_med * samp_dest * len_edge_edge

// Target munis: those who incorporated during the Great migration and received above median GM levels

// 0-th stage

su len_edge_edge, d
g above_len_med = len_edge_edge >= r(p50)

// The hypothesis we want to test is whether these new municipalities are "just" white flight to suburbs/exurbs
// Raw splits
reg touching samp_dest above_x_med samp_destXabove_x_med if main_city == 0  // Null result: cannot say they're more likely to be touching
reg len_edge_edge samp_dest above_x_med samp_destXabove_x_med if main_city == 0 // Negative result: places are closer to center city! <------ USE THIS
reg above_len_med samp_dest above_x_med samp_destXabove_x_med if main_city == 0 // Negative result: places are closer to center city! <------ USE THIS

// Document they're whiter
reg prop_white1970 samp_dest##above_x_med // Whiter, but interaction not significant
reg prop_white1970 samp_dest##above_x_med if above_len_med == 0 // Not significant

// One/no School
reg one_school samp_dest##above_x_med // Less likely, not significant
reg one_school samp_dest##above_x_med if above_len_med == 0 // more likely, not significant
reg no_school samp_dest##above_x_med // Less likely, not significant
reg no_school samp_dest##above_x_med if above_len_med == 0 // more likely, not significant

// Exclusive district
reg exclusive_district samp_dest##above_x_med // Less likely, not significant
reg exclusive_district samp_dest##above_x_med if above_len_med == 0 // more likely, not significant

// Enrollment
reg avg_totenroll_place samp_dest##above_x_med // Smaller, but not significantly
reg avg_totenroll_place samp_dest##above_x_med if above_len_med == 0 // Significantly smaller

// Landuse
reg landuse_sfr samp_dest##above_x_med // Smaller, but not significantly
reg landuse_sfr samp_dest##above_x_med if above_len_med == 0 // Significantly smaller
reg landuse_apartment samp_dest##above_x_med // Smaller, but not significantly
reg landuse_apartment samp_dest##above_x_med if above_len_med == 0 // Significantly smaller

// Police
reg pct_exp_pol samp_dest##above_x_med // Smaller, but not significantly
reg pct_exp_pol samp_dest##above_x_med if above_len_med == 0 // Significantly smaller
reg pc_pol samp_dest##above_x_med // Smaller, but not significantly
reg pc_pol samp_dest##above_x_med if above_len_med == 0 // Significantly smaller
reg pct_rev_ff samp_dest##above_x_med // Smaller, but not significantly
reg pct_rev_ff samp_dest##above_x_med if above_len_med == 0 // Significantly smaller

// Transit
reg alltransit_performance_score samp_dest##above_x_med
reg alltransit_performance_score samp_dest##above_x_med if above_len_med == 0

// White AP access
reg wtenroll_hasap_place samp_dest##above_x_med
reg wtenroll_hasap_place samp_dest##above_x_med if above_len_med == 0


// Table 2 setup

// 0-th stage
reghdfe touching samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
reghdfe len_edge_edge samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)
reghdfe above_len_med samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if main_city == 0 [aw = weight_pop], vce(cl cz)

// Document they're whiter

reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe prop_white1970 samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work


// Document their schools are whiter

reghdfe prop_white_students samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe prop_white_students samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

// One/no school
reghdfe one_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe one_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

reghdfe no_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe no_school samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

// Exclusive district
reghdfe exclusive_district samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe exclusive_district samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

// Enrollment
reghdfe avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe avg_totenroll_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work


// Landuse
reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe landuse_sfr samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work
reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe landuse_apartment samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work


// Police
reghdfe pct_exp_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe pct_exp_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work
reghdfe pc_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe pc_pol samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work
reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe pct_rev_ff samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

// Transit
reghdfe alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe alltransit_performance_score samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

// White AP Access
reghdfe wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest [aw = weight_pop], vce(cl cz) // Does work
reghdfe wtenroll_hasap_place samp_dest above_x_med samp_destXabove_x_med reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban *_samp_dest if above_len_med == 0 [aw = weight_pop], vce(cl cz) // Does work

// CZ Level stuff

use "$CLEANDATA/mechanisms.dta", clear
keep cz GM_raw_pp GM_hat_raw coastal transpo_cost_1920 v2_sumshares_urban popc1940 ap_gini_cz above_x_med vr_blwt_cz vr_blwtas_cz avg_alltransit_cz vr_bl_cz
duplicates drop
merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(3) keepusing(reg2 reg3 reg4 frac_unc* frac_uninc* change_frac_unc n_schdist_ind_cz) nogen // Need to get right regions...
g schoolflag = n_schdist_ind_cz < .
// Raw differences
// GINI
su ap_gini_cz if above_x_med == 0, d
su ap_gini_cz if above_x_med == 1, d

// VR
su vr_blwt_cz if above_x_med == 0, d
su vr_blwt_cz if above_x_med == 1, d

// Transit Score
su avg_alltransit_cz if above_x_med == 0, d
su avg_alltransit_cz if above_x_med == 1, d

// Fraction unincorporated
su change_frac_unc if above_x_med == 0, d
su change_frac_unc if above_x_med == 1, d

su frac_uninc1970 if above_x_med == 0, d
su frac_uninc1970 if above_x_med == 1, d

su frac_uninc2010 if above_x_med == 0, d
su frac_uninc2010 if above_x_med == 1, d


// Second try: full main spec
// GINI
ivreg2 ap_gini_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 ap_gini_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r

// Small positive insig coefficient

// VR
ivreg2 vr_blwt_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 vr_blwtas_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 vr_bl_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r

// Transit Score
ivreg2 avg_alltransit_cz (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r

// Fraction unincorporated
ivreg2 change_frac_unc (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 frac_uninc1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 frac_uninc2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r

