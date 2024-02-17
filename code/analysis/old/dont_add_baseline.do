// Showing why including baseline values is silly when outcome is a percentage point difference

clear
set seed 123
set obs 1000000
g id = _n

g b_mig = 10*runiform() // Our predicted values
g b_pop_1 = 100*runiform() // Actual black population
g t_pop_1 = 1000*runiform() // Total Population 1940
g t_pop_2 = 1005*runiform() // Total Population 1970
g y_1 = 5*runiform()/t_pop_1 // Outcome variable 1940
g y_2 = 10*runiform()/t_pop_2 // Outcome variable 1970
g y = y_2 - y_1 // Outcome variable long difference

g x_1 = 100*b_pop_1/t_pop_1 // Instrument 1940
g x_2 = 100*(b_pop_1+b_mig)/(t_pop_1+b_mig) // Instrument 1970
g GM_hat_raw_pp = x_2 - x_1 // Instrument

reg y GM_hat_raw_pp // True Model

// Regression 1: Mistakenly adding outcome in 1940 to true model
reg y GM_hat_raw_pp y_1 
local b1_1 = _b[GM_hat_raw_pp]
local b2_1 = _b[y_1]

// Regression 2: What the coefficient on regression 1 is actually giving you
reg y_2 GM_hat_raw_pp y_1
local b1_2 = _b[GM_hat_raw_pp]
local b2_2 = _b[y_1]

local diff1 = round(`b1_2' - `b1_1',0.0001)
local diff2 = round(`b2_2' - `b2_1',0.0001)

di "Difference between coefficients on GM_hat_raw_pp: `diff1'"
di "Difference between coefficients on GM_hat_raw_pp: `diff2'"


use "$CLEANDATA/cz_pooled", clear

reg n_cgoodman_cz_pcc GM_hat_raw_pp reg2 reg3 reg4 [aw=popc1940], r // True Model

// Regression 1: Mistakenly adding outcome in 1940 to true model
reg n_cgoodman_cz_pcc GM_hat_raw_pp reg2 reg3 reg4 b_cgoodman_cz1940_pcc [aw=popc1940], r
local b1_1 = _b[GM_hat_raw_pp]
local b2_1 = _b[b_cgoodman_cz1940_pcc]

// Regression 2: What the coefficient on regression 1 is actually giving you
reg b_cgoodman_cz1970_pcc GM_hat_raw_pp reg2 reg3 reg4 b_cgoodman_cz1940_pcc [aw=popc1940], r
local b1_2 = _b[GM_hat_raw_pp]
local b2_2 = _b[b_cgoodman_cz1940_pcc]


local diff1 = round(`b1_2' - `b1_1',0.0001)
local diff2 = round(`b2_2' - `b2_1',0.0001)

di "Difference between coefficients on GM_hat_raw_pp: `diff1'"
di "Difference between coefficients on GM_hat_raw_pp: `diff2'"

