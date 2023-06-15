// Options
// Using full destination sample or ccdb destination sample
gl ccdb_samp = "full" // either full or ccdb



import delimited using "$RAWDATA/consistent_county_xwalk/county_crosswalk_endyr_1990.csv", clear 
save "$XWALKS/consistent_1990", replace
keep if year>=1940 & year<=1970
keep year nhgisst nhgiscty statenam nhgisnam nhgisst_1990 nhgiscty_1990 weight

save "$XWALKS/consistent_1940_1970", replace

// Note: this is copied directly from clean_census_tract_2010_rural_urban_classification.do from the Derenoncourt repo


/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file generates cleans raw NHGIS data to produce a clean 2010 Census tract rural-urban classification dataset.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Import census-tract-level NHGIS dataset classifying tracts as rural or urban.
	*2. Clean variable names.
	*3. Save clean dataset.
	
*first created: 06/12/2021
*last updated:  11/24/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

	insheet using "$RAWDATA/dcourt/nhgis0068_ds172_2010_tract.csv", clear
	rename tracta tract
	drop state county
	rename statea state
	rename countya county
	tempfile urban_rural
	save "$XWALKS/clean_census_tract_2010_rural_urban_classification.dta", replace


// Note: this is copied directly from msa_1990_codes_names.do from the Derenoncourt repo

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file produces an MSA code-name crosswalk from a dictionary file.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*first created: 11/10/2021
*last updated:  11/10/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

	infile using "$RAWDATA/dcourt/msa_1990_codes_names.dct",  clear using("$RAWDATA/dcourt/msa_1990_codes_names.txt")
	drop if msa==""
	drop if regexm(msa_name, ",")!=1
	keep if regexm(msa_name,"MSA")==1 
	quietly bysort msa: gen dup=cond(_N==1,0,_n)
	keep if dup<=1
	drop dup
	save "$XWALKS/msa_1990_codes_names.dta", replace


// Note: this is copied directly from necma_1990_codes_names.do from the Derenoncourt repo

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file produces an NECMA code-name crosswalk from a dictionary file.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*first created: 11/10/2021
*last updated:  11/10/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

	infile using "$RAWDATA/dcourt/necma_1990_codes_names.dct",  clear using("$RAWDATA/dcourt/necma_1990_codes_names.txt")
	drop if necma==""
	drop if regexm(necma_name, ",")!=1
	keep if regexm(necma_name,"NECMA")==1 
	quietly bysort necma: gen dup=cond(_N==1,0,_n)
	keep if dup<=1
	drop dup
	save "$XWALKS/necma_1990_codes_names.dta", replace


// Note: this is copied directly from urbrural_county.do from the Derenoncourt repo

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file produces an urban-rural classification dataset from a dictionary file.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*first created: 11/10/2021
*last updated:  11/10/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

	infile using "$RAWDATA/dcourt/NCHS_UR_Codes_2013.dct",  clear using("$RAWDATA/dcourt/NCHS_UR_Codes_2013.txt")
	save "$XWALKS/urbrural_county.dta", replace


// Note: this is copied directly from county1940_crosswalks.do from the Derenoncourt repo

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file cleans the 1940 county crosswalks file produced by ArcGIS.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*first created: 11/10/2021
*last updated:  11/10/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

local i=1940

insheet using "$RAWDATA/dcourt/US_county_`i'_msacmsa_1990_necma_1990_smsa_1970_cz_1990.csv", clear
keep decade icpsrst icpsrcty icpsrnam statenam state county x_centroid y_centroid gisjoin gisjoin2 msacmsa necma smsaa name czone
rename icpsrst stateicp
rename icpsrcty countyicp
rename state statefip
rename county countyfip
rename icpsrnam county_name
rename statenam state_name
rename msacmsa msa
rename name smsa_name
rename smsaa smsa
rename czone cz

statastates, name(state_name)
drop _merge
replace state_name=proper(state_name)
replace county_name = proper(county_name) + " County, " + state_abbrev

merge m:1 msa using "$XWALKS/msa_1990_codes_names.dta", keep(1 3) nogen
merge m:1 necma using "$XWALKS/necma_1990_codes_names.dta", keep(1 3) nogen
merge m:1 cz using "$RAWDATA/dcourt/cz_names.dta", keep(1 3) nogen

g msanecma = ""
replace msanecma=msa if msa!=""
replace msanecma=necma if necma!=""
g msanecma_name=""
replace msanecma_name=msa_name if msa_name!=""
replace msanecma_name=necma_name if necma_name!=""
replace statefip=substr(statefip,1,length(statefip)-1)
replace countyfip=substr(countyfip,1,length(countyfip)-1)
replace countyfip="0"+countyfip if length(countyfip)==2
replace countyfip="00"+countyfip if length(countyfip)==1
g fips_str=statefip+countyfip
replace fips_str="0"+fips_str if length(fips_str)<5
destring fips_str, gen(fips)
encode fips_str, gen(fips_code)
drop if fips==0
tostring gisjoin2, gen(gisjoin2_str)

/* Remove duplicate counties for now. Come back to this if you start having 
problems with merges. But for now, these are either southern counties or 
Yellowstone National Park. */

bysort fips: gen dup= cond(_N==1,0,_n)
tab dup
tab county_name if dup>0
drop if dup>1
drop dup

/* Merge in urban rural county classification scheme. */
merge 1:1 fips using "$XWALKS/urbrural_county.dta", keepusing(ur_code_2013 ur_code_2006 ur_code_1990) keep(1 3) nogen

/* Save crosswalks. */
save "$XWALKS/county`i'_crosswalks.dta", replace


// Note: This is copied directly from clean_IPUMS_1935_1940_extract_to_construct_migration_weights.do from the Derenoncourt Repo

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file cleans the 2010 US place crosswalk file produced by ArcGIS.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*first created: 11/10/2021
*last updated:  11/10/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

shp2dta using "$RAWDATA/dcourt/place_point_2010_crosswalks/US_place_point_2010_crosswalks", database("$INTDATA/US_place_point_2010_crosswalks") coordinates("$INTDATA/US_place_point_2010_crosswalks") replace

use "$INTDATA/US_place_point_2010_crosswalks.dta", clear

foreach v of varlist _all {
	capture rename `v' `=lower("`v'")'
}	

statastates, name(state)
keep if _merge==3
drop _merge

g city = name + ", " +  state_abbrev

sort city
quietly by city: gen dup= cond(_N==1,0,_n)
tab dup 
keep if dup<=1
drop dup 
replace city=subinstr(city, " Town,", ",",.)
replace city="Indianapolis, IN" if city=="Indianapolis city (balance), IN"
replace city="Louisville, KY" if city=="Louisville/Jefferson County metro government (balance), KY"
replace city = "Augusta, GA" if city == "Augusta-Richmond County consolidated government (balance), GA"  // Augusta merged with surrounding county minus a few cities in 1995
replace city = "Athens, GA" if city == "Athens-Clarke County unified government (balance), GA" // Athens joined with surrounding county in 1991
replace city = "Lexington, KY" if city == "Lexington-Fayette, KY"
replace city = "Nashville, TN" if city == "Nashville-Davidson metropolitan government (balance), TN" // Nashville merged with surrounding county minus a few "semi-independent municipalities" in 1963
replace city = "Butte, MT"  if city == "Butte-Silver Bow (balance), MT" // Butte merged with surrounding county in 1977
replace city = "Anaconda, MT" if city == "Anaconda-Deer Lodge County, MT" //		

keep city icpsrst icpsrcty icpsrnam statenam state county x_centroid y_centroid gisjoin gisjoin2 msacmsa necma smsaa name czone
rename icpsrst stateicp
rename icpsrcty countyicp
rename state statefip
rename county countyfip
rename icpsrnam county_name
rename statenam state_name
rename msacmsa msa
rename name smsa_name
rename smsaa smsa
rename czone cz

statastates, name(state_name)
drop _merge
replace state_name=proper(state_name)
replace county_name = proper(county_name) + " County, " + state_abbrev

merge m:1 msa using "$XWALKS/msa_1990_codes_names.dta", keep(1 3) nogen
merge m:1 necma using "$XWALKS/necma_1990_codes_names.dta", keep(1 3) nogen
merge m:1 cz using "$RAWDATA/dcourt/cz_names.dta", keep(1 3) nogen

g msanecma = ""
replace msanecma=msa if msa!=""
replace msanecma=necma if necma!=""
g msanecma_name=""
replace msanecma_name=msa_name if msa_name!=""
replace msanecma_name=necma_name if necma_name!=""
replace statefip=substr(statefip,1,length(statefip)-1)
replace countyfip=substr(countyfip,1,length(countyfip)-1)
replace countyfip="0"+countyfip if length(countyfip)==2
replace countyfip="00"+countyfip if length(countyfip)==1
g fips_str=statefip+countyfip
replace fips_str="0"+fips_str if length(fips_str)<5
destring fips_str, gen(fips)
encode fips_str, gen(fips_code)
drop if fips_code==0
tostring gisjoin2, gen(gisjoin2_str)

sort city
quietly by city: gen dup= cond(_N==1,0,_n)
tab dup 
keep if dup<=1
drop dup 

save "$XWALKS/US_place_point_2010_crosswalks.dta", replace


// Note: This is copied from clean_cz_industry_employment_1940_1970.do from the Derenoncourt Repo and modified to be at county level
/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

