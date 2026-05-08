
use "$INTDATA/ssaggregate_prep/shares_base", clear
drop if mi(origin_fips)
reshape wide share, i(cz) j(origin_fips)

foreach var of varlist share*{
	replace `var' = 0 if mi(`var')
	su `var'
	if r(mean)==0{
		drop `var'
	}
}
rename share* classic_share*

tempfile rots
save `rots'



use "$CLEANDATA/cz_pooled", clear
merge 1:1 cz using `rots', keep(3) nogen

//ivreg2 vr_bh_wa_gleaid (lgm_gleaid = lgm_hat_push) sharegleaid_black2000 vr_bh_wa_gleaid2000 i.division if year == 2011,  r first

//ivreg2 vr_bh_wa_gleaid (lgm_gleaid = classic_shift_share) sharegleaid_black2000 vr_bh_wa_gleaid2000 i.division if year == 2011,   cl(MSA_nces) first

//ivreg2 vr_bh_wa_gleaid (lgm_gleaid = classic_share*) sharegleaid_black2000 vr_bh_wa_gleaid2000 i.division if year == 2011,   cl(MSA_nces) first

//ivreg2 vr_bh_wa_gleaid (lgm_gleaid = classic_share*) sharegleaid_black2000 vr_bh_wa_gleaid2000 i.division if year == 2011,   liml cl(MSA_nces)

//ivreg2 vr_bh_wa_gleaid (lgm_gleaid = classic_share*) sharegleaid_black2000 vr_bh_wa_gleaid2000 i.division if year == 2011,  cl(MSA_nces) fuller(1)


keep if year == 2011
tab division, gen(div)
keep classic_share* classic_shift? classic_shift?? lgm_gleaid vr_bh_wa_gleaid vr_bh_wa_gleaid2000 sharegleaid_black2000 division gleaid MSA_nces div?
drop if lgm_gleaid ==.
drop div1


foreach var of varlist classic_shift*{
	su `var'
	replace `var' = r(max)
}

foreach var of varlist classic_share* {
	if regexm("`var'", "classic_share(.*)") {
		local state = regexs(1) 
		}
	tempvar temp
	qui gen `temp' = `var' * classic_shift`state'
	qui regress lgm_gleaid `temp' vr_bh_wa_gleaid2000 sharegleaid_black2000 i.division , cluster(MSA_nces)
	local pi_`state' = _b[`temp']
	qui test `temp'
	local F_`state' = r(F)
	qui regress vr_bh_wa_gleaid `temp' vr_bh_wa_gleaid2000 sharegleaid_black2000 i.division, cluster(MSA_nces)
	local gamma_`state' = _b[`temp']
	drop `temp'
	}
foreach s in 11 15 14 30 12{
	if regexm("`var'", "classic_share(.*)") {
		local state = regexs(1) 
		}
	tempvar temp
	qui gen `temp' = classic_share`s' * classic_shift`s'
	ch_weak, p(.05) beta_range(-1(.001)1)   y(vr_bh_wa_gleaid) x(lgm_gleaid) z(`temp') controls(vr_bh_wa_gleaid2000 sharegleaid_black2000 div? ) cluster(MSA_nces)
	disp r(beta_min) ,  r(beta_max)
	local ci_min_`s' =string( r(beta_min), "%9.3f")
	local ci_max_`s' = string( r(beta_max), "%9.3f")
	disp "`s', `beta_`s'', `t_`s'', [`ci_min_`s'', `ci_max_`s'']"
	drop `temp'
	}


preserve
	keep classic_share* gleaid MSA_nces
	reshape long classic_share, i(gleaid MSA_nces) j(StateIdentifier)

	collapse (sd) classic_share_sd = classic_share (rawsum) classic_share_pop =classic_share, by(StateIdentifier)
	tempfile tmp
	save `tmp'
restore

gsort gleaid
bartik_weight, z(classic_share*)    weightstub(classic_shift*) x(lgm_gleaid) y(vr_bh_wa_gleaid) controls(sharegleaid_black2000 vr_bh_wa_gleaid2000 ) absorb(division) 


mat beta = r(beta)
mat alpha = r(alpha)
mat gamma = r(gam)
mat pi = r(pi)
mat G = r(G)
qui desc classic_share*, varlist
local varlist = r(varlist)

clear
svmat beta
svmat alpha
svmat gamma
svmat pi
svmat G

gen StateIdentifier = ""
local t = 1
foreach var in `varlist' {
	if regexm("`var'", "classic_share(.*)") {
		qui replace StateIdentifier = regexs(1) if _n == `t'
		}
	local t = `t' + 1
	}

/** Calculate Panel C: Variation across years in alpha **/
total alpha1 
mat b = e(b)
local sum_alpha = string(b[1,1], "%9.3f")


