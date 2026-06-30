
use "$CLEANDATA/mechanisms.dta", clear
drop if badmuni==1

drop mean_p* wtasenroll totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de ncessch leaid  tot school_level psum_*_dist pmax_*_dist min_hausdorff_dist dist_max_int dist_int_4070 *_leaid teachers_fte
duplicates drop


merge m:1 cz using "$INTDATA/census/cz_race_pop", keep(1 3) nogen keepusing(cz_wpop2010 cz_bpop2010)
merge m:1 cz using "$INTDATA/census/cz_race_pop1970", keep(1 3) nogen keepusing(cz_wpop1970 cz_bpop1970)

egen cz_pop1970 = rowtotal(cz_bpop1970 cz_wpop1970)
egen cz_pop2010 = rowtotal(cz_bpop2010 cz_wpop2010)

preserve
	use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear

	destring *FP, replace
	//g cty_fips = STATEFP*1000 + COUNTYFP
	merge m:1 cty_fips using "$XWALKS/cw_cty_czone.dta", keep(3) nogen
	ren cty_fips fips
	ren czone cz


	keep cz fips county_land county_total
	duplicates drop
	collapse (sum) county_land county_total, by(cz)
	ren county* cz*
	tempfile cz_land
	save `cz_land'
restore

merge m:1 cz using `cz_land', keep(3) nogen

preserve
	use "$INTDATA/cgoodman/cgoodman_place_county_geog.dta", clear
	keep PLACEFP STATEFP place_land
	duplicates drop
	destring PLACEFP STATEFP, replace
	tempfile place_land
	save `place_land'
restore 

merge 1:1 STATEFP PLACEFP using `place_land', keep(1 3) nogen

drop if place_wpop1970 == . 

// Atkinson Index
g pi_b_1970 = cz_bpop1970/cz_pop1970
g pi_b_2010 = cz_bpop2010/cz_pop2010

g pi_ib_1970 = place_bpop1970/place_pop1970
g pi_ib_2010 = place_bpop2010/place_pop2010
g t_i_1970 = place_pop1970
g t_i_2010 = place_pop2010
g T_1970 = cz_pop1970 

g T_2010 = cz_pop2010

global atkinson_b = 0.1

g num1970 = (1-pi_ib_1970)^(1-$atkinson_b) * pi_ib_1970^$atkinson_b * t_i_1970
g num2010 = (1-pi_ib_2010)^(1-$atkinson_b) * pi_ib_2010^$atkinson_b * t_i_2010

g denom1970 = pi_b_1970 * T_1970
g denom2010 = pi_b_2010 * T_2010

bys cz : egen temp1970 = total(num1970/denom1970)
bys cz : egen temp2010 = total(num2010/denom2010)
g sum1970 = abs(temp1970)^(1/(1-$atkinson_b))
g sum2010 = abs(temp2010)^(1/(1-$atkinson_b))

g atkinson1970 = 1 - (pi_b_1970/(1-pi_b_1970))*sum1970
g atkinson2010 = 1 - (pi_b_2010/(1-pi_b_2010))*sum2010


// Delta index, for whites
g tosum1970 = abs(place_bpop1970/cz_bpop1970 - place_land/cz_land)
bys cz : egen delta1970 = total(0.5 * tosum1970)
g tosum2010 = abs(place_bpop2010/cz_bpop2010 - place_land/cz_land)
bys cz : egen delta2010 = total(0.5 * tosum2010)
drop tosum* sum* num1970 denom1970 num2010 denom2010
// ACO/RCO