1. This do-file cleans/builds all the county to metropolitan area crosswalk files created using GIS and adds an urban-rural county classification scheme.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Read in raw 1940 data, clean geography and merge with crosswalk, construct industry employment measures at CZ level. 
	*2. Repeat for 1970.
	*3. Merge 1940 and 1970 cz industry employment datasets.
	*4. Construct Bartik measure for employment change.
*first created: 10/04/2019
*last updated:  10/07/2019
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Read in raw 1940 data, clean geography and merge with crosswalk, construct industry employment measures.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
foreach level in cz county{
		if "`level'"=="cz"{
			local levelvar cz
		}
		else if "`level'"=="county"{
			local levelvar fips
		}
		else if "`level'"=="msa"{
			local levelvar smsa
		}
		use "$RAWDATA/dcourt/jobs/raw/complete_census_1940_industry_employment.dta", clear

		* Information on the mapping of IPUMS Census industry codes to 1-digit SIC1 codes can be found at the following website:
		* https://usa.ipums.org/usa/volii/ind1940.shtml
		
		gen SIC1 = ""
		* Argriculture
		replace SIC1 = "ag" if inrange(ind,0,3)
		* Mining
		replace SIC1 = "min" if inrange(ind,4,10)
		* Construction
		replace SIC1 = "const" if inrange(ind,11,11)
		* Manufacturing
		replace SIC1 = "man" if inrange(ind,12,72)
		* Transportation, communication, and utilities
		replace SIC1 = "tcu" if inrange(ind,73,89)
		* Wholesale
		replace SIC1 = "wh" if inrange(ind,90,90)
		* Retail
		replace SIC1 = "rtl" if inrange(ind,91,110)
		* Finance and real estate
		replace SIC1 = "fire" if inrange(ind,111,113)
		* Services
		replace SIC1 = "svc" if inrange(ind,114,127)
		* Government
		replace SIC1 = "gov" if inrange(ind,128,131)
		* Unclassified
		replace SIC1 = "nr" if inrange(ind,995,999)


		* Collapse key variables to county level, keeping ind + vars needed to clean geography (see below)
		collapse (sum) emp_ = empstat , by(SIC1 year countyicp statefip)
		
		reshape wide emp_, i(countyicp statefip) j(SIC1) string
		local sectorlist ag const fire gov man min nr rtl svc tcu wh
		local new_varlist ""
		foreach sector in `sectorlist' {
			local year = year
			rename emp_`sector' emp_`sector'`year'
			local new_varlist `new_varlist' emp_`sector'
		}
		drop year
		
		egen emp_tot1940 = rowtotal(`new_varlist')
		
		* Clean geography
		rename statefip state_fips
		statastates, fips(state_fips)
		keep if _merge==3
		drop _merge
		rename state_fips statefip
		
		tostring county, g(county_str)
		
		*Create Fips Code
		tostring statefip, g(state_str)
		replace state_str="0"+state_str if length(state_str)==1
		
		replace county_str = substr(county_str, 1, length(county_str)-1)
		replace county_str= "0" + county_str if length(county_str)==2
		replace county_str= "00" + county_str if length(county_str)==1
		
		g fips_str=state_str+county_str
		
		
		* Adjust for county changes
		replace fips_str="24510" if fips_str=="24007"
		replace fips_str="29186" if fips_str=="29193"
		replace fips_str="41061" if fips_str=="41060"
		replace fips_str="32025" if fips_str=="32051"
		
		destring(fips_str), g(fips)
		*duplicates list fips //no duplicates 
		
		* Merge with County Crosswalk
		merge m:1 fips_str using "$XWALKS/county1940_crosswalks.dta", keepusing(cz cz_name smsa)
		* Note that there is one unmatched observation in the master file: fips 51785
		drop if _merge == 2 | _merge == 1
		drop _merge
		
		* Remove Alaska and Hawaii
		drop if statefip==2 | statefip==15
		
		drop statefip
		
		* Collapse again to commuting zone (CZ) level and save as tempfile
		collapse (sum) `new_varlist' emp_tot1940, by(`levelvar')
		
		tempfile ind_emp_1940
		save `ind_emp_1940'

	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*2. Repeat for 1970. 
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
			
		/* Load the data. */
		use "$RAWDATA/dcourt/jobs/raw/nhgis0061_fixed/nhgis0061_ds98_1970_county.dta", clear
		
		/* Generate fips code, drop duplicate counties. Come back to this if you have merge problems. */
		g fips_str = substr(statea, 1, 2) + substr(countya, 1, 3)
		count if strlen(fips_str) ~= 5
		assert r(N) == 0
		destring fips_str, gen(fips)
		//duplicates list fips // 1 Set of Duplicates (FIPS 51780 = (1)South Boston City, VA and (2) South Norfolk, VA.
							 // Both of the above cities were later incorporated into a different county or ind. city, and 
							 // since we want this 1960 file to merge with later 1990, 2000, and even 2010 files, we will adjust their fips
							 // to reflect this change and add to new county's enrollment counts.
							 
							 // There must be other counties or cities which also underwent name / county designation; but these will be detected
							 // at the time of merging across years and be adjusted then.
							 
		replace fips = 51083 if fips == 51780 & county == "South Boston City"
		replace fips = 51550 if fips == 51780 & county == "South Norfolk City"
		
		duplicates list fips
		drop if fips == 51083 // The 1960 file only contains private school enrollment rate, not counts, and thus we cannot merge these two entities.
								// Given VA is not in our sample, the drop should be okay but can be revisited later. 		
		rename statea state_str
		
		/* Keep only necessary vars. */
		keeporder state_str county fips c09001 c09002 c09003 c09004 c09005 c09006 c09007 c09008 c09009 c09010 c09011 c09012 c09013 c09014
		
		* Adjusting County Names and FIps to Help Merge
		replace fips = 2210 if fips == 2201
		replace county = "Seward" if state ==  "Alaska" & county == "Seward - Elec District 11"			
		g fips_str = fips
		tostring fips_str, format(%05.0f) replace
		
		merge m:1 fips_str using "$XWALKS/county1940_crosswalks.dta", nogen keep(3) keepusing(cz cz_name state_name county_name smsa)
		
		* Rename employment variables consistent with 1940 data
		rename c09001 emp_ag1970
		rename c09002 emp_min1970
		rename c09003 emp_const1970
		* adding together c09004 (Manufacturing, durable goods) and c09005 (Manufacturing, nondurable goods) to create composite manufacturing variable
		replace c09004 = c09004 + c09005
		drop c09005
		rename c09004 emp_man1970
		rename c09006 emp_tcu1970
		rename c09007 emp_wh1970
		rename c09008 emp_rtl1970
		rename c09009 emp_fire1970
		* adding together c09010 (Business and repair services), c09011 (Personal services), c09012 (Entertainment and recreation services), and c09013 (Professional and related services) to create composite services variable
		replace c09010 = c09010 + c09011 + c09012 + c09013
		drop c09011 c09012 c09013
		rename c09010 emp_svc1970
		* Assuming public admin is equivalent with gov
		rename c09014 emp_gov1970
		gen emp_nr1970 = 0
		
		* Drop if Hawaii or Alaska
		drop if state_str=="02" | state_str=="15"
		
		* Create industry employment measures
		* Collapse again to commuting zone (CZ) level and save as tempfile
		local new_varlist emp_ag1970 emp_min1970 emp_nr1970 emp_const1970 emp_man1970 emp_tcu1970 emp_wh1970 emp_rtl1970 emp_fire1970 emp_svc1970 emp_gov1970
		egen emp_tot1970 = rowtotal(`new_varlist')
		collapse (sum) `new_varlist' emp_tot1970, by(`levelvar')
		
		tempfile ind_emp_1970
		save `ind_emp_1970'
		
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	*4. Merge in 1940-1970 share of labor force in manufacturing from cleaned CZ-level County Data Books, 1947-1977. Save final dataset.
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

		* Input raw data.
		use "$RAWDATA/dcourt/ICPSR_07736_County_Book_1947_1977/DS0001/County_Book_1947_1977.dta", clear
		drop if FIPSCNTY=="000" // Drop state-level data
		g fips_str=FIPSTATE+ FIPSCNTY // Create county fips identifier for merging with other geographies
		destring fips_str, gen(fips)
		* Merge in harmonized geo identifiers.
		merge 1:1 fips_str using "$XWALKS/county1940_crosswalks.dta", keepusing(cz smsa)
		tab _merge // Check and see what counties are matching and not matching. Create a comment in the code detailing non-matching counties.
		keep if _merge==3 
		drop _merge
		
		* Add vars to this list
		local varlist CC00012 CC00013 CC00014 CC00015 CC00016 CC00017 CC00018 CC00038 CC00039 CC00040 CC00041 CC00051 CC00052 CC00053 CC00054 CC00055 CC00056 CC00057 CC00061 CC00062 CC00071 CC00073 CC00074 CC00107 CC00108 CC00109 CC00110 CC00111 CC00112 CC00115 CC00123 CC00128 CC00129 CC00132 CC00133 CC00134 CC00135 CC00150 CC00152 CC00153 CC00154 CC00155 CC00156 CC00157 CC00158 CC00159 CC00160 CC00161 CC00162 CC00163 CC00164 CC00165 CC00166 CC00167 CC00168 CC00169 CC00170 CC00171 CC00172 CC00173 CC00174 CC00175 CC00176 CC00177 CC00178 CC00179 CC00180 CC00181 CC00182 CC00183 CC00184 CC00185 CC00186 CC00187 CC00188 CC00189 CC00190 CC00191 CC00192 CC00193 CC00194 CC00195 CC00196 CC00197 CC00198 CC00199 CC00200 CC00201 CC00202 CC00203 CC00204 CC00205 CC00206 CC00207 CC00208 CC00209 CC00210 CC00211 CC00212 CC00213 CC00214 CC00215 CC00216 CC00217 CC00218 CC00219 CC00220 CC00221 CC00222 CC00223 CC00224 CC00225 CC00226 CC00227 CC00228 CC00229 CC00230 CC00231 CC00232 CC00233 CC00234 CC00235 CC00236 CC00237 CC00238 CC00239 CC00240 CC00241 CC00242 CC00243 CC00244 CC00245 CC00246 CC00247 CC00248 CC00249 CC00250 CC00251 CC00252 CC00253 CC00254 CC00255 CC00256 CC00257 CC00258 CC00259 CC00260 CC00261 CC00262 CC00263 CC00264 CC00265 CC00266 CC00267 CC00268 CC00269 CC00270 CC00271 CC00272 CC00273 CC00274 CC00275 CC00276 CC00277 CC00278 CC00279 CC00280 CC00282 CC00283 CC00284 CC00285 CC00286 CC00287 CC00288 CC00289 CC00290 CC00291 CC00292 CC00293 CC00294 CC00295 CC00296 CC00297 CC00298 CC00299 CC00300 CC00301 CC00302 CC00303 CC00304 CC00305 CC00306 CC00307 CC00308 CC00309 CC00310 CC00311 CC00312 CC00313 CC00314 CC00315 CC00316 CC00317 CC00318 CC00319 CC00320 CC00321 CC00322 CC00323 CC00324 CC00325 CC00326 CC00327 CC00328 CC00329 CC00330 CC00331 CC00332 CC00333 CC00334 CC00335 CC00336 CC00337 CC00338 CC00339 CC00340 CC00341 CC00342 CC00343 CC00344 CC00345 CC00346 CC00347 CC00348 CC00349 CC00350 CC00351 CC00352 CC00353 CC00354 CC00355 CC00356 CC00357 CC00358 CC00359 CC00360 CC00361 CC00362 CC00363 CC00364 CC00365 CC00366 CC00367 CC00368 CC00369 CC00370 CC00371 CC00372 CC00373 CC00374 CC00375 CC00376 CC00377 CC00378 CC00379 CC00380 CC00381 CC00382 CC00383 CC00384 CC00386 CC00387 CC00388 CC00389 CC00390 CC00391 CC00392 CC00393 CC00394 CC00395 CC00396 CC00397 CC00398 CC00399 CC00400 CC00401 CC00402 CC00403 CC00404 CC00405 CC00406 CC00407 CC00408 CC00409 CC00410 CC00411 CC00412 CC00413 CC00414 CC00415 CC00416 CC00417 CC00418 CC00419 CC00420 CC00421 CC00422 CC00423 CC00424 CC00425 CC00426 CC00427 CC00428 CC00429 CC00430 CC00431 CC00432 CC00433 CC00434 CC00435 CC00436 CC00437 CC00438 CC00439 CC00440 CC00441 CC00442
		
		* Replace values as missing if identified as missing according to the Codebook. Check that this is the right approach to dealing with the missing values.
		foreach var in `varlist'{
		replace `var'=. if (`var'F=="1"|`var'F=="2"|`var'F=="3"|`var'F=="6"|`var'F=="7")
		}

		********************
		**** EMPLOYMENT ****
		********************
		
		* CIVILIAN LABOR FORCE
		g civlf1940 = CC00154 //note slight difference in naming of this variable in consolidated codebook-- i checked the respective individual ccdbs (1947 vs. 1952, 62, etc.) and it appears the definitions are comparable, but let's confirm this somehow
		g civlf1950 = CC00160
		g civlf1960 = CC00161
		g civlf1970 = CC00162
		
		* EMPLOYED
		g employed1940 = CC00168
		g employed1950 = CC00169
		g employed1960 = CC00170
		g employed1970 = CC00171

		* EMPLOYED IN MANUFACTURING
		g emp_mfg1940 = CC00181
		g emp_mfg1950 = CC00182
		//CC00183 gives percent employed in manufacturing 1950, duplicates CC00182
		g emp_mfg1960 = (CC00184/100)*employed1960
		g emp_mfg1970 = (CC00185/100)*employed1970
		

		***********************
		** PREPARE FOR MERGE **
		***********************
		
		drop CC* FIP* AREA* // Drop unnecessary vars
				
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*2. Collapse dataset to sum baseline variables to CZ level and create measures with the collapsed data. 
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
		qui ds fips_str fips cz smsa, not // Get list of all non geographic identifier, count vars for collapsing
		collapse (sum) `r(varlist)', by(`levelvar') // Collapse to CZ level

		********************
		**** EMPLOYMENT ****
		********************
		
		* Time-series vars
		
		* EMPLOYMENT SHARE
		local year 40 50 60 70
		foreach var in `year' {
		g emp_share19`var' = employed19`var'*100/civlf19`var'
		la var emp_share19`var' "Share of LF employed, 19`var'"
		}
		
		* MANUFACTURING EMPLOYMENT SHARE
		local year 40 50 60 70
		foreach var in `year' {
		g mfg_lfshare19`var' = emp_mfg19`var'*100/civlf19`var'
		la var mfg_lfshare19`var' "Share of LF employed in manufacturing, 19`var'"
		}
		
		tempfile mfg_lfshare
		save `mfg_lfshare'
			
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
	*3. Merge industry employment datasets. 
	*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

		use `ind_emp_1940', clear
		merge 1:1 `levelvar' using `ind_emp_1970', nogen	
		merge 1:1 `levelvar' using `mfg_lfshare', keepusing(mfg_lfshare1940 mfg_lfshare1950 mfg_lfshare1960 mfg_lfshare1970) nogenerate
		
		save "$INTDATA/dcourt/clean_`level'_industry_employment_1940_1970.dta", replace
	}


