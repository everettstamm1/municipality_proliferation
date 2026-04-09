
// Base
create_sumshare, ///
	version("base") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black")
	
// Base^2
create_sumshare_quad, ///
	version("base_quad") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black")
	
// Base white
create_sumshare, ///
	version("base_white") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("white")


// Black at county level
create_sumshare, ///
	version("county_black") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("dest_fips") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black")
	
// White at county level
create_sumshare, ///
	version("county_white") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta") ///
	origin_id("origin_fips") ///
	dest_id("dest_fips") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("white")

// White black interaction

create_sumshare, ///
	version("white_black_int") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig_all_bint.dta") ///
	origin_id("origin_fips") ///
	dest_id("dest_fips") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("white")
	
// Black southern SOB
create_sumshare, ///
	version("black_sob") ///
	main_path("$RAWDATA/dcourt/clean_IPUMS_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/3_lasso_boustan_predict_mig_state.dta") ///
	origin_id("origin_state_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black")
	
	
// White southern SOB
create_sumshare, ///
	version("white_sob") ///
	main_path("$RAWDATA/dcourt/clean_IPUMS_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/3_lasso_boustan_predict_mig_state_white.dta") ///
	origin_id("origin_state_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("white")
	

// Black no texas
create_sumshare, ///
	version("black_notx") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample_notx") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("black")
	
// white no texas
create_sumshare, ///
	version("white_notx") ///
	main_path("$INTDATA/dcourt/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta") ///
	shift_path("$INTDATA/dcourt/2_lasso_boustan_predict_mig_white.dta") ///
	origin_id("origin_fips") ///
	dest_id("city") ///
	origin_sample("origin_sample_notx") ///
	out_path("$INTDATA/ssaggregate_prep/") ///
	type("white")
	
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
