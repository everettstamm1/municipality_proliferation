use "$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta", clear
collapse (sum) proutmig, by(origin_fips)
replace proutmig = -proutmig
destring origin_fips, replace
tempfile m
save `m'


use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear

keep if origin_sample == 1
keep if white == 1
ren city citycode

bys origin_fips : egen shift_denom = total(white)

merge m:1 city using "$INTDATA/dcourt/xwalk_296_city_cz.dta", keepusing(cz cz_popc1940) keep(2 3)
ren cz_popc1940 share_denom

replace white = 0 if _merge == 2
replace shift_denom = 0 if _merge == 2
bys cz origin_fips : egen share_num = total(white)
keep cz origin_fips share_num share_denom shift_denom
duplicates drop

merge m:1 origin_fips using `m', keep(1 3) nogen
replace proutmig = 0 if mi(proutmig)
rename proutmig shift_num

replace shift_num = 0 if mi(shift_num)
replace share_num = 0 if mi(shift_num)
replace share_denom = 0 if mi(shift_num)
replace shift_denom = 0 if mi(shift_denom)

g share = share_num / share_denom
g shift = shift_num / shift_denom


g shift_share = share * shift

preserve 
	keep origin_fips shift
	duplicates drop
	tempfile shock_level_inst
	save `shock_level_inst'
restore


preserve 
	keep origin_fips cz share
	duplicates drop
	tempfile shares
	save `shares'
restore


collapse (sum) share shift_share, by(cz)

rename share sumshare

merge 1:1 cz using "$CLEANDATA/cz_pooled", assert(3) nogen

ivreg2 n_schdist_ind_cz_pc (WM_raw_pp = shift_share) sumshare reg2 reg3 reg4   [aw=popc1940], r first

 coastal mfg_lfshare1940   frac_land higrade  mean_urban_income_1940  growth3040

reg growth3040 shift_share sumshare reg2 reg3 reg4 [aw=popc1940], r


ssaggregate n_cgoodman_cz_pc n_gen_muni_cz_pc n_spdist_cz_pc n_totfrac_cz_pc WM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile(`shares') controls("sumshare reg2 reg3 reg4 mfg_lfshare1940 mean_urban_income_1940 cz_popdens1940") s(share)

merge 1:1 origin_fips using `shock_level_inst', keep(1 3) nogen
replace shift = 0 if mi(shift)

ivreg2 n_cgoodman_cz_pc (WM_raw_pp = shift) [aw=s_n]