// Note: This is copied directly from clean_IPUMS_1935_1940_extract_to_construct_migration_weights.do from the Derenoncourt Repo

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file cleans 1940 complete count census file for constructing 1935-1940 southern county migrant shift share instrument change in the black population in northern locations between 1940 and 1970.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Clean 1940 complete count census 1935-1940 migrants extract file, perform preliminaries for bartik and save intermediate file.
*first created: 09/11/2018
*last updated:  11/23/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Clean 1940 complete count census 1935-1940 migrants extract file.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
/* Input data set and keep if origin state five years ago is in the south. 

South is defined as:
Alabama, Arkansas, Florida, Georgia, Kentucky, Louisiana, Mississippi, North 
Carolina, Oklahoma, South Carolina, Tennessee, Texas, Virginia, and West 
Virginia. Maryland and Delaware are excluded because they on net receive 
southern migrants during this period.*/	
use "$RAWDATA/dcourt//IPUMS_1940_extract_to_construct_migration_weights.dta", clear

/* Keep southerners */
decode migplac5, gen(origin_state)
g origin_sample=(origin_state=="Alabama" | origin_state=="Arkansas" | origin_state=="Florida" | origin_state=="Georgia" | origin_state=="Kentucky"| origin_state=="Louisiana" | origin_state=="Mississippi" | origin_state=="North Carolina" | origin_state=="Oklahoma" | origin_state=="South Carolina" | origin_state=="Tennessee" | origin_state=="Texas" | origin_state=="Virginia" | origin_state=="West Virginia")

drop if migcounty==9999

/* Generate an origin state icp code variable. Note that MIGPLAC5 appears to 
be the state FIPS code (compare 
https://usa.ipums.org/usa-action/variables/MIGPLAC5#codes_section to 
https://usa.ipums.org/usa-action/variables/STATEFIP#codes_section, 
so I do not use MIGPLAC5 here. To get the ICP codes, see: 
https://usa.ipums.org/usa-action/variables/STATEICP#codes_section */

/* Merge in county 1940 crosswalks to get the origin county fips 
code into the dataset. Clean the data first as there are discrepancies 
between IPUMS extract codes and NHGIS codes */

tostring migplac5, gen(southstatefip_str) 
replace southstatefip_str=southstatefip_str+"0"
gen southcounty=migcounty 
replace southcounty=southcounty+20 if migplac5==24 & southcounty!=5100 & southcounty>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits
tostring southcounty, gen(southcountyicp_str)  
replace southcountyicp_str="00"+southcountyicp_str if length(southcountyicp_str)==2 
replace southcountyicp_str="0"+southcountyicp_str if length(southcountyicp_str)==3
replace southcountyicp_str=substr(southcountyicp_str,1,length(southcountyicp_str)-2)+ "10" if migplac5==41 & southcountyicp_str=="0605" // Union county in Oregon is 605 in IPUMS census extract but 610 in NHGIS file
replace southcountyicp_str =substr(southcountyicp_str,1,length(southcountyicp_str)-1)+ "0" if(regexm(southcountyicp_str, "[0-9][0-9][0-9][5]")) // IPUMS Census extract notes county code changes with 0 or 5 but all county codes end in 0 in NHGIS file

