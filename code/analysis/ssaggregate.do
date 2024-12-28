
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


		
		
		
		
	

