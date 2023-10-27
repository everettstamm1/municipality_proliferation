use "$CLEANDATA/pcarrow_fig_data", clear
replace cz_name = "Louisville, KY/IN" if cz==13101
gsort -cz_prop_white
g order = _n
labmask order, values(cz_name)

twoway pcarrow order cz_prop_white order cz_new_prop_white || ///
		scatter order cz_prop_white, ms(oh ) ///
		yla(1/79, ang(h) notick valuelabel labsize(*0.35)) yti("") legend(order(1 "1940-1970 Newly Incorporated Municipalities" 2 "CZ Total" )) ///
		barbsize(2) xtitle("Proportion of Population White, 1970") aspect(1)
		
graph export "$FIGS/pcarrow_figure.png", replace