

local b_controls reg2 reg3 reg4 sumshare_panel_*
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940

use "cz_pooled", clear


// Harmonize decadal names in wide

drop np*
foreach y in cgoodman gen_muni schdist_ind spdist totfrac{
	rename n*_`y'_cz_pc `y'_*
}
keep cz popc1940 GM_raw_pp_* cgoodman_* gen_muni_* schdist_ind_* spdist_* totfrac_*  `b_controls' `extra_controls' sumshare_panel_* shift_share_panel_*
drop *_1 *_2 *_ GM_raw_pp_quad


rename GM_raw_pp_1940_1950 GM_raw_pp_1950
rename GM_raw_pp_1950_1960 GM_raw_pp_1960
rename GM_raw_pp_1960_1970 GM_raw_pp_1970

rename sumshare_panel_1960 sumshare_panel_1970
rename sumshare_panel_1950 sumshare_panel_1960 
rename sumshare_panel_1940 sumshare_panel_1950 

rename shift_share_panel_1960 shift_share_panel_1970
rename shift_share_panel_1950 shift_share_panel_1960 
rename shift_share_panel_1940 shift_share_panel_1950 


// Reshape to long
reshape long  GM_raw_pp_ cgoodman_ gen_muni_ schdist_ind_ spdist_ totfrac_ sumshare_panel_ shift_share_panel_, i(cz) j(year)
keep if inlist(year,1950,1960, 1970)
replace year = year - 10
replace shift_share_panel_ = 100*shift_share_panel_

foreach outcome in  cgoodman_ gen_muni_ spdist_ schdist_ind_ totfrac_{
	
	// First stage
	reg GM_raw_pp_ shift_share_panel_ i.year `b_controls' `extra_controls' [aw=popc1940] if !mi(`outcome'), r
	local b_fs_`outcome' = string(e(b)[1,1],"%9.3f")
	local sd_fs_`outcome' = string(e(V)[1,1]^0.5,"%9.3f")
	test shift_share_panel_ = 0
	local F_`outcome' : di %6.2f r(F)
	
	// Second stage
	preserve
		count if !mi(`outcome')
		local nobs_`outcome' = r(N)
		
		ssaggregate GM_raw_pp_ `outcome' [aw=popc1940], n("origin_fips") l(cz) sfile("shares_panel_base.dta") controls("`b_controls' `extra_controls'") s(share) t(year)

		merge 1:1 origin_fips year using "shock_instrument_panel_base.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
	
		ivreg2 `outcome' (GM_raw_pp_ = shift) i.year [aw = s_n]
		local b_ss_`outcome' = string(e(b)[1,1],"%9.3f")
		local sd_ss_`outcome' = string(e(V)[1,1]^0.5,"%9.3f")
	restore
}


