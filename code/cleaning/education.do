use city stateicp countyicp educd age using "$RAWDATA/census/usa_00118.dta/usa_00118.dta" if educd != 999, clear

merge m:1 stateicp countyicp using "$RAWDATA/dcourt/county1940_crosswalks", keep(3) nogen keepusing(cz)

g hsgrad = educd >= 60 if !mi(educd)
g unigrad = educd >= 100 if !mi(educd)


g hsgrad_18 = educd >= 60 if !mi(educd) & age > 18
g unigrad_18 = educd >= 100 if !mi(educd) & age > 18


g hsgrad_25 = educd >= 60 if !mi(educd) & age > 25
g unigrad_25 = educd >= 100 if !mi(educd) & age > 25

collapse (mean) hsgrad unigrad hsgrad_18 unigrad_18 hsgrad_25 unigrad_25, by(cz)
save "$INTDATA/census/education_1940", replace