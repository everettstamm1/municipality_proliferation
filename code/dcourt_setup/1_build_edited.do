/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

1. Build intermediate datasets. 

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Build data/mechanisms/population data. 
	*2. Build data/mobility datasets.
	*3. Build mechanisms/incarceration datasets.
	*4. Build mechanisms/jobs datasets.
	*5. Build mechanisms/neighborhoods datasets.
	*6. Build mechanisms/political datasets.
	*7. Build mechanisms/public_finance datasets.
	*8. Build mechanisms/schools datasets.
*first created: 11/08/2021
*last updated:  11/08/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*1. Build data/crosswalks data.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	cd "$xwalks/documentation/urban_rural_county_classification"
	do clean_census_tract_2010_rural_urban_classification.do 

	cd "$msanecma"
	do msa_1990_codes_names.do 

	cd "$msanecma"
	do necma_1990_codes_names.do 

	cd "$urbrural"
	do urbrural_county.do 	

	cd "$xwalks/documentation"
	do county1940_crosswalks.do 

	cd "$xwalks/documentation"	
	do US_place_point_2010_crosswalks.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*2. Build data/instrument data.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	cd "$migdata/documentation"
	do clean_south_county_white_nonwhite_mig_1940_1970_edited.do
	cd "$migshares/documentation"
	do clean_IPUMS_1935_1940_extract_to_construct_migration_weights.do
	cd "$migshares/documentation"
	do clean_IPUMS_1940_extract_to_construct_migration_weights.do
	cd $instrument/rndmig
	unzipfile $instrument/rndmig/rndmig.zip
	cd $migshares/rndmig
	unzipfile $migshares/rndmig/shares_rndmig.zip
	

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*3. Build data/mechanisms/population data.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	cd $population/raw/documentation
	//do interpolatedpopulations.do
	
	copy "$pf/documentation/ICPSR_07735_City_Book_1944_1977/07735-0001-Setup_edited.do" "$pf/raw/ICPSR_07735_City_Book_1944_1977/DS0001/07735-0001-Setup_edited.do"
	cd $pf/raw/ICPSR_07735_City_Book_1944_1977/DS0001
	do 07735-0001-Setup_edited.do
	cd $population/documentation
	//do clean_city_population_by_race_2000.do 
	do clean_city_population_ccdb_1944_1977_edited.do
	do $population/documentation/clean_city_population_census_1940.do
	//do $population/documentation/clean_county_pop_1870_2000_bpopshare_1870_2000_cz.do
	do $population/documentation/clean_cz_population_1940_1970.do
	do $population/documentation/clean_cz_population_density_1940.do
	do $population/documentation/clean_cz_snq_european_immigration_instrument.do
	do $population/documentation/City_Book_1944_1977_clean.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*4. Build data/mobility datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	//cd $mobdata/documentation
	//do clean_cz_mobility_1900_2015.do
	//do $mobdata/documentation/clean_cz_p25_p75_race_share.do
	//do $mobdata/documentation/clean_teen_school_attendance_mother_south_north.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*5. Build mechanisms/incarceration datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	//cd $incarceration/documentation
	//do $incarceration/documentation/clean_cz_city_murder_rates_1931_1969.do
	//cap do $incarceration/documentation/clean_cz_riots_1964_1971.do
	//do $incarceration/documentation/clean_cz_jail_rates_1920_1960.do
	//do $incarceration/documentation/clean_cz_iob_crime_incarceration.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*6. Build mechanisms/jobs datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	cd $jobs/documentation
	do clean_cz_industry_employment_1940_1970.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*7. Build mechanisms/neighborhoods datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	//cd $nbhds/documentation
	//do clean_cz_marriage_income_occscore_1940.do
	//do $nbhds/documentation/clean_cz_neighborhoods.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*8. Build mechanisms/political datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	//cd $political/documentation
	//do clean_cz_wallace_share_1968.do		
	//do $political/documentation/clean_cz_weighted_racial_animus.do

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*9. Build mechanisms/public_finance datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	//cd $pf/raw/documentation
	//do CountyAreaFin_Eight_Var_InSampleCZ_1957_2002.do
	//cd $pf/documentation
	//do clean_cz_city_police_per_capita_1920_2007.do
	//do $pf/documentation/clean_cz_public_finance_1932_2012.do
	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%	
*10. Build mechanisms/schools datasets.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	//cd $schools/documentation
	//do clean_cz_med_educd_25plus_1940.do
	//do $schools/documentation/clean_cz_prvschl_share_1920_2010.do
	
