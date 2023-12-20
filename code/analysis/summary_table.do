
// Install estout if not already installed
eststo clear
use "$CLEANDATA/cz_pooled", clear
lab var n_cgoodman_cz_pc  "$\Delta_{1940-70}$ Number of Municipalities, Per Capita (C. Goodman)"
lab var n_schdist_ind_cz_pc  "$\Delta_{1940-70}$ Number of School Districts, Per Capita"
lab var n_gen_town_cz_pc  "$\Delta_{1940-70}$ Number of Townships, Per Capita"
lab var n_spdist_cz_pc  "$\Delta_{1940-70}$ Number of Special Districts, Per Capita"
lab var n_gen_muni_cz_pc  "$\Delta_{1940-70}$ Number of Municipalities, Per Capita (CoG)"
lab var n_totfrac_cz_pc "$\Delta_{1940-70}$ Main City Share, Per Capita"
lab var GM_hat_raw_pp "$\widehat{GM}$"
lab var GM_raw_pp "GM"

keep if dcourt == 1
// Create groups of variables
local panel_A_vars n_cgoodman_cz_pc n_gen_muni_cz_pc n_schdist_ind_cz_pc n_gen_town_cz_pc n_spdist_cz_pc  n_totfrac_cz_pc
local panel_B_vars GM_raw_pp GM_hat_raw_pp
local panel_C_vars blackmig3539_share mfg_lfshare1940 transpo_cost_1920 m_rr_sqm_total

// Generate summary statistics using eststo and estpost
eststo A: estpost summarize `panel_A_vars', d 

// Create a LaTeX table using esttab

// Save the LaTeX code to a file (replace 'summary_table.tex' with your desired file name)
esttab A using "$TABS/summary.tex", replace cells((mean(label("Mean") fmt(2)) p10(label("10th Percentile") fmt(2)) p50(label("Median") fmt(2)) p90(label("90th Percentile") fmt(2)))) booktabs compress frag label nonum noobs prehead( \begin{tabular}{l*{4}{c}} \toprule) posthead("\cmidrule(lr){1-5}" "\multicolumn{5}{l}{Panel A: Outcome Variables}\\" "\cmidrule(lr){1-5}" ) substitute("\_" "_")

eststo B: estpost summarize `panel_B_vars', d

esttab B using "$TABS/summary.tex", append cells((mean(label(" ") fmt(2)) p10(label(" ") fmt(2)) p50(label(" ") fmt(2)) p90(label(" ") fmt(2)))) booktabs compress frag label nonum noobs nomtitle posthead("\cmidrule(lr){1-5}" "\multicolumn{5}{l}{Panel B: Treatment Variables}\\" "\cmidrule(lr){1-5}" ) mlabels(,none) collabels(,none) substitute("\_" "_")


eststo C: estpost summarize `panel_C_vars', d
esttab C using "$TABS/summary.tex", append  cells((mean(label(" ") fmt(2)) p10(label(" ") fmt(2)) p50(label(" ") fmt(2)) p90(label(" ") fmt(2)))) booktabs compress frag label nonum noobs nomtitle postfoot(\midrule Observations    &      130   &      130   &      130   &      130   \\	\bottomrule \end{tabular})  posthead("\cmidrule(lr){1-5}" "\multicolumn{5}{l}{Panel C: Control Variables}\\" "\cmidrule(lr){1-5}" ) mlabels(,none) collabels(,none) substitute("\_" "_")




