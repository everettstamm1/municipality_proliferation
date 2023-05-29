use "$CLEANDATA/cz_pooled.dta", clear
keep cz *popc*
drop v*
ren *popc* *popc_pooled* 
tempfile x
save `x'
// Stacked tables
use "$CLEANDATA/cz_stacked_full.dta", clear
keep cz *popc* decade

merge m:1 cz using `x', update keep(3)
sort cz decade
keep if decade==1940
g x = popc == popc_pooled1940
keep if _merge==1 ^ GM_hat2_raw_ppc<.
keep cz cz_name 
duplicates drop
list cz cz_name
cz	decade	bpopc	popc	popc_pooled1940
20500	1940		2120489	2096421
15100	1940		94216	69258
20800	1940		270300	245442
15000	1940		157581	135161
37800	1940		1139528	1061514
23500	1940		83061	59665
15200	1940		1392135	1288789
18100	1940		64935	45164
18000	1940		1028485	980025
19400	1940		7808537	7770913
29502	1940		537796	521706
38300	1940		2199435	2159599
38901	1940		51878	31003
22400	1940		65216	40752
19600	1940		1982601	1942957
11600	1940		2114313	2076530
37500	1940		85491	68656
39400	1940		524220	509073
24900	1940		54385	31351
38801	1940		325171	306321


use $city_sample/GM_city_final_dataset.dta , clear
keep if cz==15100
keep city 
tempfile x
save `x'

use $city_sample/GM_city_final_dataset_split.dta , clear
keep if cz==15100
merge 1:1 city using `x'

use "$CLEANDATA/cz_pooled.dta", clear
keep if inlist(cz_name,"San Jose, CA", ///
												"San Francisco, CA", ///
												"Phoenix, AZ", ///
												"Los Angeles, CA") | ///
							inlist(cz_name,	"Eugene, OR", ///
												"Madison, WI", ///
												"Chicago, IL", ///
												"Cleveland, OH", ///
												"Cedar Rapids, IA", ///
												"Gary, IN")
												
graph bar GM_raw_pp, over(cz_name, lab(angle(45))) ytitle("GM_raw_pp") title("1940-70 Percentage Point Change Black Population by CZ")

graph export "$FIGS/simplefigs/gm_raw_pp_barchart.pdf", as(pdf) replace

use "$CLEANDATA/cz_stacked_full.dta", clear
sort decade
drop if decade>1980
twoway (connected b_cgoodman_cz_L0 decade if cz_name =="San Jose, CA") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="San Francisco, CA") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Phoenix, AZ") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Los Angeles, CA") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Eugene, OR") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Madison, WI") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Chicago, IL") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Cleveland, OH") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Cedar Rapids, IA") ///
												(connected b_cgoodman_cz_L0 decade if cz_name =="Gary, IN"), ///
												legend(order(1 "San Jose, CA" ///
												2 "San Francisco, CA" ///
												3 "Phoenix, AZ" ///
												4 "Los Angeles, CA"  ///
												5 "Eugene, OR" ///
												6 "Madison, WI" ///
												7 "Chicago, IL" ///
												8 "Cleveland, OH" ///
												9 "Cedar Rapids, IA" ///
												10 "Gary, IN")) ///
												title("1900-1980 Number of Municipalities by CZ")
												
graph export "$FIGS/simplefigs/b_cgoodman_linegraph.pdf", as(pdf) replace


use "$CLEANDATA/cz_stacked_full.dta", clear
g urban_population = popc
replace urban_population = pop_urban if popc==.
g b_cgoodman_cz_L0_urb = b_cgoodman_cz_L0 /(urban_population/10000)
sort decade
drop if decade>1970
twoway (connected b_cgoodman_cz_L0_urb decade if cz_name =="San Jose, CA") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="San Francisco, CA") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Phoenix, AZ") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Los Angeles, CA") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Eugene, OR") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Madison, WI") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Chicago, IL") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Cleveland, OH") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Cedar Rapids, IA") ///
												(connected b_cgoodman_cz_L0_urb decade if cz_name =="Gary, IN"), ///
												legend(order(1 "San Jose, CA" ///
												2 "San Francisco, CA" ///
												3 "Phoenix, AZ" ///
												4 "Los Angeles, CA"  ///
												5 "Eugene, OR" ///
												6 "Madison, WI" ///
												7 "Chicago, IL" ///
												8 "Cleveland, OH" ///
												9 "Cedar Rapids, IA" ///
												10 "Gary, IN")) ///
												title("1900-1980 Number of Municipalities Per 10,000 by CZ")
												
												
graph export "$FIGS/simplefigs/b_cgoodman_linegraph_pc.pdf", as(pdf) replace

replace urban_population = log(urban_population)
twoway (connected urban_population decade if cz_name =="San Jose, CA") ///
												(connected urban_population decade if cz_name =="San Francisco, CA") ///
												(connected urban_population decade if cz_name =="Phoenix, AZ") ///
												(connected urban_population decade if cz_name =="Los Angeles, CA") ///
												(connected urban_population decade if cz_name =="Eugene, OR") ///
												(connected urban_population decade if cz_name =="Madison, WI") ///
												(connected urban_population decade if cz_name =="Chicago, IL") ///
												(connected urban_population decade if cz_name =="Cleveland, OH") ///
												(connected urban_population decade if cz_name =="Cedar Rapids, IA") ///
												(connected urban_population decade if cz_name =="Gary, IN"), ///
												legend(order(1 "San Jose, CA" ///
												2 "San Francisco, CA" ///
												3 "Phoenix, AZ" ///
												4 "Los Angeles, CA"  ///
												5 "Eugene, OR" ///
												6 "Madison, WI" ///
												7 "Chicago, IL" ///
												8 "Cleveland, OH" ///
												9 "Cedar Rapids, IA" ///
												10 "Gary, IN")) ///
												title("1900-1980 Log Urban Population by CZ")
												
												
graph export "$FIGS/simplefigs/urbpop_linegraph.pdf", as(pdf) replace