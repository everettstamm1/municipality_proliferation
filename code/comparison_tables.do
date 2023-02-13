
use "$CLEANDATA/county_all_local_stacked.dta", clear

keep fips decade v2_blackmig3539_share GM GM_hat2 reg* base_muni_county_L0 mfg_lfshare n_muni_county_L0

keep if decade == 1940
drop if GM==. | fips == . | reg3 == 1 
sort decade v2_blackmig3539_share

order decade fips v2_blackmig3539_share GM GM_hat2

xtile blackmig_bin = v2_blackmig3539_share if decade==1940, nq(10)
replace blackmig_bin = blackmig_bin -1

g reg = "Northeast"
replace reg = "Midwest" if reg2 == 1
replace reg = "South" if reg3 == 1
replace reg = "West" if reg4 == 1

sort decade blackmig_bin reg GM

order decade v2_blackmig3539_share blackmig_bin reg GM 

bys decade blackmig_bin reg (GM) : g n = _N
bys  decade blackmig_bin reg (GM) : keep if (_n==1 | _n ==_N) & _N>1
bys  decade blackmig_bin reg (GM) : g treated = _n == _N

drop if blackmig_bin == 0 | blackmig_bin == 9
keep fips treated blackmig_bin reg
duplicates drop
tempfile compare_fips

save `compare_fips'

import delimited using "$RAWDATA/census/national_county.txt",clear
g county_name = v4 + ", " + v1
g fips = 1000*v2 + v3

keep county_name fips
tempfile countynames
save `countynames'

use "$CLEANDATA/county_all_local_stacked.dta", clear
merge m:1 fips using `compare_fips', keep(3)  nogen
merge m:1 fips using `countynames', keep(3) nogen

ren base_muni_county_L0 base_all_local
ren n_muni_county_L0 new_all_local

merge 1:1 fips decade using "$CLEANDATA/county_schdist_ind_stacked.dta", keep(3) nogen
drop *_L1 *_L2
ren base_muni_county_L0 base_schdist_ind
ren n_muni_county_L0 new_schdist_ind


keep if decade==1940 | decade == 1950 | decade == 1960

 
g decade_end = decade+10
g decade_str = string(decade)+"-"+string(decade_end)
drop decade decade_end
ren decade_str decade
//g decadeXreg = string(decade) + " " + reg + " region"
//g decadeXbin = string(decade) + ", blackmig decile " + string(blackmig_bin)
g regXbin = reg + " region, decile " + string(blackmig_bin+1)

foreach var of varlist GM GM_hat2 v2_blackmig3539_share mfg_lfshare base* new* countypop{
	
	 
	#delimit ;
	eststo clear;

	cap estpost tabstat `var',
	statistics(mean sd count)
	by(decade) columns(statistics) missing;
	eststo est1;

	cap estpost tabstat `var' if treated==1,
	statistics(mean sd count)
	by(decade) columns(statistics) missing;
	eststo est2;

	cap estpost tabstat `var' if treated==0,
	statistics(mean sd count)
	by(decade) columns(statistics) missing;
	cap eststo est3;

	esttab est1 est2 est3 using "$TABS/comparison_counties/overall_`var'.tex", booktabs nonumber label replace lines noobs
	title("`var'"\label{tab1})
	mtitles("Overall" "Treated" "Control")
	cells((mean(fmt(2)) sd(fmt(2)) count(fmt(0))))
	collabels("Mean" "Std Dev" "Obs");
	#delimit cr
}

/*
foreach var of varlist GM GM_hat2 v2_blackmig3539_share base* new*{
	
	 
	#delimit ;
	eststo clear;

	cap estpost tabstat `var',
	statistics(mean sd count)
	by(decadeXreg) columns(statistics) missing;
	eststo est1;

	cap estpost tabstat `var' if treated==1,
	statistics(mean sd count)
	by(decadeXreg) columns(statistics) missing;
	eststo est2;

	cap estpost tabstat `var' if treated==0,
	statistics(mean sd count)
	by(decadeXreg) columns(statistics) missing;
	cap eststo est3;

	esttab est1 est2 est3 using "$TABS/comparison_counties/region_`var'.tex", booktabs nonumber label replace lines noobs
	title("`var'"\label{tab1})
	mtitles("Overall" "Treated" "Control")
	cells((mean(fmt(2)) sd(fmt(2)) count(fmt(0))))
	collabels("Mean" "Std Dev" "Obs");
	#delimit cr
}


foreach var of varlist GM GM_hat2 v2_blackmig3539_share base* new*{
	
	 
	#delimit ;
	eststo clear;

	cap estpost tabstat `var',
	statistics(mean sd count)
	by(decadeXbin) columns(statistics) missing;
	eststo est1;

	cap estpost tabstat `var' if treated==1,
	statistics(mean sd count)
	by(decadeXbin) columns(statistics) missing;
	eststo est2;

	cap estpost tabstat `var' if treated==0,
	statistics(mean sd count)
	by(decadeXbin) columns(statistics) missing;
	cap eststo est3;

	esttab est1 est2 est3 using "$TABS/comparison_counties/decile_`var'.tex", booktabs nonumber label replace lines noobs
	title("`var'"\label{tab1})
	mtitles("Overall" "Treated" "Control")
	cells((mean(fmt(2)) sd(fmt(2)) count(fmt(0))))
	collabels("Mean" "Std Dev" "Obs");
	#delimit cr
}
*/
levelsof regXbin, local(regbin)

lab var countypop "countypop"
foreach i in `regbin'{
	eststo clear

	forv j=0/1{
		preserve 
			keep if regXbin == "`i'" & treated == `j'
			local bin = blackmig_bin[1]
			local reg = reg[1]
			
			if `j'==0{
				local control_name = county_name[1]
			}
			else {
				local treat_name = county_name[1]
			}				
			qui estpost tabstat v2_blackmig3539_share GM GM_hat2 base* new* mfg_lfshare countypop, ///
			statistics(mean) ///
			by(decade) columns(statistics) missing nototal
			eststo est`j' 
		restore
	}

	esttab est1 est0 using "$TABS/comparison_counties/byregXbin_`reg'_bin_`bin'.tex", booktabs nonumber label replace lines noobs ///
		title("`i'"\label{tab1}) ///
		mtitles("`treat_name' (Treated)" "`control_name' (Control)") ///
		cells((mean(fmt(2)))) ///
		collabels("Mean")
}
			