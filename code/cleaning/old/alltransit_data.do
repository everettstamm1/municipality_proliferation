
forv s=1/56{
	local fips = cond(`s'<10,"0`s'","`s'")
	cap import delimited using "$RAWDATA/transit/alltransit_data_places_`fips'.csv", clear
	if _rc==0{
		replace place = subinstr(place, `"""', "", .)
		destring place, replace
		g STATEFP = floor(place/100000)
		g PLACEFP = mod(place, 100000)
		keep STATEFP PLACEFP alltransit_performance_score
		tempfile transit`s'
		save `transit`s''
	}
}
clear
forv s=1/56{
	cap append using `transit`s''
}

save "$INTDATA/other/alltransit_data.dta", replace