replace southcountyicp_str="1860" if southcountyicp_str=="1930" & migplac5==29 // Discrepancy between Missouri county St Genevieve county code in IPUMS Census extract vs. NHGIS file
replace southcountyicp_str="7805" if southcounty==7850 & southstatefip_str=="510" // Possible typo with Greenbrier county coded as 785 instead of 775 in IPUMS Census extract. Reassigned to South Norfolk's code from NHGIS file because both are part of Chesapeak (independent city) today.
replace southcountyicp_str="0050" if southcountyicp_str=="0053" & migplac5==22 // Possible typo with Jefferson Davis county coded as 53 instead of 50 in IPUMS Census extract. Recoded as 50.
gen gisjoin2_str = southstatefip_str + southcountyicp_str

merge m:1 gisjoin2_str using "$XWALKS/county1940_crosswalks.dta", keepusing(fips state_name county_name) keep(1 3) nogen // Drop counties that had no 1935-1940 migrants (1,162 total).
rename fips origin_fips
rename state_name origin_state_name
rename county_name origin_county_name 
drop gisjoin2

/* Merge in county 1940 crosswalks to get the destination county fips 
code into the dataset. Clean the data first as there are discrepancies 
between IPUMS extract codes and NHGIS codes */

tostring statefip, gen(statefip_str) 
replace statefip_str=statefip_str+"0"
replace county=county+20 if county==24 & county!=5100 & county>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits
tostring county, gen(countyicp_str)  
replace countyicp_str="00"+countyicp_str if length(countyicp_str)==2 
replace countyicp_str="0"+countyicp_str if length(countyicp_str)==3
replace countyicp_str=substr(countyicp_str,1,length(countyicp_str)-2)+ "10" if county==41 & countyicp_str=="0605" // Union county in Oregon is 605 in IPUMS census extract but 610 in NHGIS file
replace countyicp_str =substr(countyicp_str,1,length(countyicp_str)-1)+ "0" if(regexm(countyicp_str, "[0-9][0-9][0-9][5]")) // IPUMS Census extract notes county code changes with 0 or 5 but all county codes end in 0 in NHGIS file
replace countyicp_str="1860" if countyicp_str=="1930" & county==29 // Discrepancy between Missouri county St Genevieve county code in IPUMS Census extract vs. NHGIS file
replace countyicp_str="7805" if county==7850 & statefip_str=="510" // Possible typo with Greenbrier county coded as 785 instead of 775 in IPUMS Census extract. Reassigned to South Norfolk's code from NHGIS file because both are part of Chesapeak (independent city) today.
replace countyicp_str="0050" if countyicp_str=="0053" & statefip==22 // Possible typo with Jefferson Davis county coded as 53 instead of 50 in IPUMS Census extract. Recoded as 50.
gen gisjoin2_str = statefip_str + countyicp_str

merge m:1 gisjoin2_str using "$XWALKS/county1940_crosswalks.dta", keepusing(fips state_name county_name)
drop if _merge==2 // Drop counties that had no 1935-1940 migrants (1,162 total).
rename fips dest_fips
rename state_name dest_state_name
rename county_name dest_county_name 
drop gisjoin2
drop _merge

/* Create flag to drop southern destinations later. */
replace dest_state_name=proper(dest_state_name)
g dest_sample=1
replace dest_sample=0  if (dest_state_name=="Alabama" | dest_state_name=="Arkansas" | dest_state_name=="Florida" | dest_state_name=="Georgia" | dest_state_name=="Kentucky"| dest_state_name=="Louisiana" | dest_state_name=="Mississippi" | dest_state_name=="North Carolina" | dest_state_name=="Oklahoma" | dest_state_name=="South Carolina" | dest_state_name=="Tennessee" | dest_state_name=="Texas" | dest_state_name=="Virginia" | dest_state_name=="West Virginia")

g ccdb_sample = dest_sample
preserve
	use "$RAWDATA/dcourt/ICPSR_07735_City_Book_1944_1977/DS0001/City_Book_1944_1977.dta", clear

	*Standardize State Names
	drop if PLACE1=="0000"
	destring STATE1, replace
	statastates, fips(STATE1)  nogen

	cityfix_ccdb

	
	merge 1:1 city using "$xwalks/US_place_point_2010_crosswalks.dta", keepusing(stateicp countyicp) keep(1 3) nogen
	replace countyicp = "0130" if city == "Belleville, NJ"
	replace stateicp = "12" if city == "Belleville, NJ"
	destring countyicp, gen(county)
	destring stateicp, replace
	keep county stateicp
	duplicates drop
	tempfile urbanized_counties
	save `urbanized_counties'
restore

merge m:1 stateicp county using `urbanized_counties', keep(1 3) 
replace ccdb_sample=0 if _merge==1 // Sample is counties that have a city in the ccdb
drop _merge

replace dest_sample = 0 if dest_fips ==.

/* Create clean grade variable */
g grade_completed=.
replace grade_completed=0 if educd==2  
replace grade_completed=1 if educd==14
replace grade_completed=2 if educd==15
replace grade_completed=3 if educd==16
replace grade_completed=4 if educd==17
replace grade_completed=5 if educd==22
replace grade_completed=6 if educd==23
replace grade_completed=7 if educd==25
replace grade_completed=8 if educd==26
replace grade_completed=9 if educd==30
replace grade_completed=10 if educd==40
replace grade_completed=11 if educd==50
replace grade_completed=12 if educd==60
replace grade_completed=13 if educd==70
replace grade_completed=14 if educd==80
replace grade_completed=15 if educd==90
replace grade_completed=16 if educd==100
replace grade_completed=17 if educd==110
replace grade_completed=. if educd==999
la var grade_completed "Grade completed"

/* Generate different group types */
gen black=(race==2) // Create race dummy variable 
gen white=(race==1)
gen male=(sex==1)
gen female=(sex==2)
gen age25plus=(age>=25)

g abfh=(black==1 & female==1 & age25plus==1 & grade_completed>=9)
g abfl=(black==1 & female==1 & age25plus==1 & grade_completed<9)
g abmh=(black==1 & male==1 & age25plus==1 & grade_completed>=9)
g abml=(black==1 & male==1 & age25plus==1 & grade_completed<9)
g awfh=(white==1 & female==1 & age25plus==1 & grade_completed>=9)
g awfl=(white==1 & female==1 & age25plus==1 & grade_completed<9)
g awmh=(white==1 & male==1 & age25plus==1 & grade_completed>=9)
g awml=(white==1 & male==1 & age25plus==1 & grade_completed<9)
g abh=(black==1 & age25plus==1 & grade_completed>=9)
g abl=(black==1 & age25plus==1 & grade_completed<9)
g awh=(white==1 & age25plus==1 & grade_completed>=9)
g awl=(white==1 & age25plus==1 & grade_completed<9)	


save "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", replace



// LASSO-ing
/* Data on black netmigration for southern counties come from Boustan (2016):
south_county.dta. These data were downloaded from the following link: 
https://economics.princeton.edu/dl/Boustan/Chapter4.zip. */
use "$RAWDATA/dcourt/south_county.dta", clear
drop if netbmig==.

/* Instructions for cleaning the data from Boustan (2016) replication files
are prefaced with "Boustan (2016)".

Boustan (2016): This data set includes all of the southern data by county, from 
CCDB and ICPSR Great Plains project.

Boustan (2016): There are 350 or so counties with missing mining or 
manufacturing information in 1950 & 1970. In this case, replace with the 
1960 info. */

sort state countyicp year
replace permin=permin[_n+1] if year==1950 & permin==. & countyicp==countyicp[_n+1]
replace permin=permin[_n-1] if year==1970 & permin==. & countyicp==countyicp[_n-1]
replace perman=perman[_n+1] if year==1950 & perman==. & countyicp==countyicp[_n+1]
replace perman=perman[_n-1] if year==1970 & perman==. & countyicp==countyicp[_n-1]

/* Note that migration data is missing for several counties in Virginia. */

/* Boustan (2016): Interact variables with % cotton and % agriculture. */

replace perten=perten/100
replace perag=perag/100 if year==1950
replace perag=perag/10 if year==1960

/* Boustan (2016): Create dummy for SA (GA, FL, VA, WV, SC, NC) and interact. */

gen satl=(state==12 | state==13 | state==37 | state==45 | state==51 | state==54)
gen pertensa=perten*satl
gen permansa=perman*satl

/* Boustan (2016): Create dummy for tobacco growing states and interact with 
agriculture (NC, KY, TN). */

gen tob=(state==37 | state==21 | state==47)
gen peragtob=perag*tob

/* Boustan (2016): Create dummy for mineral region (OK, TX). */

gen ot=(state==40 | state==48)
gen perminot=permin*ot

/* Save the dataset that will be used for post LASSO */

save "$INTDATA/dcourt/clean_south_county.dta", replace

/* Additional cleaning to prepare the data for R and running LASSO. */
*local final_varlist netbmig perten perag permin perman aaa_pc warfac_pc warcon_pc avesz3 tmpav30 pcpav30 mxsw30s mxsd30s dustbowa summit swamp valley elevmax riv1120 riv2150 riv51up riv0510 elevrang awc clay kffact om perm thick minem35a Astate_5 Astate_12 Astate_13 Astate_21 Astate_22 Astate_28 Astate_37 Astate_40 Astate_45 Astate_47 Astate_48 Astate_51 Astate_54 satl pertensa permansa tob peragtob ot perminot
local final_varlist netbmig percot perten perag peragtob tob warfac_pc permin perminot ot
*perten perag permin perman warfac_pc satl pertensa permansa tob peragtob ot perminot

