local b_controls reg2 reg3 reg4 
local extra_controls mfg_lfshare1940 mean_income_1940 cz_popdens1940

use "$INTDATA/ssaggregate_prep/shares_base", clear
drop if mi(origin_fips)
reshape wide share, i(cz) j(origin_fips)

foreach var of varlist share*{
	replace `var' = 0 if mi(`var')
	su `var'
	if r(mean)==0{
		drop `var'
	}
}
rename share* classic_share*

tempfile rots
save `rots'

use "$CLEANDATA/cz_pooled", clear

merge 1:1 cz using `rots', keep(3) nogen

foreach y in n_cgoodman_cz_pc  n_schdist_ind_cz_pc  {
	

	ivreg2 `y' (GM_raw_pp =  shift_share_base)  `b_controls' `extra_controls' [aw=popc1940], r first
	local iv_`y'_b = string(e(b)[1,1], "%9.3f")
	local iv_`y'_se = string(e(V)[1,1]^(0.5), "%9.3f")

	ivreg2 `y' (GM_raw_pp =  classic_share*)  `b_controls' `extra_controls' [aw=popc1940], r  first 
	local overid_`y'_b = string(e(b)[1,1], "%9.3f")
	local overid_`y'_se = string(e(V)[1,1]^(0.5), "%9.3f")

	weakiv
	local overid_`y'_stat = string(e(j_chi2), "%9.3f")
	local overid_`y'_p = string(e(j_p), "%9.3f")


	ivreg2 `y' (GM_raw_pp =  classic_share*)  `b_controls' `extra_controls' [aw=popc1940], r  liml first 
	local liml_`y'_b = string(e(b)[1,1], "%9.3f")
	local liml_`y'_se = string(e(V)[1,1]^(0.5), "%9.3f")
	weakiv
	local liml_`y'_stat = string(e(ar_chi2), "%9.3f")
	local liml_`y'_p = string(e(ar_p), "%9.3f")

	ivreg2 `y' (GM_raw_pp =  classic_share*)  `b_controls' `extra_controls' [aw=popc1940], r  fuller(1) 
	local hful_`y'_b = string(e(b)[1,1], "%9.3f")
	local hful_`y'_se = string(e(V)[1,1]^(0.5), "%9.3f")
	weakiv
	local hful_`y'_stat = string(e(j_chi2), "%9.3f")
	local hful_`y'_p = string(e(j_p), "%9.3f")


	manyiv `y' (GM_raw_pp =  classic_share*)  `b_controls' `extra_controls' [aw=popc1940], cr
	local mbtsls_`y'_b = string(e(b)[1,4], "%9.3f")
	local mbtsls_`y'_se = string(e(se)[3,4], "%9.3f")
	
		
	foreach inst in  GM_sob_hat_raw GM_7r_hat_raw GM_r_hat_raw  {
		ivreg2 `y' (GM_raw_pp = `inst') `b_controls' `extra_controls' [aw=popc1940], r
		local `inst'_`y'_b = string(e(b)[1,1], "%9.3f")
		local `inst'_`y'_se = string(e(V)[1,1]^(0.5), "%9.3f")
	}
	ivreg2 `y' (GM_raw_pp = GM_sob_hat_raw GM_7r_hat_raw GM_r_hat_raw shift_share_base ) `b_controls' `extra_controls' [aw=popc1940], r
	local alt_`y'_b = string(e(b)[1,1], "%9.3f")
	local alt_`y'_se = string(e(V)[1,1]^(0.5), "%9.3f")
	weakiv
	local alt_`y'_stat = string(e(j_chi2), "%9.3f")
	local alt_`y'_p = string(e(j_p), "%9.3f")
	
}


capture file close fh
file open fh using "$TABS/final/inst_table.tex", write replace

file write fh " \begin{table}[htbp]\centering \def\sym#1{\ifmmode^{#1}\else\(^{#1}\)\fi}  \begin{threeparttable} \caption{Alternative IV Strategies}  \begin{tabular}{l*{5}{c}} \toprule " _n
file write fh "\toprule" _n
file write fh "& \multicolumn{2}{c}{C. Goodman Municipalities} & \multicolumn{2}{c}{School Districts} \\" _n
file write fh "\cmidrule(lr){2-3} \cmidrule(lr){4-5}" _n
file write fh "& \multicolumn{1}{c}{$\beta$} & \multicolumn{1}{c}{OverID Test} & \multicolumn{1}{c}{$\beta$} & \multicolumn{1}{c}{OverID Test} \\" _n
file write fh "&\multicolumn{1}{c}{(1)}   &\multicolumn{1}{c}{(2)}&\multicolumn{1}{c}{(3)}   &\multicolumn{1}{c}{(4)} \\" _n

