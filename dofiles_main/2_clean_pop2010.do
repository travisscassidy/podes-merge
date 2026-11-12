********************************************************************************
* Cleans Village Population from 2010 Census 
********************************************************************************

clear all
set more off 

* Paths: globals set in master.do

tempfile p1 p2 p3 p4 p5

********************************************************************************
* PART 1
********************************************************************************

import excel "$census/pop_village_2010_part1.xlsx", clear 

qui tostring *, replace

foreach v of varlist * {
	qui replace `v' = "" if `v' == "."
}

local i = 0
foreach v of varlist * {
	local ++i
	qui ren `v' v`i'
}
local last = `i'

gen province = ""
gen region   = ""
gen kec      = ""
gen desa     = ""
gen pop		 = ""

forval n = `last'(-1)1 {
	qui replace pop = v`n' if mi(pop)
}
gen byte notnumeric = real(pop) == .
replace pop = "" if notnumeric
destring pop, replace
drop notnumeric

forval n = `last'(-1)1 {
	qui replace desa = v`n' if mi(desa) & strpos(v`n',"]") == 5
	qui replace kec = v`n' if mi(kec) & desa != v`n' & strpos(v`n',"]") == 5
	qui replace region = v`n' if mi(region) & kec != v`n' ///
		& strpos(v`n',"]") == 4
	qui replace province = v`n' if mi(province) & region != v`n' ///
		& strpos(v`n',"]") == 4
}

* Trim end spaces (if any)

foreach v in province region kec desa {
	qui replace `v' = strtrim(`v')
}

* Remove carriage returns

replace desa = subinstr(desa,char(10),"",.)

* Checking for missing village names

count if mi(desa)

* Fixing village names

replace desa = "[008] UPT SP III KOTO TENGAH/ KEPENUHAN MAKMUR" ///
	if mi(desa) & ///
	desa[_n-1] == "[007] KEPENUHAN BARU[008] UPT SP III KOTO TENGAH/ KEPENUHAN"

replace desa = "[007] KEPENUHAN BARU" ///
	if desa == "[007] KEPENUHAN BARU[008] UPT SP III KOTO TENGAH/ KEPENUHAN"	

replace desa = "[011] UPT SP IV KOTO TENGAH/KEPENUHAN MULYA" if mi(desa) & ///
	desa[_n-1] == "[010] KEPENUHAN HILIR[011] UPT SP IV KOTO TENGAH/KEPENUHAN"
	
replace	desa = "[010] KEPENUHAN HILIR" ///
	if desa == "[010] KEPENUHAN HILIR[011] UPT SP IV KOTO TENGAH/KEPENUHAN"
	
replace desa = "[012] UPT SP V KOTO TENGAH/KEPENUHAN SEJATI" if mi(desa) & ///
	desa[_n-1] == "[011] UPT SP IV KOTO TENGAH/KEPENUHAN MULYA"

replace desa = "[018] KEPENUHAN BARAT SUNGAI ROKAN JAYA" if mi(desa) & ///
   desa[_n-1] == "[017] KEPENUHAN BARAT MULYA[018] KEPENUHAN BARAT SUNGAI ROKAN"
	
replace desa = "[017] KEPENUHAN BARAT MULYA" ///
	if desa == "[017] KEPENUHAN BARAT MULYA[018] KEPENUHAN BARAT SUNGAI ROKAN"
	
replace desa = "[047] KELURAHAN PASAR BARU RANTAU PANJANG" if mi(desa) & ///
	desa[_n-1] == "[046] LUBUK NAPAL[047] KELURAHAN PASAR BARU RANTAU"
	
replace desa = "[046] LUBUK NAPAL" ///
	if desa == "[046] LUBUK NAPAL[047] KELURAHAN PASAR BARU RANTAU"

count if mi(desa)

drop if mi(pop)

count if mi(desa)

* Various checks

count if substr(desa,1,5) == "[001]" & mi(kec) 
count if substr(kec,1,4) == "[01]" & mi(region)
count if substr(region,1,4) == "[01]" & mi(province)

* Fixing other names