/* Replace any vars that are still missing with the state-year mean value 
for that var. */
foreach var in `final_varlist'{
mdesc `var'
tab countyfips if `var'==.
*drop if `var'==.
egen mean_`var'=mean(`var'), by(state year)
replace `var'=mean_`var' if `var'==.
}

keep year `final_varlist'

/* Create a separate dataset for each decade. */
preserve
	keep if year==1950
	drop year
	save "$INTDATA/dcourt/south_county_migration_dataset_for_prediction_1950.dta", replace
restore

preserve
	keep if year==1960
	drop year
	save "$INTDATA/dcourt/south_county_migration_dataset_for_prediction_1960.dta", replace
restore

preserve
	keep if year==1970
	drop year
	save "$INTDATA/dcourt/south_county_migration_dataset_for_prediction_1970.dta", replace
restore

clear

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*2. Run lasso on each decade's migration dataset to obtain predictors.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

/* Initiate R and run LASSO using cv glmnet. */

/*
global Rterm_path `"/usr/local/bin/r"'

rsource, terminator(END_OF_R) roptions(--vanilla)

	// 'haven' is an R package for importing Stata '.dta' file
	library(haven)
	library(ggplot2)
	library(dplyr)
	library(tidyr)
	library(data.table)
	library(stargazer)
	library(randomForest)
	library(glmnet)
	library(rpart)
	library(parallel)
	library(stringr)
	
	// 0. Clear all
	rm(list = ls()) 

	// 1. Change to your directory
	setwd("/Users/elloraderenoncourt/Great_Migration_Mobility/code/lasso")
	
	// 2. Set code to run or not
	runLasso = FALSE
	
	if (runLasso) {
	// 3. Load the data, run lasso, get list of selected variables. Repeat for each year (1950, 1960, 1970)
	train = read_dta('south_county_migration_dataset_for_prediction_1950.dta')

	x = model.matrix(~., data=train %>% select(-netbmig))
	y = train$netbmig
	lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
	tmp_coeffs<-coef(lassoPred, s="lambda.min")
	lasso_list_of_vars_1950<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)

write.csv(lasso_list_of_vars_1950[2:dim(lasso_list_of_vars_1950)[1],1:dim(lasso_list_of_vars_1950)[2]], file='lasso_list_of_vars_1950.csv')

	train = read_dta('south_county_migration_dataset_for_prediction_1960.dta')

	x = model.matrix(~., data=train %>% select(-netbmig))
	y = train$netbmig
	lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
	tmp_coeffs<-coef(lassoPred, s="lambda.min")
	lasso_list_of_vars_1960<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)

write.csv(lasso_list_of_vars_1960[2:dim(lasso_list_of_vars_1960)[1],1:dim(lasso_list_of_vars_1960)[2]], file='lasso_list_of_vars_1960.csv')

	train = read_dta('south_county_migration_dataset_for_prediction_1970.dta')

	x = model.matrix(~., data=train %>% select(-netbmig))
	y = train$netbmig
	lassoPred=cv.glmnet(x=x, y=y,alpha=1,nfolds=5,standardize=TRUE)
	tmp_coeffs<-coef(lassoPred, s="lambda.min")
	lasso_list_of_vars_1970<-data.frame(name = tmp_coeffs@Dimnames[[1]][tmp_coeffs@i + 1], coefficient = tmp_coeffs@x)

write.csv(lasso_list_of_vars_1970[2:dim(lasso_list_of_vars_1970)[1],1:dim(lasso_list_of_vars_1970)[2]], file='lasso_list_of_vars_1970.csv')
}
END_OF_R
*/


*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*4. Run Post-LASSO to generate predicted migration figures for each county by decade.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

/* Load full clean data. */

use "$INTDATA/dcourt/clean_south_county.dta", clear

/* Predict county-level net migration rate, decade by decade with southern 
variables chosen by LASSO. Predict net migration rate ("netbmig_pred") based on 
these vars alone. */

reg netbmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1950
predict netbmig_pred if year==1950
reg netbmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1960
predict netbmig_pred01 if year==1960
reg netbmig percot perten perag peragtob tob warfac_pc permin perminot ot if year==1970
predict netbmig_pred02 if year==1970	

replace netbmig_pred=netbmig_pred01 if year==1960
replace netbmig_pred=netbmig_pred02 if year==1970
drop netbmig_pred01 netbmig_pred02

/* Boustan (2016): Total number leaving/coming to county: actual and predicted. Note 
that netbmig is a migration rate (per 100 residents). So, the range is -100 to 
+whatever. -100 because it is impossible for more than all of the residents to 
leave. But, on the positive side, the rate is unrestricted, because the growth 
could be quite high (for a county with 100 blacks in 1940, could have 100,000 
blacks in 1950 which would be a rate of 1000. */ 

gen totbmig=((bpop_l/100)*netbmig)
gen totbmig_pred=((bpop_l/100)*netbmig_pred)
gen weight=netbmig_pred*bpop_l

/* One observation per county, year. */
//drop if year==year[_n-1]

sort countyfips year
drop if countyfips==.
rename totbmig actoutmig
rename totbmig_pred proutmig
label var proutmig "predicted out migration, by county-year, south"
drop _merge

/* Merge with 1940 crosswalks data file. */

/*  Two methods for achieving consistent fips codes between the migration data, historical census data, 
and the crosswalks file created for this project. Using county icp and state icp to match to the 
crosswalk file yields the best results. Then one can merge the data with the migration weights from 
census extract located here: data/shares/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta.

Alternatively, one can use state fip and county icp as used to produce the census 
extract referenced above. The approximate code for this alternative method is below, but may need to be tweaked. 
With either approach, a few counties (4-5) don't match and must be hand checked.

tostring state, gen(southstatefip_str) 
replace southstatefip_str=southstatefip_str+"0"
gen southcounty=countyicp 
replace southcounty=southcounty+20 if countyicp==24 & southcounty!=5100 & southcounty>50 // county ICP codes in the NHGIS file are shifted forward by 2 digits
tostring southcounty, gen(southcountyicp_str)  
replace southcountyicp_str="00"+southcountyicp_str if length(southcountyicp_str)==2 
replace southcountyicp_str="0"+southcountyicp_str if length(southcountyicp_str)==3
replace southcountyicp_str=substr(southcountyicp_str,1,length(southcountyicp_str)-2)+ "10" if countyicp==41 & southcountyicp_str=="0605" // Union county in Oregon is 605 in IPUMS census extract but 610 in NHGIS file
replace southcountyicp_str =substr(southcountyicp_str,1,length(southcountyicp_str)-1)+ "0" if(regexm(southcountyicp_str, "[0-9][0-9][0-9][5]")) // IPUMS Census extract notes county code changes with 0 or 5 but all county codes end in 0 in NHGIS file
replace southcountyicp_str="1860" if southcountyicp_str=="1930" & countyicp==29 // Discrepancy between Missouri county St Genevieve county code in IPUMS Census extract vs. NHGIS file
replace southcountyicp_str="7805" if southcounty==7850 & southstatefip_str=="510" // Possible typo with Greenbrier county coded as 785 instead of 775 in IPUMS Census extract. Reassigned to South Norfolk's code from NHGIS file because both are part of Chesapeake (independent city) today.
replace southcountyicp_str="0050" if southcountyicp_str=="0053" & countyicp==22 // Possible typo with Jefferson Davis county coded as 53 instead of 50 in IPUMS Census extract. Recoded as 50.
gen gisjoin2_str = southstatefip_str + southcountyicp_str
cd "$xwalks"
merge m:1 gisjoin2_str using county1940_crosswalks.dta, keepusing(fips state_name county_name)
*/

/*

Virginia counties for which migration data are missing:
		51520 |          1        5.88        5.88
		51540 |          1        5.88       11.76
		51560 |          1        5.88       17.65
		51590 |          1        5.88       23.53
		51670 |          1        5.88       29.41
		51680 |          1        5.88       35.29
		51690 |          1        5.88       41.18
		51740 |          1        5.88       47.06
		51750 |          1        5.88       52.94
		51760 |          1        5.88       58.82
		51770 |          1        5.88       64.71
		51790 |          1        5.88       70.59
		51800 |          1        5.88       76.47
		51830 |          1        5.88       82.35
		51840 |          1        5.88       88.24

*/

merge m:1 stateicp countyicp using "$XWALKS/county1940_crosswalks.dta", keepusing(fips state_name county_name) keep(1 3)
g origin_fips=fips
rename state_name origin_state_name
rename county_name origin_county_name 

/* Hand correct counties that didn't match using crosswalk file and internet search. */

replace origin_fips = 51067 if countyfips==51620 & _merge==1
replace origin_fips = 48203 if countyfips==48203 & _merge==1
replace origin_fips = 51037 if countyfips==54039 & _merge==1
replace origin_fips = 54041 if countyfips==54041 & _merge==1
replace origin_fips = 51189 if countyfips==189 & _merge==1
drop _merge

tostring origin_fips, replace
keep origin_fips origin_state_name year proutmig actoutmig netbmig_pred 

drop if netbmig_pred==. | proutmig==.

bysort origin_fips year: gen dup= cond(_N==1,0,_n)
tab dup
drop dup

keep origin_fips year proutmig actoutmig netbmig_pred

save "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta", replace

