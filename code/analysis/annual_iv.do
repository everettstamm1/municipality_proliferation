

local b_controls reg2 reg3 reg4 sumshare_base

use "$CLEANDATA/cz_pooled", clear

//drop new_mfg_lfshare1940
//ren new_mfg_lfshare* mfg_lfshare*
lab var shift_share_base "$\widehat{GM}$"
//g occscore1960 = occscore1950
//g occscore1970 = occscore1950

		
/*
rename n*_cgoodman_cz_pc y*
reshape long y, i(cz) j(year)

gen g = 1950 if above_x_med == 1

g event_time = (year - g)/10

forv k = -4/6 {
	local ak = abs(`k')
	if `k' < 0 local lab = "n`ak'"
	if `k' >= 0 local lab  "`k'"
	di "`lab'"
    gen evt_`lab' = event_time == `k'
}

drop evt_n1
reghdfe y evt_* `b_controls' `extra_controls', absorb(cz year) cluster(cz)
coefplot, keep(evt_*) vertical xline(0)
*/




//keep if !inlist(cz,34901,35001,35100)

forv spec=2(2)10{
	foreach outcome in main {
			
		forv y=1910(10)2010{
			
			if "`outcome'" == "main" {
				local depvar diff`y'_cgoodman_exact_cz_pc
				local path "$FIGS/event_studies/es_ssaggregate_`spec'.png"
				local ylab "Change in Municipalities P.C."

			}
			if "`outcome'" == "pop" {
				local depvar diff`y'_pop_cz
				local path "$FIGS/event_studies/es_ssaggregate_`spec'_pop.png"
				local ylab "Percentage Change in Population"
			}
			if "`outcome'" == "rawcount" {
				local depvar diff`y'_cgoodman_exact_cz_pc
				local path "$FIGS/event_studies/es_ssaggregate_`spec'_raw.png"
				local ylab "Change in Municipalities"
			}

			local y1 = `y' - 10
			local ystub = mod(`y',100)

			preserve
				if "`spec'" == "1" ssaggregate  n`y'_cgoodman_exact_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'") s(share)
				if "`spec'" == "2" ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'  ") s(share)
				
				if "`spec'" == "3" ssaggregate  n`y'_cgoodman_exact_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' mfg_lfshare`y1' mean_income_1940 cz_popdens`y1'") s(share)
				if "`spec'" == "4" ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'  mfg_lfshare`y1' mean_income_1940 cz_popdens`y1' ") s(share)
				if "`spec'" == "5" ssaggregate  n`y'_cgoodman_exact_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' mfg_lfshare1940 mean_income_1940 cz_popdens1940") s(share)
				if "`spec'" == "6" ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'  mfg_lfshare1940 mean_income_1940 cz_popdens1940 ") s(share)
				if "`spec'" == "7" ssaggregate  n`y'_cgoodman_exact_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' mfg_lfshare`y1' cz_popdens`y1'") s(share)
				if "`spec'" == "8" ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls'  mfg_lfshare`y1' cz_popdens`y1' ") s(share)
				
				if "`spec'" == "9" ssaggregate  n`y'_cgoodman_exact_cz_pc GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' mfg_lfshare`y1' cz_popdens`y1' occscore`y1'") s(share)
				if "`spec'" == "10" ssaggregate  `depvar' GM_raw_pp [aw=popc1940], n("origin_fips") l(cz) sfile("$INTDATA/ssaggregate_prep/shares_base.dta") controls("`b_controls' mfg_lfshare1900 cz_popdens1900 occscore1900") s(share)
				
				merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", keep(1 3) nogen
				replace shift = 0 if mi(shift)
				lab var shift "`xlab'"
										
				g b = .
				g ci_lo = .
				g ci_hi = .
				g year = .
				g yearlab = ""
				
				if inlist("`spec'","1","3","5","7","9") ivreg2 n`y'_cgoodman_exact_cz_pc (GM_raw_pp = shift) [aw=s_n]
				if inlist("`spec'","2","4","6","8","10") ivreg2 `depvar' (GM_raw_pp = shift) [aw=s_n]

				local b = e(b)[1,1]
				local sd = e(V)[1,1]^(0.5)
				replace b = `b' if _n == 1
				replace ci_hi  = `b' + 1.96 * `sd' if _n == 1
				replace ci_lo  = `b' - 1.96 * `sd' if _n == 1
				replace year = `y' if _n == 1
				replace yearlab = "`y'" if _n == 1
				keep b ci_hi ci_lo year yearlab
				keep if _n == 1
				tempfile y`y'
				save `y`y''
			restore
		}

		preserve
			clear
			forv y = 1910(10)2010{
				append using `y`y''
			}
			labmask year, val(yearlab)
			sort year 
			set scheme s1color
			//set graphics off
			twoway 	(scatter b year, color(black)) ///
							(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
							xlabel(1910(10)2010, val angle(45)) ///
							yline(0, lc(red) lp(dash)) ///
							legend(off) ytitle("`ylab'") xtitle("Year")


			graph export "`path'", as(png) replace
		restore
	}
}