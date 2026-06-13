
local b_controls reg2 reg3 reg4 sumshare_base 


// Run the interacted regression
use "$CLEANDATA/cz_pooled", clear

lab var GM_raw_pp "GM"
ivreg2 n_cgoodman_cz_pc (GM_raw_pp = shift_share_base) reg2 reg3 reg4 sumshare_base [aw=popc1940], r
local t = 8
foreach outcome in cgoodman gen_muni schdist_ind spdist totfrac {
	forv spec = 1/8{
		if `spec' == 1 local controls "`b_controls'" 
		if `spec' == 2 local controls "`b_controls' mfg_lfshare1940"
		if `spec' == 3 local controls "`b_controls' mean_income_1940"
		if `spec' == 4 local controls "`b_controls' cz_popdens1940"
		if `spec' == 5 local controls "`b_controls' mfg_lfshare1940 mean_income_1940"
		if `spec' == 6 local controls "`b_controls' mfg_lfshare1940 cz_popdens1940"
		if `spec' == 7 local controls "`b_controls' mean_income_1940 cz_popdens1940"
		if `spec' == 8 local controls "`b_controls' mfg_lfshare1940 mean_income_1940 cz_popdens1940"
		
		preserve
			ssaggregate n_`outcome'_cz_pc ld_`outcome'_cz_pc GM_raw_pp [aw=popc1940], n(origin_fips) l(cz) sfile("$INTDATA/ssaggregate_prep//shares_base.dta") controls("`controls'") s(share)
			merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep//shock_instrument_base.dta", keep(1 3) nogen
			replace shift = 0 if mi(shift)
			
			eststo iv70_`spec' : ivreg2 n_`outcome'_cz_pc (GM_raw_pp = shift) [aw = s_n]
			
			eststo iv10_`spec' : ivreg2 ld_`outcome'_cz_pc (GM_raw_pp = shift) [aw=s_n]
			estadd local popdens = cond(inlist("`spec'","4","6","7","8"), "Yes","No")
			estadd local income = cond(inlist("`spec'","3","5","7","8"), "Yes","No")
			estadd local mfg = cond(inlist("`spec'","2","5","6","8"), "Yes","No")

		restore

	}
	if "`outcome'" == "cgoodman" local title "C. Goodman Municipalities"
	if "`outcome'" == "gen_muni" local title "CoG Municipalities"
	if "`outcome'" == "schdist_ind" local title "School Districts"
	if "`outcome'" == "spdist" local title "Special Districts"
	if "`outcome'" == "totfrac" local title "Main City Share"

	// Panel A: First Stage
	esttab iv70_1 iv70_2 iv70_3 iv70_4 iv70_5 iv70_6 iv70_7 iv70_8    ///
		using "$TABS/TA`t'.tex", ///
		replace se booktabs noconstant noobs compress frag label nomtitles nonum ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		posthead("&\multicolumn{8}{c}{`title'}\\\cmidrule(lr){2-9}" ///
				"&\multicolumn{1}{c}{(1)}&\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}&\multicolumn{1}{c}{(4)}&\multicolumn{1}{c}{(5)}&\multicolumn{1}{c}{(6)}&\multicolumn{1}{c}{(7)}&\multicolumn{1}{c}{(8)}\\" ///
				"\cmidrule(lr){1-9}" ///
				"\multicolumn{8}{l}{Panel A: 2SLS 1940-70}\\" "\cmidrule(lr){1-9}" ) ///
		prehead( \begin{tabularx}{\linewidth}{l*{8}{>{\centering\arraybackslash}X}} \toprule) ///
	 keep(GM_raw_pp) 

		
	// Panel E: 2SLS
	esttab iv10_1 iv10_2 iv10_3 iv10_4 iv10_5 iv10_6 iv10_7 iv10_8    ///
		using "$TABS/TA`t'.tex", ///
		se booktabs noconstant compress frag append noobs nonum nomtitle label ///
		posthead("\cmidrule(lr){1-9}" "\multicolumn{8}{l}{Panel B: 2SLS 1940-2010}\\" "\cmidrule(lr){1-9}" ) ///
		b(%04.3f) se(%04.3f) ///
		starlevels( * 0.10 ** 0.05 *** 0.01) ///
		keep(GM_raw_pp) ///
		postfoot(	\bottomrule \end{tabularx}) ///
		stats(popdens income mfg, labels("Pop. Dens. Control" "Avg. Income Control" "Share Mfg. Control")) substitute("\midrule" "\cmidrule(lr){1-9}")

	eststo clear
	
	local t = `t' + 1
}