use "$CLEANDATA/cz_pooled.dta", clear

ssaggregate y x z l_sh_routine33 [aw=wei], n(sic87dd) t(year) s(ind_share) sfile(Lshares) l(czone) controls("t2 Lsh_manuf") addmissing

ssaggregate n_cgoodman_cz_pc GM_raw_pp GM_hat_raw reg2 reg3 reg4 [aw=popc1940], n(sic87dd) t(year) s(ind_share) sfile(Lshares) l(czone) controls("t2 Lsh_manuf") addmissing

use "$INTDATA/dcourt/instrument/2_city_blackmigshare3539.dta", clear




		use "$INTDATA/dcourt/bartik/2_blackorigin_fips1940.dta", clear
		cityfix_census
		
		merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name) 
		replace cz = 19600 if city=="Belleville, NJ"
		replace cz_name = "Newark, NJ" if city=="Belleville, NJ"
		drop if _merge==2
		drop _merge
		merge m:1 cz cz_name using "$INTDATA/dcourt/original_130_czs", keep(2 3)
		foreach var of varlist blackorigin_fips*{
			replace `var' = 0 if  _merge == 2
		} 
		collapse (sum) blackorigin_fips*, by(cz cz_name)
		reshape long blackorigin_fips, i(cz cz_name) j(origin_fips)
		keep cz origin_fips blackorigin_fips
		ren blackorigin_fips exposure_weight
		save "$CLEANDATA/exposure_weights", replace
		
		use "$CLEANDATA/cz_pooled.dta", clear
		ivreg2 n_cgoodman_cz_pc (GM_raw_pp = GM_hat_raw) v2_sumshares_urban reg2 reg3 reg4 coastal transpo_cost_1920 [aw = popc1940], r
		set trace off
		ssaggregate n_cgoodman_cz_pc GM_raw_pp GM_hat_raw [aw=popc1940], n(origin_fips) s(exposure_weight) sfile("$CLEANDATA/exposure_weights") l(cz) controls("v2_sumshares") addmissing

		save "$INTDATA/dcourt/instrument/`v'_city_blackmigshare3539.dta", replace