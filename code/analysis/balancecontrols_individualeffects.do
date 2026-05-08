local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total t_cost frac_total  hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930

local controls reg2 reg3 reg4 sumshare_base 


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
rename transpo_cost_1920 t_cost
g n_streams_mi = mi(n_streams)
replace n_streams = -1 if mi(n_streams)



foreach outcome in cgoodman  spdist gen_muni totfrac schdist_ind{
	preserve
		ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`controls'") s(share)
		merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw = s_n]
		local b_`outcome'_none =  e(b)[1,1]
		local se_`outcome'_none =e(V)[1,1]
	restore
	
	foreach covar of varlist `covars'{
		preserve
			if "`covar'" == "n_streams" ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`controls' `covar' n_streams_mi") s(share)
			if "`covar'" != "n_streams"  ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`controls' `covar'") s(share)
			
			merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
			replace shift = 0 if mi(shift)
			
			ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw = s_n]
			local b_`outcome'_`covar' =  e(b)[1,1]
			local se_`outcome'_`covar' = e(V)[1,1]^0.5
		restore
	}
	
	preserve
		ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`controls' mfg_lfshare1940 mean_income_1940 cz_popdens1940") s(share)
		merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw = s_n]
		local b_`outcome'_imbal =  e(b)[1,1]
		local se_`outcome'_imbal = e(V)[1,1]^0.5
	restore
	
	preserve
	
		ssaggregate n_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`controls' `covars'") s(share)
		merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
		replace shift = 0 if mi(shift)
		
		ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw = s_n]
		local b_`outcome'_all =  e(b)[1,1]
		local se_`outcome'_all = e(V)[1,1]^0.5
	restore
}
	
	
foreach outcome in cgoodman spdist gen_muni totfrac schdist_ind{
	foreach covar in `covars' none all imbal{			
		di "`covar'"
		local z = abs(scalar(`b_`outcome'_`covar'') / scalar(`se_`outcome'_`covar''))
		di "`z'"
		local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
		di "`n_stars'"
		di "`b_`outcome'_`covar''"
		
		local b_`outcome'_`covar' = string(`b_`outcome'_`covar'',"%9.3f") + "`n_stars'"
		local se_`outcome'_`covar' = string(`se_`outcome'_`covar'',"%9.3f") 
	
	}
}



capture file close fh
file open fh using "$TABS/balancecontrols_individualeffects.tex", write replace
file write fh "\begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}" _n

 
file write fh "&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "\multicolumn{5}{l}{Balance Control Included}\\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "None  &    `b_cgoodman_none' &    `b_gen_muni_none' &    `b_schdist_ind_none' &    `b_spdist_none' &    `b_totfrac_none' \\" _n
	file write fh "                &  (`se_cgoodman_none')  &  (`se_gen_muni_none')  &  (`se_schdist_ind_none')  &  (`se_spdist_none')  &  (`se_totfrac_none')  \\" _n
	file write fh "\cmidrule(lr){1-6}" _n

foreach covar of varlist `covars'{
	local lab : variable label `covar'
	file write fh  "`lab'  &    `b_cgoodman_`covar'' &    `b_gen_muni_`covar'' &    `b_schdist_ind_`covar'' &    `b_spdist_`covar'' &    `b_totfrac_`covar'' \\" _n
	file write fh "                &  (`se_cgoodman_`covar'')  &  (`se_gen_muni_`covar'')  &  (`se_schdist_ind_`covar'')  &  (`se_spdist_`covar'')  &  (`se_totfrac_`covar'')  \\" _n
}
file write fh "\cmidrule(lr){1-6}" _n
file write fh  "Imbalanced  &    `b_cgoodman_imbal' &    `b_gen_muni_imbal' &    `b_schdist_ind_imbal' &    `b_spdist_imbal' &    `b_totfrac_imbal' \\" _n
	file write fh "                &  (`se_cgoodman_imbal')  &  (`se_gen_muni_imbal')  &  (`se_schdist_ind_imbal')  &  (`se_spdist_imbal')  &  (`se_totfrac_imbal')  \\" _n
	file write fh  "All  &    `b_cgoodman_all' &    `b_gen_muni_all' &    `b_schdist_ind_all' &    `b_spdist_all' &    `b_totfrac_all' \\" _n
	file write fh "                &  (`se_cgoodman_all')  &  (`se_gen_muni_all')  &  (`se_schdist_ind_all')  &  (`se_spdist_all')  &  (`se_totfrac_all')  \\" _n
file write fh "\cmidrule(lr){1-6}" _n
file write fh "Observations    &      130   &      130   &      118   &      130   &      130   \\" _n
file write fh "\bottomrule \end{tabularx}" _n

file close fh



local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total t_cost frac_total  hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930

local controls reg2 reg3 reg4 


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
rename transpo_cost_1920 t_cost
g n_streams_mi = mi(n_streams)
replace n_streams = -1 if mi(n_streams)
replace n_streams = n_streams/10000


// Normalize
foreach covar of varlist `covars'{
	sum `covar',d
	replace `covar' = (`covar' - r(mean))/r(sd)
}


eststo clear
foreach outcome in cgoodman  spdist gen_muni totfrac schdist_ind{
	eststo : reg n_`outcome'_cz_pc  `covars' n_streams_mi `controls' [aw = popc1940], r
}
	
esttab     ///
		using "$TABS/balancecontrols_rf.tex", ///
		replace se booktabs noconstant noobs compress label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" ///
                "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" ///
				"\cmidrule(lr){1-6}"  ) ///
		prehead( \begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}) ///
	 keep( `covars') ///
	 postfoot(	\bottomrule \end{tabularx}) ///
	stats(N, labels("Observations") fmt(0)) substitute("\midrule" "\cmidrule(lr){1-6}")
	
	
	
	
	
local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total t_cost frac_total  hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930

local controls reg2 reg3 reg4  


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
rename transpo_cost_1920 t_cost
g n_streams_mi = mi(n_streams)
replace n_streams = -1 if mi(n_streams)
replace n_streams = n_streams/10000

// Normalize
foreach covar of varlist `covars'{
	sum `covar',d
	replace `covar' = (`covar' - r(mean))/r(sd)
}


