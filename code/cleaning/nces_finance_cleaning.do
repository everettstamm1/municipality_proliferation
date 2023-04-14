
import delimited "$RAWDATA/nces/districts_saipe.csv", clear 

save "$INTDATA/nces/district_poverty.dta", replace 

import delimited "$RAWDATA/nces/schools_nhgis_geog_2000.csv", clear

// leaid-county fips xwalk, 2000 definitions
import delimited "$RAWDATA/nces/school-districts_lea_directory.csv", clear

drop if county_code < 0 | leaid == . 
keep leaid county_code fips year

save "$XWALKS/leaid_county_xwalk.dta", replace

import delimited "$RAWDATA/nces/districts_ccd_finance.csv", clear 

drop if leaid<0
merge 1:1 leaid year using "$INTDATA/nces/district_poverty.dta", keep(1 3) nogen

order year leaid fips censusid district_name district_id

// All sample selection/transformation decision here come from the Latinx paper code
foreach i of varlist district_id-est_population_5_17_pct {
	replace `i'=. if `i'<0
}

drop if enrollment_fall_responsible==0
drop if enrollment_fall_responsible==.
drop if leaid==260

merge 1:1 year leaid using "$XWALKS/leaid_county_xwalk", keep(3) nogen

collapse (sum) exp_total rev_local_total enrollment_fall_responsible, by(county_code year)
g exp_pp = exp_total/enrollment_fall_responsible
g locrev_pp = rev_local_total/enrollment_fall_responsible

drop if year<1994
collapse (mean) exp_pp locrev_pp, by(county_code)

ren county_code fips
save "$CLEANDATA/nces/nces_finance_data.dta", replace

/* old code, come back to if needed
drop district_id 
drop if enrollment_fall_responsible==0
drop if enrollment_fall_responsible==.
gen totrev_pp=rev_total/enrollment_fall_responsible
gen fedrev_pp=rev_fed_total/enrollment_fall_responsible
gen strev_pp=rev_state_total/enrollment_fall_responsible
gen locrev_pp=rev_local_total/enrollment_fall_responsible
gen exp_pp=exp_total/enrollment_fall_responsible

replace censusid=. if censusid<0

gen finance_reform_00=0

replace finance_reform_00=1 if fips==2 | fips==4 | fips==5 | fips==6 | fips==8 | fips==16 | fips==20 | fips==21 | fips==24 | fips==25  | fips==29 | fips==30 | fips==33 |  fips==34 | fips==35 | fips==37 | fips==39 | fips==47 | fips==48 | fips==50 |  fips==54 | fips==56

gen finance_reform_10=0

replace finance_reform_10=1 if fips==2 | fips==4 | fips==5 | fips==6 | fips==8 | fips==16 | fips==20 | fips==21 | fips==24 | fips==25  | fips==29 | fips==30 | fips==33 |  fips==34 | fips==35 | fips==37 | fips==39 | fips==47 | fips==48 | fips==50 |  fips==54 | fips==56 | fips==53 | fips==38 | fips==36 

order district_name year leaid fips
sort district_name leaid
bysort leaid: replace district_name=district_name[_n-1] if district_name==""
bysort leaid: replace district_name=district_name[_n+1] if district_name==""

drop if leaid==260

gen bilingual_revenue=rev_state_bilingual_ed+ rev_fed_state_bilingual_ed

gen bilrev_pp=bilingual_revenue/enrollment_fall_responsible

order district_name year leaid fips finance_reform_00 finance_reform_10 totrev_pp-exp_pp bilrev_pp enrollment_fall_responsible
*/
