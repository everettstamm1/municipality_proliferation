
use "$CLEANDATA/mechanisms", clear
	keep totenroll blenroll wtenroll n_ap n_ap_w75 gt de crdc_id  wtenroll_hasap wtenroll_newmuni wtenroll_hasde wtenroll_hasgt ap gt de above_x_med samp_dest
	duplicates drop

	
	g prop_white = wtenroll/totenroll
	lab var prop_white "Proportion White Students"

label define gm 0 "Below Median GM" 1 "Above Median GM"
label define inc 0 "Not Inc. 1940-70" 1 "Inc. 1940-70"
	
label values above_x_med gm
label values samp_dest inc
	
eststo clear
bysort above_x_med samp_dest : eststo : quietly estpost summarize  totenroll prop_white n_ap ap gt de [aw=totenroll], listwise


esttab using "$TABS/schools/crosstab.tex", cells("mean(fmt(0 3)) sd(fmt(0 3))") replace nonum booktabs ///
		prehead("\begin{tabular}{l*{10}{c}} \toprule" "&\multicolumn{4}{c}{Below Median GM}&\multicolumn{4}{c}{Above Median GM} \\ \cmidrule(lr){1-4}  \cmidrule(lr){5-9}" "&\multicolumn{2}{c}{Not Inc. 1940-70}&\multicolumn{2}{c}{Inc. 1940-70}&\multicolumn{2}{c}{Not Inc. 1940-70}&\multicolumn{2}{c}{Inc. 1940-70} \\\cmidrule(lr){2-3}  \cmidrule(lr){4-5}  \cmidrule(lr){6-7}  \cmidrule(lr){8-9} " ) ///
		 postfoot(\midrule \bottomrule \end{tabular}) 
