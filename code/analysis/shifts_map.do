use "$INTDATA/ssaggregate_prep/shock_instrument_base.dta", clear
ren origin_fips county
maptile shift, geography(county1990) savegraph("$FIGS/base_shifts.png") twopt(title("Black Shifts") note("Shifts normalized by 1935-39 migrants")) conus replace

use "$INTDATA/ssaggregate_prep/shock_instrument_base_white.dta", clear
ren origin_fips county
maptile shift, geography(county1990) savegraph("$FIGS/base_white_shifts.png") twopt(title("White Shifts") note("Shifts normalized by 1935-39 migrants")) conus replace

use "$INTDATA/ssaggregate_prep/shock_instrument_black_notx.dta", clear
ren origin_fips county
maptile shift, geography(county1990) savegraph("$FIGS/black_notx_shifts.png") twopt(title("Black Shifts") note("Shifts normalized by 1935-39 migrants")) conus replace

use "$INTDATA/ssaggregate_prep/shock_instrument_white_notx.dta", clear
ren origin_fips county
maptile shift, geography(county1990) savegraph("$FIGS/white_notx_shifts.png") twopt(title("White Shifts") note("Shifts normalized by 1935-39 migrants")) conus replace

use "$INTDATA/ssaggregate_prep/shock_instrument_base_white.dta", clear
ren shift white_shift

merge 1:1 origin_fips using "$INTDATA/ssaggregate_prep/shock_instrument_base.dta"