// Need cz pops for only munis
foreach y in 1970 2010{
	bys cz : egen cz_pop_munis`y' = total(place_pop`y')

	foreach r in b w{
		bys cz : egen cz_`r'pop_munis`y' = total(place_`r'pop`y')

	}
}
bys cz (place_land) : g sum1970 = sum(place_pop1970)
bys cz (place_land) : g sum2010 = sum(place_pop2010)
g neg_place_land = place_land*-1
bys cz (neg_place_land) : g rsum1970 = sum(place_pop1970)
bys cz (neg_place_land) : g rsum2010 = sum(place_pop2010)

bys cz (place_land) : g nlo1970 = _n if (cz_bpop_munis1970 <= sum1970) & ((cz_bpop_munis1970 > sum1970[_n - 1]) | _n == 1)
bys cz (nlo1970) : replace nlo1970 = nlo1970[1]


bys cz (place_land) : g nlo2010 = _n if (cz_bpop_munis2010 <= sum2010) & ((cz_bpop_munis2010 > sum2010[_n - 1]) | _n == 1)
bys cz (nlo2010) : replace nlo2010 = nlo1970[1]


bys cz (neg_place_land) : g nhi1970 = _n if (cz_bpop_munis1970 <= rsum1970) & ((cz_bpop_munis1970 > rsum1970[_n - 1]) | _n == 1)
bys cz (nhi1970) : replace nhi1970 = nhi1970[1]


bys cz (neg_place_land) : g nhi2010 = _n if (cz_bpop_munis2010 <= rsum2010) & ((cz_bpop_munis2010 > rsum2010[_n - 1]) | _n == 1)
bys cz (nhi2010) : replace nhi2010 = nhi2010[1]

bys cz (place_land) : egen Tlo1970 = total(place_pop1970[_n <= nlo1970])
bys cz (place_land) : egen Tlo2010 = total(place_pop2010[_n <= nlo1970]) 

bys cz (neg_place_land) : egen Thi1970 = total(place_pop1970[_n <= nhi1970])
bys cz (neg_place_land) : egen Thi2010 = total(place_pop2010[_n <= nhi2010]) 


g term2_1970_temp = place_pop1970 * place_land/Tlo1970
bys cz (place_land): egen term2_1970 = total(term2_1970_temp[_n <= nlo1970])


bys cz : egen num1_1970 = total(place_bpop1970 * place_land/cz_bpop_munis1970)
g num1970 = num1_1970 - term2_1970

g denom1_1970_temp = place_pop1970 * place_land/Thi1970
bys cz (neg_place_land): egen denom1_1970 = total(denom1_1970_temp[_n <= nhi1970])
g denom1970 = denom1_1970 - term2_1970

g aco1970 = 1 - (num1970/denom1970)

g term2_2010_temp = place_pop2010 * place_land/Tlo2010
bys cz (place_land): egen term2_2010 = total(term2_2010_temp[_n <= nlo2010])


bys cz : egen num1_2010 = total(place_bpop2010 * place_land/cz_bpop_munis2010)
g num2010 = num1_2010 - term2_2010

g denom1_2010_temp = place_pop2010 * place_land/Thi2010
bys cz (neg_place_land): egen denom1_2010 = total(denom1_2010_temp[_n <= nhi2010])
g denom2010 = denom1_2010 - term2_2010

g aco2010 = 1 - (num2010/denom2010)

drop num* denom*
// RCO
bys cz : egen numnum_1970 = total(place_bpop1970 * place_land/cz_bpop_munis1970)
bys cz : egen numdenom_1970 = total(place_wpop1970 * place_land/cz_wpop_munis1970)
g denomnum_temp1970 = place_pop1970 * place_land / Tlo1970
g denomndenom_temp1970 = place_pop1970 * place_land / Thi1970

bys cz (place_land) : egen denomnum_1970 = total(denomnum_temp1970[_n <= nlo1970])
bys cz (neg_place_land) : egen denomdenom_1970 = total(denomndenom_temp1970[_n <= nhi1970])

g rco1970 = (numnum_1970/numdenom_1970 - 1)/(denomnum_1970/denomdenom_1970 - 1)

bys cz : egen numnum_2010 = total(place_bpop2010 * place_land/cz_bpop_munis2010)
bys cz : egen numdenom_2010 = total(place_wpop2010 * place_land/cz_wpop_munis2010)
g denomnum_temp2010 = place_pop2010 * place_land / Tlo2010
g denomndenom_temp2010 = place_pop2010 * place_land / Thi2010

bys cz (place_land) : egen denomnum_2010 = total(denomnum_temp2010[_n <= nlo2010])
bys cz (neg_place_land) : egen denomdenom_2010 = total(denomndenom_temp2010[_n <= nhi2010])

g rco2010 = (numnum_2010/numdenom_2010 - 1)/(denomnum_2010/denomdenom_2010 - 1)
drop num* denom*

preserve
	keep GEOID place_bpop1970 place_wpop1970 place_bpop2010 place_wpop2010 place_pop1970 place_pop2010
	tempfile pops
	save `pops'
	use "$CLEANDATA/other/touching_dist_munis.dta", clear
	destring GEOID_i GEOID_j, replace
	ren GEOID_i GEOID
	merge m:1 GEOID using `pops', keep(3) nogen
	foreach var of varlist place_bpop1970 place_wpop1970 place_bpop2010 place_wpop2010 place_pop1970 place_pop2010{
		ren `var' `var'_i
	}
	ren GEOID GEOID_i
	ren GEOID_j GEOID
	merge m:1 GEOID using `pops', keep(3) nogen
	foreach var of varlist place_bpop1970 place_wpop1970 place_bpop2010 place_wpop2010 place_pop1970 place_pop2010{
		ren `var' `var'_j
	}
	ren GEOID GEOID_j
	ren touching c_ij_b
	g c_ij_nexpd = exp(-centroid_dist)
	foreach y in 1970 2010{
		foreach t in b nexpd{
			g tt_`t'_`y' = place_pop`y'_i * place_pop`y'_j * c_ij_`t'
			g bb_`t'_`y' = place_bpop`y'_i * place_bpop`y'_j * c_ij_`t'
			g ww_`t'_`y' = place_wpop`y'_i * place_wpop`y'_j * c_ij_`t'
			g bw_`t'_`y' = place_wpop`y'_i * place_bpop`y'_j * c_ij_`t'
		}
	} 
	// Doing inner and outer loop simultaneously
	collapse (sum) tt_* bb_* ww_* bw_*, by(cz)
	
	tempfile clustering_vars
	save `clustering_vars'
restore
	
merge m:1 cz using `clustering_vars', keep(1 3) nogen

