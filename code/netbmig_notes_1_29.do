fips_str	fips	year	whitemig	nonwhitemig
01001	1001	1950	-1399	-4050
01001	1001	1960	-143	-2567 -2710
01001	1001	1970	5228	-2351 2877

year	bpop_l	netbmig	totpop	totpop30
1950	11194	-36.18	20977	19694
1960	8363	-24.5	18186	
1970	7900	-25.3	18739	


\Chapter4\C
> hapter 4\figure_4.1&4.2+table4.2\Instrument\south_county.dta" 

use "$RAWDATA/boustan/Chapter4/Chapter 4/figure_4.1&4.2+table4.2/Instrument/south_county.dta", clear

cf _all using "$RAWDATA/dcourt/south_county.dta", verbose
import delimited using "$RAWDATA/boustan/Chapter4/Chapter 4/data/1940_raw_NHGIS/nhgis0026_ds76_1940_tract.csv", clear

use "$RAWDATA/dcourt/ICPSR_07736_County_Book_1947_1977/DS0001/County_book_1947_1977.dta", clear
g bpop1970 = (CC00056/100)*CC00015
g bpop1960 = (CC00055/100)*CC00014
g nwpop1960 = (CC00054/100)*CC00014

g nwpop1950 = (CC00053/100)*CC00013

keep if _n==2