// Add stars to coefficients
foreach m in fs ss{
	foreach outcome in cgoodman_  spdist_ gen_muni_ totfrac_ schdist_ind_{
		local z = abs(scalar(`b_`m'_`outcome'') / scalar(`sd_`m'_`outcome''))
		di "`z'"
		local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
		di "`n_stars'"
		local b_`m'_`outcome' = "`b_`m'_`outcome''" + "`n_stars'"
		di "HERE"

	}
	
}

// Write to latex table

capture file close fh
file open fh using "panel_IV.tex", write replace
file write fh "\begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}" _n

 
file write fh "&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Panel A: First Stage $\widehat{GM}_t$}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "$\widehat{GM}_t$  &    `b_fs_cgoodman_' &    `b_fs_gen_muni_' &    `b_fs_schdist_ind_' &    `b_fs_spdist_' &    `b_fs_totfrac_' \\" _n
file write fh "                &  (`sd_fs_cgoodman_')  &  (`sd_fs_gen_muni_')  &  (`sd_fs_schdist_ind_')  &  (`sd_fs_spdist_')  &  (`sd_fs_totfrac_')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "F-Stat & `F_cgoodman_' & `F_gen_muni_' & `F_schdist_ind_' & `F_spdist_' & `F_totfrac_' \\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Panel B: IV 1940-70}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh " GM\_t &    `b_ss_cgoodman_' &    `b_ss_gen_muni_' &    `b_ss_schdist_ind_' &    `b_ss_spdist_' &    `b_ss_totfrac_' \\" _n
file write fh "                &  (`sd_ss_cgoodman_')  &  (`sd_ss_gen_muni_')  &  (`sd_ss_schdist_ind_')  &  (`sd_ss_spdist_')  &  (`sd_ss_totfrac_')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "Observations    &      `nobs_cgoodman_'   &      `nobs_gen_muni_'   &      `nobs_schdist_ind_'   &      `nobs_spdist_'   &      `nobs_totfrac_'   \\" _n
file write fh "\bottomrule \end{tabularx}" _n

file close fh

////////
local b_controls reg2 reg3 reg4
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940



use "cz_pooled", clear
ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"
drop np*
foreach y in cgoodman gen_muni schdist_ind spdist totfrac{
	rename n*_`y'_cz_pc `y'_*
}

keep cz popc1940 GM_raw_pp_* cgoodman_* gen_muni_* schdist_ind_* spdist_* totfrac_* `b_controls' `extra_controls' sumshare_split_* shift_share_split_*
drop *_1 *_2 *_ GM_raw_pp_quad *_18?? *_1900 *_1910 *_1920 *_1930 *_1980 *_1990 *_20??

rename GM_raw_pp_1940_1950 GM_raw_pp_1950
rename GM_raw_pp_1950_1960 GM_raw_pp_1960
rename GM_raw_pp_1960_1970 GM_raw_pp_1970

rename sumshare_split_1960 sumshare_split_1970
rename sumshare_split_1950 sumshare_split_1960 
rename sumshare_split_1940 sumshare_split_1950 


rename shift_share_split_1960 shift_share_split_1970
rename shift_share_split_1950 shift_share_split_1960 
rename shift_share_split_1940 shift_share_split_1950 

reshape long  GM_raw_pp_ cgoodman_ gen_muni_ schdist_ind_ spdist_ totfrac_ sumshare_split_ shift_share_base_ shift_share_split_, i(cz) j(year)
keep if inlist(year,1950,1960, 1970)
replace year = year - 10


tempfile splitdf
save `splitdf'
g b = .
g ci_lo = .
g ci_hi = .

foreach outcome in  cgoodman_ gen_muni_ spdist_ schdist_ind_ totfrac_{
	if "`outcome'"=="cgoodman_" local name "C. Goodman Munis"
	if "`outcome'"=="gen_muni_" local name "CoG Munis"
	if "`outcome'"=="spdist_" local name "Special Districts"
	if "`outcome'"=="schdist_ind_" local name "School Districts"
	if "`outcome'"=="totfrac_" local name "Main City Share"

	foreach y in 1940 1950 1960{
		preserve
			keep if year == `y'
			reg GM_raw_pp_ shift_share_split_ `b_controls' `extra_controls' [aw=popc1940] if !mi(`outcome'), r
			test shift_share_split_ = 0
			local F_`outcome'_`y' : di %6.2f r(F)

			ssaggregate GM_raw_pp_ `outcome' [aw=popc1940], n("origin_fips") l(cz) sfile("shares_panel_`y'_base.dta") controls("`b_controls' `extra_controls' sumshare_split_") s(share) 

			merge 1:1 origin_fips using "shock_instrument_panel_`y'_base.dta", keep(1 3) nogen
			replace shift = 0 if mi(shift)

			ivreg2 `outcome' (GM_raw_pp_ = shift)  [aw = s_n]
			local b`y' = e(b)[1,1]
			local sd`y' = e(V)[1,1]^(0.5)
			
			
		restore 
		
		replace b = `b`y'' if year == `y'
		replace ci_lo = `b`y'' - 1.96 * `sd`y'' if year == `y'
		replace ci_hi = `b`y'' + 1.96 * `sd`y'' if year == `y'
		
	}
	
		
	sort year 
	set scheme s1color
	//set graphics off
	twoway 	(scatter b year, color(black)) ///
					(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
					xlabel(1940 "1940-50" 1950 "1950-60" 1960 "1960-70", angle(45)) ///
					yline(0, lc(red) lp(dash)) ///
					legend(off) title("`name'") note("1940-50 First Stage F-Stat: `F_`outcome'_1940'" "1950-60 First Stage F-Stat: `F_`outcome'_1950'" "1960-70 First Stage F-Stat: `F_`outcome'_1960'")
	
	graph export "`outcome'split_IV.png", as(png) replace

}