// Instrument creation
foreach destid in dest_fips{
	// Predicted full
	clear all
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id `destid'
	global destination_id_code `destid'_code
	global dest_sample dest_sample
	global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
	global version full
	global weight_types pr
	global weight_var outmig
	global start_year 1940
	global panel_length 3

	use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear

	do "$CODE/helper/bartik_generic.do"

	*10. Clean and standardize city names and output final instrument measures at the city-level	
			
	use "$INTDATA/bartik/full_blackorigin_fips1940.dta", clear
	order black* total*
	egen vfull_totblackmig`destid'3539=rowmean(total_black`destid'*)
	sum vfull_totblackmig`destid'3539

	drop total* black*
	tempfile dest_fips_blackmigshare3539
	save `dest_fips_blackmigshare3539'

	foreach w in pr {
		use "$INTDATA/bartik/full_black_`w'outmigorigin_fips19401970_collapsed_wide.dta", clear
		merge 1:1 `destid' using `dest_fips_blackmigshare3539', keep(3) nogenerate

		save "$INTDATA/dcourt/full_black_`w'mig_1940_1970_wide_xw_`destid'.dta", replace
	}
}

/*

// Predicted ccdb

clear all
	
global groups black // took out white
global origin_id origin_fips
global origin_id_code origin_fips_code
global origin_sample origin_sample
global destination_id dest_fips
global destination_id_code dest_fips_code
global dest_sample ccdb_sample
global weights_data "$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta"
global version ccdb
global weight_types pr act
global weight_var outmig
global start_year 1940
global panel_length 3

use "$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear

do "$CODE/helper/bartik_generic.do"


*10. Clean and standardize city names and output final instrument measures at the city-level	
		
use "$INTDATA/bartik/20_blackorigin_fips1940.dta", clear

order black* total*
egen vccdb_totblackmigdest_fips3539=rowmean(total_blackdest_fips*)
sum vccdb_totblackmigdest_fips3539

drop total* black*
tempfile dest_fips_blackmigshare3539
save `dest_fips_blackmigshare3539'

foreach w in pr act{
	use "$INTDATA/bartik/ccdb_black_`w'outmigorigin_fips19401970_collapsed_wide.dta", clear
	merge 1:1 dest_fips using `dest_fips_blackmigshare3539', keep(3) nogenerate

	save "$INTDATA/dcourt/ccdb_black_`w'mig_1940_1970_wide_xw.dta", replace
}
*/
// CCDB City Populations for 1970

/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

SUMMARY: 
	This do-file cleans/builds city population data data from the City Data Book 1944-1977.
	
STEPS:
	*1. Input raw data and clean/construct variables and save dataset. 
	
*first created: 12/29/2019
*last updated:  12/29/2019
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Input raw data and clean/construct variables to be used in PF and other covariate measures. 
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	
	