replace kec = "[051] PADANGSIDIMPUAN ANGKOLA JULU" if mi(kec) & ///
	desa == "[001] SIMATOHIR"
	
replace kec = "[010] GUNUNGSITOLI IDANOI" if mi(kec) & ///
	desa == "[001] HILIMBOWO IDANOI" 
	
replace region = "[78] GUNUNGSITOLI" if mi(region) & ///
	desa == "[001] HILIMBOWO IDANOI" 

* Count occurrences of [ ] to check whether names have been combined 

foreach v in desa kec region province {
	gen n_lbrack_`v' = length(`v') - length(subinstr(`v',"[","",.)) if !mi(`v')
	gen n_rbrack_`v' = length(`v') - length(subinstr(`v',"]","",.)) if !mi(`v')
}

keep province region kec desa pop

save `p1'

********************************************************************************
* PART 2
********************************************************************************

import excel "$census/pop_village_2010_part2.xlsx", clear 

qui tostring *, replace

foreach v of varlist * {
	qui replace `v' = "" if `v' == "."
}

local i = 0
foreach v of varlist * {
	local ++i
	qui ren `v' v`i'
}
local last = `i'

gen province = ""
gen region   = ""
gen kec      = ""
gen desa     = ""
gen pop		 = ""

forval n = `last'(-1)1 {
	qui replace pop = v`n' if mi(pop)
}
gen byte notnumeric = real(pop) == .
replace pop = "" if notnumeric
destring pop, replace
drop notnumeric

forval n = `last'(-1)1 {
	qui replace desa = v`n' if mi(desa) & strpos(v`n',"]") == 5
	qui replace kec = v`n' if mi(kec) & desa != v`n' & strpos(v`n',"]") == 5
	qui replace region = v`n' if mi(region) & kec != v`n' ///
		& strpos(v`n',"]") == 4
	qui replace province = v`n' if mi(province) & region != v`n' ///
		& strpos(v`n',"]") == 4
}

* Trim end spaces (if any)

foreach v in province region kec desa {
	qui replace `v' = strtrim(`v')
}

* Remove carriage returns

replace desa = subinstr(desa,char(10),"",.)

* Checking for missing village names

count if mi(desa)

count if desa == "[001] PANGKAL MAS MULYA"

* Fixing names

replace kec = "[060] MESUJI TIMUR" if mi(kec) & ///
	desa == "[001] PANGKAL MAS MULYA"

replace kec = "[070] RAWAJITU UTARA" if mi(kec) & ///	
	desa == "[001] SIDANG GUNUNG TIGA"

replace kec = "[010] TULANG BAWANG UDIK" if mi(kec) & ///
	desa == "[010] MARGA KENCANA"

replace region = "[12] TULANG BAWANG BARAT" if mi(region) & ///
	desa == "[010] MARGA KENCANA"	
	
count if mi(desa)

drop if mi(pop)

count if mi(desa)

* Various checks

count if substr(desa,1,5) == "[001]" & mi(kec) // 0
count if substr(kec,1,4) == "[01]" & mi(region)
count if substr(region,1,4) == "[01]" & mi(province)	
	
* Count occurrences of [ ] to check whether names have been combined 

foreach v in desa kec region province {
	gen n_lbrack_`v' = length(`v') - length(subinstr(`v',"[","",.)) if !mi(`v')
	gen n_rbrack_`v' = length(`v') - length(subinstr(`v',"]","",.)) if !mi(`v')
}

replace province = "[19] KEPULAUAN BANGKA BELITUNG" if ///
	region == "[19] KEPULAUAN BANGKA BELITUNG    [01] BANGKA"

replace region = "[01] BANGKA" if ///
	region == "[19] KEPULAUAN BANGKA BELITUNG    [01] BANGKA"

keep province region kec desa pop

save `p2'

********************************************************************************
* PART 3
********************************************************************************

import excel "$census/pop_village_2010_part3.xlsx", clear 

qui tostring *, replace

foreach v of varlist * {
	qui replace `v' = "" if `v' == "."
}

