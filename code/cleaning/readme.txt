Dear researcher,

You can find the housing supply data in Stata format in the companion file; including the geographic 
and regulatory variables, and calculated supply elasticities. 
The data covers 269 Metropolitan areas for which I have full information (using the 1999 
county-based MSA or NECMA definitions).

The geographic data, as described in the paper is calculated using the principal city in the 
MSA (the first one in the name list), so the information can be readily exported to other 
metropolitan area definitions. Please see paper and online appendix for details.

The slope and internal water shares are conditional on not being in the oceans or Great 
Lakes: the formula to calculate land unavailability in Stata is: gen unaval=1-
(((FLAT_SHARE_50_15/100)-lu11-lu92-lu91)*(S_LAND_50/100)).

Feel free to use and further disseminate the data at will. However, please do reference its 
provenance: Saiz, Albert (forthcoming) "The Geographic Determinants of Housing 
Supply;" Quarterly Journal of Economics.

Thank you for your interest in the data. I hope that this can be of use for your research.

Albert Saiz
Assistant Professor
The Wharton School
1466 Steinberg-Dietrich Hall
3620 Locust Walk
Philadelphia, PA 19104.6302
Tel. 215-898 28 59
saiz@wharton.upenn.edu