sum alpha1
local mean_alpha = string(r(mean), "%9.3f")


destring StateIdentifier, replace
merge 1:1 StateIdentifier using `tmp'
gen beta2 = alpha1 * beta1
gen share2 = alpha1 * (classic_share_pop)
gen share_sd2 = alpha1 * classic_share_sd
gen G2 = alpha1 * G1
collapse (sum) alpha1 beta2 share2 share_sd2 G2 (mean) G1 , by(StateIdentifier)
gen agg_beta = beta2 / alpha1
gen agg_share = share2 / alpha1
gen agg_share_sd = share_sd2 / alpha1
gen agg_g = G2 / alpha1

preserve 
	 use "$RAWDATA/mmp/raw data/mmp gis and pop.dta", clear
	keep StateIdentifier State
	drop if StateIdentifier == 15 & State == "Jalisco"
	replace State = "State of Mexico" if StateIdentifier == 15
	replace State = subinstr(State, "á", "a", .)
	replace State = subinstr(State, "é", "e", .)
	replace State = subinstr(State, "í", "i", .)
	replace State = subinstr(State, "ó", "o", .)
	replace State = subinstr(State, "ú", "u", .)
	replace State = subinstr(State, "Á", "A", .)
	replace State = subinstr(State, "É", "E", .)
	replace State = subinstr(State, "Í", "I", .)
	replace State = subinstr(State, "Ó", "O", .)
	replace State = subinstr(State, "Ú", "U", .)
	replace State = subinstr(State, "ñ", "n", .)
	replace State = subinstr(State, "Ñ", "N", .)
	drop if State == "Puebla*"
		duplicates drop

	 tempfile statenames
	 save `statenames'
restore
merge 1:1 StateIdentifier using `statenames'
keep if _merge == 3

tempfile weights
save `weights'

