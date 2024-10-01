// Calculates dissimilarity index. Unique id is subunits (neighborhood, districts, etc) of level of aggregation agg_id (Communiting Zone, MSA, etc). Name is the name of the new variable, mingroup is the variable of the count of minority group, majgroup is the variable of the majority group. If onegroup is specified, the variance ratio against the total population is calculated, so majgroup is assumed to be a total population count.

cap prog drop makeDissimilarity
prog def makeDissimilarity
	syntax [if], gen(name) mingroup(varname) majgroup(varname) id(varname) agg_id(varname) [onegroup]
	
	qui unique `id'
	assert r(N) == r(unique)

	tempvar total agg_total agg_mingroup exp P num denom
	if `"`onegroup'"' == `""' egen `total' = rowtotal(`majgroup' `mingroup'), m
	if `"`onegroup'"' != `""' g `total' = `majgroup' 

	bys `agg_id' : egen `agg_total' = total(`total')
	bys `agg_id' : egen `agg_mingroup' = total(`mingroup')
	
	g `exp' = `mingroup'/`total'
	g `P' = `agg_mingroup'/`agg_total'

	
	g `num' = `total' * abs(`exp' - `P')
	g `denom' = 2 * `agg_total' * `P' * (1 - `P')
	
	bys `agg_id' : egen `gen' = total(0.5 * `num' / `denom')
end