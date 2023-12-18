use "$CLEANDATA/pcarrow_fig_data", clear
replace cz_name = "Louisville, KY/IN" if cz==13101
gsort -cz_prop_white
g order = _n
labmask order, values(cz_name)

g namepos = min(cz_prop_white, cz_new_prop_white)

twoway pcarrow order cz_prop_white order cz_new_prop_white || ///
		(scatter order cz_prop_white, ms(oh) barbsize(2)) || ///
		(scatter order namepos, ms(none) mlabel(cz_name) mlabpos(9) mlabsize(2) mlabcol(black)),  ///
		yla(none) yti("") legend(cols(1) order(1 "1940-1970 Newly Incorporated Municipalities" 2 "CZ Total" )) ///
		 xtitle("Proportion of Population White, 1970") ysize(9) xscale(range(65 100)) xla(65(5)100) graphregion(color(white))
graph export "$FIGS/pcarrow_figure.pdf", replace as(pdf)