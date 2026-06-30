/**************************************************************************
 |                                                                         
 |                    STATA SETUP FILE FOR ICPSR 07735
 |         COUNTY AND CITY DATA BOOK [UNITED STATES] CONSOLIDATED
 |                       FILE: CITY DATA, 1944-1977
 |
 |
 | NOTE: This setup file was produced solely from the study documentation,
 | independent of the data.
 |
 |  Please edit this file as instructed below.
 |  To execute, start Stata, change to the directory containing:
 |       - this do file
 |       - the ASCII data file
 |       - the dictionary file
 |
 |  Then execute the do file (e.g., do 07735-0001-statasetup.do)
 |
 **************************************************************************/

set mem 20m  /* Allocating 20 megabyte(s) of RAM for Stata SE to read the
                 data file into memory. */


set more off  /* This prevents the Stata output viewer from pausing the
                 process */

/****************************************************

Section 1: File Specifications
   This section assigns local macros to the necessary files.
   Please edit:
        "data-filename" ==> The name of data file downloaded from ICPSR
        "dictionary-filename" ==> The name of the dictionary file downloaded.
        "stata-datafile" ==> The name you wish to call your Stata data file.

   Note:  We assume that the raw data, dictionary, and setup (this do file) all
          reside in the same directory (or folder).  If that is not the case
          you will need to include paths as well as filenames in the macros.

********************************************************/

local raw_data "$RAWDATA/dcourt/ICPSR_07735_City_Book_1944_1977/DS0001/07735-0001-Data.txt"
local dict "$RAWDATA/dcourt/ICPSR_07735_City_Book_1944_1977/DS0001/07735-0001-Setup.dct"
local outfile "$INTDATA/dcourt//City_Book_1944_1977.dta"

/********************************************************

Section 2: Infile Command

This section reads the raw data into Stata format.  If Section 1 was defined
properly, there should be no reason to modify this section.  These macros
should inflate automatically.

**********************************************************/

infile using "`dict'", using ("`raw_data'") clear


/*********************************************************

Section 3: Value Label Definitions
This section defines labels for the individual values of each variable.
We suggest that users do not modify this section.

**********************************************************/


label data "County and City Data Book [United States] Consolidated File:  City Data, 1944-1977"

#delimit ;
label define CC0061    01 "AUSTRIA" 02 "CANADA" 03 "CHINA" 04 "CUBA"
                       05 "CZECHOSLOVAKIA" 06 "DENMARK" 07 "FINLAND"
                       08 "FRANCE" 09 "GERMANY" 10 "GREECE" 11 "HUNGARY"
                       12 "IRELAND" 13 "ITALY" 14 "JAPAN" 15 "LITHUANIA"
                       16 "MEXICO" 17 "NETHERLANDS" 18 "NORWAY"
                       19 "PHILIPPINES" 20 "POLAND" 21 "PORTUGAL"
                       22 "ROMANIA" 23 "SWEDEN" 24 "SWITZERLAND"
                       25 "UNITED KINGDOM" 26 "USSR" 27 "YUGOSLAVIA" ;
label define CC0062    01 "AUSTRIA" 02 "CANADA" 03 "CHINA" 04 "CUBA"
                       05 "CZECHOSLOVAKIA" 06 "DENMARK" 07 "FINLAND"
                       08 "FRANCE" 09 "GERMANY" 10 "GREECE" 11 "HUNGARY"
                       12 "IRELAND" 13 "ITALY" 14 "JAPAN" 15 "LITHUANIA"
                       16 "MEXICO" 17 "NETHERLANDS" 18 "NORWAY"
                       19 "PHILIPPINES" 20 "POLAND" 21 "PORTUGAL"
                       22 "ROMANIA" 23 "SWEDEN" 24 "SWITZERLAND"
                       25 "UNITED KINGDOM" 26 "USSR" 27 "YUGOSLAVIA" ;
label define CC0399    1 "COUNCIL MANAGER" 2 "COMMISSION" 3 "MAYOR COUNCIL"
                       4 "REPRESENTATIVE TOWN MEETING" 5 "TOWN MEETING" ;


#delimit cr

/********************************************************************

 Section 4: Save Outfile

  This section saves out a Stata system format file.  There is no reason to
  modify it if the macros in Section 1 were specified correctly.

*********************************************************************/

