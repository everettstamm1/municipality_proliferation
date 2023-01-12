capture program drop gz7
program define gz7

	// Program to open gzip files directly for windows users, as gzuse isn't working as of 05.17.2022
	// Requires 7-Zip to be installed and 7z.exe to be added to system path.
	// https://www.7-zip.org/download.html
	// Also allows option to use gzuse from package gzsave, to keep code concise

	syntax, filepath(string) filename(string) [gzuse(integer $use_gzuse)]


	if `gzuse'==1{
		cap gzuse "`filepath'/`filename'", clear
		if _rc==601{
			exit _rc
		}
		else if _rc==199{
			di "You have not installed gzsave, please do so by running "ssc install gzsave" and completing any additional setup."
		}
		else if _rc>0{
			di "Something went wrong running gzuse. Review your installation of gzsave.
		}
	}
	else{

		local working_directory : pwd
		cd "`filepath'"

		!7z.exe x "`filename'" -so > "uncompressed.dta"
		
		cap use uncompressed.dta, clear
		
		if _rc>0{
			di "Something went wrong unzipping `filename' from the command line. Review your 7-Zip setup."
			erase uncompressed.dta
			cd "`working_directory'"
			exit _rc
		}
		else{
			erase uncompressed.dta
			cd "`working_directory'"
		}
	}
end

