
import delimited using "$RAWDATA/census/nhgis0048_csv/nhgis0048_csv/nhgis0048_ds107_1980_county.csv", clear

replace gisjoin = "G3200250" if gisjoin == "G3205100"
merge 1:1 gisjoin using  "$RAWDATA/dcourt/county1940_crosswalks", keepusing(cz) keep(3) nogen

g mfg = dia003 + dia004
egen lforce = rowtotal(dia*)

collapse (sum) mfg lforce, by(cz)
g mfg_lfshare1980 = mfg/lforce
drop mfg lforce
tempfile mfg1980
save `mfg1980'

import delimited using "$RAWDATA/census/nhgis0048_csv/nhgis0048_csv/nhgis0048_ds123_1990_county.csv", clear

replace gisjoin = "G3200250" if gisjoin == "G3205100"
merge 1:1 gisjoin using  "$RAWDATA/dcourt/county1940_crosswalks", keepusing(cz) keep(3) nogen


g mfg = e4p004 + e4p005
egen lforce = rowtotal(e4p*)

collapse (sum) mfg lforce, by(cz)
g mfg_lfshare1990 = mfg/lforce
drop mfg lforce
tempfile mfg1990
save `mfg1990'
import delimited using "$RAWDATA/census/nhgis0048_csv/nhgis0048_csv/nhgis0048_ds151_2000_county.csv", clear

replace gisjoin = "G3200250" if gisjoin == "G3205100"
merge 1:1 gisjoin using  "$RAWDATA/dcourt/county1940_crosswalks", keepusing(cz) keep(3) nogen

g mfg = gmh003 + gmh016
egen lforce = rowtotal(gmh*)

collapse (sum) mfg lforce, by(cz)
g mfg_lfshare2000 = mfg/lforce
drop mfg lforce

merge 1:1 cz using `mfg1980', nogen
merge 1:1 cz using `mfg1990', nogen

save "$INTDATA/census/cz_mfg_1980_2000.dta", replace
