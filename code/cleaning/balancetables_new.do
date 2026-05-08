local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total t_cost frac_total  hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930

local controls reg2 reg3 reg4 sumshare_base 


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
rename transpo_cost_1920 t_cost
g n_streams_mi = mi(n_streams)
replace n_streams = -1 if mi(n_streams)

	

foreach covar of varlist `covars'{
		reg `covar' shift_share_base reg2 reg3 reg4 [aw=popc1940], r
		local b_`covar'_nss =  e(b)[1,1]
		local se_`covar'_nss = e(V)[1,1]^0.5
		
		reg `covar' shift_share_base reg2 reg3 reg4 sumshare_base [aw=popc1940], r
		local b_`covar' =  e(b)[1,1]
		local se_`covar' = e(V)[1,1]^0.5
		
		su `covar' [aw=popc1940], d
		local mean_`covar' = r(mean)
		local sd_`covar' = r(sd)
	
}

	
	
foreach covar in `covars' {			
	di "`covar'"
	local z = abs(scalar(`b_`covar'') / scalar(`se_`covar''))
	local z_nss = abs(scalar(`b_`covar'_nss') / scalar(`se_`covar'_nss'))

	local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
	local n_stars_nss = cond(`z_nss' > 2.58,"***",cond(`z_nss'>1.96,"**",cond(`z_nss' > 1.64,"*","")))
	
	local b_`covar' = string(`b_`covar'',"%9.3f") + "`n_stars'"
	local se_`covar' = string(`se_`covar'',"%9.3f") 

	local b_`covar'_nss = string(`b_`covar'_nss',"%9.3f") + "`n_stars_nss'"
	local se_`covar'_nss = string(`se_`covar'_nss',"%9.3f") 
	
	local mean_`covar' = string(`mean_`covar'',"%9.3f") 
	local sd_`covar' = string(`sd_`covar'',"%9.3f") 


}




capture file close fh
file open fh using "$TABS/balancetables/balancetable.tex", write replace
file write fh "\begin{tabular}{l*{3}{c}} \toprule" _n

 file write fh "&\multicolumn{2}{c}{$\widehat{GM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}"  _n
 
 file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\" _n
 file write fh "\midrule " _n

				
foreach covar of varlist `covars'{
	local lab : variable label `covar'
	file write fh  "`lab'  &    `b_`covar'_nss' & `b_`covar'' & `mean_`covar'' \\" _n
	file write fh "                &  (`se_`covar'_nss')  &  (`se_`covar'')  &  (`sd_`covar'')    \\" _n
}

file write fh "\bottomrule \end{tabular}" _n

file close fh


// Now for white instrument

local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total t_cost frac_total  hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930

local controls reg2 reg3 reg4 sumshare_base 


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
rename transpo_cost_1920 t_cost
g n_streams_mi = mi(n_streams)
replace n_streams = -1 if mi(n_streams)



foreach covar of varlist `covars'{
		reg `covar' shift_share_base_white reg2 reg3 reg4 [aw=popc1940], r
		local b_`covar'_nss =  e(b)[1,1]
		local se_`covar'_nss = e(V)[1,1]^0.5
		
		reg `covar' shift_share_base_white reg2 reg3 reg4 sumshare_base_white [aw=popc1940], r
		local b_`covar' =  e(b)[1,1]
		local se_`covar' = e(V)[1,1]^0.5
		
		su `covar' [aw=popc1940], d
		local mean_`covar' = r(mean)
		local sd_`covar' = r(sd)
	
}

	
	
