********************************************************************************
* 6_check_merge.do
* Integrity check of the PODES 2005-2025 merge ($work/podes_05_25.dta). It uses
* the output files only (the merge is not rerun).
*
* Part 1. Zero loss (asserted). For each wave, a record is identified by its
*   content: the variables that come only from that wave's file (not in another
*   wave's file or in the crosswalks; id* and nm* excluded, because the merge
*   fills and recodes them).
*   (a) every record must appear on some row of podes_05_25 (no record lost);
*   (b) every row's data for the wave must equal one record (no row mixes
*       records).
*   Records dropped on purpose can be listed as exceptions (locals exc<wave>);
*   none at present.
* Part 2. Linkage report (counts and lists, no asserts):
*   (a) rows holding records of one wave only, by wave;
*   (b) rows holding a 2011 record and no 2008 or 2014-2025 record that have a
*       same-name 2014 village (exact 2012/2013/2014 code + name, else name in
*       the kecamatan, else name in the kabupaten);
*   (c) 2011 and 2008: rows holding a record whose name differs from all of the
*       row's own names while a record with one of the row's own names exists
*       in the kabupaten.
* Part 3. Shared codes: per wave, codes of podes_05_25 shared by rows with
*   different names.
*
* Output: $work/check_*.dta / .csv (see the locals below).
* Requires Stata 16 or later (frames). Paths: globals set in master.do.
********************************************************************************

clear all
set more off
set linesize 255

********************************************************************************
**# Settings
********************************************************************************

* Work in $work: file lists below are space-separated, so the paths in them
	* must not contain spaces (the folder names may)
local cwd "`c(pwd)'"
cd "$work"
local wd "."

* Merged data
local out "`wd'/podes_05_25.dta"

* Wave files (the 2005 wave is PODES 2005 + PODES 2005 Nias, appended in this
	* order, as in 4_merge_podes.do; "2010" is the SP2010 population file)
local waves 2005 2008 2010 2011 2014 2018 2019 2020 2021 2024 2025
local f2005 "`wd'/podes2005.dta `wd'/podes2005nias.dta"
local f2008 "`wd'/podes2008.dta"
local f2010 "`wd'/pop2010.dta"
foreach y in 2011 2014 2018 2019 2020 2021 2024 2025 {
	local f`y' "`wd'/podes`y'.dta"
}

* Crosswalks read by 4_merge_podes.do (their variables are not wave content)
local fcross "`wd'/cross_1998_2024.dta `wd'/cross_2024_2025.dta"

* Prefix of the report files
local rep "`wd'/check"

* Record code and name in each wave file (to identify records in the
	* reports), and the code and name of each wave in podes_05_25 (Part 3)
local recid2025 id2025
local recnm2025 nm2025
local recid2024 id2024_1
local recnm2024 nm2024_1
foreach y in 2021 2020 2019 2018 2011 {
	local recid`y' id`y'_1
	local recnm`y' nm`y'_1
}
local recid2014 id2014
local recnm2014 nm2014
local recid2010 id2010_1
local recnm2010 nm2010_1
local recid2008 id2008_2
local recnm2008 nm2008_2
local recid2005 id2005
local recnm2005 nm2005
foreach y of local waves {
	local outid`y' `recid`y''
	local outnm`y' `recnm`y''
}
local outid2008 id2008_1
local outnm2008 nm2008_1

* Exceptions: records dropped deliberately, as a condition on the wave file's
	* variables, e.g.
	* local exc2014 `"id2014 == 9108036004 & nm2014 == "YENSAWAI BARAT""'
	* None at present.

* Wave variables changed by 4_merge_podes.do after the wave is merged (they
	* would show as false losses, so they are left out of the record
	* content). None: after each merge only id*/nm* variables and merge
	* markers are recoded or filled.
local modified ""

********************************************************************************
**# Content variables of each wave
********************************************************************************

foreach y of local waves {
	local v`y'
	foreach f of local f`y' {
		qui describe using "`f'", varlist
		local tmp `r(varlist)'
		local v`y' : list v`y' | tmp
	}
}
local vcross
foreach f of local fcross {
	qui describe using "`f'", varlist
	local tmp `r(varlist)'
	local vcross : list vcross | tmp
}
qui describe using "`out'", varlist
local vout `r(varlist)'

foreach y of local waves {
	local others `vcross'
	foreach z of local waves {
		if `z' != `y' local others : list others | v`z'
	}
	local c`y' : list v`y' - others
	local c`y' : list c`y' & vout
	local c`y' : list c`y' - modified
	local tmp
	foreach v of local c`y' {
		if !inlist(substr("`v'", 1, 2), "id", "nm") local tmp `tmp' `v'
	}
	local c`y' `tmp'
	local n : word count `c`y''
	di as res "CONTENT `y': `n' variables"
}

