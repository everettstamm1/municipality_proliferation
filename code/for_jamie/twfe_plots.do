
local b_controls reg2 reg3 reg4 sumshare_base
local extra_controls cz_popdens1940 mean_income_1940 mfg_lfshare1940
 use "cz_pooled", clear


ren pre_cgoodman_cz_pc npre_cgoodman_cz_pc
lab var shift_share_base "$\widehat{GM}$"

// Add pop growth variable
forv i=1/11{
	local y = 1900+10*`i'
	local y1 = `y' - 10
	g grow`y' = (pop`y' - pop`y1')/pop`y1'
}
		
		
keep cz grow* pop* popc1940 GM_raw_pp `b_controls' `extra_controls'  n19*_cgoodman_cz_pc n20*_cgoodman_cz_pc above_x_med shift_share_base sumshare_base region
rename n*_cgoodman_cz_pc y*

// Reshape to cz-decade level
reshape long y grow, i(cz) j(year)

g b = .
g ci_lo = .
g ci_hi = .

// Run TWFE with different controls and plot results



reghdfe y ib1940.year##i.above_x_med , absorb(cz year) vce(cluster cz)

forv y=1910(10)2010{
	if `y'==1940{
		replace b = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
	}
	else{
		local name = "`y'.year#1.above_x_med"
		local b = e(b)["y1","`name'"] 
		local sd = e(V)["`name'","`name'"]^(0.5)
		replace b = `b' if year == `y'
		replace ci_lo =`b' - 1.96 *`sd'  if year == `y'
		replace ci_hi = `b' + 1.96 *`sd' if year == `y'
	}
}


sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off) 
				
				
graph export "twfe_main.png", as(png) replace




reghdfe y ib1940.year##i.above_x_med ib1940.year##c.sumshare_base, absorb(cz year) vce(cluster cz)

forv y=1910(10)2010{
	if `y'==1940{
		replace b = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
	}
	else{
		local name = "`y'.year#1.above_x_med"
		local b = e(b)["y1","`name'"] 
		local sd = e(V)["`name'","`name'"]^(0.5)
		replace b = `b' if year == `y'
		replace ci_lo =`b' - 1.96 *`sd'  if year == `y'
		replace ci_hi = `b' + 1.96 *`sd' if year == `y'
	}
}


sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off)
				
graph export "twfe_sumshare_base.png", as(png) replace


reghdfe y ib1940.year##i.above_x_med ib1940.year##c.grow, absorb(cz year) vce(cluster cz)

forv y=1910(10)2010{
	if `y'==1940{
		replace b = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
	}
	else{
		local name = "`y'.year#1.above_x_med"
		local b = e(b)["y1","`name'"] 
		local sd = e(V)["`name'","`name'"]^(0.5)
		replace b = `b' if year == `y'
		replace ci_lo =`b' - 1.96 *`sd'  if year == `y'
		replace ci_hi = `b' + 1.96 *`sd' if year == `y'
	}
}


sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off)
				
graph export "twfe_popgrowth.png", as(png) replace

reghdfe y ib1940.year##i.above_x_med ib1940.year##i.region, absorb(cz year) vce(cluster cz)

forv y=1910(10)2010{
	if `y'==1940{
		replace b = 0 if year == `y'
		replace ci_lo = 0 if year == `y'
		replace ci_hi = 0 if year == `y'
	}
	else{
		local name = "`y'.year#1.above_x_med"
		local b = e(b)["y1","`name'"] 
		local sd = e(V)["`name'","`name'"]^(0.5)
		replace b = `b' if year == `y'
		replace ci_lo =`b' - 1.96 *`sd'  if year == `y'
		replace ci_hi = `b' + 1.96 *`sd' if year == `y'
	}
}


sort year 
set scheme s1color
//set graphics off
twoway 	(scatter b year, color(black)) ///
				(rcap ci_hi ci_lo year, lc(black) msymbol(i)), ///
				xlabel(1910(10)2010, angle(45)) ///
				yline(0, lc(red) lp(dash)) ///
				legend(off)
				
graph export "twfe_regions.png", as(png) replace

