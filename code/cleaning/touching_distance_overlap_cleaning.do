
use "$CLEANDATA/cz_pooled.dta", clear
levelsof cz, local(czs)
clear
foreach cz in `czs'{
	foreach t in touching centroid_dist{
		import delimited using "$INTDATA/other/full_touching_distance/full_`t'_`cz'.csv", clear
		tostring v1, replace
		replace v1 = "GEOID" if _n == 1
		foreach v of varlist * {
		   local vname = `v'[1]
		   rename `v' `t'`vname'
		}
		drop if _n == 1
		ren `t'GEOID GEOID_i
		if "`t'" == "centroid_dist" qui destring *, replace force

		qui reshape long `t', i(GEOID_i) j(GEOID_j) string
		if "`t'" == "centroid_dist" qui destring GEOID_j, replace force

		if "`t'" == "touching" qui destring GEOID_i GEOID_j, replace force

		g cz = `cz'
		tempfile `t'`cz'
		save ``t'`cz''
	}
}

clear
foreach cz in `czs'{
	append using `touching`cz''
	merge 1:1 GEOID_i GEOID_j cz using `centroid_dist`cz'', nogen update
}
g temp  = touching == "TRUE"
replace temp = 1 if GEOID_i == GEOID_j
drop touching
ren temp touching
replace centroid_dist = 0 if GEOID_i == GEOID_j
save "$CLEANDATA/other/touching_dist_munis.dta", replace


use "$CLEANDATA/cz_pooled.dta", clear
levelsof cz, local(czs)
clear
foreach cz in `czs'{
	foreach t in touching centroid_dist{
		import delimited using "$INTDATA/school_touching/school_`t'_`cz'.csv", clear
		tostring v1, replace
		replace v1 = "GEOID" if _n == 1
		foreach v of varlist * {
		   local vname = `v'[1]
		   rename `v' `t'`vname'
		}
		drop if _n == 1
		ren `t'GEOID GEOID_i
		if "`t'" == "centroid_dist" qui destring *, replace force

		qui reshape long `t', i(GEOID_i) j(GEOID_j) string
		if "`t'" == "centroid_dist" qui destring GEOID_j, replace force

		if "`t'" == "touching" qui destring GEOID_i GEOID_j, replace force

		g cz = `cz'
		tempfile `t'`cz'
		save ``t'`cz''
	}
}

clear
foreach cz in `czs'{
	append using `touching`cz''
	merge 1:1 GEOID_i GEOID_j cz using `centroid_dist`cz'', nogen update
}
g temp  = touching == "TRUE"
replace temp = 1 if GEOID_i == GEOID_j
drop touching
ren temp touching
replace centroid_dist = 0 if GEOID_i == GEOID_j
save "$CLEANDATA/other/touching_dist_schools.dta", replace

forv s=4/55{
	cap confirm file "$INTDATA/other/muni_district_overlap/distgrid_`s'.csv"
	if _rc==0{
		foreach t in dist muni{	
			import delimited using "$INTDATA/other/muni_district_overlap/`t'grid_`s'.csv", clear
			tostring v1, replace
			replace v1 = "GEOID_muni" if _n == 1
			foreach v of varlist * {
			   local vname = `v'[1]
			   rename `v' `t'`vname'
			}
			drop if _n == 1
			ren `t'GEOID_muni GEOID_muni

			qui reshape long `t', i(GEOID_muni) j(GEOID_dist)
			destring GEOID_muni, replace
			g STATEFP = `s'
			tempfile `t'`s'
			save ``t'`s''
		}
	}	
}



clear
forv s=4/55{
	cap confirm file "$INTDATA/other/muni_district_overlap/distgrid_`s'.csv"
	if _rc==0{
		append using `dist`s''
		merge 1:1 GEOID_muni GEOID_dist STATEFP using `muni`s'', nogen update
	}
}
save "$CLEANDATA/other/muni_district_overlap.dta", replace

import delimited using "$INTDATA/other/muni_district_overlap/district_areas.csv", clear
save


use "$CLEANDATA/cz_pooled.dta", clear
levelsof cz, local(czs)
clear
foreach cz in `czs'{
	foreach t in hausdorffgrid {
		import delimited using "$INTDATA/other/muni_district_overlap/`t'_`cz'.csv", clear
		tostring v1, replace
		replace v1 = "GEOID" if _n == 1
		foreach v of varlist * {
		   local vname = `v'[1]
		   rename `v' `t'`vname'
		}
		drop if _n == 1
		ren `t'GEOID GEOID_i
		qui destring *, replace force

		qui reshape long `t', i(GEOID_i) j(GEOID_j)

		g cz = `cz'
		tempfile `t'`cz'
		save ``t'`cz''
	}
}

clear
foreach cz in `czs'{
	append using `hausdorffgrid`cz''
	

}
ren hausdorffgrid hausdorff

save "$CLEANDATA/other/hausdorff_munis.dta", replace



// Distances to center city

import excel using "$CLEANDATA/other/shortest_line_edge_edge.xlsx", clear first
keep if GEOID_m == GEOID_2
keep len STATEFP PLACEFP
duplicates drop
ren len len_edge_edge
tempfile edge_edge 
save "$INTDATA/other/edge_edge.dta", replace


import excel using "$CLEANDATA/other/shortest_line_center_edge.xlsx", clear first
keep if GEOID_m == GEOID_2
keep len STATEFP PLACEFP
duplicates drop
ren len len_center_edge
tempfile center_edge 
save "$INTDATA/other/center_edge.dta", replace

// Flagging main cities

import excel using "$CLEANDATA/other/shortest_line_edge_edge.xlsx", clear first
drop STATEFP PLACEFP
g STATEFP = floor(GEOID_m/100000)
g PLACEFP = mod(GEOID_m, 100000)
keep PLACEFP STATEFP
duplicates drop
save "$INTDATA/other/main_cities.dta", replace

import excel using "$CLEANDATA/other/touching_munis.xlsx", clear first
drop if cz != cz_2 // Not counting those that are touching a *DIFFERENT* principle city
keep GEOID_2
duplicates drop
g STATEFP = floor(GEOID_2 / 100000)
g PLACEFP = mod(GEOID_2,100000)
drop GEOID_2
save "$INTDATA/other/touching_munis", replace


import delimited using "$CLEANDATA/other/shared_boundaries_muni.csv", clear
g temp = int_len/len
replace temp = 1 if temp > 1 // Little extra from buffer
bys geoid : egen pmax_shared_boundary_muni = max(temp)
bys geoid : egen psum_shared_boundary_muni = sum(temp)
keep geoid pmax_shared_boundary_muni psum_shared_boundary_muni
duplicates drop
ren geoid GEOID
save "$INTDATA/other/shared_boundaries_muni", replace

import delimited using "$CLEANDATA/other/shared_boundaries_dist.csv", clear
g temp = int_len/len
replace temp = 1 if temp > 1 // Little extra from buffer
bys geoid : egen pmax_shared_boundary_dist = max(temp)
bys geoid : egen psum_shared_boundary_dist = sum(temp)
keep geoid pmax_shared_boundary_dist psum_shared_boundary_dist
duplicates drop
ren geoid leaid
save "$INTDATA/other/shared_boundaries_dist", replace