********************************************************************************
**# Load the merged data
********************************************************************************

use "`out'", clear
gen long row = _n
local N = _N
di as res "podes_05_25: N = `N'"

********************************************************************************
**# Part 1: zero loss
********************************************************************************

local bad = 0
local first = 1
foreach y of local waves {

	* rows of podes_05_25 that hold data of this wave
	cap frame drop o
	frame put row `c`y'', into(o)
	frame o {
		egen int __nn = rownonmiss(`c`y''), strok
		qui keep if __nn > 0
		drop __nn
		gen byte src = 2
		local nrows = _N
		tempfile o`y'
		qui save `o`y''
	}

	* the wave's records
	cap frame drop w
	frame create w
	frame w {
		local k = 0
		foreach f of local f`y' {
			local ++k
			if `k' == 1 qui use "`f'", clear
			else qui append using "`f'"
		}
		gen long rec = _n
		local nrec = _N
		gen byte exc = 0
		if `"`exc`y''"' != "" {
			qui replace exc = (`exc`y'')
			qui count if exc
			if r(N) != 1 {
				di as err "exception for `y' matches " r(N) ///
					" records (expected 1)"
				local bad = 1
			}
		}

		* record code and name (reports)
		preserve
			keep rec `recid`y'' `recnm`y''
			rename (`recid`y'' `recnm`y'') (r_id r_nm)
			tempfile k`y'
			qui save `k`y''
		restore

		qui ds id* nm*
		keep rec exc `r(varlist)' `c`y''
		egen int __nn = rownonmiss(`c`y''), strok
		qui count if __nn == 0
		local nempty = r(N)
		gen byte src = 1
		qui append using `o`y''

		* records and rows with the same content
		bys `c`y'' (src): gen byte has1 = src[1] == 1
		by `c`y'': gen byte has2 = src[_N] == 2
		by `c`y'': egen int nrecs = total(src == 1)
		by `c`y'': gen long rec_m = rec[1] if has1
		qui count if src == 1 & nrecs > 1 & __nn > 0
		local ndup = r(N)

		* (a) lost records
		qui count if src == 1 & !has2 & __nn > 0
		local nlost = r(N)
		qui count if src == 1 & !has2 & __nn > 0 & exc
		local nlost_exc = r(N)
		qui count if src == 1 & has2 & exc
		local nexc_kept = r(N)
		* (b) rows whose data equal no record
		qui count if src == 2 & !has1
		local nmixed = r(N)

		di as res "WAVE `y': records `nrec' (no content `nempty';" ///
			" in duplicate tuples `ndup')" ///
			" | rows holding `nrows' | LOST `nlost'" ///
			" (exceptions `nlost_exc') | MIXED `nmixed'"
		if `nlost' - `nlost_exc' > 0 | `nmixed' > 0 local bad = 1
		if `nexc_kept' > 0 {
			di as txt "  note: the `y' exception record is not lost"
		}

		preserve
			qui keep if src == 1 & !has2 & __nn > 0
			gen wave = `y'
			qui ds id* nm*
			keep wave rec exc `r(varlist)'
			if `first' == 0 qui append using `lost'
			else tempfile lost
			qui save `lost', replace
		restore
		preserve
			qui keep if src == 2 & !has1
			gen wave = `y'
			keep wave row
			if `first' == 0 qui append using `mixed'
			else tempfile mixed
			qui save `mixed', replace
		restore
		local first = 0

		* row -> record held (the first record if several have the same
		* content)
		qui keep if src == 2 & has1
		gen byte amb`y' = nrecs > 1
		rename rec_m rec`y'
		keep row rec`y' amb`y'
		tempfile map`y'
		qui save `map`y''
	}
}
frame drop o
frame drop w

* Lists
preserve
	use `lost', clear
	order wave rec exc
	sort wave rec
	qui save "`rep'_lost.dta", replace
	di as res "LOST records (all waves): " _N
	qui count if !exc
	di as res "  of which not documented exceptions: " r(N)
	list wave rec exc if _n <= 50, noobs clean
	use `mixed', clear
	sort wave row
	qui save "`rep'_mixed.dta", replace
	di as res "MIXED rows (all waves): " _N
	if _N > 0 list wave row if _n <= 50, noobs clean
restore

if `bad' {
	di as err "FAIL: records lost or rows mixed" ///
		" (see $work/check_lost.dta, $work/check_mixed.dta)"
	cd "`cwd'"
	exit 9
}
di as res "PASS: zero loss (exceptions only) and no mixed rows"

********************************************************************************
**# Part 2: linkage report
********************************************************************************

