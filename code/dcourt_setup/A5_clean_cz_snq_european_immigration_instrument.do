/*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

This do-file constructs CZ-level measures of Sequeira et al (2020)'s instrument for European mass migration into US counties.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
STEPS:
	*1. Pull 1940 county-level populaty from County Data Book 1947 and merge with Sequeira et al (2020) replication dataset. 
	*2. Create CZ-level measure of European mass migration instrument.
*first created: 11/13/2019
*last updated:  11/22/2021
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------*/	
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*1. Pull 1940 county-level populaty from County Data Book 1947 and merge with Sequeira et al (2020) replication dataset. 
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%

	use "$RAWDATA/dcourt/ICPSR_07736_County_Book_1947_1977/DS0001/County_Book_1947_1977.dta", clear
	drop if FIPSCNTY=="000" // Drop state-level data
	g fips_str=FIPSTATE+ FIPSCNTY // Create county fips identifier for merging with other geographies
	
	* Merge in harmonized geo identifiers.
	merge 1:1 fips_str using $RAWDATA/dcourt/county1940_crosswalks.dta, keepusing(cz)
	tab _merge // Check and see what counties are matching and not matching. Create a comment in the code detailing non-matching counties.
	keep if _merge==3 
	drop _merge
	
	* Add vars to this list
	local varlist CC00012 CC00013 CC00014 CC00015 CC00051 CC00052 CC00053 CC00054
	
	* Replace values as missing if identified as missing according to the Codebook. Check that this is the right approach to dealing with the missing values.
	foreach var in `varlist'{
	replace `var'=. if (`var'F=="1"|`var'F=="2"|`var'F=="3"|`var'F=="6"|`var'F=="7")
	}
		
	* POPULATION
	forval yr=4/7{
	local stub=`yr'-2
	g pop19`yr'0=CC0001`stub'
	}
	g wpop1940 = CC00051
	* Keep only necessary vars
	keep fips_str cz *pop*
	
	* Save file
	tempfile pop1940
	save `pop1940'
	
	use "$RAWDATA/dcourt/Sequeira_et_al_REStud_Replication_Final/Main_Tables.dta", clear

	keep fips_code instmig_avg 

	rename fips_code fips
	
	merge 1:1 fips using $RAWDATA/dcourt/county1940_crosswalks.dta, nogenerate keep (3)

	merge 1:1 fips_str using `pop1940', keepusing(pop1940 wpop1940) keep (3) /// Ste. Genevieve, MO county drops but it is located in Farmington, MO CZ which is not in the sample.

*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
*2. Create CZ-level measure of European mass migration instrument.
*------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------%
	
	* Generate pop1940 weighted average of instmig_avg

	g instmig_avg_pop=pop1940*instmig_avg

	collapse (sum) instmig_avg_pop pop1940 wpop1940, by(cz)

	g wt_instmig_avg=instmig_avg_pop/pop1940
	
	g wt_instmig_avg_pp= (instmig_avg_pop+wpop1940)/(pop1940+instmig_avg_pop) - wpop1940/pop1940
	keep wt_instmig_avg wt_instmig_avg_pp cz

	save $INTDATA/dcourt/clean_cz_snq_european_immigration_instrument.dta, replace

