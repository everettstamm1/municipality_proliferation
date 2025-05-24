import excel using "$XWALKS/ZIP_COUNTY_032025.xlsx", clear first

destring ZIP, gen(zip)
destring COUNTY, gen(cty_fips)
ren RES_RATIO weight
keep zip cty_fip weight
duplicates drop

joinby cty_fips using "$XWALKS/cw_cty_czone"
keep zip czone weight
duplicates drop

bys zip : egen main = max(weight)
keep if weight == main
keep czone zip
duplicates tag zip, gen(tag) // figure out tiebreaks later
bys zip (czone) : drop if tag == 1 & _n == 1 // figure out tiebreaks later
tempfile zip_cty_xwalk
save `zip_cty_xwalk'


use "F:/Latinx_Migration_School_Segregation/interim/nces/pss", clear

drop if home_school == 2 | n_total == 1 | higrade == lograde | higrade == 0
keep if !mi(year_opened)

keep pin year state_fip cty_fip year_opened zip

bys pin (cty_fip) : replace cty_fip = cty_fip[1] if mi(cty_fip)


preserve
	keep if mi(cty_fip)
	keep pin zip year_opened
	bys pin (year_opened) : replace year_opened = year_opened[_N]

	duplicates drop
	merge m:1 zip using `zip_cty_xwalk' // No tiebroken are matched so idgaf
	g n1 = 1
	collapse (sum) n1 , by(czone year_opened)
	
	tempfile mictys
	save `mictys'
	
restore 

drop if mi(cty_fip)

g cty_fips = 1000*state_fip + cty_fip
keep pin cty_fips year_opened
bys pin (year_opened) : replace year_opened = year_opened[_N]
duplicates drop // Keeping different answers for the same school for now
joinby cty_fips using "$XWALKS/cw_cty_czone"

g n2 = 1

collapse (sum) n2 , by(czone year_opened)

merge 1:1 czone year_opened using `mictys', nogen
egen n = rowtotal(n1 n2)

g n40 = n if year_opened < 1940 & year_opened <= 1970
g n70 = n if year_opened < 1970
collapse (sum) n40 n70, by(czone)
ren czone cz

tempfile pss
save `pss'

use "$CLEANDATA/cz_pooled", clear

merge 1:1 cz using `pss', keep(3) nogen

g y_pss = n70/(pop1970/10000) - n40/(pop1940/10000) 

ivreg2 y_pss (GM_raw_pp  = GM_hat_raw )  reg2 reg3 reg4 mean_income_1940 mfg_lfshare1940 cz_popdens1940 sumshare_base [aw=popc1940] , r


preserve 
	ssaggregate y_pss  GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("reg2 reg3 reg4 mean_income_1940 mfg_lfshare1940 cz_popdens1940 sumshare_base") s(share)
	
	merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
	replace shift = 0 if mi(shift)
	
	 ivreg2 y_pss (GM_raw_pp= shift) [aw = s_n]
restore
