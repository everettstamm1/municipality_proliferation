// Recentering creation for SCC


set seed 27283437
	forval i=1(1)1000{  
		
	use	"data/input/2_lasso_boustan_predict_mig.dta", clear
	keep year origin_fips proutmig
	g order = _n
	g rng = uniform()
	sort rng
	replace  proutmig = proutmig[order]
	
	tempfile proutmig`i'
	save `proutmig`i''

	clear all
	set maxvar 32000
		
	global groups black // took out white
	global origin_id origin_fips
	global origin_id_code origin_fips_code
	global origin_sample origin_sample
	global destination_id city
	global destination_id_code city_code
	global dest_sample dest_sample
	global weights_data "`proutmig`i''"
	global version re`i'
	global weight_types pr // took out act
	global weight_var outmig
	global start_year 1940
	global panel_length 0
	global shares_dir "data/interim" 
	global sharesXweights_dir "data/interim" 
	use "data/input/clean_IPUMS_1935_1940_extract_to_construct_migration_weights.dta", clear

	do "$CODE/helper/bartik_generic.do"
	}