/* bpop construction: leaves a lot out
*Import Data
use "$RAWDATA/dcourt/ICPSR_07735_City_Book_1944_1977/DS0001/City_Book_1944_1977.dta", clear

*Standardize State Names
drop if PLACE1=="0000"
destring STATE1, replace
statastates, fips(STATE1)  nogen

*Standardize City Names
g city = proper(AREANAME) 

//A - fix spelling and formatting variations
replace city = stritrim(city)
replace city = subinstr(city, ",Mont", "", 1)
replace city = subinstr(city, "N Mex", "", 1)
replace city = subinstr(city, "W Va", "", 1)
replace city = subinstr(city, ",Nj", "", 1)
replace city = subinstr(city, ",Cal.", "", 1)
replace city = subinstr(city, "Cal.", "", 1)
replace city = subinstr(city, ", Mich", "", 1)
replace city = subinstr(city, "Nc.", "", 1)
replace city = subinstr(city, ", Ga.", "", 1)
replace city = subinstr(city, ", Miss", "", 1)
replace city = subinstr(city, "Pa.", "", 1)
replace city = subinstr(city, ",Tex", "", 1)
replace city = subinstr(city, " 5", "", 1 )

replace city = "Aliquippa" if city == "Aliquippa Pa"
replace city = "Arlington" if city == "Arlington County Va"
replace city = "Arlington" if city == "Arlington Town Mass"
replace city = "Belmont" if city == "Belmont Town Mass"
replace city = "Belvedere" if city == "Belvedere Twp Ca"
replace city = "Brookline" if city == "Brookline Town Mass"
replace city = "Central Falls" if city == "Central Falls Ri"
replace city = "East Bakersfield" if city == "East Bakersfield Cal"
replace city = "Haverford" if city == "Haverford Twp Pa"
replace city = "Lower Merion Twp" if city == "Lower Merion Twp Pa"
replace city = "Hagerstown" if city == "Magerstown" & state_name=="MARYLAND"
replace city = "Nashville" if city == "Nashville-Davidson"
replace city = "North Bergen" if city == "North Bergen Twp Nj"
replace city = "Sharon" if city == "Sharon Pa"
replace city = "Teaneck" if city == "Teaneck Twp Nj"
replace city = "Upper Darby" if city == "Upper Danby Twp Pa"
replace city = "Watertown" if city == "Watertown Town Mass"
replace city = "West Hartford" if city == "West Hartford Town Con"
replace city = "Woodbridge" if city == "Woodbridge Twp Nj"

replace city = "East St. Louis" if city == "East St Louis" 
replace city = "South St. Paul" if city == "South St Paul" 
replace city = "St. Charles" if city == "St Charles" 
replace city = "St. Clair Shores" if city == "St Clair Shores" 
replace city = "St. Cloud" if city == "St Cloud" 
replace city = "St. Joseph" if city == "St Joseph" 
replace city = "St. Louis Park" if city == "St Louis Park" 
replace city = "St. Louis" if city == "St Louis" 
replace city = "St. Paul" if city == "St Paul" 
replace city = "St. Petersburg" if city == "St Petersburg" 
replace city = "San Buenaventura (Ventura)" if city == "Ventura Nsan Buenaventur" 
replace city = "Wauwatosa" if city == "Wauwatusa" 
replace city = "McKeesport" if city == "Mc Keesport" 
replace city = "McAllen" if city == "Mc Allen" 
replace city = "Fond du Lac" if city == "Fond Du Lac" 
replace city = "DeKalb" if city == "De Kalb" 
replace city = "Northglenn" if city == "North Glenn" & state_name == "COLORADO"
replace city = "Milford city (balance)" if city == "Milford" & state_name == "CONNECTICUT"
replace city = "LaGrange" if city == "Lagrange" & state_name == "GEORGIA"
replace city = "Hallandale Beach" if city == "Hallandale" & state_name == "FLORIDA"
replace city = "Eastpointe" if city == "East Detroit" & state_name == "MICHIGAN"
replace city = "Elk Grove Village" if city == "Elk Grove" & state_name == "ILLINOIS"
replace city = "Winona" if city == "Minona" & state_name == "MINNESOTA"
replace city = "Lafayette, IN" if city == "Lafayette, IL"

replace city = city + ", " + state_abbrev
replace city = subinstr(city, " ,", ",", 1)

g city_original=city

//A - fix NYC name to match croswalk
replace city = "New York, NY" if city=="New York City, NY"

//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
//B1 - the following cities overlap with their subsitutes
*replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
replace city = "Haverford College, PA" if city == "Haverford, PA"
replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"
replace city = "Ardmore, PA" if city == "Lower Merion Twp, PA"
replace city = "Drexel Hill, PA" if city == "Upper Darby, PA" 

//B2 - the following cities just share a border with their subsitutes but do not overlap
replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
replace city = "Secaucus, NJ" if city == "North Bergen, NJ" 
replace city = "Bogota, NJ" if city == "Teaneck, NJ" 

//B3 - the following cities do not share a border with their substitutes but are within a few miles
replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
replace city = "Rutherford, NJ" if city == "Nutley, NJ" 
replace city = "Oildale, CA" if city == "East Bakersfield, CA"
	
*drop the last remaining unmatched city, which has no acceptable substitute in crosswalk
drop if city == "Honolulu, HI" 

*manually avoid duplicate names to facilitate merge with crosswalk
sort city STATE1
quietly by city STATE1: gen dup= cond(_N==1,0,_n)
tab dup
drop dup

*Drop individual boroughs of New York City, NY. Place1==2505 is for all of NYC.	
drop if regexm(AREANAME, "NEW YORK CITY")==1 & PLACE1!="2505"
* Drop Orange, TX which for some reason appears twice, but is not in the sample as it is in Texas.
drop if PLACE1 == "3140" | PLACE1 == "3130"



*Create fips
tostring STATE1, replace
g fips_str = STATE1 + PLACE1 // Create county fips identifier for merging with other geographies

* Add vars to this list
local varlist CC0040 CC0041 CC0042 CC0043 CC0044 CC0045 CC0046 CC0048 CC0052 CC0053 CC0230 CC0231 CC0232 CC0233 CC0234 CC0158 CC0159 CC0160 CC0161 CC0162 CC0163 CC0164 CC0165 CC0166 CC0167 CC0168 CC0169 CC0170 CC0171 CC0172 CC0173 CC0174 CC0175 CC0176 CC0177 CC0178 CC0179 CC0180 CC0181 CC0182 CC0183 CC0184 CC0185 CC0186 CC0187 CC0188 CC0189 CC0190 CC0191 CC0192 CC0193 CC0194 CC0195 CC0196 CC0197 CC0198 CC0199 CC0200 CC0201 CC0202 CC0203 CC0204 CC0205 CC0206 CC0207 CC0208 CC0209 CC0210 CC0211 CC0212 CC0213 CC0214 CC0215 CC0216 CC0217 CC0218 CC0219 CC0220 CC0221 CC0222 CC0223 CC0224 CC0225 CC0226 CC0227 CC0228 CC0229 CC0006 CC0007 CC0008 CC0009 CC0010 CC0011 CC0055 CC0056 CC0566 CC0567 CC0568 CC0569 CC0570 CC0571 CC0572 CC0573 CC0574 CC0575 CC0576 CC0577 CC0578 CC0579 CC0580 CC0581 CC0582 CC0583 CC0584 CC0585 CC0401 CC0402 CC0403 CC0404 CC0405 CC0406 CC0407 CC0408 CC0409 CC0410 CC0411 CC0412 CC0413 CC0414 CC0415 CC0416 CC0417 CC0418 CC0419 CC0420 CC0421 CC0422 CC0423 CC0424 CC0425 CC0426 CC0427 CC0428 CC0429 CC0430 CC0431 CC0432 CC0433 CC0434 CC0435 CC0436 CC0437 CC0438 CC0439 CC0440 CC0441 CC0442 CC0443 CC0444 CC0445 CC0446 CC0447 CC0448 CC0449 CC0450 CC0451 CC0452 CC0453 CC0454 CC0455 CC0456 CC0457 CC0458 CC0459 CC0460 CC0461 CC0462 CC0463 CC0464 CC0465 CC0466 CC0467 CC0468 CC0469 CC0470 CC0471 CC0472 CC0473 CC0474 CC0475 CC0476 CC0477 CC0478 CC0479 CC0480 CC0481 CC0482 CC0483 CC0484 CC0485 CC0486 CC0487 CC0488 CC0489 CC0490 CC0491 CC0492 CC0493 CC0494 CC0495 CC0496 CC0497 CC0498 CC0499 CC0500 CC0501 CC0502 CC0503 CC0504 CC0505 CC0506 CC0507 CC0508 CC0509 CC0510 CC0511 CC0512 CC0513 CC0514 CC0515 CC0516 CC0517 CC0518 CC0519 CC0520 CC0521 CC0522 CC0523 CC0524 CC0525 CC0526 CC0527 CC0528 CC0529 CC0530 CC0531 CC0120 CC0121 CC0122 CC0123 CC0124 CC0125 CC0126 CC0127 CC0128 CC0129 CC0130 CC0131 CC0132 CC0133 CC0134 CC0135 CC0136 CC0137 CC0138 CC0139 CC0140 CC0141 CC0142 CC0143 CC0144 CC0145 CC0146 CC0147 CC0148 CC0149 CC0150 CC0151 CC0152 CC0153 CC0154 CC0155 CC0156 CC0157 CC0054 CC0055 CC0056 CC0057 CC0058 CC0059 CC0060 CC0061 CC0062 CC0063   

* Replace values as missing if identified as missing according to the Codebook. Check that this is the right approach to dealing with the missing values.
foreach var in `varlist'{
replace `var'=. if (`var'F=="1"|`var'F=="2"|`var'F=="3"|`var'F=="6"|`var'F=="7")
}
	
**********************
**** DEMOGRAPHICS ****
**********************

*TOTAL POPULATION

g popc1970 = CC0010
g bpopc1970 = (CC0046/100)*popc1970

			
*********************
**Prepare for merge**
*********************	
*Drop unneccesary vars 
drop RECNUM* STATE* PLACE* CC* AREA*  // Drop unnecessary vars
	

tempfile popc1970
save `popc1970'

use "$RAWDATA/census/usa_00040.dta", clear

g bpopc1940 = (race==2)
g popc1940 = 1


rename city citycode
decode citycode, gen(city)

*Standardize City Names
//A - fix spelling and formatting variations
split city, p(,) g(part)
replace city = proper(part1) + "," + upper(part2) 
drop part1 part2

g city_original=city

replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
replace city = "Norristown, PA" if city == "Norristown Borough, PA"
replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
replace city = "Jamestown, NY" if city == "Jamestown , NY"
replace city = "Kensington, PA" if city == "Kensington,"
replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
replace city = "DuBois, PA" if city == "Du Bois, PA"
replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
replace city = "McKeesport, PA" if city == "Mckeesport, PA"
replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
replace city = "Lafayette, IN" if city == "La Fayette, IN"
replace city = "Schenectady, NY" if city == "Schenectedy, NY"
replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
replace city = "New Kensington, PA" if city == "Kensington, PA"
replace city = "Lafayette, IN" if city == "Lafayette, IL"

//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
//B1 - the following cities overlap with their subsitutes
*	replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"

//B2 - the following cities just share a border with their subsitutes but do not overlap
replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
replace city = "Bogota, NJ" if city == "Teaneck, NJ" 

//B3 - the following cities do not share a border with their substitutes but are within a few miles
replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
replace city = "Wallington, NJ" if city == "Nutley, NJ" 
replace city = "Short Hills, NJ" if city == "South Orange, NJ"

// New york new jersey
replace city = "New York, NJ" if city == "New York, NY" & statefip==34

collapse (sum) popc1940 bpopc1940, by(city)

tempfile popc1940
save `popc1940'


foreach d in 1950 1960{
	use "$data/new_data/usa_00020.dta", clear

	keep if year == `d'
	
	rename perwt popc`d'
	g bpopc`d' = popc`d' if race == 2
	drop if city==0

	rename city citycode
	decode citycode, gen(city)

	*Standardize City Names
	//A - fix spelling and formatting variations
	split city, p(,) g(part)
	replace city = proper(part1) + "," + upper(part2) 
	drop part1 part2

	g city_original=city

	replace city = "St. Joseph, MO" if city == "Saint Joseph, MO" 
	replace city = "St. Louis, MO" if city == "Saint Louis, MO" 
	replace city = "St. Paul, MN" if city == "Saint Paul, MN" 
	replace city = "McKeesport, PA" if city == "Mckeesport, PA" 
	replace city = "Norristown, PA" if city == "Norristown Borough, PA"
	replace city = "Shenandoah, PA" if city == "Shenandoah Borough, PA"
	replace city = "Jamestown, NY" if city == "Jamestown , NY"
	replace city = "Kensington, PA" if city == "Kensington,"
	replace city = "Oak Park Village, IL" if city == "Oak Park Village,"
	replace city = "Fond du Lac, WI" if city == "Fond Du Lac, WI"
	replace city = "DuBois, PA" if city == "Du Bois, PA"
	replace city = "McKees Rocks, PA" if city == "Mckees Rocks, PA"
	replace city = "McKeesport, PA" if city == "Mckeesport, PA"
	replace city = "Hamtramck, MI" if city == "Hamtramck Village, MI"
	replace city = "Lafayette, IN" if city == "La Fayette, IN"
	replace city = "Schenectady, NY" if city == "Schenectedy, NY"
	replace city = "Wallingford Center, CT" if city == "Wallingford, CT"
	replace city = "Oak Park, IL" if city == "Oak Park Village, IL"
	replace city = "New Kensington, PA" if city == "Kensington, PA"
	replace city = "Lafayette, IN" if city == "Lafayette, IL"

	//B - Replace city names with substitutes in the crosswalk when perfect match with crosswalk impossible
	//B1 - the following cities overlap with their subsitutes
	*	replace city = "Silver Lake, NJ" if city == "Belleville, NJ"
	replace city = "Brookdale, NJ" if city == "Bloomfield, NJ" 
	replace city = "Upper Montclair, NJ" if city == "Montclair, NJ"

	//B2 - the following cities just share a border with their subsitutes but do not overlap
	replace city = "Glen Ridge, NJ" if city == "Orange, NJ"
	replace city = "Essex Fells, NJ" if city == "West Orange, NJ" 
	replace city = "Bogota, NJ" if city == "Teaneck, NJ" 

	//B3 - the following cities do not share a border with their substitutes but are within a few miles
	replace city = "Kenilworth, NJ" if city == "Irvington, NJ"  
	replace city = "Wallington, NJ" if city == "Nutley, NJ" 
	replace city = "Short Hills, NJ" if city == "South Orange, NJ"

	// New york new jersey
	replace city = "New York, NJ" if city == "New York, NY" & statefip==34

	

	collapse (sum) popc`d' bpopc`d', by(city)
	
	tempfile popc`d'
	save `popc`d''
}

use `popc1940', clear
merge 1:1 city using `popc1950'
ren _merge merge_1950
merge 1:1 city using `popc1960'
ren _merge merge_1960

merge 1:1 city using `popc1970'
ren _merge merge_1970


*Merge with State Crosswalks
	merge m:1 city using "$xwalks/US_place_point_2010_crosswalks.dta", keepusing(countyfip state_fips) keep(1 3) nogen
	replace countyfip = "013" if city == "Belleville, NJ"
	replace state_fips = 34 if city == "Belleville, NJ"
*/

