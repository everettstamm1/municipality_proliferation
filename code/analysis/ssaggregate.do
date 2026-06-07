
use "$INTDATA/dcourt/bartik/2_blackorigin_fips1940.dta", clear
ren city citycode

merge 1:1 city using "$INTDATA/dcourt/GM_city_final_dataset.dta",  keepusing(cz cz_name v2_sumshares) keep(2 3)

collapse (sum) blackorigin_fips*, by(cz cz_name)

merge m:1 cz cz_name using "$INTDATA/dcourt/original_130_czs", keep(2 3)
foreach var of varlist blackorigin_fips*{
	replace `var' = 0 if  _merge == 2
} 

collapse (sum) blackorigin_fips*, by(cz cz_name)
reshape long blackorigin_fips, i(cz cz_name) j(origin_fips)
keep cz origin_fips blackorigin_fips
ren blackorigin_fips exposure_weight
save "$CLEANDATA/exposure_weights", replace

use "$CLEANDATA/exposure_weights", clear
collapse (sum) exposure_weight, by(cz)
ren exposure_weight sum_share
tempfile ss
save `ss'

use "$CLEANDATA/cz_pooled.dta", clear
merge 1:1 cz using `ss', keep(3) nogen



foreach outcome in cgoodman schdist_ind gen_muni spdist totfrac {
	preserve
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw) , r
		ssaggregate n_`outcome'_cz_pc GM_raw_pp GM_hat_raw , n(origin_fips) s(exposure_weight) sfile("$CLEANDATA/exposure_weights") l(cz) controls("sum_share")
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw) [aw=s_n], r
	restore
}

use "$INTDATA/dcourt/bartik/2_od_matrix_black_1940.dta", clear
keep blackorigin_fips origin_fips city total_blackcity
bys city origin_fips : gen dup = cond(_N == 1,0,_n)
drop if dup>0
drop dup


ren city citycode
merge m:1 city using "$INTDATA/dcourt/GM_city_final_dataset.dta", keep(2 3) keepusing(cz) nogen
foreach var of varlist blackorigin_fips*{
	replace `var' = 0 if mi(`var')
}
collapse (sum) blackorigin_fips, by(cz origin_fips)

tempfile shares_long
save `shares_long'

collapse (sum) blackorigin_fips, by(cz)
ren blackorigin_fips sumshare

tempfile sumshare
save `sumshare'


/*
use "$INTDATA/dcourt/bartik/2_blackorigin_fips1940.dta", clear
ren city citycode
merge m:1 city using "$INTDATA/dcourt/GM_city_final_dataset.dta", keep(2 3) keepusing(cz) nogen
foreach var of varlist blackorigin_fips*{
	replace `var' = 0 if mi(`var')
}

collapse (sum) blackorigin_fips*, by(cz)


tempfile shares_wide
save `shares_wide'

reshape long blackorigin_fips, i(cz) j(origin_fips)
tempfile shares_long
save `shares_long'
*/

use "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta", clear 
collapse (sum) proutmig, by(origin_fips)
destring origin_fips, replace
tempfile m
save `m'

use "$CLEANDATA/cz_pooled.dta", clear
g x = 100*((bpopc1970/popc1970) - (bpopc1940/popc1940))
g z_raw = v2_black_proutmigpr
g z = 100*v2_black_proutmigpr/popc1940
g y = n_cgoodman_cz_pc
merge 1:1 cz using `sumshare', keep(3) nogen
g sumshare_urban = sumshare/popc1940

ivreg2 y (x = z_raw) sumshare reg2 reg3 reg4 [aw=popc1940],  r
ivreg2 y (x = z) sumshare reg2 reg3 reg4 [aw=popc1940],  r


ssaggregate y x popc1 [aw=popc1940], n(origin_fips) l(cz) sfile(`shares_long') controls("sumshare reg2 reg3 reg4") s(blackorigin_fips)

merge 1:1 origin_fips using `m', keep(1 3) nogen
replace proutmig = 0 if mi(proutmig)

ivreg2 y (x = proutmig) [aw=s_n]

use "$INTDATA/dcourt/bartik/2_wide_blackorigin_fips1940.dta", clear
merge 1:m origin_fips using  "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
		
		
use "/Users/edog9/Downloads/ADH/ADH/Data/location_level.dta", clear
		
	
merge 1:1 czone year using "/Users/edog9/Downloads/ADH/ADH/Data/Lshares_wide", assert(3) nogen

ssaggregate y z x [aw=wei], n(sic87dd) t(year) s(ind_share)  addmissing controls("t2 Lsh_manuf reg* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource")


replace sic87dd = 0 if mi(sic87dd)
merge 1:1 sic87dd year using "/Users/edog9/Downloads/ADH/ADH/Data/shocks", assert(1 3) nogen // sic87dd==0 is _m==1
merge m:1 sic87dd using "/Users/edog9/Downloads/ADH/ADH/Data/industries", assert(1 3) nogen
foreach v of varlist g* sic3 sic2 sicgroup {
	replace `v'= 0 if sic87dd==0
}

gen g90 = g*(year==1990)
gen g00 = g*(year==2000)

label var g "Industry China Shock (binned)"

tsset sic87dd year, delta(10)
tab sic87dd if sic87dd!=0, gen(ind_)
drop ind_1
tsset, clear

ivreg2 y (x=g)  if sic87dd!=0 [aw=s_n], cluster(sic3)


//su z, d
//g z_norm = (z - r(mean))/r(sd)
ivreg2 y (x=z) t2 Lsh_manuf reg* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource [aw=wei], cluster(clus) partial(t2 Lsh_manuf reg* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource)


ssaggregate y x z [aw=wei], n(sic87dd) t(year) s(ind_share) controls("t2 Lsh_manuf reg* l_sh_popedu_c l_sh_popfborn l_sh_empl_f l_sh_routine33 l_task_outsource")

ivreg2 y (x=z) year [aw=s_n], r


use "/Users/edog9/Downloads/ADH/ADH/Data/industry_level.dta",clear
tab sic87dd if sic87dd!=0, gen(ind_)
drop ind_1
tsset, clear // necessary for ivreg2 to work with the partial option

ivreg2 y2 (x2=g) if sic87dd!=0 [aw=s_n], cluster(sic3) 
