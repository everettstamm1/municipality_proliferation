
// Base
create_sumshare, ///
	version("base") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black") ///
	shift_name("proutmig")
	
// Base^2
create_sumshare_quad, ///
	version("base_quad") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black") ///
	shift_name("proutmig")
	
// Base white
create_sumshare, ///
	version("base_white") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("white") ///
	shift_name("proutmig")


// Black southern SOB
create_sumshare, ///
	version("black_sob") ///
	main_path("$RAWDATA/dcourt/clean_IPUMS_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/3_lasso_boustan_predict_mig_state.dta") ///
	origin_id("origin_state_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black") ///
	shift_name("proutmig")
	
	
// Black state resid
create_sumshare, ///
	version("base_stres") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/3_residstate_act_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black") ///
	shift_name("residoutmig")
	
	
// Black top urban county dropped
create_sumshare, ///
	version("base_rur") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/rur_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black") ///
	shift_name("proutmig")
		
// Black Panel
create_sumshare_panel, ///
	version("base") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black") ///
	time("year")
	
	
// Placebo shocks
forval i=1(1)1000{ 
	di "At iteration i=`i'"
	set seed 20260409     	
	use	"$RAWDATA/dcourt/county1940_crosswalks.dta", clear
	g proutmig=rnormal(0,sqrt(5))
	
	rename fips_str origin_fips
	g year=1940
	
	keep origin_fips year proutmig
	
	tempfile rndmig`i'1940
	
	save `rndmig`i'1940'
	
	create_sumshare, ///
	version("base_placebo_`i'") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path( `rndmig`i'1940') ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/placebo/") ///
	type("black") ///
	shift_name("proutmig")
	
	
	}
