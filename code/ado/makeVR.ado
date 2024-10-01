// Calculates variance ratio. Unique id is subunits (neighborhood, districts, etc) of level of aggregation agg_id (Communiting Zone, MSA, etc). Name is the name of the new variable, mingroup is the variable of the count of minority group, majgroup is the variable of the majority group. If onegroup is specified, the variance ratio against the total population is calculated, so majgroup is assumed to be a total population count.

cap prog drop makeVR
prog def makeVR
	syntax, gen(name) mingroup(varname) majgroup(varname) id(varname) agg_id(varname) [if] [onegroup]
	
	qui unique `id'
	assert r(N) == r(unique)
	
	tempvar total agg_total agg_mingroup agg_total agg_mingroup exp1 exp2 exp3 iso P
	
	if `"`onegroup'"' == `""' egen `total' = rowtotal(`majgroup' `mingroup'), m
	if `"`onegroup'"' != `""' gen `total' = `majgroup' 
	
	bys `agg_id' : egen `agg_total' = total(`total')
	bys `agg_id' : egen `agg_mingroup' = total(`mingroup')
	
	
	g `exp1' = `mingroup'/`agg_mingroup'
	g `exp2' = `mingroup'/`total'
	g `exp3' = `exp1' * `exp2'
	
	bys `agg_id' : egen `iso' = total(`exp3')
	g `P' = `agg_mingroup'/`agg_total'

	g `gen' = (`iso' - `P')/(1 - `P')
end