foreach covar in `covars' {			
	di "`covar'"
	local z = abs(scalar(`b_`covar'') / scalar(`se_`covar''))
	local z_nss = abs(scalar(`b_`covar'_nss') / scalar(`se_`covar'_nss'))

	local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
	local n_stars_nss = cond(`z_nss' > 2.58,"***",cond(`z_nss'>1.96,"**",cond(`z_nss' > 1.64,"*","")))
	
	local b_`covar' = string(`b_`covar'',"%9.3f") + "`n_stars'"
	local se_`covar' = string(`se_`covar'',"%9.3f") 

	local b_`covar'_nss = string(`b_`covar'_nss',"%9.3f") + "`n_stars_nss'"
	local se_`covar'_nss = string(`se_`covar'_nss',"%9.3f") 
	
	local mean_`covar' = string(`mean_`covar'',"%9.3f") 
	local sd_`covar' = string(`sd_`covar'',"%9.3f") 


}




capture file close fh
file open fh using "$TABS/balancetables/balancetable_white.tex", write replace
file write fh "\begin{tabular}{l*{3}{c}} \toprule" _n

 file write fh "&\multicolumn{2}{c}{$\widehat{WM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}"  _n
 
 file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\" _n
 file write fh "\midrule " _n

				
foreach covar of varlist `covars'{
	local lab : variable label `covar'
	file write fh  "`lab'  &    `b_`covar'_nss' & `b_`covar'' & `mean_`covar'' \\" _n
	file write fh "                &  (`se_`covar'_nss')  &  (`se_`covar'')  &  (`sd_`covar'')    \\" _n
}

file write fh "\bottomrule \end{tabular}" _n

file close fh




// Now for pctile instrument

local covars avg_precip avg_temp n_streams coastal mfg_lfshare1940 m_rr_sqm_total t_cost frac_total  hsgrad_25 unigrad_25 mean_income_1940 cz_popdens1940 growth1930

local controls reg2 reg3 reg4 sumshare_base 


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear
rename transpo_cost_1920 t_cost
g n_streams_mi = mi(n_streams)
replace n_streams = -1 if mi(n_streams)



foreach covar of varlist `covars'{
		reg `covar' GM_hat reg2 reg3 reg4 [aw=popc1940], r
		local b_`covar'_nss =  e(b)[1,1]
		local se_`covar'_nss = e(V)[1,1]^0.5
		
		reg `covar' GM_hat reg2 reg3 reg4 sumshare_base [aw=popc1940], r
		local b_`covar' =  e(b)[1,1]
		local se_`covar' = e(V)[1,1]^0.5
		
		su `covar' [aw=popc1940], d
		local mean_`covar' = r(mean)
		local sd_`covar' = r(sd)
	
}

	
	
foreach covar in `covars' {			
	di "`covar'"
	local z = abs(scalar(`b_`covar'') / scalar(`se_`covar''))
	local z_nss = abs(scalar(`b_`covar'_nss') / scalar(`se_`covar'_nss'))

	local n_stars = cond(`z' > 2.58,"***",cond(`z'>1.96,"**",cond(`z' > 1.64,"*","")))
	local n_stars_nss = cond(`z_nss' > 2.58,"***",cond(`z_nss'>1.96,"**",cond(`z_nss' > 1.64,"*","")))
	
	local b_`covar' = string(`b_`covar'',"%9.3f") + "`n_stars'"
	local se_`covar' = string(`se_`covar'',"%9.3f") 

	local b_`covar'_nss = string(`b_`covar'_nss',"%9.3f") + "`n_stars_nss'"
	local se_`covar'_nss = string(`se_`covar'_nss',"%9.3f") 
	
	local mean_`covar' = string(`mean_`covar'',"%9.3f") 
	local sd_`covar' = string(`sd_`covar'',"%9.3f") 


}




capture file close fh
file open fh using "$TABS/balancetables/balancetable_pctile.tex", write replace
file write fh "\begin{tabular}{l*{3}{c}} \toprule" _n

 file write fh "&\multicolumn{2}{c}{$\widehat{Percentile GM}$}&\multicolumn{1}{c}{Mean}\\\cmidrule(lr){2-3}\cmidrule(lr){4-4}"  _n
 
 file write fh "&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}\\" _n
 file write fh "\midrule " _n

				
foreach covar of varlist `covars'{
	local lab : variable label `covar'
	file write fh  "`lab'  &    `b_`covar'_nss' & `b_`covar'' & `mean_`covar'' \\" _n
	file write fh "                &  (`se_`covar'_nss')  &  (`se_`covar'')  &  (`sd_`covar'')    \\" _n
}

file write fh "\bottomrule \end{tabular}" _n

file close fh