********************************************************************************
* import_output.do
* Unzips output/output_csv.zip and saves each .csv file as a Stata .dta file
* in the output folder. Needs no PODES data.
********************************************************************************

clear all
set more off

* Folder that contains master.do (skip if master.do has set it)
if "$root" == "" global root "C:/Users/yourname/PODES Merge"

local cwd "`c(pwd)'"
cd "$root/output"
unzipfile "output_csv.zip", replace

foreach f in podes_lineage_2005_2025 cross_1998_2024 cross_2024_2025 ///
	cross_bps_kemendagri_2020 moha_lineage_2016_2025 {
	import delimited using "`f'.csv", clear varnames(1) case(preserve) ///
		bindquote(strict) maxquotedrows(unlimited) ///
		encoding("utf-8")
	* show codes with all digits
	foreach v of varlist _all {
		cap confirm numeric variable `v'
		if !_rc format `v' %15.0g
	}
	compress
	save "`f'.dta", replace
}

cd "`cwd'"