local i = 0
foreach v of varlist * {
	local ++i
	qui ren `v' v`i'
}
local last = `i'

gen province = ""
gen region   = ""
gen kec      = ""
gen desa     = ""
gen pop		 = ""

forval n = `last'(-1)1 {
	qui replace pop = v`n' if mi(pop)
}
gen byte notnumeric = real(pop) == .
replace pop = "" if notnumeric
destring pop, replace
drop notnumeric

forval n = `last'(-1)1 {
	qui replace desa = v`n' if mi(desa) & strpos(v`n',"]") == 5
	qui replace kec = v`n' if mi(kec) & desa != v`n' & strpos(v`n',"]") == 5
	qui replace region = v`n' if mi(region) & kec != v`n' ///
		& strpos(v`n',"]") == 4
	qui replace province = v`n' if mi(province) & region != v`n' ///
		& strpos(v`n',"]") == 4
}

* Trim end spaces (if any)

foreach v in province region kec desa {
	qui replace `v' = strtrim(`v')
}

* Remove carriage returns

replace desa = subinstr(desa,char(10),"",.)

* Checking for missing village names

count if mi(desa)

* Various checks

count if substr(desa,1,5) == "[001]" & mi(kec) // 0
count if substr(kec,1,4) == "[01]" & mi(region)
count if substr(region,1,4) == "[01]" & mi(province)

* Count occurrences of [ ] to check whether names have been combined 

foreach v in desa kec region province {
	gen n_lbrack_`v' = length(`v') - length(subinstr(`v',"[","",.)) if !mi(`v')
	gen n_rbrack_`v' = length(`v') - length(subinstr(`v',"]","",.)) if !mi(`v')
}

keep province region kec desa pop

save `p3'

********************************************************************************
* PART 4
********************************************************************************

import excel "$census/pop_village_2010_part4.xlsx", clear 

qui tostring *, replace

foreach v of varlist * {
	qui replace `v' = "" if `v' == "."
}

local i = 0
foreach v of varlist * {
	local ++i
	qui ren `v' v`i'
}
local last = `i'

gen province = ""
gen region   = ""
gen kec      = ""
gen desa     = ""
gen pop		 = ""

forval n = `last'(-1)1 {
	qui replace pop = v`n' if mi(pop)
}
gen byte notnumeric = real(pop) == .
replace pop = "" if notnumeric
destring pop, replace
drop notnumeric

forval n = `last'(-1)1 {
	qui replace desa = v`n' if mi(desa) & strpos(v`n',"]") == 5
	qui replace kec = v`n' if mi(kec) & desa != v`n' & strpos(v`n',"]") == 5
	qui replace region = v`n' if mi(region) & kec != v`n' ///
		& strpos(v`n',"]") == 4
	qui replace province = v`n' if mi(province) & region != v`n' ///
		& strpos(v`n',"]") == 4
}

* Trim end spaces (if any)

foreach v in province region kec desa {
	qui replace `v' = strtrim(`v')
}

* Remove carriage returns

replace desa = subinstr(desa,char(10),"",.)

* Checking for missing village names

count if mi(desa)

* Various checks

count if substr(desa,1,5) == "[001]" & mi(kec)
count if substr(kec,1,4) == "[01]" & mi(region)
count if substr(region,1,4) == "[01]" & mi(province)

* Fixing other names

replace kec = "[040] TANIMBAR SELATAN" if mi(kec) & ///
	region == "[01] MALUKU TENGGARA BARAT     [040] TANIMBAR SELATAN"

replace region = "[01] MALUKU TENGGARA BARAT" if ///
	region == "[01] MALUKU TENGGARA BARAT     [040] TANIMBAR SELATAN"
	
* Count occurrences of [ ] to check whether names have been combined 

foreach v in desa kec region province {
	gen n_lbrack_`v' = length(`v') - length(subinstr(`v',"[","",.)) if !mi(`v')
	gen n_rbrack_`v' = length(`v') - length(subinstr(`v',"]","",.)) if !mi(`v')
}

keep province region kec desa pop

save `p4'	

** PART 5 ** 

import excel "$census/pop_village_2010_part5.xlsx", clear 

qui tostring *, replace

foreach v of varlist * {
	qui replace `v' = "" if `v' == "."
}

