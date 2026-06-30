
forv s=4/55{
	cap confirm file "$INTDATA/other/muni_district_overlap/distgrid_`s'.csv"
	if _rc==0{

			import delimited using "$INTDATA/other/muni_district_overlap/distgrid_`s'.csv", clear
			tostring v1, replace
			replace v1 = "GEOID_muni" if _n == 1
			foreach v of varlist * {
			   local vname = `v'[1]
			   rename `v' dist`vname'
			}
			drop if _n == 1
			ren distGEOID_muni GEOID_muni

			qui reshape long dist, i(GEOID_muni) j(GEOID_dist)
			destring GEOID_muni, replace
			g STATEFP = `s'
			tempfile dist`s'
			save `dist`s''
	}	
}



clear
forv s=4/55{
	cap confirm file "$INTDATA/other/muni_district_overlap/distgrid_`s'.csv"
	if _rc==0{
		append using `dist`s''
	}
}
save "$CLEANDATA/other/muni_district_overlap.dta", replace



forv s=4/55{
	cap confirm file "$INTDATA/other/final2/distgrid_`s'.csv"
	if _rc==0{

			import delimited using "$INTDATA/other/final2/distgrid_`s'.csv", clear
			tostring v1, replace
			replace v1 = "GEOID_muni" if _n == 1
			foreach v of varlist * {
			   local vname = `v'[1]
			   rename `v' dist`vname'
			}
			drop if _n == 1
			ren distGEOID_muni GEOID_muni

			qui reshape long dist, i(GEOID_muni) j(GEOID_dist)
			destring GEOID_muni, replace
			g STATEFP = `s'
			tempfile dist`s'
			save `dist`s''
	}	
}



clear
forv s=4/55{
	cap confirm file "$INTDATA/other/final2/distgrid_`s'.csv"
	if _rc==0{
		append using `dist`s''
	}
}
save "$CLEANDATA/other/muni_district_overlap_2.dta", replace