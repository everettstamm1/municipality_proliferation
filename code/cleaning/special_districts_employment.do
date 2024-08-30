

import delimited using "$RAWDATA/census/2012_downloadable_data/2012_downloadable_data/Individual Unit File/12cempst.dat", clear

g state = real(substr(v1,1,2))
g type = real(substr(v1,3,1))
g county = real(substr(v1,4,3))
g id = real(substr(v1,7,3))
g suppcode = real(substr(v1,10,3))
g subcode = real(substr(v1,13,2))
g item = real(substr(v1,18,3))
g ft = real(substr(v1,21,10))
g ft_flag = substr(v1,32,1)
g ftp = real(substr(v1,33,12))
g ftp_flag = substr(v1,46,1)
g pt = real(substr(v1,47,10))
g pt_flag = substr(v1,58,1)
g ptp = real(substr(v1,59,12))
g ptp_flag = substr(v1,72,1)
g pth = real(substr(v1,73,10))
g pth_flag = substr(v1,84,1)
g fte = real(substr(v1,85,10))
drop v1

tempfile data
save `data'

import delimited using "$RAWDATA/census/2012_downloadable_data/2012_downloadable_data/Individual Unit File/12cempid.dat", clear

replace v1 = strltrim(v1)

replace v1 = v1 + " " + v2 if !mi(v2)
replace v1 = v1 + " " + v3 if !mi(v3)

g state = real(substr(v1,1,2))
g type = real(substr(v1,3,1))
g county = real(substr(v1,4,3))
g id = real(substr(v1,7,3))
g suppcode = real(substr(v1,10,3))
g subcode = real(substr(v1,13,2))
g name = substr(v1,15,78)
g region = real(substr(v1,79,1))
g statefip = real(substr(v1,110,2))
g countyfip = real(substr(v1,112,3))
g pop_enroll_func_code = substr(v1,126,9)
g popyr = real(substr(v1,135,2))
g school_level = real(substr(v1,137,2))
g pr_selection = real(substr(v1,146,6))
g weekly_hr_code = real(substr(v1,189,1))
g ftp_code = real(substr(v1,190,1))
g ptp_code = real(substr(v1,191,1))
g m_sch_teach_pay = real(substr(v1,192,2))
g m_sch_admin_pay = real(substr(v1,194,2))
g m_sch_other_pay = real(substr(v1,196,2))
g year_data = real(substr(v1,198,2))
g year_depsch_data = real(substr(v1,200,2))
g survey_form_type = real(substr(v1,205,2))
drop v1 v2 v3

merge 1:m state type county id using `data', keep(3) nogen

//keep if year_data == 12

g cty_fips = 1000*statefip + countyfip
merge m:1 cty_fips using "$XWALKS/cw_cty_czone", keep(3) nogen
ren type govttype
keep cz item cty_fips id name pt ptp ft ftp fte govttype


g itemstr = ""
replace itemstr = "Transit" if item == 94
replace itemstr = "Total" if item == 0
replace itemstr = "Fire" if item == 24 | item == 124
replace itemstr = "Health" if item == 32 | item == 40
replace itemstr = "Streets" if item == 44
replace itemstr = "HCD_Welfare" if item == 50 | item == 79
replace itemstr = "Libraries" if item == 52
replace itemstr = "Parks" if item == 61
replace itemstr = "Police" if item == 62 | item == 162
replace itemstr = "Utilities" if inlist(item,80,81,87,91,92,93)
replace itemstr = "Federal" if inlist(item,2,6,14)
replace itemstr = "State" if inlist(item,21, 22, 90)
replace itemstr = "Education" if inlist(item,12,112,16,18,21)
replace itemstr = "Other" if itemstr == ""


levelsof itemstr, local(items)
g n = 1

collapse (sum) pt ptp ft ftp fte n, by(cz cty_fips id itemstr govttype)

reshape wide pt ptp ft ftp fte n, i(cz cty_fips id govttype) j(itemstr) string

collapse (sum) pt* ft* n*, by(cz govttype)
g ft_salaryTotal = ftpTotal/ftTotal
g fte_salaryTotal = (ftpTotal + ptpTotal)/fteTotal

foreach i in `items'{
	if "`i'"!="Total"{
		g ft_salary`i' = ftp`i'/ft`i'
		g fte_salary`i' = (ftp`i' + ptp`i')/fte`i'
		
		foreach t in pt ptp ft ftp fte ft_salary fte_salary{
			g p_`t'_`i' = `t'`i'/`t'Total
		}
	}
}
ren czone cz

reshape wide ptEducation-p_fte_salary_Utilities, i(cz) j(govttype)
save "$INTDATA/cog/special_districts_employment", replace