save `outfile', replace


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
	


*Standardize State Names
drop if PLACE1=="0000"
destring STATE1, replace
rename STATE1 state_fips
merge m:1 state_fips using "$RAWDATA/other/statastates"
drop _merge
rename state_fips STATE1

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

*Merge with City Crosswalk
merge 1:1 city using "$RAWDATA/dcourt/US_place_point_2010_crosswalks.dta", keepusing(cz cz_name)
replace cz = 19600 if city=="Belleville, NJ"
replace cz_name = "Newark, NJ" if city=="Belleville, NJ"
*Resolve Unmerged Cities
tab _merge

*Save
drop if _merge==2 & city != "Belleville, NJ"
drop _merge

*Create fips
tostring STATE1, replace
g fips_str = STATE1 + PLACE1 // Create county fips identifier for merging with other geographies

* Add vars to this list
local varlist CC0001 CC0002 CC0003 CC0004 CC0005 CC0040 CC0041 CC0042 CC0043 CC0044 CC0045 CC0046 CC0048 CC0052 CC0053 CC0230 CC0231 CC0232 CC0233 CC0234 CC0158 CC0159 CC0160 CC0161 CC0162 CC0163 CC0164 CC0165 CC0166 CC0167 CC0168 CC0169 CC0170 CC0171 CC0172 CC0173 CC0174 CC0175 CC0176 CC0177 CC0178 CC0179 CC0180 CC0181 CC0182 CC0183 CC0184 CC0185 CC0186 CC0187 CC0188 CC0189 CC0190 CC0191 CC0192 CC0193 CC0194 CC0195 CC0196 CC0197 CC0198 CC0199 CC0200 CC0201 CC0202 CC0203 CC0204 CC0205 CC0206 CC0207 CC0208 CC0209 CC0210 CC0211 CC0212 CC0213 CC0214 CC0215 CC0216 CC0217 CC0218 CC0219 CC0220 CC0221 CC0222 CC0223 CC0224 CC0225 CC0226 CC0227 CC0228 CC0229 CC0006 CC0007 CC0008 CC0009 CC0010 CC0011 CC0055 CC0056 CC0566 CC0567 CC0568 CC0569 CC0570 CC0571 CC0572 CC0573 CC0574 CC0575 CC0576 CC0577 CC0578 CC0579 CC0580 CC0581 CC0582 CC0583 CC0584 CC0585 CC0401 CC0402 CC0403 CC0404 CC0405 CC0406 CC0407 CC0408 CC0409 CC0410 CC0411 CC0412 CC0413 CC0414 CC0415 CC0416 CC0417 CC0418 CC0419 CC0420 CC0421 CC0422 CC0423 CC0424 CC0425 CC0426 CC0427 CC0428 CC0429 CC0430 CC0431 CC0432 CC0433 CC0434 CC0435 CC0436 CC0437 CC0438 CC0439 CC0440 CC0441 CC0442 CC0443 CC0444 CC0445 CC0446 CC0447 CC0448 CC0449 CC0450 CC0451 CC0452 CC0453 CC0454 CC0455 CC0456 CC0457 CC0458 CC0459 CC0460 CC0461 CC0462 CC0463 CC0464 CC0465 CC0466 CC0467 CC0468 CC0469 CC0470 CC0471 CC0472 CC0473 CC0474 CC0475 CC0476 CC0477 CC0478 CC0479 CC0480 CC0481 CC0482 CC0483 CC0484 CC0485 CC0486 CC0487 CC0488 CC0489 CC0490 CC0491 CC0492 CC0493 CC0494 CC0495 CC0496 CC0497 CC0498 CC0499 CC0500 CC0501 CC0502 CC0503 CC0504 CC0505 CC0506 CC0507 CC0508 CC0509 CC0510 CC0511 CC0512 CC0513 CC0514 CC0515 CC0516 CC0517 CC0518 CC0519 CC0520 CC0521 CC0522 CC0523 CC0524 CC0525 CC0526 CC0527 CC0528 CC0529 CC0530 CC0531 CC0120 CC0121 CC0122 CC0123 CC0124 CC0125 CC0126 CC0127 CC0128 CC0129 CC0130 CC0131 CC0132 CC0133 CC0134 CC0135 CC0136 CC0137 CC0138 CC0139 CC0140 CC0141 CC0142 CC0143 CC0144 CC0145 CC0146 CC0147 CC0148 CC0149 CC0150 CC0151 CC0152 CC0153 CC0154 CC0155 CC0156 CC0157 CC0054 CC0055 CC0056 CC0057 CC0058 CC0059 CC0060 CC0061 CC0062 CC0063   

* Replace values as missing if identified as missing according to the Codebook. Check that this is the right approach to dealing with the missing values.
foreach var in `varlist'{
replace `var'=. if (`var'F=="1"|`var'F=="2"|`var'F=="3"|`var'F=="6"|`var'F=="7")
}
	
**********************
**** DEMOGRAPHICS ****
**********************

*TOTAL POPULATION
g pop1930 = CC0006
g pop1940 = CC0007
g pop1950 = CC0008
g pop1960 = CC0009
g pop1970 = CC0010
g pop1975 = CC0011

*POPULATION BY RACE
g whtpop1940 = (CC0040/100)*pop1940
g whtpop1970 = (CC0041/100)*pop1970

g nwhtpop1940 = CC0042
g nwhtpop1950 = (CC0043/100)*pop1950
g nwhtpop1960 = (CC0044/100)*pop1960
g nwhtpop1970 = pop1970 - whtpop1970

g whtpop1950 = pop1950 - nwhtpop1950
g whtpop1960 = pop1960 - nwhtpop1960 

g bpop1960 = (CC0045/100)*pop1960
g bpop1970 = (CC0046/100)*pop1970
g bpopchange_1960_1970 = bpop1970 - bpop1960 //easier to recover raw figure this way than by using CC0047
	
*POPULATION BY SEX
g fpop1970 = (CC0048/100)*pop1970
g fpop1940 = pop1940 - CC0049
			
			
*Land Areas

ren CC0001 land_area1940
ren CC0002 land_area1950 
ren CC0003 land_area1960
ren CC0004 land_area1970
ren CC0005 land_area1975

*Migration

ren CC0066 pct_same_house1970
*********************
**Prepare for merge**
*********************	
*Drop unneccesary vars 
drop RECNUM* CC* AREA*  // Drop unnecessary vars
	
save "$RAWDATA/dcourt/clean_city_population_ccdb_1944_1977.dta", replace