local i = 0
foreach v of varlist * {
	local ++i
	qui ren `v' v`i'
}
local last = `i'

gen province = ""
gen region   = ""
gen kec      = ""
gen desa     = ""
gen pop		 = ""

forval n = `last'(-1)1 {
	qui replace pop = v`n' if mi(pop)
}
gen byte notnumeric = real(pop) == .
replace pop = "" if notnumeric
destring pop, replace
drop notnumeric

forval n = `last'(-1)1 {
	qui replace desa = v`n' if mi(desa) & strpos(v`n',"]") == 5
	qui replace kec = v`n' if mi(kec) & desa != v`n' & strpos(v`n',"]") == 5
	qui replace region = v`n' if mi(region) & kec != v`n' ///
		& strpos(v`n',"]") == 4
	qui replace province = v`n' if mi(province) & region != v`n' ///
		& strpos(v`n',"]") == 4
}

* Trim end spaces (if any)

foreach v in province region kec desa {
	qui replace `v' = strtrim(`v')
}

* Remove carriage returns

replace desa = subinstr(desa,char(10),"",.)

* Checking for missing village names

count if mi(desa)

* Fixing missing pop observations

replace pop = 99 if mi(pop) & ///
	desa == "[008] BOMBERAY VII (UPT) / WONODADI                                  99"

replace pop = 263 if mi(pop) & ///
	desa == "[050] WINDESI                                             [002] YOPMEOS                                                                             263"

replace pop = 443 if mi(pop) & ///	
	desa == "[003] WAMESA TENGAH                                                              443"

* Fixing names

replace desa = "[008] BOMBERAY VII (UPT) / WONODADI MULYA" if ///
	desa == "[008] BOMBERAY VII (UPT) / WONODADI                                  99"
	
replace desa = "[007] BOMBERAY  VI (UPT) / BUMI MUROH INDAH" if ///
	desa == "[007] BOMBERAY  VI (UPT) / BUMI MUROH"	
	
replace kec = "[050] WINDESI" if mi(kec) & ///
	desa == "[050] WINDESI                                             [002] YOPMEOS                                                                             263"
	
replace desa = "[002] YOPMEOS" if ///
	desa == "[050] WINDESI                                             [002] YOPMEOS                                                                             263"

replace desa = "[003] WAMESA TENGAH" if ///
	desa == "[003] WAMESA TENGAH                                                              443"
	
count if mi(pop)

drop if mi(pop)

count if mi(desa)

* Various checks

count if substr(desa,1,5) == "[001]" & mi(kec) // 0
count if substr(kec,1,4) == "[01]" & mi(region)
count if substr(region,1,4) == "[01]" & mi(province)

* Count occurrences of [ ] to check whether names have been combined 

foreach v in desa kec region province {
	gen n_lbrack_`v' = length(`v') - length(subinstr(`v',"[","",.)) if !mi(`v')
	gen n_rbrack_`v' = length(`v') - length(subinstr(`v',"]","",.)) if !mi(`v')
}

keep province region kec desa pop

save `p5'

use `p1', clear
forval n = 2/5 {
	append using `p`n''
}

gen prov_id = substr(province,2,2)
destring prov_id, replace

gen region_id = substr(region,2,2)
destring region_id, replace

gen kec_id = substr(kec,2,3)
destring kec_id, replace

gen desa_id = substr(desa,2,3)
destring desa_id, replace

replace province = substr(province,6,.)
replace region = substr(region,6,.)
replace kec = substr(kec,7,.)
replace desa = substr(desa,7,.)

foreach v in prov_id province region_id region kec_id kec {
	qui replace `v' = `v'[_n-1] if mi(`v')
}

* Tyding

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

* For crosswalk

