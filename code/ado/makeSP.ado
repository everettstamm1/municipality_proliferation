// Calculates dissimilarity index. Unique id is subunits (neighborhood, districts, etc) of level of aggregation agg_id (Communiting Zone, MSA, etc). Name is the name of the new variable, mingroup is the variable of the count of minority group, majgroup is the variable of the majority group. If onegroup is specified, the variance ratio against the total population is calculated, so majgroup is assumed to be a total population count.

cap prog drop makeSP
prog def makeSP
	syntax [if], gen(name) mingroup(varname) majgroup(varname) id(varname)  agg_id(varname) distances(string) [nexpd]
	
	qui unique `id'
	assert r(N) == r(unique)
	
	tempvar neg_area total agg_total agg_mingroup agg_majgroup P_maj P_min P_t
	
	egen `total' = rowtotal(`majgroup' `mingroup'), m
	
	bys `agg_id' : egen `agg_total' = total(`total')
	bys `agg_id' : egen `agg_mingroup' = total(`mingroup')
	bys `agg_id' : egen `agg_majgroup' = total(`majgroup')
	
	preserve
		keep `id' `total' `mingroup' `majgroup'
		tempfile pops
		save `pops'
		
		use "`distances'", clear
		cap destring `id'_i `id'_j, replace
		ren `id'_i `id'
		merge m:1 `id' using `pops', keep(3) nogen
		tempvar total_i mingroup_i majgroup_i
		g `total_i' = `total'
		g `mingroup_i' = `mingroup'
		g `majgroup_i' = `majgroup'
		ren `id' `id'_i
		ren `id'_j `id'
		merge m:1 `id' using `pops', keep(3) nogen
		tempvar total_j mingroup_j majgroup_j
		g `total_j' = `total'
		g `mingroup_j' = `mingroup'
		g `majgroup_j' = `majgroup'
		ren `id' `id'_j
		
		tempvar c
		if `"`nexpd'"' == `""' gen `c' = touching
		if `"`nexpd'"' != `""' gen `c' = exp(-centroid_dist)
		
		g tt = `total_i' * `total_j' *`c'
		g nn = `mingroup_i' * `mingroup_j' * `c'
		g mm = `majgroup_i' * `majgroup_j' * `c'
		
		collapse (sum) tt nn mm, by(`agg_id')
		tempfile clustering_vars
		save `clustering_vars'
	restore
	merge m:1 `agg_id' using `clustering_vars', keep(3) nogen 
	
	g `P_min' = nn/(`agg_mingroup' * `agg_mingroup')

	g `P_maj' =  mm/(`agg_majgroup' * `agg_majgroup')
	g `P_t' =  tt/(`agg_total' * `agg_total')
	
	g `gen' = ((`agg_majgroup' * `P_maj') + (`agg_mingroup' * `P_min'))/((`agg_total' * `P_t'))
	drop nn mm tt
end