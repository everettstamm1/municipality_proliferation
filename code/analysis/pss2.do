import excel using "$XWALKS/ZIP_COUNTY_032025.xlsx", clear first

destring ZIP, gen(zip)
destring COUNTY, gen(cty_fips)
ren RES_RATIO weight
keep zip cty_fip weight
duplicates drop

joinby cty_fips using "$XWALKS/cw_cty_czone"
keep zip czone weight
duplicates drop

bys zip : egen main = max(weight)
keep if weight == main
keep czone zip
duplicates tag zip, gen(tag) // figure out tiebreaks later
bys zip (czone) : drop if tag == 1 & _n == 1 // figure out tiebreaks later
tempfile zip_cty_xwalk
save `zip_cty_xwalk'


use "F:/Latinx_Migration_School_Segregation/interim/nces/pss", clear
drop if (higrade ==0 | higrade > 6) & year < 1997
drop if (higrade <6 | higrade > 11) & year >= 1997
drop if home_school == 2 | n_total == 1 | higrade == lograde | higrade == 0
keep if !mi(year_opened)

keep pin year state_fip cty_fip year_opened zip n_total white black ft_teachers total_teachers

bys pin (cty_fip) : replace cty_fip = cty_fip[1] if mi(cty_fip)


preserve
	keep if mi(cty_fip)
	keep pin zip year_opened n_total white black ft_teachers total_teachers
	bys pin (year_opened) : replace year_opened = year_opened[_N]
	foreach v in n_total white black ft_teachers total_teachers{
		bys pin : egen temp = mean(`v')
		drop `v'
		ren temp `v'
	}
	duplicates drop
	merge m:1 zip using `zip_cty_xwalk' // No tiebroken are matched so idgaf
	
	keep pin year_opened n_total white black czone ft_teachers total_teachers
	
	tempfile mictys
	save `mictys'
	
restore 

drop if mi(cty_fip)

g cty_fips = 1000*state_fip + cty_fip
keep pin cty_fips year_opened n_total white black ft_teachers total_teachers
bys pin (year_opened) : replace year_opened = year_opened[_N]
foreach v in n_total white black ft_teachers total_teachers{
	bys pin : egen temp = mean(`v')
	drop `v'
	ren temp `v'
}
duplicates drop // Keeping different answers for the same school for now
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen

keep pin year_opened n_total white black czone ft_teachers total_teachers

append using `mictys'
ren czone cz
merge m:1 cz using "$CLEANDATA/cz_pooled", keep(3) nogen keepusing(above_x_med reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940)


g samp_dest = .
replace samp_dest = 1 if (year_opened >=1940 & year_opened <=1970) 
replace samp_dest = 0 if (year_opened <1940 | year_opened >1970) 

g samp_destXabove_x_med = samp_dest * above_x_med
g share_white = white /n_total
g share_black = black /n_total
g student_ft_ratio = n_total / ft_teachers
g student_total_ratio = n_total / total_teachers
reghdfe share_black samp_destXabove_x_med above_x_med  samp_dest  reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 [aw=n_total], vce(cl cz) 
reghdfe student_ft_ratio samp_destXabove_x_med above_x_med  samp_dest  reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 [aw=n_total], vce(cl cz) 
reghdfe student_total_ratio samp_destXabove_x_med above_x_med  samp_dest  reg2 reg3 reg4 sumshare_base mfg_lfshare1940 mean_income_1940 cz_popdens1940 [aw=n_total], vce(cl cz) 
