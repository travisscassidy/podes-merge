********************************************************************************
* BPS-Kemendagri village code correspondence (2020 semester 2)
	* Official BPS correspondence (sig.bps.go.id), plus the author's
	* manual additions and corrections. First part of the author's
	* merge_dd_pop.do.
********************************************************************************

clear all
set more off 

* Paths: globals set in master.do
local cross_folder "$cross/bps_kemendagri"

********************************************************************************
* Supplemental BPS-MoHA Code Correspondence Manually Created by TC
	* Covers the villages that are missing in the official correspondence
********************************************************************************

import excel "`cross_folder'/manual_cross_kb_vlg.xlsx", clear firstrow
	
format %10.0f kode*
format %25s kec_dagri nama_*

tempfile manual_cross_kb_vlg
save `manual_cross_kb_vlg'

********************************************************************************
* Corrections to BPS-MoHA Code Correspondence, Created by TC
********************************************************************************

import excel "`cross_folder'/corrections_cross_kb_vlg.xlsx", clear firstrow
	
format %10.0f kode*
format %25s nama_*

tempfile corrections_cross_kb_vlg
save `corrections_cross_kb_vlg'
	
********************************************************************************
* Open and Clean BPS-MoHA Code Correspondence 
	* Will be needed to merge DD/pop data with PODES and lights data
	* Codes are for 2020 semester 2
********************************************************************************

** Province, District, Subdistrict **

foreach r in kec kab prov {

	import delimited "`cross_folder'/cross_kb_`r'", ///
		clear varnames(1) stringcols(_all) bindquote(strict)
			
	replace kode_dagri = subinstr(kode_dagri,".","",.)
	replace kode_dagri = "" if kode_dagri == "-"
	destring kode*, replace
	foreach x in bps dagri {
		ren nama_`x' `r'_`x'
		ren kode_`x' `r'_id_`x'	
	}

	tempfile cross_kb_`r'
	save `cross_kb_`r''

}

** Village **

local folder "`cross_folder'/bydistrict"

local files: dir "`folder'" files "*.csv"

local i = 0

* Save district-specific datasets

foreach f of local files {
	
	local ++ i
	
	import delimited "`cross_folder'/bydistrict/`f'", ///
		clear varnames(1) stringcols(_all) bindquote(strict)
		
	tempfile temp`i'
	save `temp`i''	
		
}

* Combine datasets
use `temp1', clear
forval k = 2/`i' {
	append using `temp`k''
}

* Fix codes
replace kode_dagri = subinstr(kode_dagri,".","",.)
destring kode_*, replace
format %10.0f kode_*

* Tidy names
replace nama_bps = strupper(strtrim(stritrim(nama_bps)))
replace nama_dagri = strupper(strtrim(stritrim(nama_dagri)))

* Line breaks, invalid UTF-8 bytes, and double quotes used as apostrophes
foreach v of varlist nama_bps nama_dagri {
	replace `v' = subinstr(`v', char(10), " ", .)
	replace `v' = subinstr(`v', char(13), " ", .)
	replace `v' = ustrfix(`v', "'")
	replace `v' = strtrim(stritrim(`v'))
}

* Add province, district, subdistrict codes and names

gen kec_id_bps  = floor(kode_bps/(10^3))
gen kab_id_bps  = floor(kode_bps/(10^6))
gen prov_id_bps = floor(kode_bps/(10^8))

foreach r in kec kab prov {
	merge m:1 `r'_id_bps using `cross_kb_`r''
		assert _merge != 1
		drop if _merge == 2
		drop _merge 
}	

* Tidy
format %25s nama*
order prov_id_bps prov_bps prov_id_dagri prov_dagri kab_id_bps kab_bps ///
	  kab_id_dagri kab_dagri kec_id_bps kec_bps kec_id_dagri kec_dagri
	  
* Append manual crosswalk
append using `manual_cross_kb_vlg'

* Merge in corrections
merge 1:1 kode_dagri using `corrections_cross_kb_vlg', update replace
	assert _merge != 2
	drop _merge

* Fill in missing subdistrict info for appended villages
sort kode_dagri
replace kab_id_dagri = floor(kode_dagri/(10^6)) if mi(kab_id_dagri)
replace kec_id_dagri = floor(kode_dagri/(10^4)) if mi(kec_id_dagri)
forval i = 1/10 {
	di ""
	di "`i'"
	di ""
	foreach x in kec kab {
		replace `x'_dagri = `x'_dagri[_n-1] ///
			if mi(`x'_dagri) & `x'_id_dagri == `x'_id_dagri[_n-1]
		replace `x'_dagri = `x'_dagri[_n+1] ///
			if mi(`x'_dagri) & `x'_id_dagri == `x'_id_dagri[_n+1]
	}	
}

* Prep for merge with pop/DD/PODES
gen double id_merge = kode_dagri
format %10.0f id_merge
gen desa_merge = nama_dagri
gen idusing = _n

* Harmonize names for merge
replace desa_merge = "PEA JAMBU" ///
	if desa_merge == "MUKTI LINCIR" & id_merge == 1110092009
replace desa_merge = "3 / 4 ULU" ///
	if desa_merge == "3/4 ULU" & id_merge == 1671021004
replace desa_merge = "36 ILIR" ///
	if desa_merge == "ILIR" & id_merge == 1671121003
replace desa_merge = "PAL 30" ///
	if desa_merge == "PAL" & id_merge == 1703102014	
replace desa_merge = "LAHONTOHE" ///
	if desa_merge == "LAMORENDE" & id_merge == 7403272003
replace desa_merge = "LAMORENDE" ///
	if desa_merge == "LAGHONTOGHE" & id_merge == 7403272004
replace desa_merge = "MEYANO DAS" ///
	if desa_merge == "MEYANO DAS (MEYANO RAYA)" & id_merge == 8103082003
	
* Save
drop idusing
compress
save "$work/cross_bps_kemendagri_2020.dta", replace
