

	
use "$CLEANDATA/cz_pooled", clear

g growth4070 = 100*(pop1970 - pop1940) / pop1940
estpost corr  growth4070 GM_raw_pp  n_cgoodman_cz_pc 
local nobs = e(N)
local gm_b = e(b)[1,1]
local gm_p = e(p)[1,1]
local n_b = e(b)[1,2]
local n_p = e(p)[1,2]

local gm_stars = cond(`gm_p' < 0.01,"***",cond(`gm_p'<0.05,"**",cond(`gm_p'<0.1,"*",""))) 
local n_stars = cond(`n_p' < 0.01,"***",cond(`n_p'<0.05,"**",cond(`n_p'<0.1,"*",""))) 

local gm = string( `gm_b', "%9.3f") + "`gm_stars'"
local n = string( `n_b', "%9.3f") + "`n_stars'"

capture file close fh
file open fh using "$TABS/corr_matrix.tex", write replace


file write fh "\begin{tabular}{l*{3}{c}} \toprule" _n
file write fh "& GM & $\Delta$ Municipalities P.C. \\" _n
file write fh "\cmidrule(lr){2-2} \cmidrule(lr){3-3}" _n
file write fh "&\multicolumn{1}{c}{(1)} & \multicolumn{1}{c}{(2)} \\" _n
file write fh "\cmidrule(lr){1-3}" _n 
file write fh " Pop. Growth 1940-70 & `gm' & `n' \\" _n
file write fh "\cmidrule(lr){1-3}" _n
file write fh "Observations & `nobs' & `nobs' \\" _n
file write fh "\bottomrule" _n
file write fh "\end{tabular}" _n
file close fh