preserve
	use "$RAWDATA/mmp/raw data/mmp gis and pop.dta", clear
	keep StateIdentifier State
	drop if StateIdentifier == 15 & State == "Jalisco"
	replace State = subinstr(State, "á", "a", .)
	replace State = subinstr(State, "é", "e", .)
	replace State = subinstr(State, "í", "i", .)
	replace State = subinstr(State, "ó", "o", .)
	replace State = subinstr(State, "ú", "u", .)
	replace State = subinstr(State, "Á", "A", .)
	replace State = subinstr(State, "É", "E", .)
	replace State = subinstr(State, "Í", "I", .)
	replace State = subinstr(State, "Ó", "O", .)
	replace State = subinstr(State, "Ú", "U", .)
	replace State = subinstr(State, "ñ", "n", .)
	replace State = subinstr(State, "Ñ", "N", .)
	drop if State == "Puebla*"
	duplicates drop
	tempfile statenames
	save `statenames'
 
	use "$RAWDATA/shapefiles/mex_states.dta", clear
	g State = ADMIN_NAME
	merge 1:1 State using `statenames', nogen
	merge m:1 StateIdentifier using `weights', nogen
	gen r = .
	gen g = .
	gen b = .

	* Red channel: only for positive values
	replace r = round(255 * alpha1) if alpha1 > 0
	replace r = 0 if alpha1 <= 0

	* Blue channel: only for negative values
	replace b = round(-255 * alpha1) if alpha1 < 0
	replace b = 0 if alpha1 >= 0

	* Green channel = optional, can soften colors
	replace g = 255 - abs(r - b)
	* Helper function to format as hex
	gen str2 rr = string(r, "%02x")
	gen str2 gg = string(g, "%02x")
	gen str2 bb = string(b, "%02x")

	* Combine to full hex color string
	gen str7 color = "#" + rr + gg + bb

	* Assign grey color to missing values
	replace color = "gray" if missing(alpha1)
	
	spmap alpha1 using "$RAWDATA/shapefiles/mex_coords.dta",  id(_ID) clmethod(custom) clbreaks(-0.2(0.05)0.2) fcolor(BuRd)
	graph export "$FIGS/final/weights_map.png", replace
	
	spmap agg_beta using "$RAWDATA/shapefiles/mex_coords.dta",  id(_ID) clmethod(custom) clbreaks(-3.2(0.4)1) fcolor(BuRd)
	graph export "$FIGS/final/beta_map.png", replace

	spmap agg_g using "$RAWDATA/shapefiles/mex_coords.dta",  id(_ID) 
	graph export "$FIGS/final/shifts_map.png", replace
	
	spmap agg_share using "$RAWDATA/shapefiles/mex_coords.dta",  id(_ID) 
	graph export "$FIGS/final/shares_map.png", replace
restore


gsort -alpha1


/** Panel A: Negative and Positive Weights **/
total alpha1 if alpha1 > 0
mat b = e(b)
local sum_pos_alpha = string(b[1,1], "%9.3f")
total alpha1 if alpha1 < 0
mat b = e(b)
local sum_neg_alpha = string(b[1,1], "%9.3f")

sum alpha1 if alpha1 > 0
local mean_pos_alpha = string(r(mean), "%9.3f")
sum alpha1 if alpha1 < 0
local mean_neg_alpha = string(r(mean), "%9.3f")

local share_pos_alpha = string(abs(`sum_pos_alpha')/(abs(`sum_pos_alpha') + abs(`sum_neg_alpha')), "%9.3f")
local share_neg_alpha = string(abs(`sum_neg_alpha')/(abs(`sum_pos_alpha') + abs(`sum_neg_alpha')), "%9.3f")



/** Panel B: Correlations of Industry Aggregates **/
gen F = .
gen agg_pi = .
gen agg_gamma = .
levelsof StateIdentifier, local(states)
foreach s in `states' {
	capture replace F = `F_`s'' if StateIdentifier == `s'
	capture replace agg_pi = `pi_`s'' if StateIdentifier == `s'
	capture replace agg_gamma = `gamma_`s'' if StateIdentifier == `s'		
	}
corr alpha1 agg_g agg_beta F agg_share_sd

mat corr = r(C)
forvalues i =1/5 {
	forvalues j = `i'/5 {
		local c_`i'_`j' = string(corr[`i',`j'], "%9.3f")
		}
	}

/** Panel  D: Top 5 Rotemberg Weight Inudstries **/
foreach s in 11 15 14 30 12 {
	qui sum alpha1 if StateIdentifier == `s'
	local alpha_`s' = string(r(mean), "%9.3f")
	qui sum agg_g if StateIdentifier == `s'	
	local g_`s' = string(r(mean), "%9.0f")
	qui sum agg_beta if StateIdentifier == `s'	
	local beta_`s' = string(r(mean), "%9.3f")
	qui sum agg_share if StateIdentifier == `s'	
	local share_`s' = string(r(mean)*100000, "%9.3f")
	tempvar temp
	qui gen `temp' = StateIdentifier == `s'
	gsort -`temp'
	local s_name_`s' = State[1]
	drop `temp'
	}


/** Over ID Figures **/
gen omega = alpha1*agg_beta
total omega
mat b = e(b)
local b = b[1,1]

gen label_var = StateIdentifier 
gen beta_lab = string(agg_beta, "%9.3f")


gen abs_alpha = abs(alpha1) 
gen positive_weight = alpha1 > 0
gen agg_beta_pos = agg_beta if positive_weight == 1
gen agg_beta_neg = agg_beta if positive_weight == 0
twoway (scatter agg_beta_pos agg_beta_neg F  [aweight=abs_alpha ], msymbol(Oh Dh) ), legend(label(1 "Positive Weights") label( 2 "Negative Weights")) yline(`b', lcolor(black) lpattern(dash)) xtitle("First stage F-statistic")  ytitle("{&beta}{subscript:k} estimate")
graph export "$FIGS/final/overid.png", replace

gsort -alpha1
twoway (scatter F alpha1, mcolor(dblue) mlabel(State  ) msize(0.5) mlabsize(2) ) (scatter F alpha1 if _n > 5, mcolor(dblue) msize(0.5) ), name(a, replace) xtitle("Rotemberg Weight") ytitle("First stage F-statistic") yline(10, lcolor(black) lpattern(dash)) legend(off)
graph export "$FIGS/final/F_vs_rotemberg_weight.png", replace


/** Panel E: Weighted Betas by alpha weights **/
gen agg_beta_weight = agg_beta * alpha1
preserve
	collapse (sum) agg_beta_weight alpha1 (mean)  agg_beta, by(positive_weight)
	egen total_agg_beta = total(agg_beta_weight)
	gen share = agg_beta_weight / total_agg_beta
	gsort -positive_weight
	local agg_beta_pos = string(agg_beta_weight[1], "%9.3f")
	local agg_beta_neg = string(agg_beta_weight[2], "%9.3f")
	local agg_beta_pos2 = string(agg_beta[1], "%9.3f")
	local agg_beta_neg2 = string(agg_beta[2], "%9.3f")
	local agg_beta_pos_share = string(share[1], "%9.3f")
	local agg_beta_neg_share = string(share[2], "%9.3f")
restore

/*** Write final table **/

capture file close fh
file open fh using "$TABS/final/gs_table.tex", write replace


file write fh " \begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}  \begin{threeparttable} \caption{Alternative IV Strategies}  \begin{tabular}{l*{6}{c}} \toprule " _n
file write fh "\toprule" _n

/** Panel A **/
file write fh "\multicolumn{4}{l}{\textbf{Panel A: Negative and positive weights}}\\" _n
file write fh "\cmidrule(lr){1-4} " _n
file write fh " & Sum & Mean & Share \\ \cmidrule(lr){1-4}" _n
file write fh "Negative & `sum_neg_alpha' & `mean_neg_alpha' & `share_neg_alpha' \\\\" _n
file write fh "Positive & `sum_pos_alpha' & `mean_pos_alpha' & `share_pos_alpha' \\" _n

/** Panel B **/
file write fh "\cmidrule(lr){1-4} " _n
file write fh "\multicolumn{6}{l}{\textbf{Panel B: Correlations of Industry Aggregates}}\\" _n
file write fh "\cmidrule(lr){1-6} " _n

file write fh " & $\alpha_k$ & \$g_k$ & $\beta_k$ & \$F_k$ & Var(\$z_k$) \\ \cmidrule(lr){1-6}" _n
file write fh "$\alpha_k$     & 1      &         &         &         &         \\\\" _n
file write fh "\$g_k$          & `c_1_2'  & 1       &         &         &         \\\\" _n
file write fh "$\beta_k$      & `c_1_3'  & `c_2_3'  & 1       &         &         \\\\" _n
file write fh "\$F_k$          & `c_1_4'  & `c_2_4'  & `c_3_4'  & 1       &         \\\\" _n
file write fh "Var(\$z_k$)     & `c_1_5'  & `c_2_5'  & `c_3_5'  & `c_4_5'  & 1       \\" _n

/** Panel C **/
file write fh "\cmidrule(lr){1-6} " _n
file write fh "\multicolumn{3}{l}{\textbf{Panel C: Variation in $\alpha_{k}$}}\\" _n
file write fh "\cmidrule(lr){1-3}"
file write fh " & Sum & Mean \\" _n
file write fh "\cmidrule(lr){1-3}"
file write fh "All years & `sum_alpha' & `mean_alpha' \\ " _n

/** Panel D **/
file write fh "\cmidrule(lr){1-3} " _n
file write fh "\multicolumn{6}{l}{\textbf{Panel D: Top 5 Rotemberg weight industries}}\\" _n
file write fh "\cmidrule(lr){1-6} " _n
file write fh " & $\hat{\alpha}_k$ & \$g_k$ & $\hat{\beta}_k$ & 95\% CI & State Share \\ \cmidrule(lr){1-6}" _n
foreach s in  15 11 14 30 12 {
	if `ci_min_`s'' != -10 & `ci_max_`s'' != 10 {
		file write fh "`s_name_`s'' & `alpha_`s'' & `g_`s'' & `beta_`s'' & (`ci_min_`s'', `ci_max_`s'') & `share_`s'' \\\\" _n
	}
	else {
		file write fh "`s_name_`s'' & `alpha_`s'' & `g_`s'' & `beta_`s'' & \multicolumn{1}{c}{N/A} & `share_`s'' \\\\" _n
	}
}

/** Panel E **/
file write fh "\cmidrule(lr){1-6} " _n
file write fh "\multicolumn{4}{l}{\textbf{Panel E: Estimates of $\beta_k$ for positive and negative weights}}\\" _n
file write fh "\cmidrule(lr){1-4} " _n
file write fh " & $\alpha$-weighted Sum & Share of overall $\beta$ & Mean \\ \cmidrule(lr){1-4}" _n
file write fh "Negative & `agg_beta_neg' & `agg_beta_neg_share' & `agg_beta_neg2' \\\\" _n
file write fh "Positive & `agg_beta_pos' & `agg_beta_pos_share' & `agg_beta_pos2' \\\\" _n
file write fh "\hline\hline"  _n
file write fh "\end{tabular}" _n
file write fh "\end{threeparttable}" _n
file write fh "\end{table}" _n
file close fh


// Note justifying shares

use "$CLEANDATA/push_factors/lasso_Xs.dta", clear
order StateIdentifier state year mexpop* pop_15*
preserve
	// Keeping only mmp states for analysis
	use "$RAWDATA/mmp/raw data/mig174.dta", clear
	*** merge in the mexican state identifier codes to match with the community number
	merge m:1 commun using "$RAWDATA/mmp/raw data/mmp gis and pop.dta",  nogen // UPDATE THIS
	keep StateIdentifier
	duplicates drop
	tempfile mmp_states
	save `mmp_states'
restore
merge m:1 StateIdentifier using `mmp_states',keep(3) nogen
keep StateIdentifier state mexpop2000
egen totpop2000 = total(mexpop2000)
keep if inlist(StateIdentifier,11,15,14,30,12)
egen totpop2000_selected = total(mexpop2000)
g share_selected = totpop2000_selected / totpop2000
su share_selected,d