foreach v in nm2010_1 nm2010_2 nm_rd2010 nm_sp2010 {
	gen `v' = desa
}

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2010_1 id2010_2 id_rd2010 id_sp2010 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

* Fix codes that were swapped

foreach v of varlist id2010_1 {
	recode `v' (7401121004 = 7401121008) (7401121008 = 7401121004) ///
			   (7605031001 = 7605031003) (7605031003 = 7605031001) ///
			   (9417011007 = 9417011008) (9417011008 = 9417011007) ///
			   (9417021007 = 9417021006) (9417021011 = 9417021010) ///
			   (9417021010 = 9417021008) (9417021008 = 9417021007) ///
			   (9417021009 = 9417021011) ///
			   (9417013002 = 9417013004) (9417013004 = 9417013002) ///
			   (9417013003 = 9417013005) (9417013005 = 9417013003) ///
			   (9417022006 = 9417022009) (9417022009 = 9417022012) ///
			   (9417022012 = 9417022013) (9417022013 = 9417022014) ///
			   (9417022014 = 9417022003) (9417022003 = 9417022006) ///
			   (9417022007 = 9417022010) (9417022010 = 9417022005) ///
			   (9417022005 = 9417022008) (9417022008 = 9417022011) ///
			   (9417022011 = 9417022004) (9417022004 = 9417022007) ///
			   (9417023007 = 9417023006) (9417023006 = 9417023008) ///
			   (9417023008 = 9417023005) (9417023005 = 9417023004) ///
			   (9417023004 = 9417023007) (9417025005 = 9417025006) ///
			   (9417025006 = 9417025005) ///
			   (9417026001 = 9417052001) (9417026002 = 9417052002) ///
			   (9417026003 = 9417052003) (9417026004 = 9417052004) ///
			   (9417027001 = 9417026001) (9417027002 = 9417026002) ///
			   (9417027003 = 9417026003) (9417027004 = 9417026004) ///
			   (9417027005 = 9417026005) (9417027006 = 9417026006) ///
			   (9417010017 = 9417010015) /*(9417021009 = 9417021006)*/ ///
			   (9417030020 = 9417030017) (9417030021 = 9417030018) ///
			   (9417031006 = 9417031003) (9417031004 = 9417031006) ///
			   (9417031007 = 9417031004) (9417031005 = 9417031008) ///
			   (9417033004 = 9417033001) (9417033003 = 9417033002) ///
			   (9417033009 = 9417033004) (9417034003 = 9417034005) ///
			   (9417034005 = 9417034001) (9417034001 = 9417034003) ///
			   (9417034004 = 9417034010) (9417034010 = 9417034011) ///
			   (9417034011 = 9417034006) (9417034006 = 9417034002) ///
			   (9417034002 = 9417034004) ///
			   (9417041008 = 9417041006) (9417041006 = 9417041005) ///
			   (9417042003 = 9417042001) (9417042001 = 9417042003) ///
			   (9417042008 = 9417042007) (9417042007 = 9417042006) ///
			   (9417042006 = 9417042005) (9417042005 = 9417042008) ///
			   (9417043004 = 9417043003) (9417043005 = 9417043004) ///
			   (9417043006 = 9417043005) (9417043007 = 9417043006) ///
			   (9417043008 = 9417043007) (9417043010 = 9417043008) ///
			   (9417043009 = 9417043010) (9417050025 = 9417050026) ///
			   (9417050026 = 9417050027) (9417051009 = 9417051010) ///
			   (9417054005 = 9417054004) (9417054006 = 9417054005) ///
			   (9417055004 = 9417055003) (9417055003 = 9417055004) ///
			   (9417060010 = 9417060012) (9417060017 = 9417060019) ///
			   (9417062004 = 9417062005) (9417062005 = 9417062003) ///
			   (9417062003 = 9417062002) (9417062002 = 9417062004) ///
			   (9417040017 = 9417040023) (9417040018 = 9417040017) ///
			   (9417060016 = 9417060010) 

}
		

* Tidy

order id* nm* prov_id province region_id region kec_id kec desa_id desa pop	

drop prov_id region_id kec_id desa_id regstr kecstr desastr

foreach v in province region region_type kec desa pop {
	cap ren `v' `v'_2010
}

format %10.0f id* 
format %12.0fc pop_2010
format %25s nm* province* region* kec* desa*

la var pop_2010 "Population, 2010"

save "$work/pop2010", replace