* Rows of podes_05_25 with the record each holds per wave
keep row id* nm*
foreach y of local waves {
	qui merge 1:1 row using `map`y'', keep(master match) nogenerate
	rename rec`y' rec
	qui merge m:1 rec using `k`y'', keep(master match) nogenerate
	rename (rec r_id r_nm) (rec`y' r`y'_id r`y'_nm)
}
* waves held, in the order 2025 ... 2005
gen str11 wpat = ""
foreach y in 2025 2024 2021 2020 2019 2018 2014 2011 2010 2008 2005 {
	qui replace wpat = wpat + cond(mi(rec`y'), ".", "x")
}
egen byte nw = rownonmiss(rec*)
format %10.0f id* r*_id
qui save "`rep'_rows.dta", replace

* Name normalization: upper case, letters and digits only
cap program drop normnm
program define normnm
	args new old
	gen `new' = ustrregexra(ustrupper(`old'), "[^A-Z0-9]", "")
end

* (a) rows holding records of one wave only
di as res _n "PART 2a: rows holding records of one wave only"
foreach y of local waves {
	qui count if nw == 1 & !mi(rec`y')
	di as res "  ONEWAVE `y': " r(N)
}
qui count if nw == 0
di as res "  rows holding no record: " r(N)
preserve
	qui keep if nw <= 1
	gen wave = .
	foreach y of local waves {
		qui replace wave = `y' if !mi(rec`y')
	}
	gen rec = .
	gen r_id = .
	gen r_nm = ""
	foreach y of local waves {
		qui replace rec = rec`y' if wave == `y'
		qui replace r_id = r`y'_id if wave == `y'
		qui replace r_nm = r`y'_nm if wave == `y'
	}
	keep row wave rec r_id r_nm id2025 nm2025 id2024_1 nm2024_1 id2014 ///
		nm2014 id2011_1 nm2011_1 id2008_1 nm2008_1 id2005 nm2005
	order row wave rec r_id r_nm
	sort wave r_id
	format %10.0f r_id id*
	qui export delimited using "`rep'_onewave.csv", replace
restore

* (b) rows holding a 2011 record and no 2008 or 2014-2025 record, and a 2014
	* village with the same name
di as res _n "PART 2b: 2011 records without a 2008 or 2014-2025 partner"
* keys of the rows holding a 2014 record
preserve
	qui keep if !mi(rec2014)
	tempfile L
	qui save `L'
	local k = 0
	tempfile Kx
	foreach p in 2012_1 2013_1 2014 {
		use id`p' nm`p' using `L', clear
		rename (id`p' nm`p') (code nmx)
		local ++k
		if `k' > 1 qui append using `Kx'
		qui save `Kx', replace
	}
	normnm n nmx
	qui drop if mi(code) | n == ""
	keep code n
	qui duplicates drop
	qui save `Kx', replace
	use id2014 nm2014 row using `L', clear
	normnm n nm2014
	gen double kec = floor(id2014/1000)
	gen double kab = floor(id2014/1000000)
	bys kec n: gen int ncand_kec = _N
	bys kab n: gen int ncand_kab = _N
	tempfile L14
	qui save `L14'
	keep kec n ncand_kec
	qui duplicates drop
	tempfile Kk
	qui save `Kk'
	use `L14', clear
	keep kab n ncand_kab
	qui duplicates drop
	tempfile Kb
	qui save `Kb'
restore
preserve
	egen byte __later = rownonmiss(rec2008 rec2014 rec2018 rec2019 ///
		rec2020 rec2021 rec2024 rec2025)
	qui keep if !mi(rec2011) & __later == 0
	di as res "  rows: " _N
	normnm n r2011_nm
	gen double code = r2011_id
	gen double kec = floor(r2011_id/1000)
	gen double kab = floor(r2011_id/1000000)
	qui merge m:1 code n using `Kx', keep(master match) gen(m_exact)
	qui merge m:1 kec n using `Kk', keep(master match) gen(m_kec)
	qui merge m:1 kab n using `Kb', keep(master match) gen(m_kab)
	gen cand = cond(m_exact == 3, "1 exact code+name (2012/2013/2014)", ///
		cond(m_kec == 3, "2 same name, same kec (2014)", ///
		cond(m_kab == 3, "3 same name, same kab (2014)", "4 no candidate")))
	tab cand
	qui count if m_kab == 3 | m_kec == 3 | m_exact == 3
	di as res "  ONLY2011 with a same-name 2014 village in the kab: " r(N)
	keep row wpat r2011_id r2011_nm cand ncand_kec ncand_kab id2011_1 ///
		nm2011_1 id2005 nm2005
	sort cand r2011_id
	list r2011_id r2011_nm wpat cand ncand_kab ///
		if substr(cand, 1, 1) != "4", noobs clean
	qui export delimited using "`rep'_only2011.csv", replace
