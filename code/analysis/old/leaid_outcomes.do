use "$CLEANDATA/county_all_local_stacked_full", clear

global C3 base_muni_county_L0 reg2 reg3 reg4 i.decade

global C4 base_muni_county_L0 reg2 reg3 reg4 mfg_lfshare blackmig3539_share i.decade

gl C5 ${C4} mean_tri add_tri_ctrl

forv pc=0/1{
	preserve
		forv weight=0/1{
			if "`weight'"=="0" local w = 1
			if "`weight'"=="1" local w ="countypop1940"
			eststo clear
			foreach outcome in exp_pp locrev_pp{
				local pclab ""
				if `pc'==1{
					replace `outcome' = 100000*`outcome'/ countypop1940
					local pclab ", Per Capita (100,000)"
				}

				if "`outcome'"=="exp_pp" local outlab = "Expenditure"
				if "`outcome'"=="locrev_pp" local outlab ="Local Revenue"
				foreach c in 3 4 5{
					local share_controls = cond("`c'"=="3","No","Yes")
					local tri_controls = cond("`c'"=="5","Yes","No")
					
					su `outcome' [aw=`w']
					local y_mean : di %6.3f  `r(mean)'

					eststo : reg `outcome' n_muni_county_L0 ${C`c'} [aw=`w'], r cl(fips)
					local rsq : di %6.3f e(r2)
					estadd local Rsquared = `rsq'
					estadd local dep_mean = 	`y_mean'
					estadd local share_ctrls = "`share_controls'"
					estadd local tri_ctrls = "`tri_controls'"
				}
			}
			
			esttab using "$TABS/leaid_outcomes/schdist_ind_`weight'_`pc'", ///
							replace label se booktabs nonum noconstant nomtitle compress ///
							starlevels( * 0.10 ** 0.05 *** 0.01) ///
							stats(Rsquared dep_mean share_ctrls tri_ctrls N, labels( ///
							"R-Squared"  ///
							"Dep Var Mean" ///
							"Mfg/Black Mig Controls" ///
							"TRI Controls" ///
							"Observations")) ///
							title("Regressing School Finance Data on Number of New School Districts`pclab'") ///
							keep(n_muni_county_L0) ///
							mgroups("Expenditure Per Student" "Local Revenue Per Student", pattern(1 0 0 1 0 0) ///
							prefix(\multicolumn{@span}{c}{) suffix(}) span erepeat(\cmidrule(lr){@span})) ///
							addnotes("X variable is number of new school districts per county by decade for 1940-50, 1950-60, and 1960-70." "Y variable is county-level average `outlab' per student from 1994-2018. Controls include base decade number of " "independent school districts and region and (X variable) decade fixed effects." "Standard errors clustered at county level.") 
		}
	restore
}