// Calculates dissimilarity index. Unique id is subunits (neighborhood, districts, etc) of level of aggregation agg_id (Communiting Zone, MSA, etc). Name is the name of the new variable, mingroup is the variable of the count of minority group, majgroup is the variable of the majority group. If onegroup is specified, the variance ratio against the total population is calculated, so majgroup is assumed to be a total population count.

cap prog drop makeRCO
prog def makeRCO
	syntax [if], gen(name) mingroup(varname) majgroup(varname) id(varlist) area(varname) agg_id(varname)
	
	qui unique `id'
	assert r(N) == r(unique)
	
	tempvar touse
	g `touse' =  !(mi(`majgroup') & mi(`mingroup'))
	tempvar neg_area total agg_total agg_mingroup agg_majgroup agg_area ///
			sum rsum nlo nhi Tlo Thi numnum numdenom denomnum_tosum  ///
			denomdenom_tosum denomnum denomdenom
	
	g `neg_area' = -1 * `area' if `touse'
	egen `total' = rowtotal(`majgroup' `mingroup') if `touse', m
	
	bys `agg_id' : egen `agg_total' = total(`total') if `touse'
	bys `agg_id' : egen `agg_mingroup' = total(`mingroup') if `touse'
	bys `agg_id' : egen `agg_majgroup' = total(`majgroup') if `touse'
	bys `agg_id' : egen `agg_area' = total(`area') if `touse'
	
	
	bys `agg_id' (`area') : g `sum' = sum(`total') if `touse'
	bys `agg_id' (`neg_area') : g `rsum' = sum(`total') if `touse'
	
	bys `agg_id' (`area') : g `nlo' = _n if (`agg_mingroup' <= `sum') & ///
											(`agg_mingroup' > `sum'[_n - 1] | _n == 1) & `touse'
	bys `agg_id' (`neg_area') : g `nhi' = _n if (`agg_mingroup' <= `rsum') & ///
											(`agg_mingroup' > `rsum'[_n - 1] | _n == 1) & `touse'
	bys `agg_id' (`nlo') : replace `nlo' = `nlo'[1] if `touse'
	bys `agg_id' (`nhi') : replace `nhi' = `nhi'[1] if `touse'
	
	bys `agg_id' (`area') : egen `Tlo' = total(`total'[_n <= `nlo']) if `touse'
	bys `agg_id' (`neg_area') : egen `Thi' = total(`total'[_n <= `nhi']) if `touse'
	
	bys `agg_id' : egen `numnum' = total(`mingroup' * `area' / `agg_mingroup') if `touse'
	bys `agg_id' : egen `numdenom' = total(`majgroup' * `area' / `agg_majgroup') if `touse'

	g `denomnum_tosum' = `total' * `area'/`Tlo' if `touse'
	g `denomdenom_tosum' = `total' * `area' / `Thi' if `touse'
	
	bys `agg_id' (`area') : egen `denomnum' = total(`denomnum_tosum'[_n <= `nlo']) if `touse'
	bys `agg_id' (`neg_area') : egen `denomdenom' = total(`denomdenom_tosum'[_n <= `nhi']) if `touse'
	
	g `gen' = (`numnum'/`numdenom' - 1)/(`denomnum'/`denomdenom' - 1) if `touse'


end