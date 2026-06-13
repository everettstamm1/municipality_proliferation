	use "$INTDATA/counts/cgoodman_cz", clear
	drop n_cgoodman_cz*
	merge 1:1 cz using "$CLEANDATA/cz_pooled", keep(1 3) keepusing(cz)
	forv y =1900(10)2000{
		local y2 = `y'+10
		g n_cgoodman_cz`y' = b_cgoodman_cz`y2' - b_cgoodman_cz`y'
		g samp_cgoodman_cz`y' = n_cgoodman_cz`y'*(_merge == 3)
	}
	reshape long n_cgoodman_cz samp_cgoodman_cz, i(cz) j(decade)
	collapse (sum)  n_cgoodman_cz samp_cgoodman_cz, by(decade)
	

	
	* Create shading region for 1940 to 1970
gen shade_bottom = .  // bottom of shaded area (min y)
gen shade_top = .     // top of shaded area (max y)

replace shade_bottom = 0 if inrange(decade, 1940, 1970)
replace shade_top    = 2633 if inrange(decade, 1940, 1970)  // adjust if your y max is not 100


g decade2 = decade + 5

labmask decade2, values(decade)
twoway (rarea shade_top shade_bottom decade if inrange(decade,1940,1970), ///
        color(gs14)) ///
		(bar n_cgoodman_cz decade2 if inrange(decade,1900,2000), col(red%30) barwidth(10)) ///
(bar samp_cgoodman_cz decade2 if inrange(decade,1900,2000), col(blue%30) barwidth(10)), ///
	xtitle("Decade") ///
    ytitle("Count") ///
    legend(order(2 "Nationwide Total" 3 "Sample Non-Southern CZs" ) ///
           cols(1)) ///
    graphregion(color(white)) ///
    scheme(s1color) 
graph export "$FIGS/FA1.png", replace as(png)
/*
// Numbers for footnote 8
use "$INTDATA/counts/cgoodman_cz", clear
 
g n_10_40 = b_cgoodman_cz1940 - b_cgoodman_cz1910
g n_40_70 = b_cgoodman_cz1970 - b_cgoodman_cz1940
g n_70_00 = b_cgoodman_cz2000 - b_cgoodman_cz1970

g n = 1
collapse (sum)  n_10_40 n_40_70 n_70_00 b_cgoodman_cz1940 b_cgoodman_cz1970, by(n)

use "$INTDATA/counts/gen_muni_cz", clear

	use "$INTDATA/cog/2_county_counts.dta", clear
keep if level == 2
	drop if fips_state == "02" | fips_state=="15"
keep if cz < .
collapse (sum) gen_muni, by(year)


use "$INTDATA/counts/gen_muni_cz", clear
g n =1
collapse (sum) b_gen_muni*, by(n)