foreach outcome in cgoodman  spdist gen_muni totfrac schdist_ind{
	
	
	foreach covar of varlist `covars'{
		
		if "`covar'" == "n_streams" reg n_`outcome'_cz_pc `covar' n_streams_mi `controls' [aw=popc1940], r
		if "`covar'" != "n_streams"  reg n_`outcome'_cz_pc `covar' `controls' [aw=popc1940], r
		local b_`outcome'_`covar' =  r(table)[1,1]
		local se_`outcome'_`covar' = r(table)[2,1] 
	
	}
	
}
	
	
foreach outcome in cgoodman spdist gen_muni totfrac schdist_ind{
	foreach covar in `covars' {			
		di "outcome: `outcome'"
		di "covar: `covar'"
		di "beta: `b_`outcome'_`covar''"
		di "se: `se_`outcome'_`covar''"

		local z = abs(scalar(`b_`outcome'_`covar'') / scalar(`se_`outcome'_`covar''))
		di "`z'"
		local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
		di "`n_stars'"
		local b_`outcome'_`covar' = string(`b_`outcome'_`covar'',"%9.3f") + "`n_stars'"
		local se_`outcome'_`covar' = string(`se_`outcome'_`covar'',"%9.3f") 
		di "beta print: `b_`outcome'_`covar''"
		di "se print: `se_`outcome'_`covar''"

	
	}
}



capture file close fh
file open fh using "$TABS/balancecontrols_rf_sep.tex", write replace
file write fh "\begin{tabularx}{\textwidth}{l*{5}{>{\centering\arraybackslash}X}} \toprule \setlength{\tabcolsep}{15pt}" _n

 
file write fh "&\multicolumn{1}{c}{C. Goodman}&\multicolumn{3}{c}{Census of Governments}&\multicolumn{1}{c}{Census}\\\cmidrule(lr){2-2}\cmidrule(lr){3-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Special Districts}&\multicolumn{1}{c}{Main City Share}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}\cmidrule(lr){5-5}\cmidrule(lr){6-6}" _n

file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\" _n
file write fh "\cmidrule(lr){1-6}" _n

foreach covar of varlist `covars'{
	local lab : variable label `covar'
	file write fh  "`lab'  &    `b_cgoodman_`covar'' &    `b_gen_muni_`covar'' &    `b_schdist_ind_`covar'' &    `b_spdist_`covar'' &    `b_totfrac_`covar'' \\" _n
	file write fh "                &  (`se_cgoodman_`covar'')  &  (`se_gen_muni_`covar'')  &  (`se_schdist_ind_`covar'')  &  (`se_spdist_`covar'')  &  (`se_totfrac_`covar'')  \\" _n
}

file write fh "\cmidrule(lr){1-6}" _n
file write fh "Observations    &      130   &      130   &      118   &      130   &      130   \\" _n
file write fh "\bottomrule \end{tabularx}" _n

file close fh

	