foreach y in 1970 2010{
		foreach t in b nexpd{
			g P_bb_`t'_`y' = bb_`t'_`y'/(cz_bpop_munis`y' * cz_bpop_munis`y')
			g P_ww_`t'_`y' =  ww_`t'_`y'/(cz_wpop_munis`y' * cz_wpop_munis`y')
			g P_tt_`t'_`y' =  tt_`t'_`y'/(cz_pop_munis`y' * cz_pop_munis`y')
			g P_bw_`t'_`y' =  bw_`t'_`y'/(cz_bpop_munis`y' * cz_wpop_munis`y')
			
			g SP_`t'_`y' = ((cz_wpop_munis`y' * P_ww_`t'_`y') + (cz_bpop_munis`y' * P_bb_`t'_`y'))/((cz_pop_munis`y' * P_tt_`t'_`y'))
			g RCL_`t'_`y' = (P_bb_`t'_`y'/P_bw_`t'_`y') - 1
		}
}


preserve
	keep GEOID place_bpop1970 place_wpop1970 place_bpop2010 place_wpop2010 place_pop1970 place_pop2010 cz_bpop_munis1970 cz_wpop_munis1970 cz_bpop_munis2010 cz_wpop_munis2010
	tempfile pops
	save `pops'
	use "$CLEANDATA/other/touching_dist_munis.dta", clear
	destring GEOID_i GEOID_j, replace
	ren GEOID_i GEOID
	merge m:1 GEOID using `pops', keep(3) nogen
	foreach var of varlist place_bpop1970 place_wpop1970 place_bpop2010 place_wpop2010 place_pop1970 place_pop2010{
		ren `var' `var'_i
	}
	ren GEOID GEOID_i
	ren GEOID_j GEOID
	merge m:1 GEOID using `pops', keep(3) nogen
	foreach var of varlist place_bpop1970 place_wpop1970 place_bpop2010 place_wpop2010 place_pop1970 place_pop2010{
		ren `var' `var'_j
	}
	ren GEOID GEOID_j
	g c_ij_nexpd = exp(-centroid_dist)
	bys GEOID_i : egen K_denom1970 = total(c_ij_nexpd * place_pop1970_j)
	bys GEOID_i : egen K_denom2010 = total(c_ij_nexpd * place_pop2010_j)
	g K_ij_1970 = c_ij_nexpd * place_pop1970_j/K_denom1970
	g K_ij_2010 = c_ij_nexpd * place_pop2010_j/K_denom2010

	g inner_w_1970 = K_ij_1970 * place_wpop1970_j/place_pop1970_j
	g inner_w_2010 = K_ij_2010 * place_wpop2010_j/place_pop2010_j
	g inner_b_1970 = K_ij_1970 * place_bpop1970_j/place_pop1970_j
	g inner_b_2010 = K_ij_2010 * place_bpop2010_j/place_pop2010_j
	collapse (mean) place_wpop1970_i place_bpop1970_i place_bpop2010_i place_wpop2010_i cz_wpop_munis1970 cz_bpop_munis1970 cz_wpop_munis2010 cz_bpop_munis2010 (sum) inner_*, by(GEOID_i cz)
	
	foreach y in 1970 2010{
		g DP_bb_`y' = (place_bpop`y'/cz_bpop_munis`y')*inner_b_`y'
		g DP_bw_`y' = (place_bpop`y'/cz_bpop_munis`y')*inner_w_`y'
		g DP_wb_`y' = (place_wpop`y'/cz_wpop_munis`y')*inner_b_`y'
		g DP_ww_`y' = (place_wpop`y'/cz_wpop_munis`y')*inner_w_`y'
	}
	
	
	collapse (sum) DP_*, by(cz)
	tempfile distance_decay
	save `distance_decay'
restore
	
merge m:1 cz using `distance_decay', keep(1 3) nogen


