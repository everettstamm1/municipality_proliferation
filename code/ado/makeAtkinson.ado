// Calculates dissimilarity index. Unique id is subunits (neighborhood, districts, etc) of level of aggregation agg_id (Communiting Zone, MSA, etc). Name is the name of the new variable, mingroup is the variable of the count of minority group, majgroup is the variable of the majority group. If onegroup is specified, the variance ratio against the total population is calculated, so majgroup is assumed to be a total population count.

cap prog drop makeAtkinson
prog def makeAtkinson
	syntax [if], gen(name) mingroup(varname) majgroup(varname) id(varlist) agg_id(varname) b(real)
	
	qui unique `id'
	assert r(N) == r(unique)
	
	local bb = `b'

	tempvar total agg_total agg_mingroup pi_b pi_ib num denom tosum sum
	
	egen `total' = rowtotal(`majgroup' `mingroup'), m
	
	bys `agg_id' : egen `agg_total' = total(`total')
	bys `agg_id' : egen `agg_mingroup' = total(`mingroup')
	
	
	g `pi_b' = `agg_mingroup' / `agg_total'
	g `pi_ib' = `mingroup' / `total'
	
	g `num' = (1-`pi_ib')^(1-`bb') * `pi_ib'^`bb' * `total'
	g `denom' = `pi_b' * `agg_total'
	
	bys `agg_id' : egen `tosum' = total(`num'/`denom')
	g `sum' = abs(`tosum')^(1/(1-`bb'))
	g `gen' = 1 - (`pi_b'/(1-`pi_b')) * `sum'
end