/** Panel A **/
file write fh "\cmidrule(lr){1-5} " _n
file write fh "\multicolumn{4}{l}{\textbf{Panel A: Alternative Estimators}}\\" _n
file write fh "\cmidrule(lr){1-5} " _n
file write fh "Overidentified TSLS & `overid_n_cgoodman_cz_pc_b' & `overid_n_cgoodman_cz_pc_stat' & `overid_n_schdist_ind_cz_pc_b' & `overid_n_schdist_ind_cz_pc_stat' \\" _n
file write fh " & (`overid_n_cgoodman_cz_pc_se') & [`overid_n_cgoodman_cz_pc_p'] & (`overid_n_schdist_ind_cz_pc_se') & [`overid_n_schdist_ind_cz_pc_p'] \\" _n
file write fh "\addlinespace"  _n
file write fh "LIML & `liml_n_cgoodman_cz_pc_b' & `liml_n_cgoodman_cz_pc_stat' & `liml_n_schdist_ind_cz_pc_b' & `liml_n_schdist_ind_cz_pc_stat' \\" _n
file write fh " & (`liml_n_cgoodman_cz_pc_se') & [`liml_n_cgoodman_cz_pc_p'] & (`liml_n_schdist_ind_cz_pc_se') & [`liml_n_schdist_ind_cz_pc_p'] \\" _n
file write fh "\addlinespace"  _n
file write fh "MBTSLS & `mbtsls_n_cgoodman_cz_pc_b' & & `mbtsls_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`mbtsls_n_cgoodman_cz_pc_se') & & (`mbtsls_n_schdist_ind_cz_pc_se') & \\" _n
file write fh "\addlinespace"  _n
file write fh "HFUL & `hful_n_cgoodman_cz_pc_b' & `hful_n_cgoodman_cz_pc_stat' & `hful_n_schdist_ind_cz_pc_b' & `hful_n_schdist_ind_cz_pc_stat' \\" _n
file write fh " & (`hful_n_cgoodman_cz_pc_se') & [`hful_n_cgoodman_cz_pc_p'] & (`hful_n_schdist_ind_cz_pc_se') & [`hful_n_schdist_ind_cz_pc_p'] \\" _n
file write fh "\cmidrule[\heavyrulewidth](lr){1-5}  " _n

/** Panel B **/
file write fh "\multicolumn{4}{l}{\textbf{Panel B: Alternative Instruments}}\\" _n
file write fh "\cmidrule(lr){1-5} " _n
file write fh "All Southern Crossings & `s_n_cgoodman_cz_pc_b' &  & `s_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`s_n_cgoodman_cz_pc_se') & & (`s_n_schdist_ind_cz_pc_se') &  \\" _n
file write fh "\addlinespace"  _n
file write fh "Long-Term Migrants & `l_n_cgoodman_cz_pc_b' &  & `l_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`l_n_cgoodman_cz_pc_se') & & (`l_n_schdist_ind_cz_pc_se') &  \\" _n
file write fh "\addlinespace"  _n
file write fh "Undocumented Crossings & `ud_n_cgoodman_cz_pc_b' &  & `ud_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`ud_n_cgoodman_cz_pc_se') & & (`ud_n_schdist_ind_cz_pc_se') &  \\" _n
file write fh "\addlinespace"  _n
file write fh "Looking for Work & `w_n_cgoodman_cz_pc_b' &  & `w_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`w_n_cgoodman_cz_pc_se') & & (`w_n_schdist_ind_cz_pc_se') &  \\" _n
file write fh "\addlinespace"  _n
file write fh "Finding Friends & `ff_n_cgoodman_cz_pc_b' &  & `ff_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`ff_n_cgoodman_cz_pc_se') & & (`ff_n_schdist_ind_cz_pc_se') &  \\" _n
file write fh "\addlinespace"  _n
file write fh "Alt. Shifts OverID & `alt_n_cgoodman_cz_pc_b' & `alt_n_cgoodman_cz_pc_stat' & `alt_n_schdist_ind_cz_pc_b' & `alt_n_schdist_ind_cz_pc_stat' \\" _n
file write fh " & (`alt_n_cgoodman_cz_pc_se') & [`alt_n_cgoodman_cz_pc_p'] & (`alt_n_schdist_ind_cz_pc_se') & [`alt_n_schdist_ind_cz_pc_se'] \\" _n
file write fh "\cmidrule[\heavyrulewidth](lr){1-5}  " _n

/** Panel C **/

file write fh "\multicolumn{4}{l}{\textbf{Panel C: Original Instrument}}\\" _n
file write fh "\cmidrule(lr){1-5} " _n
file write fh "US Bound Migrants & `iv_n_cgoodman_cz_pc_b' &  & `iv_n_schdist_ind_cz_pc_b' &  \\" _n
file write fh " & (`iv_n_cgoodman_cz_pc_se') & & (`iv_n_schdist_ind_cz_pc_se') &  \\" _n

file write fh "\hline\hline"  _n
file write fh "\end{tabular}" _n
file write fh "\end{threeparttable}" _n
file write fh "\end{table}" _n

file close fh