g s_vr_bb_1970 = (DP_bb_1970 - cz_bpop_munis1970/cz_pop_munis1970)/(1 - cz_bpop_munis1970/cz_pop_munis1970)
g s_vr_ww_1970 = (DP_ww_1970 - cz_wpop_munis1970/cz_pop_munis1970)/(1 - cz_wpop_munis1970/cz_pop_munis1970)
g s_vr_bb_2010 = (DP_bb_2010 - cz_bpop_munis2010/cz_pop_munis2010)/(1 - cz_bpop_munis2010/cz_pop_munis2010)
g s_vr_ww_2010 = (DP_ww_2010 - cz_wpop_munis2010/cz_pop_munis2010)/(1 - cz_wpop_munis2010/cz_pop_munis2010)

keep cz SP_* RCL_* DP_* atkinson* delta* aco* rco* s_vr_*
duplicates drop

save "$INTDATA/cz_segregation_vars.dta", replace


merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(3) keepusing(coastal transpo_cost_1920 GM_raw_pp GM_hat_raw v2_sumshares_urban reg2 reg3 reg4 frac_unc* frac_uninc* change_frac_unc n_schdist_ind_cz cz_name popc1940) nogen // Need to get 


ivreg2 atkinson1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 atkinson2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r


ivreg2 delta1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 delta2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r


ivreg2 aco1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban  [aw = popc1940], r
ivreg2 aco2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if aco2010 >= 0 & aco2010 <= 1 [aw = popc1940], r


ivreg2 rco1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban  [aw = popc1940], r
ivreg2 rco2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if rco2010 >= -1 & rco2010 <= 1 [aw = popc1940], r


ivreg2 rco1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if rco1970 >= -1 & rco1970 <= 1 [aw = popc1940], r
ivreg2 rco2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban if rco2010 >= -1 & rco2010 <= 1 [aw = popc1940], r


ivreg2 SP_b_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r
ivreg2 SP_b_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig

ivreg2 SP_nexpd_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // Pos
ivreg2 SP_nexpd_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // barely insig pos


ivreg2 RCL_b_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig
ivreg2 RCL_b_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // pos

ivreg2 RCL_nexpd_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // Insig
ivreg2 RCL_nexpd_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig



ivreg2 DP_bb_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // pos
ivreg2 DP_bb_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // pos

ivreg2 DP_bw_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // neg
ivreg2 DP_bw_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r //neg

ivreg2 DP_wb_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig
ivreg2 DP_wb_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r //insig


ivreg2 DP_ww_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig
ivreg2 DP_ww_2010 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r //neg

ivreg2 s_vr_bb_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig
ivreg2 s_vr_ww_1970 (GM_raw_pp = GM_hat_raw) reg2 reg3 reg4 coastal transpo_cost_1920 v2_sumshares_urban [aw = popc1940], r // insig