
local b_controls blackmig3539_share
local extra_controls urban_share1940 frac_total transpo_cost_1920 m_rr_sqm_total

use "$CLEANDATA/cz_pooled", clear
keep if dcourt == 1

lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

	eststo clear
	forv r=1/4{
		if `r'==1 local region "Northeast"
		if `r'==2 local region "Midwest"
		if `r'==3 local region "South"
		if `r'==4 local region "West"
		
		if `r'==1 local header = `"&\multicolumn{1}{c}{C. Goodman}&\multicolumn{4}{c}{Census of Governments}\\\cmidrule(lr){2-2}\cmidrule(lr){3-6}&\multicolumn{2}{c}{Municipalities}&\multicolumn{1}{c}{School districts}&\multicolumn{1}{c}{Townships}&\multicolumn{1}{c}{Special districts}\\\cmidrule(lr){2-3}\cmidrule(lr){4-6}&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}\\"'
		if `r'!=1 local header 
		
		if `r'==4 local footer = "postfoot(	\bottomrule \end{tabular}) "
		if `r'!=4 local footer 
		if `r'!=1 local append = "append"
		if `r'==1 local append
		if `r'==1 local replace = "replace"
		if `r'!=1 local replace
		if `r'==1 local prehead = "prehead( \begin{tabular}{l*{7}{c}} \toprule)"
		if `r'!=1 local prehead
		
		
		count if reg`r'==1
		local n = `r(N)'
		
		
		foreach outcome in cgoodman schdist_ind gen_town spdist gen_muni{
			su n_`outcome'_cz_pc [aw=popc1940] if reg`r'==1
			local dv : di %6.2f r(mean)
			
			// First Stage
			eststo fs_`outcome'_`r' : reg GM_raw_pp GM_hat_raw_pp `b_controls' if reg`r'==1 [aw=popc1940], r
			test GM_hat_raw_pp=0
			local F : di %6.2f r(F)

			// 2SLS 
			eststo iv_`outcome'_`r' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = GM_hat_raw_pp) `b_controls'  [aw = popc1940] if reg`r'==1, r
				estadd local Fs = `F'
				estadd local dep_var = `dv'

		}

		// Panel A: First Stage
		esttab fs_cgoodman_`r' fs_gen_muni_`r' fs_schdist_ind_`r' fs_gen_town_`r' fs_spdist_`r'  ///
			using "$TABS/final/region_effect.tex", ///
			`replace' se booktabs noconstant noobs compress `append' frag label nomtitles nonum ///
			b(%04.3f) se(%04.3f) ///
			starlevels( * 0.10 ** 0.05 *** 0.01) ///
			posthead( `"`header'"' ///
					"\cmidrule(lr){1-6}" ///
					"\multicolumn{5}{c}{`region' Census Region, N = `n'}\\\cmidrule(lr){1-6}" ///
					"\multicolumn{5}{l}{Panel A: First Stage}\\" "\cmidrule(lr){1-6}" ) ///
			 `prehead' ///
		 keep(GM_hat_raw_pp) 
			
		// Panel B: 2SLS
		esttab iv_cgoodman_`r' iv_gen_muni_`r' iv_schdist_ind_`r' iv_gen_town_`r' iv_spdist_`r' ///
			using "$TABS/final/region_effect.tex", ///
			se booktabs noconstant compress frag append noobs nonum nomtitle label ///
			posthead("\cmidrule(lr){1-6}" "\multicolumn{5}{l}{Panel D: 2SLS}\\" "\cmidrule(lr){1-6}" ) ///
			b(%04.3f) se(%04.3f) ///
			starlevels( * 0.10 ** 0.05 *** 0.01) ///
			keep(GM_raw_pp) `footer'
			

	}