// New bpop construction: Using all county data, keeping only sample
/*
gz7, filepath("$RAWDATA/census") filename("usa_00042.dta.gz")
keep if year == 1940
drop statefip
merge m:1 stateicp countyicp using "$XWALKS/county1940_crosswalks", keepusing(statefip countyfip) 

g pop = perwt
g bpop = perwt if race == 2

replace bpop = 0 if race!=2

collapse (sum) pop bpop, by(year statefip countyfip)
destring statefip, replace
preserve
	use "$RAWDATA/dcourt/ICPSR_07735_City_Book_1944_1977/DS0001/City_Book_1944_1977.dta", clear

	*Standardize State Names
	drop if PLACE1=="0000"
	destring STATE1, replace
	statastates, fips(STATE1)  nogen

	cityfix_ccdb

	
	merge 1:1 city using "$xwalks/US_place_point_2010_crosswalks.dta", keepusing(countyfip state_fips) keep(1 3) nogen
	replace countyfip = "013" if city == "Belleville, NJ"
	replace state_fips = 34 if city == "Belleville, NJ"
	keep countyfip state_fips
	ren state_fips statefip
	duplicates drop
	tempfile urbanized_counties
	save `urbanized_counties'
restore

merge m:1 statefip countyfip using `urbanized_counties', keep(3) nogen

reshape wide pop bpop, i(statefip countyfip) j(year)

tempfile c1940 
save `c1940'

gz7, filepath("$RAWDATA/census") filename("usa_00044.dta.gz")

g pop = perwt
g bpop = perwt if race == 2

replace bpop = 0 if race!=2

collapse (sum) pop bpop, by(year statefip countyfip)
cap destring statefip, replace
tostring countyfip, gen(countyfip_str)
replace countyfip_str = "00" + countyfip_str if countyfip<10
replace countyfip_str = "0" + countyfip_str if countyfip>=10 & countyfip <100
drop countyfip
ren countyfip_str countyfip

merge m:1 statefip countyfip using `urbanized_counties', keep(3) nogen

reshape wide pop bpop, i(statefip countyfip) j(year)

merge 1:1 statefip countyfip using `c1940', keep(3) nogen

g fips = 1000*statefip + real(countyfip)
drop if fips ==.
count if bpop1940 ==. | bpop1950 ==. | bpop1960 ==. | bpop1970 ==. | ///
					pop1940 ==. | pop1950 ==. | pop1960 ==. | pop1970 ==.
					*/
					
// New bpop construction 2: using nhgis totals

import delimited using "$RAWDATA/census/nhgis0019_csv/nhgis0019_ds77_1940_county.csv", clear
drop if statea == 155 | statea == 25 // drop  hawaii, alaksa territory

egen pop = rowtotal(bv*) 
egen bpop = rowtotal(bv2003 bv2004)

keep year statea countya pop bpop

tempfile n1940
save `n1940'

import delimited using "$RAWDATA/census/nhgis0019_csv/nhgis0019_ds84_1950_county.csv", clear
drop if statea == 155 | statea == 25 // drop  hawaii, alaksa territory
drop if countya == 8999 // Virgina Independent Cities

egen pop = rowtotal(b3p*) 
egen bpop = rowtotal(b3p003 b3p007)

keep year statea countya pop bpop

tempfile n1950
save `n1950'

import delimited using "$RAWDATA/census/nhgis0019_csv/nhgis0019_ds91_1960_county.csv", clear
drop if statea == 155 | statea == 25 // drop  hawaii, alaksa territory

egen pop = rowtotal(b5s*) 
egen bpop = rowtotal(b5s002 b5s009)

keep year statea countya pop bpop

tempfile n1960
save `n1960'

import delimited using "$RAWDATA/census/nhgis0019_csv/nhgis0019_ds94_1970_county.csv", clear
drop if statea == 2 | statea == 15 // drop alaska hawaii

replace statea = statea*10
replace countya = countya*10

egen pop = rowtotal(cbw*) 
g bpop = cbw002

keep year statea countya pop bpop

tempfile n1970
save `n1970'

clear 

forv d=1940(10)1970{
	append using `n`d''
}

ren statea nhgisst
ren countya nhgiscty

merge 1:m year nhgisst nhgiscty using "$XWALKS/consistent_1940_1970", keep(3) nogen
replace pop = pop*weight
replace bpop = bpop*weight

collapse (sum) pop bpop, by(year nhgisst_1990 nhgiscty_1990)
ren nhgisst_1990 statefip
ren nhgiscty_1990 countyfip

g cty_fips = statefip*100+countyfip/10

merge m:1 cty_fips using "$XWALKS/cw_cty_czone", assert(3) nogen
ren cty_fips fips
ren czone cz
/*
ren statefip state_fips
merge m:1 state_fips countyfip using "$xwalks/US_place_point_2010_crosswalks.dta", keepusing(city) keep(1 3) nogen
ren state_fips statefip 

*/

reshape wide pop bpop, i(fips) j(year)

drop if bpop1940 ==. | bpop1950 ==. | bpop1960 ==. | bpop1970 ==. | ///
					pop1940 ==. | pop1950 ==. | pop1960 ==. | pop1970 ==.

keep if pop1940 >=25000 | pop1970>=25000

// Dropping southern sample
drop if statefip == 10 | ///
				statefip == 50 | ///					
				statefip == 120 | ///
				statefip == 130 | ///
				statefip == 210 | ///
				statefip == 220 | ///
				statefip == 280 | ///
				statefip == 370 | ///
				statefip == 400 | ///
				statefip == 450 | ///
				statefip == 470 | ///
				statefip == 480 | ///
				statefip == 510 | ///
				statefip == 540


save "$INTDATA/dcourt/nhgis_county_pops", replace

foreach level in county cz{
	if "`level'"=="cz"{
			local levelvar cz
			local levellab "CZ"
			
		}
		else if "`level'"=="county"{
			local levelvar fips
			local levellab "County"

		}
		else if "`level'"=="msa"{
			local levelvar msapmsa2000
			local levellab "MSA"
		}
	

	use "$INTDATA/dcourt/nhgis_county_pops", clear
	ren fips dest_fips

	merge 1:1 dest_fips using "$INTDATA/dcourt/full_black_prmig_1940_1970_wide_xw_dest_fips.dta", keep(1 3)
	
	g full_sample = _merge == 3
	drop _merge

	foreach var of varlist black_proutmigpr*{
		replace `var' = 0 if `var'==.
		ren `var' vfull_`var'
	}
	
	ren dest_fips fips
	collapse (sum) pop* bpop* vfull_*, by(`levelvar')

	local base = 1940
	foreach d in 1950 1960 1970{
		* Actual black pop change in city
		g bpopchange`base'_`d'=100*(bpop`d'-bpop`base')/pop`base'
		g bpopchangepp`base'_`d'=100*((bpop`d'/pop`d')-(bpop`base'/pop`base'))

		foreach v in full {
			g v`v'_bpopchange`base'_`d'=100*v`v'_black_proutmigpr`d'/pop`base'
			g v`v'_blackmig3539_share`base'=100*v`v'_totblackmigdest_fips3539/pop`base'
			
			g v`v'_bpopchangepp`base'_`d'=100*((v`v'_black_proutmigpr`d'+bpop`base')/(v`v'_black_proutmigpr`d'+ pop`base') - bpop`base'/pop`base')

		}
		local base = `d'
	}

	// mfg lfshare controls
	merge 1:1 `levelvar' using "$INTDATA/dcourt/clean_`level'_industry_employment_1940_1970.dta", keepusing(mfg_lfshare*) keep(3) nogen 

	if "`level'" == "county"{
		// Region dummies
		preserve 
			use "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", clear
			keep state_id region
			duplicates drop
			tempfile regions
			save `regions'
		restore 
		g state_id = floor(fips/1000)
		merge m:1 state_id using `regions', keep(1 3) nogen
		drop state_id

	}
	else{
		merge 1:1 cz using "$RAWDATA/dcourt/cz_state_region_crosswalk.dta", keep(3) nogen
	}
	tabulate region, gen(reg)	

	/* Rank measures
	local base = 1940
	foreach d in 1950 1960 1970{
		xtile GM_`base'_`d' = bpopchange`base'_`d', nq(100) 
		xtile GM_hat_`base'_`d' = vfull_bpopchange`base'_`d', nq(100) 
				
		local base = `d'
	}
*/
	la var vfull_blackmig3539_share1940 "Black Southern Mig 1935-1940"
	la var reg2 "Midwest"
	la var reg3 "South"
	la var reg4 "West"	

	local base = 1940
	foreach d in 1950 1960 1970{
		ren bpopchange`base'_`d' GM_raw_`base'_`d'
		ren bpopchangepp`base'_`d' GM_raw_pp_`base'_`d'
		ren vfull_bpopchangepp`base'_`d' GM_hat_raw_pp_`base'_`d'

		ren vfull_bpopchange`base'_`d' GM_hat_raw_`base'_`d'
		local base = `d'
	}

	// Creating 1940-70 variables
	g GM_raw = 100*(bpop1970 - bpop1940)/pop1940
	g GM_raw_pp=100*((bpop1970/pop1970)-(bpop1940/pop1940))

	foreach v in full {
		g GM_hat_raw=100*v`v'_black_proutmigpr1970/pop1940
		g v`v'_blackmig3539_share=100*v`v'_totblackmigdest_fips3539/pop1940
		
		g GM_hat_raw_pp=100*((v`v'_black_proutmigpr1970+bpop1940)/(v`v'_black_proutmigpr1970+ pop1940) - bpop1940/pop1940)
	}
	save "$CLEANDATA/dcourt/GM_`level'_final_dataset_split", replace

}
