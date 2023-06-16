gl path = "/Users/Everett Stamm/Dropbox/municipality_proliferation\derenoncourt_opportunity\replication_AER\"
gl instrument =  "$path/data/instrument"
gl migshares = "$instrument/shares" 
gl migdata  = "$instrument/migration"
gl xwalks = "$path/data/crosswalks"

use "${migshares}/2_blackorigin_fips1940.dta", clear
ren city citycode
decode citycode, gen(city)
merge 1:1 city using "$xwalks/US_place_point_2010_crosswalks", keep(3) keepusing(cz cz_name) nogen

keep cz cz_name city citycode *origin_fips*
order cz cz_name city citycode 

save "$CLEANDATA/other/urban_fig_3a_data_cz", replace

use "$INTDATA/bartik/full_blackorigin_fips1940.dta", clear
ren dest_fips cty_fips

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) keepusing(cz) nogen
ren czone cz
merge m:1 cz using "$xwalks/cz_names", keep(1 3) nogen
ren cty_fips fips

keep cz cz_name fips  *origin_fips*
order cz cz_name fips  

save "$CLEANDATA/other/totpop_fig_3a_data_cz", replace

	use ${migdata}/raw/south_county.dta, clear
	drop _merge
	g mig = (netbmig/100)*bpop_l
merge m:1 stateicp countyicp using "$xwalks/county1940_crosswalks.dta", keepusing(fips) keep(1 3)
g origin_fips=fips

replace origin_fips = 51067 if countyfips==51620 & _merge==1
replace origin_fips = 48203 if countyfips==48203 & _merge==1
replace origin_fips = 51037 if countyfips==54039 & _merge==1
replace origin_fips = 54041 if countyfips==54041 & _merge==1
replace origin_fips = 51189 if countyfips==189 & _merge==1
drop _merge
replace origin_fips = 1000*state + countyfips if origin_fips==.
drop if mig==.
drop state_name
	statastates, fips(state)
	replace state_name=strlower(state_name)

keep if (state_name=="alabama" | state_name=="arkansas" | state_name=="florida" | state_name=="georgia" | state_name=="kentucky" ///
	| state_name=="louisiana" | state_name=="mississippi" | state_name=="north carolina" | state_name=="oklahoma" | state_name=="south carolina" ///
	| state_name=="tennessee" | state_name=="texas" | state_name=="virginia" | state_name=="west virginia")
	
		collapse (sum)  mig , by(origin_fips year)
		tostring origin_fips, replace
merge 1:1 origin_fips year using ${instrument}/2_lasso_boustan_predict_mig.dta, keepusing(proutmig) nogenerate

replace proutmig=mig if proutmig==.
	replace proutmig=proutmig/1000
	lab var mig "Actual Migration"
		
	save "$CLEANDATA/other/fig_3b_data", replace