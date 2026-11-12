********************************************************************************
* PODES Merge: master do-file
*
* Builds the village crosswalks and merges PODES 2005-2025 into one file with
* one row per village lineage (work/podes_05_25.dta). See README.txt.
*
* Set the two paths below, then run this file. Everything else is relative to
* them. Requires Stata 16 or later.
********************************************************************************

clear all
set more off
if c(stata_version) < 16 {
	di as err "Stata 16 or later is required"
	exit 198
}

********************************************************************************
* 1. Paths (edit these two lines)
********************************************************************************

* Folder that contains this file
global root "C:/Users/yourname/PODES Merge"

* Folder with the PODES data purchased from BPS, one subfolder per wave named
	* as in README.txt ("PODES 2005", "PODES 2005 Nias", "PODES 2008", ...)
global podes_raw "$root/podes_raw"

********************************************************************************
* 2. Other folders (no need to edit)
********************************************************************************

global main   "$root/dofiles_main"
global aux    "$root/dofiles_aux"
global cross  "$root/crosswalks"
global names  "$root/names"
global census "$root/census"
global work   "$root/work"
global temp   "$root/temp"

cap mkdir "$work"
cap mkdir "$temp"

********************************************************************************
* 3. User-written command: reclink2 (Wasi and Flaaen 2015, Stata Journal)
********************************************************************************

cap which reclink2
if _rc {
	net install dm0082, from("http://www.stata-journal.com/software/sj15-3")
}

********************************************************************************
* 4. Run
********************************************************************************

cap log close master
log using "$work/master.log", replace text name(master)

* District crosswalk 1990-2014 (work/district_cross_1990_2014.dta)
do "$main/1_clean_district_cross.do"

* SP2010 village population (work/pop2010.dta)
do "$main/2_clean_pop2010.do"

* PODES waves (work/podesYYYY.dta)
do "$main/3_clean_podes.do"

* Crosswalks (work/cross_*.dta) and the merge (work/podes_05_25.dta)
do "$main/4_merge_podes.do"

* BPS-Kemendagri village codes (work/cross_bps_kemendagri_2020.dta)
do "$main/5_link_bps_kemendagri.do"

* Integrity check of the merge (work/check_*)
do "$main/6_check_merge.do"

log close master