restore

* (c) rows holding a record whose name differs from all of the row's own
	* names while a record with one of the row's own names exists in the
	* kabupaten
local own2011 nm2011_1 nm2011_2 nm2014
local kid2011 id2011_1
local own2008 nm2008_1 nm2008_2 nm2011_1
local kid2008 id2008_2
foreach y in 2011 2008 {
	di as res _n "PART 2c: `y'"
	* holders of each record (code, name, 2014 name, waves held)
	preserve
		qui keep if !mi(rec`y')
		keep rec`y' nm2014 wpat
		gen h = "[" + nm2014 + " " + wpat + "]"
		bys rec`y' (h): gen strL holders = h if _n == 1
		by rec`y': replace holders = holders[_n-1] + " ; " + h if _n > 1
		by rec`y': keep if _n == _N
		keep rec`y' holders
		rename rec`y' orec
		tempfile H
		qui save `H'
	restore
	* records of the wave by kabupaten and normalized name
	preserve
		use `k`y'', clear
		normnm n r_nm
		gen double kab = floor(r_id/1000000)
		rename (rec r_id r_nm) (orec o_id o_nm)
		keep kab n orec o_id o_nm
		tempfile P
		qui save `P'
	restore
	preserve
		qui keep if !mi(rec`y')
		normnm rn r`y'_nm
		gen byte differs = rn != ""
		local j = 0
		foreach o of local own`y' {
			local ++j
			normnm o`j' `o'
			qui replace differs = 0 if o`j' == rn
		}
		qui keep if differs
		gen double kab1 = floor(`kid`y''/1000000)
		qui replace kab1 = floor(r`y'_id/1000000) if mi(kab1)
		gen double kab2 = floor(r`y'_id/1000000)
		gen own = ""
		foreach o of local own`y' {
			qui replace own = own + cond(own == "", "", " / ") + `o' ///
				if `o' != "" & ///
				strpos(" / " + own + " / ", " / " + `o' + " / ") == 0
		}
		keep row rec`y' r`y'_id r`y'_nm own o1-o`j' kab1 kab2 wpat id2014 ///
			`kid`y''
		qui reshape long o, i(row) j(k)
		qui drop if o == ""
		drop k
		qui duplicates drop row o, force
		qui reshape long kab, i(row o) j(kk)
		drop kk
		qui duplicates drop row o kab, force
		rename o n
		qui joinby kab n using `P'
		qui merge m:1 orec using `H', keep(master match) nogenerate
		qui replace holders = "nobody" if mi(holders)
		gen holds = string(r`y'_id, "%10.0f") + " " + r`y'_nm
		gen ownrec = string(o_id, "%10.0f") + " " + o_nm
		keep row `kid`y'' own id2014 holds wpat ownrec holders
		qui duplicates drop row ownrec, force
		order row `kid`y'' own id2014 holds wpat ownrec holders
		sort `kid`y'' row
		bys row: gen byte first = _n == 1
		qui count if first
		di as res "  NAMEDIFF `y': rows " r(N) ", row-record pairs " _N
		drop first
		format %10.0f `kid`y'' id2014
		list, noobs clean
		qui export delimited using "`rep'_namediff_`y'.csv", replace
	restore
}

********************************************************************************
**# Part 3: codes shared by rows with different names
********************************************************************************

di as res _n "PART 3: codes shared by rows with different names"
local first = 1
foreach y of local waves {
	local i `outid`y''
	local n `outnm`y''
	preserve
		qui keep if !mi(`i')
		bys `i' (`n'): gen byte shared = `n'[1] != `n'[_N]
		normnm nn `n'
		bys `i' (nn): gen byte shared_n = nn[1] != nn[_N]
		qui count if shared
		local r = r(N)
		bys `i': gen byte g = _n == 1 & shared
		qui count if g
		local c = r(N)
		qui count if shared_n
		local rn = r(N)
		qui count if g & shared_n
		di as res "  SHARED `i' (`n'): rows `r', codes `c'" ///
			" | after name normalization: rows `rn', codes " r(N)
		qui keep if shared
		gen wave = `y'
		gen double code = `i'
		gen name = `n'
		gen rec = rec`y'
		gen r_nm = r`y'_nm
		keep wave code name shared_n row rec r_nm wpat id2014 nm2014 ///
			id2025 nm2025
		if `first' == 0 qui append using `shared'
		else tempfile shared
		qui save `shared', replace
		local first = 0
	restore
}
preserve
	use `shared', clear
	sort wave code name
	format %10.0f code id*
	qui export delimited using "`rep'_shared.csv", replace
restore

cd "`cwd'"
di as res _n "DONE"
