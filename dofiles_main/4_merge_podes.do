********************************************************************************
* Merge PODES 2005-2025
	* (also 2010 census population)
********************************************************************************

clear all
set more off 

* Paths: globals set in master.do

local aux "$aux"

* Unzip the BPS 1998-2013 and 2010-2015 village crosswalks into $temp
local cwd "`c(pwd)'"
cd "$temp"
foreach z in 1998_2013 2010_2015 {
	unzipfile "$cross/village_crosswalk_`z'.zip", replace
}
cd "`cwd'"

********************************************************************************
********************************************************************************
**# CROSS
* Combining PODES Waves using Crosswalk
********************************************************************************
********************************************************************************

********************************************************************************
**# CROSS 98-13
* Combining crosswalks: 1998-2013
********************************************************************************

foreach n of numlist 11/19 21 31/36 51/53 61/65 71/76 81 82 91 94 {
	if `n' == 13 {
		local y = 2005
	}
	else {
		local y = 1998
	}
	qui import dbase ///
		"$temp/village_crosswalk_1998_2013/`n'_`y'_2013_1", ///
		clear case(lower)
	foreach v of varlist * {
		cap destring `v', replace
	}	
	if inlist(`n',32,34) {
		qui tostring dashuk, replace
	}
	if `n' == 33 {
		qui replace id2008_1 = "" if real(id2008_1) == .
		qui destring id2008_1, replace
	}
	cap confirm variable klas_
	if !_rc {
		qui gen type = 1 if klas_ == "D"
		qui replace type = 2 if klas_ == "K"
	}
	else {
		cap confirm variable klas
		if !_rc {
			qui gen type = 1 if klas == "D"
			qui replace type = 2 if klas == "K"
		}
	}
	tempfile cross`n'
	qui save `cross`n''		
}

use `cross11', clear
foreach n of numlist 12/19 21 31/36 51/53 61/65 71/76 81 82 91 94 {
	qui append using `cross`n''
}

* Village Types

la var type "Village Organizational Type"
la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
la val type type

drop jml_desa jml_kec jml_kab ibukota kd_dashuk dashuk klas klas_ ubah ///
	 newfield1
	 
/*
foreach v in u_r2000 u_r2001 v12 u_r2005 u_r2007 u_r2009  {
	tab `v'
}
*/
replace type = 1 if mi(type) & u_r2005 == 0
replace type = 2 if mi(type) & u_r2005 == 1
replace type = 3 if mi(type) & u_r2005 == 2 //NAGARI
// fill in more "type" values later?

* Consolidating IDs

foreach x in id nm {
	foreach y in 1998 1999 {
		replace `x'`y' = `x'_`y' if mi(`x'`y')
		drop `x'_`y'
	}
}

replace id1998 = id1999 if inlist(id1998,3,5) // two curious ids...

replace id_sp2010 = idsp2010 if mi(id_sp2010)
replace id_sp2010 = idsp2010_ if mi(id_sp2010)
drop idsp2010 idsp2010_
ren nmsp2010 nm_sp2010

replace id_podes11 = idpodes11 if mi(id_podes11)
replace id_ppls11 = idppls11 if mi(id_ppls11)
drop idpodes11 idppls11

replace nm_podes11 = nmpodes11 if mi(nm_podes11)
replace nm_ppls11 = nmppls11 if mi(nm_ppls11)
drop nmpodes11 nmppls11

* Cleaning village names

foreach v of varlist nm* {
	di ""
	di "`v'"
	di ""
	qui replace `v' = strupper(`v')
	qui replace `v' = subinstr(`v',"  "," ",.)	
	qui replace `v' = subinstr(`v',"   "," ",.)	
	qui replace `v' = subinstr(`v',"    "," ",.)
}

* BPS code to help with merge

tempvar id
tostring id1998, gen(`id')
gen bps_1998 = substr(`id',1,4)
destring bps_1998, replace

* Extra version of names to aid in merging when "Nagari" is inconsistently added

gen nm2005_nagari = nm2005
	
* Fix typos, tweak names

recode id2013_1 (1175040010 = 1175040019) if id2011_1 == 1175040008

foreach v of varlist id2005 id2006 id2007* id2008* {
	qui recode `v' (1311010000 = 1311010001) if id2013_1 == 1311012002
}	

foreach v of varlist nm2005 nm2006 nm2007* nm2008* {
	qui replace `v' = "NAGARI SEI LIMAU" if id2013_1 == 1311012002
}				

* Fixing incorrect split timing that prevents merge of 2005 PODES

foreach i of numlist 1672020003 1672020005 1672030002 1672030006 1701050022 ///
		1701060041 1708030059 1708010007 1708010015 1708010005 1708010008 ///
		1708040001 1708040009 1708030054 1708040018 1802020038 1802080004 ///
		1807031005 1808030007 3201231003 3308130028 1209100004 1405012003 ///
		1509020007 1509020011 1509020014 1509030014 1509031006 1509050022 ///
		1509051007 1608020020 3308140003 3511040002 3511110002 3511170004 ///
		3602011012 5308011004 6201060021 6404010010 6404030005 6405020017 ///
		6405020005 6405040002 6405060004 6405060005 6406040032 6406042002 ///
		6406042003 6406043013 7306071010 7316011002 7316011001 7316011003 ///
		7316041009 7317051001 7317051007 7318040031 7404031001 7603040004 ///
		9101060020 9101080014 9102030020 9105170033 9103070005/9103070007 ///
		9105090016 {
	qui replace nm2005 = nm2004 if id2004 == `i'
	qui replace id2005 = id2004 if id2004 == `i'
}		  

local i 7603090017
qui replace nm2005 = nm2004 if id2005 == `i'
qui replace id2005 = id2004 if id2005 == `i'

forval y = 2005/2006 {
	replace id`y' = 1401040022 if id2007 == 1401040026
	replace nm`y' = "GERINGGING BARU" if id2007 == 1401040026
}

replace nm2005 = "DAME 1" if id2005 == 7103020014 & nm2008_1 == "DAME I"
replace nm2005 = "LIRUNG 1" if id2005 == 7104020005 & nm2008_1 == "LIRUNG I"

replace id2005 = id2006 if id2006 == 7103090011
replace nm2005 = "SOATALOARA II" if id2006 == 7103090011

replace nm2005 = nm2008_1 if id2008_1 == 7104030009
replace id2005 = id2008_1 if id2008_1 == 7104030009

replace nm2005 = "KAYULOE BARAT" if id2005 == 7304031002	

replace nm2005 = "PANGDEN LANDORUNDUN" if id2005 == 7318090039
replace id2005 = 7318071006 if id2005 == 7318090039

foreach i of numlist 5303140017 5303140024 5306021013 5306021014 ///
		5311012001/5311012010 6102011001/6102011006 7601030003 7601030011 {
	forval y = 2005/2006 {
		foreach x in id nm {
			replace `x'`y' = `x'_se06 if id_se06 == `i'
		}
	}
}

replace nm2005 = "LUBUK TUNJUNG" ///
	if nm2005 == "SUKA KARYA" & id2005 == 1702021009	
replace nm2005 = "PILAR" if id2005 == 1106060039	
replace nm2005 = "MEUNASAH TEUNGOH" if id2005 == 1110040040											
replace nm2005 = "TUNGEL" if id2005 == 1113040010
replace nm2005 = "PADANG PASIR" if id2005 == 1113040005
replace nm2005 = "TETINGGI" if id2005 == 1113041001
replace nm2005 = "SIOBON JULU" if id2005 == 1202050031
replace nm2005 = "BONDAKASE" if id2005 == 1202060023
replace nm2005 = "PARAN JULU" if id2005 == 1203050005
replace nm2005 = "SEUNEUBOK" if id2005 == 1101010015
replace nm2005 = "LALLA BAHAGIA" if id2005 == 1101040012
replace nm2005 = "PRK PATILUBAN" if id2005 == 1202060010
replace nm2005 = "GAJAH" if id2005 == 1208111009
replace nm2005 = "MERDEKA" if id2005 == 1211080037
replace nm2005 = "SUNGAI GOLANG" if id2005 == 1402030027
replace nm2005 = "SP DARUL IHSAN" if id2005 == 1473020009
replace nm2005 = "TANJUNG LANJUT" if id2005 == 1505060014
replace nm2005 = "TOLAN I/II" if id2005 == 1207060004
replace nm2005 = "KEM-KEM" if id2005 == 1211030002
replace nm2005 = "PERTUMBEKAN" if id2005 == 1211030010
replace nm2005 = "TOPAO" if id2005 == 7318052012
replace nm2005 = "KADO" if id2005 == 7318060018
replace nm2005 = "BATAN" if id2005 == 7318083006
replace nm2005 = "BUNTU LOBO" if id2005 == 7318090018
replace nm2005 = "TO LADA" if id2005 == 7322030014
replace nm2005 = "PAYA OMBUR" if id2005 == 1203041069
replace nm2005 = "NAGARI AIA DINGIN" if id2005 == 1303050001

/*
replace nm2005 = "" if id2005 == 
*/

* Fix typo

recode id2002 (1216010008 = 1210010008) if id2003 == 1216010008
recode id2002 (1309110001 = 1309110016) if id2003 == 1309110001

* Cases where merge fails because crosswalk has id and nm for 2003 but not 2002

foreach x in "nm" "id" {
	replace `x'2002 = `x'2003 ///
		if mi(`x'2002) & ///
		(inrange(id2003,1214010011,1214080032) | ///
		 inrange(id2003,1209010001,1209210007))
}

replace nm2002 = nm2003 if mi(nm2002)
replace id2002 = id2003 if mi(id2002)

* Cases where merge fails because crosswalk only goes back to 2005

foreach i of numlist 1301030008 1301030008 1301030009 1301020011 ///
		1301020013 1302101001 1302101003 1302101004 1302110009 {
	replace nm2002 = nm2005 if mi(nm2002) & id2005 == `i'
	replace id2002 = id2005 if mi(id2002) & id2005 == `i'
}

foreach i of numlist 1302100002 1302100001 1302010001 1302080003 {
	replace nm2002 = nm2008_1 if mi(nm2002) & id2005 == `i'
	replace id2002 = id2005 if mi(id2002) & id2005 == `i'
}

foreach c in 1209 1303 {	
	replace nm2002 = nm2005 if mi(nm2002) & inrange(id2005,`c'000000,`c'999999)	
	replace id2002 = id2005 if mi(id2002) & inrange(id2005,`c'000000,`c'999999)	
}

* Province 13 - SUMATERA BARAT - crosswalk only goes back to 2005

forval y = 1998/2004 {	
	replace nm`y' = subinstr(nm2005,"NAGARI ","",1) ///
		if mi(nm`y') & inrange(id2005,1300000000,1399999999)	
	replace id`y' = id2005 if mi(id`y') & inrange(id2005,1300000000,1399999999)	
}

* Fix Sumatera Barat district codes to account for splits and other code changes
	* prior to 2005
	* Reference is district crosswalk
	
	forval y = 1998/2005 {
		tostring id`y', gen(temp_id`y')
	}
	
	* 1301
	replace temp_id1998 = subinstr(temp_id1998,"1301","1305",1) ///
		if substr(temp_id2005,1,4) == "1301"
	
	* 1302
	replace temp_id1998 = subinstr(temp_id1998,"1302","1301",1) ///
		if substr(temp_id2005,1,4) == "1302"
	
	* 1303
	replace temp_id1998 = subinstr(temp_id1998,"1303","1302",1) ///
		if substr(temp_id2005,1,4) == "1303"
		
	* 1304
	replace temp_id1998 = subinstr(temp_id1998,"1304","1303",1) ///
		if substr(temp_id2005,1,4) == "1304"
		
	* 1305
	replace temp_id1998 = subinstr(temp_id1998,"1305","1304",1) ///
		if substr(temp_id2005,1,4) == "1305"
		
	* 1306
	replace temp_id1998 = subinstr(temp_id1998,"1306","1305",1) ///
		if substr(temp_id2005,1,4) == "1306"
		
	* 1307
	replace temp_id1998 = subinstr(temp_id1998,"1307","1306",1) ///
		if substr(temp_id2005,1,4) == "1307"
		
	* 1308
	replace temp_id1998 = subinstr(temp_id1998,"1308","1307",1) ///
		if substr(temp_id2005,1,4) == "1308"
		
	* 1309
	replace temp_id1998 = subinstr(temp_id1998,"1309","1308",1) ///
		if substr(temp_id2005,1,4) == "1309"
		
	* 1310
	replace temp_id1998 = subinstr(temp_id1998,"1310","1302",1) ///
		if substr(temp_id2005,1,4) == "1310"
	forval y = 1999/2002 {	
		replace temp_id`y' = subinstr(temp_id`y',"1310","1303",1) ///
			if substr(temp_id2005,1,4) == "1310"
	}	
		
	* 1311
	replace temp_id1998 = subinstr(temp_id1998,"1311","1303",1) ///
		if substr(temp_id2005,1,4) == "1311"
	forval y = 1999/2002 {	
		replace temp_id`y' = subinstr(temp_id`y',"1311","1304",1) ///
			if substr(temp_id2005,1,4) == "1311"
	}
	
	* 1312
	replace temp_id1998 = subinstr(temp_id1998,"1312","1308",1) ///
		if substr(temp_id2005,1,4) == "1312"
	forval y = 1999/2002 {	
		replace temp_id`y' = subinstr(temp_id`y',"1312","1309",1) ///
			if substr(temp_id2005,1,4) == "1312"
	}
	
	* 1371-1376: no code changes
	
	* 1377
	replace temp_id1998 = subinstr(temp_id1998,"1377","1305",1) ///
		if substr(temp_id2005,1,4) == "1377"
	forval y = 1999/2001 {	
		replace temp_id`y' = subinstr(temp_id`y',"1377","1306",1) ///
			if substr(temp_id2005,1,4) == "1377"
	}	
	
	destring temp_id????, replace
	
	forval y = 1998/2002 {
		replace id`y' = temp_id`y' if inrange(id2005,1300000000,1399999999)
	}
	
	drop temp_id????
	
* Miscellaneous fixes for Sumatera Barat

forval y = 1998/2002 {
	
	replace nm`y' = "PASIR TALANG" if inrange(id2002,1302040004,1302040005)
	replace id`y' = 1303020052 if inrange(id2002,1302040004,1302040005)

	replace nm`y' = "NAGARI MALALO" if inrange(id2002,1305021001,1305021002)	
	replace id`y' = 1305020060 if inrange(id2002,1305021001,1305021002)
	
	replace nm`y' = "BARUAH GUNUANG" if id2002 == 1305090002
	replace id`y' = 1305051005 if id2002 == 1305090002
	
	replace nm`y' = "NAGARI PARIT MALINTANG" if id2002 == 1306051005
	replace id`y' = 1306051016 if id2002 == 1306051005
	
	replace nm`y' = "NAGARI GUGUK" if id2002 == 1306052003
	replace id`y' = 1306052020 if id2002 == 1306052003
	
	replace nm`y' = "NAGARI SUNGAI SARIK" if id2002 == 1306060004
	replace id`y' = 1306060022 if id2002 == 1306060004
	
	replace nm`y' = "NAGARI GUNUNG PADANG ALA" if id2002 == 1306071003
	replace id`y' = 1306071033 if id2002 == 1306071003

	replace nm`y' = "LUBUK BASUNG" if id2002 == 1307020005
	replace id`y' = 1307020055 if id2002 == 1307020005
	
	replace id`y' = 1307060057 if id2002 == 1307062005

	replace nm`y' = "VIII KOTO TALAGO" if id2002 == 1308040005
	replace id`y' = 1308040015 if id2002 == 1308040005
	
	replace nm`y' = "BATANG TABA KAMPUNG JUA" ///
		if inrange(id2002,1371030028,1371030029)
	replace id`y' = 1371030024 if inrange(id2002,1371030028,1371030029)	
	
	replace nm`y' = "SEBERANG PALINGGAM" if id2002 == 1371040011
	
}

* More fixes for Sumatera Barat

foreach v of varlist nm2008_1 nm2007* nm_se06 nm2006 nm2005 {
	replace `v' = nm2008_2 if id2008_2 == 1302010003 & nm2008_2 == "UPT SILAUT"
}

foreach v of varlist id2008_1 id2007* id_se06 id2006 id2005 {
	replace `v' = id2008_2 if id2008_2 == 1302010003 & nm2008_2 == "UPT SILAUT"
}

recode id2005 (1302010002 = 1302010004) ///
	if id2012_2 == 1302010016 & nm2012_2 == "SINDANG LUNANG"
replace nm2005 = "UPT SINDANG" ///
	if id2012_2 == 1302010016 & nm2012_2 == "SINDANG LUNANG"
	
* Fix other district codes
	
tostring id2002, gen(temp_id2002)

replace temp_id2002 = subinstr(temp_id2002,"8106","8103",1) ///
	if substr(temp_id2002,1,4) == "8106"

replace temp_id2002 = subinstr(temp_id2002,"9205","9409",1) ///
	if substr(temp_id2002,1,4) == "9205"
	
destring temp_id2002, replace

replace id2002 = temp_id2002 //if inrange(id2002,8106000000,8106999999)

drop temp_id2002	

* Fix typos that prevent merge with PODES 2000

foreach i of numlist 1210010008 {
	replace id2000 = id1999 if id1999 == `i'
	replace id2001 = id1999 if id1999 == `i'
}

foreach i of numlist 1208020001/1208020009 {
	qui replace id2000 = id2001 if id2000 == `i'
}

foreach i of numlist 1771020003 1771020014 {
	foreach x in id nm {
		replace `x'1999 = `x'1998 if id1998 == `i'
		replace `x'2000 = `x'1998 if id1998 == `i'
	}
}

foreach i of numlist 1803070017 1805010037 1806080008 {
	foreach x in id nm {
		replace `x'2000 = `x'1999 if id1999 == `i'
	}
}

recode id2000 (3204130008 = 3202130008) if nm2000 == "CIMERANG"
recode id2000 (3204130007 = 3202130007) if nm2000 == "CITAMIANG"
recode id2000 (3204130006 = 3202130006) if nm2000 == "PAGELARAN"
recode id2000 (3204130005 = 3202130005) if nm2000 == "PURABAYA"
recode id2000 (3204130004 = 3202130004) if nm2000 == "MARGALUYU"
recode id2000 (3204130003 = 3202130003) if nm2000 == "CICUKANG"
recode id2000 (3204130002 = 3202130002) if nm2000 == "NEGLASARI"

* Fix problem: crosswalk randomly switched two villages halfway through period

foreach x in id1999 id2000 id2001 id2002 id2003 id2004 id2005 id2006 id_se06 {
	qui replace `x' = id2007 if inlist(id2007,1276010006,1276010007)
}

qui replace nm_se06 = nm2007 if inlist(id2007,1276010006,1276010007)

* Cases where merge fails because crosswalk only goes back to 2007 or coding 
	* of split has incorrect timing

foreach i of numlist 1202010005 1202010022 1202011007 1202010024 1202010021 ///
		1202060020 {
	foreach x in "nm" "id" {
		qui replace `x'2002 = `x'2007 if id2007 == `i'
		qui replace `x'2003 = `x'2007 if id2007 == `i'
		qui replace `x'2004 = `x'2007 if id2007 == `i'
		qui replace `x'2005 = `x'2007 if id2007 == `i'
		qui replace `x'2006 = `x'2007 if id2007 == `i'
	}
}

* Cases where PODES uses id2003 rather than id2002

foreach i of numlist 1102021001/1102021007 1102020019 1102030052 1102031020 ///
		1102032001/1102032006 1102040039 1102040026 6210020014 6210030011 ///
		7318020002 7318020005 7318020007 7318020029 7323080012 7401110001 ///
		3302210019 7323090004 7401080011 7407030008 7401060007 7401060013 ///
		7402030025 1106060051 1106060052 1106062010 1105131008 {
	replace nm2002 = nm2003 if id2003 == `i'
	replace id2002 = id2003 if id2003 == `i'
}

foreach i of numlist 1102033006 7205011004/7205011011 {
	replace id2002 = id2003 if id2003 == `i'
}

foreach i of numlist 7321040006 {
	replace id2002 = id2003 if id2002 == `i'
}

replace nm2002 = nm2003 if inrange(id2003,1102041001,1102045016)
replace id2002 = id2003 if inrange(id2003,1102041001,1102045016)

replace nm2002 = nm2003 if inrange(id2003,7318010008,7318011006)
replace id2002 = id2003 if inrange(id2003,7318010008,7318011006)

replace nm2002 = nm2003 if inrange(id2003,6307010001,6307090043)
replace id2002 = id2003 if inrange(id2003,6307010001,6307090043)

foreach c in 7318 {	
	replace nm2002 = nm2003 if inrange(id2002,`c'000000,`c'999999)	
	replace id2002 = id2003 if inrange(id2002,`c'000000,`c'999999)	
}

foreach i of numlist 9406110006/9406110010 {
	replace nm2002 = nm2004 if id2002 == `i'
	replace nm2003 = nm2004 if id2002 == `i'
}

replace id2002 = id2003 if inrange(id2003,1277030001,1277030012) | ///
	inrange(id2002,6203190001,6203240026) | ///
	inrange(id2003,5301030001,5301030014)
	
* Split timing is wrong for two villages with similar names

forval y = 2000/2001 {
    replace nm`y' = nm2002 if inlist(id2002,1105130103,1105131008)
	replace id`y' = id2002 if inlist(id2002,1105130103,1105131008)
}

forval y = 2002/2004 {
	qui replace id`y' = id2005 ///
		if inlist(id2005,1204040011,1204040012) & regexm(nm2005,"MELA")
	qui replace nm`y' = nm2005 ///
		if inlist(id2005,1204040011,1204040012) & regexm(nm2005,"MELA")	
}

* Other fixes	

gen byte __aloban = id2005 == 1204040012 & nm2005 == "ALOBAN"
replace nm2005 = nm2004 if __aloban
replace id2005 = id2004 if __aloban
drop __aloban

foreach i of numlist 1272020001 1272020002 1272030001 1272030004 {
	replace nm2005 = subinstr(nm2005,"TG.","TANJUNG",1) if id2005 == `i'
}

foreach i of numlist 1377010016 1377010017 1377020011/1377020017 {
	replace nm2005 = subinstr(nm2005,"KP.","KAMPUNG",1) if id2005 == `i'
}

foreach i of numlist 1213020010 1213020012 1213020016 1213020021 1213040005 {
	replace nm2005 = subinstr(nm2005,"PERK.","",1) if id2005 == `i'
}
	
foreach i of numlist 1208040009/1208040017 1212280001 {
	replace nm2005 = subinstr(nm2005,"SUNGAI ","SEI ",1) if id2005 == `i'
}

foreach i of numlist 1109051003 1601081013 1104040003 1208111002 {
	replace nm2005 = nm2004 if id2005 == `i'
}						

foreach i of numlist 1204041005 1211090001 1213030011 1213030012 1377010012 ///
		1377020021 1377030002 1377030005 1402060015 1405030028 1406060013 ///
		1409051005 1502040010 1502050013 1504010026/1504010029 1505020002 ///
		1212050007 7603030001 {
	replace nm2005 = nm2007 if id2005 == `i'
	replace nm2006 = nm2007 if id2005 == `i'
}		

foreach i of numlist 1207020003 {
	replace nm2005 = nm2008_1 if id2005 == `i'
}	

* Fix cases where PODES 2005 and crosswalk disagree about when codes change

foreach i of numlist 1702021001/1702021009 1702032001/1702032005 ///
		1702033001/1702033009 1702034001/1702034004 1702043001/1702043011 ///
		1702044001/1702044010 1702045001/1702045010 1702046001/1702046014 ///
		1702047001/1702047009 1103041006/1103041016 1107071020/1107071023 ///
		1109021001/1109021004 1117040002/1117040003 1117040006/1117040008 ///
		1117060002/1117060015 1104023002/1104023006 1602011001/1602011015 ///
		1602022001/1602022020 1602023001/1602023016 1602041001/1602041007 ///
		1602051001/1602051014 1602131001/1602131017 {
	qui replace id2005 = id2004 if id2005 == `i'	   
}	

foreach i of numlist 1110010086 1509041001/1509041009 1509061001/1509061005 ///
		1603012010 1608020034 1277030004 1277030015 1771011001/1771011004 ///
		1771011006 1771010007 1771010008 1771020024/1771020027 1771030004 ///
		1771030012 1771040006 1771040007 1771021008 5306031003 5306031005 ///
		5306031006 {
	replace nm2005 = nm2004 if id2005 == `i'
	replace id2005 = id2004 if id2005 == `i'
}

foreach i of numlist 7318011005 7318030018 7318040038 7318050019 7318051006 ///
		7318060041 7318070016 7318082004 7318090017 7318090040 {
	replace nm2005 = nm2006 if id2005 == `i'
}
	
foreach i of numlist 1104022013 1214030037 1214030036 {
	qui replace id2005 = id2003 if id2003 == `i'
	qui replace id2004 = id2003 if id2003 == `i'
}  

foreach i of numlist 7321053008 {
	foreach yr in 2004 2005 {
		qui replace nm`yr' = nm2003 if id2003 == `i'
		qui replace nm`yr' = subinstr(nm`yr',"UPT ","",1) if id2003 == `i'
	}
}
   
foreach i of numlist 1105080005/1105080012 1105130052/1105130064 1105130076 ///
		1105130077 1105130082 1203040058/1203040069 1203040081 ///
		1203041005/1203041029 1203041035/1203041037 1203042030/1203042034 ///
		1203042054/1203042078 1203050119 1203050129/1203050137 1203050129 ///
		1203140004 1203140016 1203160088/1203160090 1202010014 1202010016 ///
		1203030027 1203030032 1203030045 1203052003 1204011007/1204011014 ///
		1204020001 1204030019 1204031002/1204031009 1204040010 1204040011 ///
		1204050002 1204050005 1205061001/1205061009 1205061012 ///
		1206060013/1206060020 1207020004/1207020015 1207710001/1207710009 ///
		1207720001/1207720010 ///
		1208710001/1208710013 1208720001/1208720012 1209020001/1209020005 ///
		1209040001/1209040006 1209060001/1209060005 1209060013 1209060014 ///
		1209090005 1209090010 1209090011 1209090013 1209160017/1209160035 ///
		1209170001/1209170004 1209170013 1209170014 1209180001/1209180003 ///
		1209180014/1209180019 1209190015/1209190023 1210050003/1210050014 ///
		1210060017 1210100010 1210100015/1210100018 1213040002 1213040004 ///
		1213040008/1213040012 1213190002/1213190008 1218010031/1218010038 ///
		1276020006 1276020007 1276030002/1276030007 1276040004/1276040008 ///
		1401060002 1403010012/1403010024 1403060001/1403060010 ///
		1403080007/1403080011 1403090004 1403090005 1405024001/1405024006 ///
		1407020001 1407020002 1407021001/1407021005 1407040015 ///
		1471110001/1471110004 1508010001/1508010006 1603010016/1603010026 ///
		1603011010 1603011011 1603012012 1603020001/1603020004 ///
		1603020014/1603020024 1603050004/1603050015 1603060020 ///
		1603080003/1603080008 1603080021/1603080031 1603083001/1603083013 ///
		1201151008 1201151009 {
	qui replace id2005 = id2007 if id2005 == `i'
	qui replace id2006 = id2007 if id2006 == `i'
}

replace id2005 = 1210030012 if id2007 == 1210032012
replace id2006 = 1210030012 if id2007 == 1210032012

replace id2005 = 1210030013 if id2007 == 1210032013
replace id2006 = 1210030013 if id2007 == 1210032013

foreach i of numlist 1210032012 1210032013 1213040017 7604040007 {
	replace nm2005 = nm2007 if id2007 == `i'
	replace nm2006 = nm2007 if id2007 == `i'
}

foreach i of numlist 7604011005 7604040006 7604030009 1203041034 6372010006 ///
		6372010007 6372031001 6372032001 6372031004 6372032004 {
	foreach x in "nm" "id" {
		qui replace `x'2005 = `x'2007 if id2007 == `i'
		qui replace `x'2006 = `x'2007 if id2007 == `i'
	}
}

foreach i of numlist 1101010002 1104020046 1105130033 1105130117 1203040024 ///
		1403120005/1403120012 1403121006/1403121012 1403122006/1403122012 ///
		1403123009/1403123015 1404020031 1405012002 1405012003 1502020023 ///
		1502020026 1502040026 1508040023 1508041005 1508041007 1508041008 ///
		1202010003 1202010005 1209010001/1209010005 1209040007/1209040011 ///
		1209100002/1209100004 1209140007 1209200001/1209200008 1213080006 ///
		1213090001 1213090004 1213140006 1213170002 1213180005 1214030011 {
	foreach x in "nm" "id" {
		qui replace `x'2005 = `x'2007 if id2005 == `i'
		qui replace `x'2006 = `x'2007 if id2006 == `i'
	}
}

foreach i in 1702040062 1702040048 1102040012 1102045005 1103011014 1104010022 ///
			 1104050008 1213040013 {
	qui replace nm2005 = nm2004 if id2004 == `i'
}

* Issues with 2011 -> 2008 merge

foreach i of numlist 1214030037 {
	foreach x in id2006 id_se06 id2007 id2007_2 id2008_1 id2008_2 {
		qui replace `x' = id2005 if id2005 == `i'
	}
}

foreach i of numlist 5304010013 5304010015 5304011002 5304011003 5304011005 ///
		5304011006 5304040017 5304050016 5304080001 5304080003 5304080015 /// 
		5304101011 5304101014 5305010009 5305020008 5305020017 5305020029 ///
		5305040001 5305040002 5305040003 5305040005 5305040016 5305040017 ///
		7102130005 {
	qui replace id2008_1 = id2008_2 if id2008_1 == `i'
}

foreach i of numlist 1104030017 1104030018 1104030057 1104032004 1104032005 ///
		1104041027 7403071003/7403071005 7403073001 7403073004 7403082005 ///
		7403073007 7403180024 1209210008 1409041003 6205060024 6205060025 ///
		7102130005 {
	qui replace nm2008_1 = nm2008_2 if id2008_1 == `i'
}

foreach i of numlist 1104031011 {
	qui replace id2008_1 = id2009_1 if id2008_1 == `i'
}

foreach i of numlist 7403141013 7403141020 6208040003/6208040015 6211010003 ///
		6211010004 6211030007 {
	qui replace nm2008_1 = nm2009_1 if id2008_1 == `i'
}

foreach i of numlist 6207011007 {
	qui replace nm2008_1 = nm2006 if id2008_1 == `i'
}

foreach i of numlist 7403141025 {
	qui replace nm2008_1 = nm2010_1 if id2008_1 == `i'
}

foreach v in nm2009_1 nm2009_2 nm2010_1 nm2010_2 {
    qui replace nm2008_1 = `v' if mi(nm2008_1)
}

foreach i of numlist 1409010018/1409010020 1405026001 1405032002 1405032005 ///
		1409040020 {
	qui replace id2008_1 = id2007 if id2008_1 == `i'
}

foreach i of numlist 1409010009 {
	qui replace nm2008_1 = nm2007 if id2008_1 == `i'
}

drop if id2008_1 == 9107170000

replace nm2008_1 = nm2011_1 if id2011_1 == 9408051008

foreach i of numlist 9107132005 9404090019 {
	qui replace nm2008_1 = nm2007 if id2008_1 == `i'
	qui replace id2008_1 = id2007 if id2008_1 == `i'
}

foreach i of numlist 9107051005 {
	qui replace nm2006 = nm2007 if id2005 == `i'
	qui replace nm2005 = nm2007 if id2005 == `i'
	qui replace id2006 = id2007 if id2005 == `i'
	qui replace id2005 = id2007 if id2005 == `i'
}

foreach i of numlist 7403073007 7403082012 7403180035 6311040013 6311040014 ///
		6311040002 6311041019 6106050009 5205060010 3213060010 6108170006 ///
		8272041004 {
	qui replace id2008_1 = id2008_2 if id2008_2 == `i'
}

foreach i of numlist 6311040013 6311040014 6311040002 6311041019 {
	qui replace nm2008_1 = nm2008_2 if id2008_2 == `i'
}

recode id2008_1 (7503010001 = 7503011001) (7503010002 = 7503011002) ///
				(7503010009 = 7503012004) (7503020004 = 7503021001) ///
				(7503020006 = 7503021003) (7503030003 = 7503033001) ///
				(7503030009 = 7503033003) (7503030018 = 7503033005) ///
				(7503030021 = 7503032004) (7503030022 = 7503032005) ///
				(7503050007 = 7503051001) (1203070083 = 1220090006) ///
				(1203100064 = 1203102007) (7205010037 = 7205013003) ///
				(7205040023 = 7205043003) (7205040028 = 7205043008) ///
				(7205050006 = 7205052001) (7205050008 = 7205053002) ///
				(7205050013 = 7205053006) (8272030014 = 8272031001) ///
				(8272030016 = 8272031003) (8272041005 = 8272041002) ///
				(8272051001 = 8272051002) (8272051002 = 8272051001) ///
				(7601030005 = 7601030012)

replace id2008_1 = id2011_1 if id2011_1 == 7103100026
replace nm2008_1 = "KALEKUBE II" if id2011_1 == 7103100026

* Yensawai split between 2010 and 2011 (crosswalk is wrong)
foreach x in "_podes11" "_ppls11" "2011_1" "2011_2" "2012_1" { 
	replace id`x' = id2013_1 if inlist(id2013_1,9108036003,9108036004)
	replace nm`x' = nm2013_1 if inlist(id2013_1,9108036003,9108036004)
}
count if id2010_1 == 9108032004
assert `r(N)' == 1
preserve
	keep if id2010_1 == 9108032004
	tempfile yensawai
	save `yensawai'
restore
recode id2010_1 (. = 9108032004) if id2013_1 == 9108036004
merge m:1 id2010_1 using `yensawai', update
	assert _merge != 2
	drop _merge
	
* Lenmalas split between 2010 and 2011 (crosswalk is wrong)
foreach x in "_podes11" "_ppls11" "2011_1" "2011_2" { 
	replace id`x' = id2012_1 if inrange(id2012_1,9108022005,9108022007)
	replace nm`x' = nm2012_1 if inrange(id2012_1,9108022005,9108022007)
}
count if id2010_1 == 9108022003
assert `r(N)' == 1
preserve
	keep if id2010_1 == 9108022003
	foreach x in "_podes11" "_ppls11" "2011_1" "2011_2" { 
		replace id`x' = .
		replace nm`x' = ""
	}
	tempfile lenmalas
	save `lenmalas'
restore
drop if id2010_1 == 9108022003
recode id2010_1 (. = 9108022003) if inrange(id2012_1,9108022005,9108022007)
merge m:1 id2010_1 using `lenmalas', update
	assert _merge != 2
	drop _merge

* Other random fixes

forval y = 1998/2003 {
	recode id`y' (1209090010 = 1209090011) if nm2000 == "PANOMBEAN"
}

replace nm2011_1 = nm2013_1 if id2013_1 == 9106022009
replace id2011_1 = id2013_1 if id2013_1 == 9106022009

* Fix cases where id1998 is more aggregated than nm1998
	* Clearly the village split after 1998, but name does not reflect this

replace nm1998 = "TEBING TINGGI" if id1998 == 1505010022
replace nm1998 = "LUBUK SEBERUK" if id1998 == 1602031015
replace nm1998 = "SIMPANG TIGA" if id1998 == 1602060009
replace nm1998 = "KANDIS" if id1998 == 1602100015
replace nm1998 = "RANTAU ALAI" if id1998 == 1602100004
replace nm1998 = "KEL TANJUNG RAJA" if id1998 == 1602100025
replace nm1998 = "KEBAN AGUNG" if id1998 == 1604100002
replace nm1998 = "LESUNG BATU" if id1998 == 1605010016
replace nm1998 = "CIPTODADI" if id1998 == 1605060014
replace nm1998 = "UPANG" if id1998 == 1606071001
replace nm1998 = "PELANGAS" if id1998 == 1607010006
replace nm1998 = "MAYANG" if id1998 == 1607010007
replace nm1998 = "TELAKKAPIT" if id1998 == 1607020008
replace nm1998 = "PUPUT" if id1998 == 1607020011
replace nm1998 = "TELUK LIMAU" if id1998 == 1607020012
replace nm1998 = "TEMPILANG" if id1998 == 1607030002
replace nm1998 = "PENYAMPAK" if id1998 == 1607030005
replace nm1998 = "MANCUNG" if id1998 == 1607030007
replace nm1998 = "KELAPA" if id1998 == 1607030008
replace nm1998 = "DENDANG" if id1998 == 1607030010
replace nm1998 = "KACUNG" if id1998 == 1607030011
replace nm1998 = "PANGKAL NIUR" if id1998 == 1607040001
replace nm1998 = "RIAU SILIP" if id1998 == 1607040002

foreach s in ///
	"1607040003	CIT" ///
	"1607040004	PUGUL" ///
	"1607040005	GUNUNG MUDA" ///
	"1607040006	GUNUNG PELAWAN" ///
	"1607050010	AIR DUREN" ///
	"1607050011	AIR RUAI" ///
	"1607060001	BALUNIJUK/PAGARAWAN" ///	
	"1607060002	BATURUSA" ///
	"1607060003	RIDING PANJANG" ///	
	"1607060004	JURUNG" ///
	"1607060005	KIMAK" ///	
	"1607060007	PUDINGBESAR" ///
	"1607060012	KOTAWARINGIN" ///	
	"1607070001	PENAGAN/KT KAPUR" ///
	"1607070004	PETALING" ///	
	"1607070006	KACE" ///
	"1607080001	NAMANG BELILIK" ///	
	"1607080002	CAMBAI JELUTUNG" ///	
	"1607080004	TANJUNG GUNUNG" ///	
	"1607100001	BATU BETUMPANG" ///	
	"1607100012	BANGKAKOTA" ///	
	"1607110001	BATU BERIGA" ///	
	"1607110004	KOBA" ///	
	"1607120002	TUKAK/SADAI" ///	
	"1607120004	GADUNG" ///	
	"1607120009	BENCAH" ///	
	"1607120012	NYELANDING" ///	
	"1602020014	ULAK BALAM" ///	
	"1603060045	PENANDINGAN" ///	
	"1603060049	KARTAMULIA" ///	
	"1503050002	LUBUK NAPAL" ///	
	"5301070001	WAI MANU" ///	
	"5301070004	MALINJAK" ///	
	"5301070007	PRAI KAROKU JANGGA" ///	
	"5301070014	WAIRASA" ///
	"5301070017	MAKATA KERI" ///
	"5301070023	SAMBALI LOKU" ///
	"5301070024	BULU BOKAT" ///
	"5301070025	LENANG" ///
	"5302010008	LEWAPAKU" ///
	"5302010010	KANGELI" ///
	"5302020001	TARIMBANG" ///
	"5302030001	PRAIMADITA" ///
	"5302030003	TANDULA JANGGA" ///
	"5302040004	HADAKAMALI" ///
	"5302040011	PAMBURU" ///
	"5302050001	KATAKA" ///
	"5302050006	HANGGARORU" ///
	"5302050007	HEIKATAPU" ///
	"5302060006	KAMBATA TANA" ///
	"5302060009	PALAKAHEMBI" ///
	"5302062003	HAMBA PRAING" ///
	"5305030021	HUMUSU A" ///
	"5306010001	ALKANI" ///
	"5306010002	WEOE" ///
	"5306010003	WOBRIAMATA" ///
	"5306010004	RABASA" ///
	"5306010005	UMALOR" ///
	"5306010006	UMATOOS" ///
	"5306010007	SIKUN" ///
	"5306010008	LASAEN" ///
	"5306010011	MAKTIHAN" ///
	"5306010012	WEDEROK" ///
	"5306010014	HAITIMUK" ///
	"5306010015	LEUNKLOT" ///
	"5306010016	WEKMIDAR" ///
	"5306010018	ALALA" ///
	"5306010019	BIUDUK FOHO" ///
	"5306010020	LORO TOLUS" ///
	"5306010022	NITI" ///
	"5306010023	TAFULI" ///
	"5306020002	KATERI" ///
	"5306020003	UMAKATAHAN" ///
	"5306020005	FAHILUKA" ///
	"5306020010	FATUARUIN" ///
	"5306020011	BANI BANI" ///
	"5306020013	AS MANULEA" ///
	"5306020014	TUNABESI" ///
	"5306030005	SANLEO" ///
	"5306030006	NUMPONI" ///
	"5306030007	UABAU" ///
	"5306030008	KUSA" ///
	"5306030010	MANDEU" ///
	"5306030012	TESA" ///
	"5306030013	MANDEU RAIMANUS" ///
	"5306031001	LAKEKUN" ///
	"5306031002	LITAMALI" ///
	"5306031004	BABULU" ///
	"5306031005	ALAS" ///
	"5306031006	ALAS UTARA" ///
	"5306040004	NUALAIN" ///
	"5306040006	DIRUN" ///
	"5306040010	MAKIR" ///
	"5306050001	DAFALA" ///
	"5306050005	UMAKLARAN" ///
	"5306050006	SILAWAN" ///
	"5306050008	LASIOLAT" ///
	"5306050011	MAUMUTIN" ///
	"5306050013	DUALASI" ///
	"5306060001	NAITIMU" ///
	"5306060007	KABUNA" ///
	"5306060008	JENILU" ///
	"5306060009	LAWALUTOLUS" ///
	"5306060010	BAKUSTULAMA" ///
	"5306060011	NANAET" ///
	"5307010001	KAYANG" ///
	"5307010002	BARALER" ///
	"5307010003	KALONDAMA" ///
	"5307010004	TUDE" ///
	"5307010006	MURIABANG" ///
	"5307010007	NULE" ///
	"5307010008	KALEB" ///
	"5307010010	BATU" ///
	"5307010011	PANDAI" ///
	"5307010012	LEER" ///
	"5307010013	ARAMABA" ///
	"5307010014	KAERA" ///
	"5307020001	PROBUR" ///
	"5307020002	TRIBUR" ///
	"5307020003	WAKAPSIR" ///
	"5307020004	MATARU SELATAN" ///
	"5307020008	WOLWAL" ///
	"5307020009	MORU" ///
	"5307020010	HALERMAN" ///
	"5307020012	MATARU TIMUR" ///
	"5307030001	PADANG ALANG" ///
	"5307030002	KUNEMAN" ///
	"5307030003	SILAIPUI" ///
	"5307030004	SIDABUI" ///
	"5307030005	KELAISI BARAT" ///
	"5307030008	KALEISI TENGAH" ///
	"5307040003	PIDO" ///
	"5307040005	KAMOT" ///
	"5307040006	TARAMANA" ///
	"5307040007	TANGLAPUI" ///
	"5307040009	KOLANA UTARA" ///
	"5307040012	PISOMU/PADANG-PANJANG" ///
	"5307040013	MARITAING" ///
	"5307050002	ALOR KECIL" ///
	"5307050003	ALOR BESAR" ///
	"5307050004	AMPERA" ///
	"5307050005	DULOLONG" ///
	"5307050006	AIMOLI" ///
	"5307050010	ALILA" ///
	"5307050018	WELAI SELATAN" ///
	"5307050020	LEMBUR TENGAH" ///
	"5307050022	MARU" ///
	"5307050023	TERNATE" ///
	"5307051001	BINONGKO" ///
	"5307051002	KALABAHI BARAT" ///
	"5307051003	KALABAHI KOTA" ///
	"5307051004	KALABAHI TENGAH" ///
	"5307051006	WELAI BARAT" ///
	"5307051007	WELAI TIMUR" ///
	"5307051008	KABOLA" ///
	"5307051009	KENARI" ///
	"5311010005	WATUMANU" ///
	"5311010006	KELITEY" ///
	"5311010010	SEBOWULI" ///
	"5311020008	TODABELU" ///
	"5311030001	B E L A" ///
	"5311030007	SAWU" ///
	"5311030008	JAWAPOGO" ///
	"5311030014	UA" ///
	"5311040012	UTETOTO" ///
	"5311050005	NAGESEPADHI" ///
	"5311050016	GERODHERE" ///
	"5311060010	WAWOWAE" ///
	"5311060016	P I G A" ///
	"5311060017	MASUMELI" ///
	"5311060019	INELIKA" ///
	"5311060020	ULUWAE" ///
	"5311060021	INEGENA" ///
	"5311060023	DENATANA" ///
	"5311070005	TAEN TERONG" ///
	"5311070006	WANGKA" ///
	"5311070012	SAMBINASI" ///
	"5311080002	RENDUBUTOWE" ///
	"5311080004	LANGEDHAWE" ///
	"5311080006	TEDAMUDE" ///
	"5311080010	MBAY I" ///
	"5311080012	LAPE" ///
	"5311080013	OLAIA" ///
	"5311080014	TOTOMALA" ///
	"5311080015	TENDATOTO" ///
	"5312010001	KOMODO" ///
	"5312010011	WARLOKA" ///
	"5312010012	MACANG TANGGAR" ///
	"5312010022	GOLO BILAS" ///
	"5312010025	MBUIT" ///
	"5312010026	GOLO SEPANG" ///
	"5312010027	TANJUNG PONTIANAK" ///
	"5312010029	WAE KELAMBU" ///
	"5312010030	LABUAN BAJO" ///
	"5302030008	KANANGGAR" ///
	"5304020012	KONBAKI" ///
	{
	
	local code = real(substr("`s'",1,10))	
	local name = strtrim(substr("`s'",12,.))
			
	replace nm1998 = "`name'" if id1998 == `code'
	
}

* Fixes to improve PODES 1996 merge

forval y = 1998/2001 {
    replace id`y' = id2002 if id2002 == 1106020014
	replace nm`y' = nm2002 if id2002 == 1106020014
}

* ID 1996, NAME 1996

gen double id1996 = id1998
gen nm1996 = nm1998

order id1996 nm1996

* Sort by ID

sort id1996 id1998 id1999 id2000 id2002 id2005, stable
				
* Standardize names (remove gratuitous spaces, etc.)

qui do "`aux'/standardize_nm1996"
qui do "`aux'/standardize_nm2000"
qui do "`aux'/standardize_nm2002"
qui do "`aux'/standardize_nm2005"
qui do "`aux'/standardize_nm2008_1"
qui do "`aux'/standardize_nm2011_1"

* Drop duplicate

drop if id2013_1 == 1707053008 & mi(type)

foreach i in 1971031004 9171020015 {
	drop if id2013_1 == `i' & id2013_1[_n-1] == `i'
}		

* Tidying
cap drop __00*
drop if desano == 0
format %10.0f id*

* Save
save "$work/cross_1998_2013.dta", replace

********************************************************************************
**# CROSS 10-15
* Combining crosswalks: 2010-2015
********************************************************************************

foreach n of numlist 11/19 21 31/36 51/53 61/65 71/76 81 82 91 94 {
	if `n' == 94 {
		local y = 1998
	}
	else {
		local y = 2010
	}
	qui import dbase ///
		"$temp/village_crosswalk_2010_2015/`n'_`y'_podes14_2015", ///
		clear case(lower)	
	foreach v of varlist * {
		cap destring `v', replace
	}
	format id* %10.0f
	tempfile cross`n'
	qui save `cross`n''		
}

use `cross11', clear
foreach n of numlist 12/19 21 31/36 51/53 61/65 71/76 81 82 91 94 {
	qui append using `cross`n''
}
drop ket id1998-nmsp2010

* Cleaning village names

foreach v of varlist nm* {
	di ""
	di "`v'"
	di ""
	qui replace `v' = strupper(`v')
	qui replace `v' = subinstr(`v',"  "," ",.)	
	qui replace `v' = subinstr(`v',"   "," ",.)	
	qui replace `v' = subinstr(`v',"    "," ",.)
}

* 2014 village ID

gen double id2014 = idpodes14
replace id2014 = id2014_1 if mi(id2014)
replace id2014 = id2014_2 if mi(id2014)
format %10.0f id2014

* BPS code to help with merge

tempvar id
tostring id2014_2, gen(`id')
gen bps_2014 = substr(`id',1,4)
destring bps_2014, replace

* Tidying

drop if desano == 0

* grib
//bys id2014: keep if _n == 1
drop /*id2015_1 nm2015_1*/ provno kabno kecno desano

format %12.0f id*

* Drop observations that are not villages
	* Code is for a province, district, or kecamatan
	
tostring id2014, gen(idstr)
drop if substr(idstr,-3,.) == "000"
drop idstr

drop __0*

* Edit IDs to facilitate merge with 1998-2013 crosswalk

foreach i in 1302012001 1302012002 1302012003 1302012004 1302012005 1302012006 ///
			 1302012007 1302012008 1302012009 1302012010 1302011002 1302011003 ///
			 1302011004 1302011005 1302011006 1302011007 1302011008 1302011009 ///
			 1302011010 1302021001 1302021002 1302021003 1302021004 1302021005 ///
			 1302021006 1302021007 1302021008 1302021009 1302021010 1306100005 ///
			 1603033001 1603033002 1603033003 1603033004 1603033005 1603033006 ///
			 1603033007 1603033008 1603033009 1603033010 1603033011 1302031001 ///
			 1302031002 1302031003 1302031004 1302031005 1302031006 1302031007 ///
			 1302031008 1302031009 1302031010 {
			 	
	qui replace id2013_1 = id2012_2 if id2013_1 == `i'

}

* Fix cases where village codes and names switched starting with id2013_1, 
	* apparently due to a mistake
	* Issue detected in two districts: bps_2013 = 5321, 8208 
	
bys id2013_1: egen n_matches13 = ///
	total(id2013_1 == id2013_2 | nm2013_1 == nm2013_2)	
	
gen tempbps_2013 = floor(id2013_1/(10^6))	

foreach x in id nm {	
	foreach v in `x'2013_2 `x'podes14 `x'2014_1 `x'2014_2 {
		replace `v' = `x'2013_1 ///
			if n_matches13 == 0 & inlist(tempbps_2013,5321,8208)
	}
}

drop tempbps_2013 n_matches13

* Fix split timing

foreach i in 9419022009 9419022010 {
	foreach yr in 2014_1 2014_2 2015_1 {
		replace id`yr' = idpodes14 if idpodes14 == `i'
		replace nm`yr' = nmpodes14 if idpodes14 == `i'
	}
}

* grib
* Fill in missing id2014_2, nm2014_2
*
replace id2014_2 = idpodes14 if mi(id2014_2)
replace nm2014_2 = nmpodes14 if mi(nm2014_2)
*

* Tidying
duplicates drop

* Save
save "$work/cross_2010_2015.dta", replace

********************************************************************************
**# CROSS 13-18
* Crosswalk: 2013-2018
********************************************************************************

import excel "$cross/village_crosswalk_2013_2018/desa_2013_2018_1", ///
	firstrow clear
	
* Put variable names in lower case

forval y = 2013/2017 {
	forval n = 1/2 {
		ren ID`y'_`n' id`y'_`n'
		ren NM`y'_`n' nm`y'_`n'
	}
}

ren ID2018_1 id2018_1
ren NM2018_1 nm2018_1

* Format IDs and names

format id* %12.0f
format nm* %25s

* Problematic cases where villages appear to amalgamate in 2017 then split the
	* next year (seems like a crosswalk error)
	
	/*	
	foreach yr in 2016 2018 {
		bys id`yr'_1: gen u`yr'_1 = _n == 1	
		bys id2017_1: egen n_u`yr'_1 = total(u`yr'_1)
	}

	browse if n_u2016_1 > 1 & n_u2018_1 > 1
	*/

foreach id in 1102032007 1102033012 1102042005 1102043010 {
	foreach x in id nm {
		replace `x'2017_1 = `x'2016_1 if id2016_1 == `id' & id2018_1 == `id'
		replace `x'2017_2 = `x'2016_1 if id2016_1 == `id' & id2018_1 == `id'
	}
	drop if (id2016_1 == `id' & id2016_1 != id2017_1) | ///
			(id2018_1 == `id' & id2018_1 != id2017_1)
}

* Fix split timing

foreach i in 9419022008 9419022009 {
	foreach yr in 2014_1 2014_2 2015_1 2015_2 2016_1 {
		replace id`yr' = id2016_2 if id2016_2 == `i'
		replace nm`yr' = nm2016_2 if id2016_2 == `i'
	}
}

foreach v in id2014_1 id2014_2 id2015_1 {
	recode `v' (9419022008 = 9419022009) (9419022009 = 9419022010)
}

save "$work/cross_2013_2018.dta", replace

********************************************************************************
**# CROSS 14-19
* Crosswalk: 2014-2019
********************************************************************************

import excel ///
"$cross/village_crosswalk_2014_2021/data_histori_2014_2_hingga_2019_2", ///
	firstrow clear
	
* Rename variables
forval y = 2014/2019 {
	forval n = 1/2 {
		cap ren DESA`y'_`n' id`y'_`n'
		cap ren NMDS`y'_`n' nm`y'_`n'
	}
}	

* Make IDs numberic
destring id*, replace
	
* Format IDs and names
format id* %12.0f
format nm* %25s

* Clean up strings
foreach v of varlist nm* {
	replace `v' = strtrim(`v')
	replace `v' = subinstr(`v',"  "," ",.)
}

* Fix cases where, for same id2019_1, there are two incomplete series
	* One series is nonmissing only for years <= 2019
	* Other series is nonmissing only for years >= 2019
	
sort id2019_1 id2019_2, stable
by id2019_1: gen nvals = _N
by id2019_1: egen nnonmiss = total(!mi(id2018_1))

preserve
	keep if nvals > nnonmiss & !mi(id2019_1) & mi(id2019_2)
	tempfile prob1
	save `prob1'
restore

drop if nvals > nnonmiss & !mi(id2019_1) & mi(id2019_2)

merge m:1 id2019_1 using `prob1', update
	drop _merge
	
preserve
	keep if nvals > nnonmiss & !mi(id2019_2) & mi(id2018_2)
	tempfile prob2
	save `prob2'
restore	

drop if nvals > nnonmiss & !mi(id2019_2) & mi(id2018_2)

merge m:1 id2019_2 using `prob2', update
	drop _merge
	
drop nvals nnonmiss

sort id2017_1 id2017_2, stable
by id2017_1: gen nvals = _N
by id2017_1: egen nnonmiss = total(!mi(id2016_1))

preserve
	keep if nvals > nnonmiss & !mi(id2017_1) & mi(id2017_2)
	tempfile prob3
	save `prob3'
restore

drop if nvals > nnonmiss & !mi(id2017_1) & mi(id2017_2)

merge m:1 id2017_1 using `prob3', update
	drop _merge
	
drop nvals nnonmiss

sort id2016_1 id2016_2, stable
by id2016_1: gen nvals = _N
by id2016_1: egen nnonmiss = total(!mi(id2015_1))

sort id2016_1 id2016_2

local cond = "nvals == 2 & id2016_1 == id2016_1[_n-1] & " + ///
			 "inlist(id2016_1,7410030045,9430010002)"

replace nm2016_1 = nm2016_1[_n-1] if `cond'

forval n = 1/2 {	
	forval yr = 2014/2015 {
		cap replace nm`yr'_`n' = nm`yr'_`n'[_n-1] if `cond' 
		cap replace id`yr'_`n' = id`yr'_`n'[_n-1] if `cond' 
	}
}

drop nvals nnonmiss

sort id2015_1 id2015_2, stable
by id2015_1: gen nvals = _N
by id2015_1: egen nnonmiss = total(!mi(id2014_2))

sort id2015_1 id2015_2

local cond = "nvals == 2 & id2015_1 == id2015_1[_n-1] & " + ///
			 "inlist(id2015_1,7412010010,7412040008,7412060005,9101061004)"

replace nm2015_1 = nm2015_1[_n-1] if `cond'
replace nm2014_2 = nm2014_2[_n-1] if `cond'
replace id2014_2 = id2014_2[_n-1] if `cond'

drop nvals nnonmiss

* Fill in missing id2018_1 & nm2018_1 w/ id2018_2 & nm2018_2

replace id2018_1 = id2018_2 if mi(id2018_1)
replace nm2018_1 = nm2018_2 if mi(nm2018_1)

* Fix cases where id2018_1 and id2018_2 above should differ

recode id2018_1 ///
(9110020022 = 9110020018) (9110010008 = 9110010012) (9110010012 = 9110010013) ///
(9110080015 = 9110080004) (9110081004 = 9110081008) (9110081008 = 9110081009) ///
(9110090015 = 9110090003) 

foreach i in 9110080013 {
	replace nm2018_1 = nm2018_2 if id2018_1 == `i'
}

* Fix miscellaneous problems

replace nm2019_1 = "PADANGDATAR TANAH MATI" ///
	if id2019_1 == 1376010027 & nm2019_1 == "TANAH MATI"
replace nm2019_2 = "PADANGDATAR TANAH MATI" ///
	if id2019_1 == 1376010027
replace id2019_2 = id2019_1 if id2019_1 == 1376010027	
drop if id2019_1 == 1376010036 & mi(id2018_1)

foreach i in 9432010024 9428032001 {
	replace id2019_2 = id2019_1 if id2019_1 == `i'
	replace nm2019_2 = nm2019_1 if id2019_1 == `i'
}

drop if id2019_1 == 9428030007
drop if id2019_1 == 9432020054

recode id2019_1 (9402222016 = 9402222002)
drop if id2019_1 == 9402222002 & mi(id2019_2)

recode id2019_2 (. = 9402222015) if id2019_1 == 9402222003
drop if id2019_1 == 9402222015

recode id2019_2 (. = 9418043017) if id2019_1 == 9418011021
drop if id2019_1 == 9418043017

foreach i in 7403131009 7403090030 8103143013 8103141014 8103141015 8201140009 ///
			 9107114008 9107119006 9107061013 9107110028 9107121009 9107121010 ///
			 9107121011 9107130013 9107131007 9107131008 9107131009 9109013005 ///
			 9109051010 9109073010 9109072010 9404051005 9404051006 9404052006 ///
			 9404052007 9411063016 9430010030 9430044002 9430044003 9430044004 ///
			 9430044005 9430044007 9430044006 9431030010 9431050004 {
	replace id2018_1 = id2018_2 if id2018_2 == `i'
	replace nm2018_1 = nm2018_2 if id2018_2 == `i'
}

foreach i in 7410070032 {
	replace id2018_1 = id2017_1 if id2017_1 == `i'
	replace id2018_2 = id2017_2 if id2017_1 == `i'
}

foreach i in 9110030017 9110021014 9110080001 1606020039 1606030020 1606041016 ///
			 1709011001 1709011007 1709011006 1709011011 1709011004 1709011002 ///
			 1709011010 1709011009 1709011005 1709011008 1709011003 1701061018 ///
			 6211020021 7212090024 9107101007 9107101006 9107101008 {
	foreach x in id nm {
		replace `x'2018_1 = `x'2019_1 if id2019_1 == `i'
		replace `x'2018_2 = `x'2019_2 if id2019_1 == `i'
	}
}

foreach i in 9412032011 9412032012 9412032013 9412032014 9412032015 {
	foreach x in id nm {
		replace `x'2018_1 = `x'2019_2 if id2019_2 == `i'
		replace `x'2018_2 = `x'2019_2 if id2019_2 == `i'
	}
}

foreach i in 1612040014 1612040015 1612050014 1612050015 {
	foreach x in id nm {
		replace `x'2018_1 = `x'2015_1 if id2018_1 == `i'
		replace `x'2018_2 = `x'2015_1 if id2018_1 == `i'
	}
}

replace id2018_1 = 9107100014 if id2018_2 == 9107100016
replace id2018_1 = 9107100015 if id2018_2 == 9107100014
replace id2018_1 = 9107100016 if id2018_2 == 9107100019
replace id2018_1 = 9107100017 if id2018_2 == 9107100015
replace id2018_1 = 9107100018 if id2018_2 == 9107100018
replace id2018_1 = 9107100019 if id2018_2 == 9107100017
replace id2018_1 = 9107122009 if id2018_2 == 9107122008
replace id2018_1 = 9107172007 if id2018_2 == 9107172008
replace id2018_1 = 9107172008 if id2018_2 == 9107172007
replace id2018_1 = 9107172009 if id2018_2 == 9107172010
replace id2018_1 = 9107172010 if id2018_2 == 9107172009
replace id2018_1 = 9109021007 if id2018_2 == 9109021009
replace id2018_1 = 9109091006 if id2018_2 == 9109091007
replace id2018_1 = 9109101001 if id2018_2 == 9109112001
replace id2018_1 = 9109101002 if id2018_2 == 9109112002
replace id2018_1 = 9109101003 if id2018_2 == 9109112003
replace id2018_1 = 9109101004 if id2018_2 == 9109112004
replace id2018_1 = 9109101005 if id2018_2 == 9109112005
replace id2018_1 = 9109101006 if id2018_2 == 9109112006
replace id2018_1 = 9109101007 if id2018_2 == 9109112007

replace id2018_1 = 9109070021 if id2018_2 == 9109112008
replace id2018_1 = 9109071005 if id2018_2 == 9109112010
replace id2018_1 = 9109071007 if id2018_2 == 9109112011
replace id2018_1 = 9109071006 if id2018_2 == 9109112009

replace id2018_1 = 9410031004 if id2018_2 == 9410031009
replace id2018_1 = 9410031005 if id2018_2 == 9410031015
replace id2018_1 = 9410031009 if id2018_2 == 9410031013
replace id2018_1 = 9410031011 if id2018_2 == 9410031010
replace id2018_1 = 9410031012 if id2018_2 == 9410031011
replace id2018_1 = 9410032007 if id2018_2 == 9410032014
replace id2018_1 = 9410032008 if id2018_2 == 9410032011
replace id2018_1 = 9410032010 if id2018_2 == 9410032012
replace id2018_1 = 9410033008 if id2018_2 == 9410033004
replace id2018_1 = 9410033007 if id2018_2 == 9410033005
replace id2018_1 = 9410033005 if id2018_2 == 9410033006
replace id2018_1 = 9410033004 if id2018_2 == 9410033008
replace id2018_1 = 9410033006 if id2018_2 == 9410033007
replace id2018_1 = 9410034010 if id2018_2 == 9410034014
replace id2018_1 = 9410034011 if id2018_2 == 9410034015
replace id2018_1 = 9410034012 if id2018_2 == 9410034007
replace id2018_1 = 9410034013 if id2018_2 == 9410034008
replace id2018_1 = 9410034014 if id2018_2 == 9410034009
replace id2018_1 = 9410034015 if id2018_2 == 9410034012
replace id2018_1 = 9410035005 if id2018_2 == 9410035006
replace id2018_1 = 9410035006 if id2018_2 == 9410035007
replace id2018_1 = 9410035007 if id2018_2 == 9410035009
replace id2018_1 = 9410035008 if id2018_2 == 9410035004
replace id2018_1 = 9410037003 if id2018_2 == 9410037005
replace id2018_1 = 9410037004 if id2018_2 == 9410037006
replace id2018_1 = 9410042001 if id2018_2 == 9410042007
replace id2018_1 = 9410040006 if id2018_2 == 9410040008
replace id2018_1 = 9410040009 if id2018_2 == 9410040006
replace id2018_1 = 9410040008 if id2018_2 == 9410040009
replace id2018_1 = 9410041002 if id2018_2 == 9410041006
replace id2018_1 = 9410041003 if id2018_2 == 9410041007
replace id2018_1 = 9410031010 if id2018_2 == 9410031012
replace id2018_1 = 9410034007 if id2018_2 == 9410034010
replace id2018_1 = 9410034008 if id2018_2 == 9410034011
replace id2018_1 = 9410034009 if id2018_2 == 9410034013
replace id2018_1 = 9410035004 if id2018_2 == 9410035005
replace id2018_1 = 9410035009 if id2018_2 == 9410035008
replace id2018_1 = 9410037002 if id2018_2 == 9410037003
replace id2018_1 = 9410042002 if id2018_2 == 9410042008
replace id2018_1 = 9410042005 if id2018_2 == 9410042009
replace id2018_1 = 9410041005 if id2018_2 == 9410041009
replace id2018_1 = 9410041006 if id2018_2 == 9410041010
replace id2018_1 = 9410042004 if id2018_2 == 9410042002
replace id2018_1 = 9410042003 if id2018_2 == 9410042010
replace id2018_1 = 9410070011 if id2018_2 == 9410070015
replace id2018_1 = 9410041004 if id2018_2 == 9410041008
replace id2018_1 = 9410070010 if id2018_2 == 9410070011
replace id2018_1 = 9410070013 if id2018_2 == 9410070010
replace id2018_1 = 9410070012 if id2018_2 == 9410070014
replace id2018_1 = 9410070015 if id2018_2 == 9410070012
replace id2018_1 = 9410070014 if id2018_2 == 9410070013
replace id2018_1 = 9410071017 if id2018_2 == 9410071010
replace id2018_1 = 9410071016 if id2018_2 == 9410071009
replace id2018_1 = 9410071018 if id2018_2 == 9410071006
replace id2018_1 = 9410071019 if id2018_2 == 9410071016
replace id2018_1 = 9410071020 if id2018_2 == 9410071014
replace id2018_1 = 9410072003 if id2018_2 == 9410072003
replace id2018_1 = 9410072004 if id2018_2 == 9410072004
replace id2018_1 = 9410072005 if id2018_2 == 9410072005
replace id2018_1 = 9410073007 if id2018_2 == 9410073007
replace id2018_1 = 9410073005 if id2018_2 == 9410073008
replace id2018_1 = 9410074003 if id2018_2 == 9410074012
replace id2018_1 = 9410074009 if id2018_2 == 9410074011
replace id2018_1 = 9410080008 if id2018_2 == 9410080018
replace id2018_1 = 9410080018 if id2018_2 == 9410080009
replace id2018_1 = 9410083006 if id2018_2 == 9410083007
replace id2018_1 = 9410081016 if id2018_2 == 9410081012
replace id2018_1 = 9410081010 if id2018_2 == 9410081008
replace id2018_1 = 9410081011 if id2018_2 == 9410081004
replace id2018_1 = 9410081012 if id2018_2 == 9410081005
replace id2018_1 = 9410081013 if id2018_2 == 9410081007
replace id2018_1 = 9410081015 if id2018_2 == 9410081003
replace id2018_1 = 9410082003 if id2018_2 == 9410082005
replace id2018_1 = 9410082004 if id2018_2 == 9410082003
replace id2018_1 = 9410082005 if id2018_2 == 9410082006
replace id2018_1 = 9410082006 if id2018_2 == 9410082004
replace id2018_1 = 9410083003 if id2018_2 == 9410083006
replace id2018_1 = 9410083004 if id2018_2 == 9410083003
replace id2018_1 = 9410083005 if id2018_2 == 9410083004
replace id2018_1 = 9410083006 if id2018_2 == 9410083007
replace id2018_1 = 9410083007 if id2018_2 == 9410083005
replace id2018_1 = 9410084004 if id2018_2 == 9410084008
replace id2018_1 = 9410084005 if id2018_2 == 9410084004
replace id2018_1 = 9410084006 if id2018_2 == 9410084005
replace id2018_1 = 9410084007 if id2018_2 == 9410084006
replace id2018_1 = 9410084008 if id2018_2 == 9410084007
replace id2018_1 = 9410090001 if id2018_2 == 9410091001
replace id2018_1 = 9410090007 if id2018_2 == 9410090022
replace id2018_1 = 9410090005 if id2018_2 == 9410091002
replace id2018_1 = 9410090008 if id2018_2 == 9410090017
replace id2018_1 = 9410090009 if id2018_2 == 9410090006
replace id2018_1 = 9410091003 if id2018_2 == 9410091007
replace id2018_1 = 9410092006 if id2018_2 == 9410092008
replace id2018_1 = 9410092005 if id2018_2 == 9410092009
replace id2018_1 = 9410092007 if id2018_2 == 9410090009
replace id2018_1 = 9410092008 if id2018_2 == 9410092005
replace id2018_1 = 9410092011 if id2018_2 == 9410092006
replace id2018_1 = 9410090010 if id2018_2 == 9410091006
replace id2018_1 = 9410091003 if id2018_2 == 9410090011
replace id2018_1 = 9410091002 if id2018_2 == 9410091005
replace id2018_1 = 9410091001 if id2018_2 == 9410091003
replace id2018_1 = 9410091005 if id2018_2 == 9410091004
replace id2018_1 = 9410092007 if id2018_2 == 9410092007
replace id2018_1 = 9410073006 if id2018_2 == 9410073005
replace id2018_1 = 9410081008 if id2018_2 == 9410081010
replace id2018_1 = 9410091004 if id2018_2 == 9410091006
replace id2018_1 = 9435010020 if id2018_2 == 9435010021
replace id2018_1 = 9435010021 if id2018_2 == 9435010020
replace id2018_1 = 9435030011 if id2018_2 == 9435030011
replace id2018_1 = 9435041006 if id2018_2 == 9435041006
replace id2018_1 = 9435041007 if id2018_2 == 9435041008
replace id2018_1 = 9435041008 if id2018_2 == 9435041009
replace id2018_1 = 9435041009 if id2018_2 == 9435041007
replace id2018_1 = 9435050011 if id2018_2 == 9435050016
replace id2018_1 = 9435050015 if id2018_2 == 9435050019

recode id2018_1 (9411068011 = 9411068005)

replace id2018_1 = 9109080015 if id2019_1 == 9109080016
replace id2018_1 = 9410090001 if id2019_1 == 9410090023
replace id2018_1 = 9410090005 if id2019_1 == 9410090024

* UWAGI and IPOUWO: the BPS crosswalk gives their 2018 semester-2 and 2019 codes 
	* as 9410091001 and 9410091002 (codes of YOUTADI and YOUTADI II in 
	* PODES 2018, not in PODES 2019). Their PODES 2019 codes, 9410090023 and 
	* 9410090024, are on separate rows that have no 2014-2018 codes (the two 
	* lines above give them the 2018 code). Without this the merged data has two 
	* rows for each village. Put the 2019 codes on the 2014 lineage and drop the 
	* separate rows.
foreach p in "9410090001 9410090023" "9410090005 9410090024" {
	tokenize `p'
	drop if id2019_1 == `2' & mi(id2017_1)
	replace id2019_1 = `2' if id2018_1 == `1'
	replace id2019_2 = `2' if id2018_1 == `1'
}

* HOLUAOGALMA (Yalimo, kec 9432020): the BPS crosswalk links the 2017 sem-2
	* village HOUAOGALMA 9432020015 (PODES 2014 HOLUAOGALMA 9432020050) to the
	* 2018 code of YAREMA 9432020002, and gives the 2018 village HOLUOGALMA
	* 9432020052 (PODES 2018 HALUOKALMA, PODES 2025 HOLUOGALMA) a row of its own
	* with no 2014-2017 codes. Same name; 2018 YAREMA already continues 2014
	* YAREMA. Put the 2018-2019 codes of HOLUOGALMA on the HOUAOGALMA row and
	* drop the separate row
drop if id2019_1 == 9432020052 & mi(id2017_1)
foreach v in 2018_1 2018_2 2019_1 2019_2 {
	replace nm`v' = "HOLUOGALMA" if id2017_2 == 9432020015
	replace id`v' = 9432020052 if id2017_2 == 9432020015
}


replace id2018_1 = 9410092009 if id2019_1 == 9410092010
replace id2018_2 = 9410092009 if id2019_1 == 9410092010
replace nm2018_2 = nm2019_1 if id2019_1 == 9410092010

replace id2018_1 = 9410092010 if id2019_1 == 9410092011
replace id2018_2 = 9410092010 if id2019_1 == 9410092011
replace nm2018_2 = nm2019_1 if id2019_1 == 9410092011

local idold = 1603070016
local idnew = 1603071002
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070020
local idnew = 1603071006
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020003
local idnew = 1603021003
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070021
local idnew = 1603071007
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070018
local idnew = 1603071004
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020004
local idnew = 1603021004
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070017
local idnew = 1603071003
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070025
local idnew = 1603071009
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020009
local idnew = 1603021009
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020010
local idnew = 1603021010
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020001
local idnew = 1603021001
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020005
local idnew = 1603021005
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070015 
local idnew = 1603071001
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020002
local idnew = 1603021002
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020026
local idnew = 1603021012
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020006
local idnew = 1603021006
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070019
local idnew = 1603071005
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070022
local idnew = 1603071008
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020025
local idnew = 1603021011
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020007
local idnew = 1603021007
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603020008
local idnew = 1603021008
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

local idold = 1603070026
local idnew = 1603071010
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'
drop if id2019_1 == `idnew' & mi(id2018_1)

* Fixing amalgamations

local idold = 7402083006
local idnew = 7402083002
local namenew = "BHONTU-BHONTU"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402062010
local idnew = 7402062005
local namenew = "DANA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402011007
local idnew = 7402011003
local namenew = "LABASA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402071012
local idnew = 7402071005
local namenew = "MANTOBUA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402021013
local idnew = 7402021011
local namenew = "MATOMBURA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402011008
local idnew = 7402011002
local namenew = "WAALE-ALE"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402062011
local idnew = 7402062007
local namenew = "WAKADIA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'		

local idold = 7402010020
local idnew = 7402010019
local namenew = "UP. WUNA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402010021
local idnew = 7402010019
local namenew = "UP. WUNA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402020024
local idnew = 7402020020
local namenew = "LAIBA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 7402020021
local idnew = 7402020011
local namenew = "WALAMBENO WITE"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

foreach i in 7402020022 7402020023 7402021014 7402022006 7402022007 7402030020 ///
			 7402031010 7402061011 7402061012 7402062009 7402071010 7402071011 ///
			 7402072008 7402072009 7402080014 7402081008 7402083007 7402083008 ///
			 7402090016 7402091011 7402092005 7402092006 7402112005 {
	replace nm2019_1 = nm2015_1	if id2019_1 == `i'
	replace nm2019_2 = nm2015_1	if id2019_1 == `i'
	replace id2019_2 = id2015_1	if id2019_1 == `i'
	replace id2019_1 = id2015_1	if id2019_1 == `i'
}	

local idold = 7206041010
local idnew = 7206041007
local namenew = "LAMPASIO"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

local idold = 9104053007
local idnew = 9104053001
local namenew = "HORNA"
replace nm2019_1 = "`namenew'" if id2019_1 == `idold'
replace nm2019_2 = "`namenew'" if id2019_1 == `idold'
replace id2019_2 = `idnew' if id2019_1 == `idold'
replace id2019_1 = `idnew' if id2019_1 == `idold'

* Fix rows that are broken into two incomplete pieces: 
	* One piece with nonmissing codes and names for 2014_2 to 2016_2
	* One piece with nonmissing codes and names for 2016_2 to 2019_2
	
sort id2016_2 id2016_1	
by id2016_2: gen nvals = _N
replace nvals = 0 if mi(id2016_2)
foreach i in 1213030011 {
	foreach v of varlist *17* *18* *19* {
		by id2016_2: replace `v' = `v'[_n+1] ///
			if nvals > 1 & id2016_2 == `i' & id2016_2 == id2016_2[_n+1]
	}
	drop if id2016_2 == `i' & mi(id2016_1)
}

drop nvals 

* Merge in manual crosswalk for 2018-2019

preserve
	local filename "manual_village_crosswalk_podes_2018_2019"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	tempfile manual_2018_2019
	save `manual_2018_2019'
restore

merge m:1 id2019_1 nm2019_1 using `manual_2018_2019', update
	assert _merge != 2 
	
	* Filling in earlier IDs and names
	* A manual row (no 2014-2017 codes) copies them from the row of its 2018
	* village whose 2014 name equals its 2019 name (WAROPKO: INGGEMBIT 2019 <-
	* INGGEMBIT 2014); otherwise from the first row in a fixed order (the row
	* that continues the 2018 code first)
	gen byte __rcv = mi(id2017_1) & _merge >= 3
	gen __key = cond(__rcv, nm2019_1, nm2014_2)
	preserve
		keep if !__rcv
		keep id2018_1 __key
		duplicates drop
		gen byte __match = 1
		tempfile donors1883
		save `donors1883'
	restore
	merge m:1 id2018_1 __key using `donors1883', keep(master match) nogenerate
	gen byte __notcont = id2014_2 != id2018_1
	bys id2018_1 __rcv (__notcont id2014_2 nm2014_2 id2015_1 id2016_1 id2017_1): ///
		gen __first = __key[1] if !__rcv
	bys id2018_1 (__first): replace __first = __first[_N]
	replace __key = __first if __rcv & mi(__match)
	sort id2018_1 __key __rcv __notcont id2014_2 nm2014_2 id2015_1 id2016_1 ///
		id2017_1 id2019_1 nm2019_1
	foreach v of varlist *2014* *2015* *2016* *2017* {
		by id2018_1 __key: replace `v' = `v'[_n-1] if mi(`v') & __rcv
	}
	drop __rcv __key __match __notcont __first
	
	drop _merge	
	
* Problematic cases where villages appear to amalgamate in 2017 then split the
	* next year (seems like a crosswalk error)
	/*	
	foreach yr in 2016 2018 {
		bys id`yr'_1: gen u`yr'_1 = _n == 1	
		bys id2017_1: egen n_u`yr'_1 = total(u`yr'_1)
	}

	browse if n_u2016_1 > 1 & n_u2018_1 > 1
	*/
foreach id in 1102032007 1102033012 1102042005 1102043010 {
	foreach x in id nm {
		replace `x'2017_1 = `x'2016_1 if id2016_1 == `id' & id2018_1 == `id'
		replace `x'2017_2 = `x'2016_1 if id2016_1 == `id' & id2018_1 == `id'
	}
	drop if (id2016_1 == `id' & id2016_1 != id2017_1) | ///
			(id2018_1 == `id' & id2018_1 != id2017_1)
}

* Clean up strings again
foreach v of varlist nm* {
	replace `v' = strtrim(`v')
	replace `v' = subinstr(`v',"  "," ",.)
}

* Fill in missing id2019_2 and nm2019_2
replace id2019_2 = id2019_1 if mi(id2019_2)
replace nm2019_2 = nm2019_1 if mi(nm2019_2)

* Fix split timing

foreach i in 9419022008 9419022009 {
	foreach yr in 2014_2 2015_1 2015_2 2016_1 {
		replace id`yr' = id2016_2 if id2016_2 == `i'
		replace nm`yr' = nm2016_2 if id2016_2 == `i'
	}
}

foreach v in id2014_2 id2015_1 {
	recode `v' (9419022008 = 9419022009) (9419022009 = 9419022010)
}

* Tidying
duplicates drop
sort id2019_1

* To add merge of village that split then amalgamated twice
expand 2 if id2014_2 == 8272041002

* Save
save "$work/cross_2014_2019.dta", replace

********************************************************************************
**# CROSS 19-20
* Crosswalk: 2019-2020
********************************************************************************

import dbase ///
	"$cross/village_crosswalk_2014_2021/hirarki_desa_2019_2020", clear
	
* Rename variables
forval y = 2019/2020 {
	forval n = 1/2 {
		cap ren DESA`y'_`n' id`y'_`n'
		cap ren NMDS`y'_`n' nm`y'_`n'
	}
}	

* Make IDs numeric
destring id*, replace
	
* Format IDs and names
format id* %12.0f
format nm* %25s

* Fix problems
recode id2019_2 ///
   (1376010036 = 1376010027) (9428030007 = 9428032001) (9432020054 = 9432010024)

* Tidying
sort id2019_2 id2020_1

* Save
save "$work/cross_2019_2020.dta", replace

********************************************************************************
**# CROSS 20-21
* Crosswalk: 2020-2021
********************************************************************************

** 2020_1 and 2020_2 **

import dbase "$cross/village_crosswalk_2014_2021/hirarki_desa_2020", ///
	clear
	
duplicates drop	
	
bys DESA2020_2 NMDS2020_2: gen nvals = _N	

preserve
	keep if nvals == 1
	drop nvals
	tempfile d_unique
	save `d_unique'
restore

preserve
	keep if nvals != 1
	drop nvals
	tempfile d_nonunique
	save `d_nonunique'
restore	
	
** 2020_2 and 2021_1 **	

import dbase "$cross/village_crosswalk_2014_2021/hirarki_desa_2021", ///
	clear
	
duplicates drop	
	
merge m:1 DESA2020_2 NMDS2020_2 using `d_unique'

preserve
	keep if _merge != 3
	drop _merge
	merge 1:m DESA2020_2 NMDS2020_2 using `d_nonunique', update
	assert _merge == 4
	drop _merge
	tempfile merged_nonunique
	save `merged_nonunique'
restore

drop if _merge != 3
drop _merge
	
append using `merged_nonunique'

* Rename variables
forval y = 2020/2021 {
	forval n = 1/2 {
		cap ren DESA`y'_`n' id`y'_`n'
		cap ren NMDS`y'_`n' nm`y'_`n'
	}
}	

* Clean up strings
foreach v of varlist nm* {
	replace `v' = strtrim(`v')
	replace `v' = subinstr(`v',"  "," ",.)
}

* Make IDs numberic
destring id*, replace
	
* Format IDs and names
format id* %12.0f
format nm* %25s

* Tidying
sort id2020_1 id2020_2 id2021_1
order id2020_1 nm2020_1 id2020_2 nm2020_2 id2021_1 nm2021_1
drop FLAG_DS0

* Save
save "$work/cross_2020_2021.dta", replace

********************************************************************************
**# CROSS 21-24
* Combined crosswalk: 2021-2024
********************************************************************************

import dbase "$cross/village_crosswalk_2021_2024/panelmfd_2021_2024", ///
	clear
	
duplicates drop	
	
* Drop rows with blank names and codes equal to zero	
drop if KODE_20211 == 0	

* Rename variables
forval yr = 2021/2024 {
	ren KODE_`yr'1 id`yr'_1 
	ren NAMA_`yr'1 nm`yr'_1 
}

* Merge in manual crosswalk for 2021-2024
preserve
	local filename "manual_village_crosswalk_podes_2021_2024"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	tempfile manual_2021_2024
	save `manual_2021_2024'
restore

merge m:1 id2024_1 nm2024_1 using `manual_2021_2024', update replace
	drop _merge

* Format IDs and names
format id* %12.0f
format nm* %25s

* Tidying
sort id2021_1 id2022_1 id2023_1 id2024_1

* Save
save "$work/cross_2021_2024.dta", replace

********************************************************************************
**# CROSS 24-25
* Crosswalk, 2024-2025 (PODES 2025 villages, manual crosswalk, MFD 2024 sem 2)
********************************************************************************

* Manual crosswalk (also helps merge MFD 2024 sem 2)

local filename "manual_village_crosswalk_podes_2024_2025"
import excel "$cross/manual_podes/`filename'", ///
	firstrow clear
drop notes
format %10.0f id*
tempfile manual_2024_2025
save `manual_2024_2025'

* MFD 2024 sem 2

local file "$cross/mfd_2024_sem2/mfd 2024 sem 2.xlsx"
import excel "`file'", clear firstrow
drop id kd* semester
ren iddesa id2024_2
foreach x in prov kab kec {
	ren nm`x' `x'_2024_2
}
ren nmdesa nm2024_2
gen double id_merge = id2024_2
gen desa_merge = nm2024_2
format %10.0f id*
tempfile mfd2024sem2
save `mfd2024sem2'

* PODES 2025 villages

use id* nm* province_2025 region_2025 region_type_2025 kec_2025 ///
	using "$work/podes2025.dta", clear

merge 1:1 id2025_1 using `manual_2024_2025'
	assert _merge != 2
	drop _merge

gen double id_merge = id2025
replace id_merge = id2024_2 if !mi(id2024_2)
format %10.0f id_merge
gen desa_merge = nm2025
replace desa_merge = nm2024_2 if !mi(nm2024_2)

merge 1:1 id_merge using `mfd2024sem2', update nogenerate
drop id_merge desa_merge

* 2024 codes and names: MFD 2024 sem 2 or manual crosswalk; else the 2025 ones

replace id2024_2 = id2025 if mi(id2024_2)
replace nm2024_2 = nm2025 if mi(nm2024_2)
replace id2024_1 = id2024_2 if mi(id2024_1)
replace nm2024_1 = nm2024_2 if mi(nm2024_1)

drop if mi(id2025)
keep id* nm* province_2025 region_2025 region_type_2025 kec_2025
order id* nm*

* Save
save "$work/cross_2024_2025.dta", replace

********************************************************************************
**# COMBINED CROSS 98-24
* Combined crosswalk: 1998-2024
********************************************************************************

* Start with 2021-2024 crosswalk 

use "$work/cross_2021_2024.dta", clear

* 2020-2021 crosswalk - obs w/ unique values of id2021_1

preserve
	use "$work/cross_2020_2021.dta", clear
	bys id2021_1: gen nvals = _N
	keep if nvals == 1
	drop nvals
	tempfile cross_2020_2021_u
	save `cross_2020_2021_u'
restore

* 2020-2021 crosswalk - obs w/ nonunique values of id2021_1

preserve
	use "$work/cross_2020_2021.dta", clear
	bys id2021_1: gen nvals = _N
	keep if nvals > 1 & !mi(id2021_1)
	drop nvals
	tempfile cross_2020_2021_n
	save `cross_2020_2021_n'
restore

merge m:1 id2021_1 using `cross_2020_2021_u', update
	assert _merge != 2

	preserve
		keep if _merge == 1 // 10 unmerged villages are 2021 amalgamations
		drop _merge
		merge 1:m id2021_1 using `cross_2020_2021_n', update
			assert _merge >= 3
			drop _merge
		tempfile m1
		save `m1'
	restore
	
drop if _merge == 1	
drop _merge

append using `m1'

* 2019-2020 crosswalk - obs w/ unique values of id2020_1

preserve
	use "$work/cross_2019_2020.dta", clear
	bys id2020_1: gen nvals = _N
	keep if nvals == 1
	drop nvals
	tempfile cross_2019_2020_u
	save `cross_2019_2020_u'
restore

* 2019-2020 crosswalk - obs w/ nonunique values of id2020_1

preserve
	use "$work/cross_2019_2020.dta", clear
	bys id2020_1: gen nvals = _N
	keep if nvals > 1 & !mi(id2020_1)
	drop nvals
	tempfile cross_2019_2020_n
	save `cross_2019_2020_n'
restore

merge m:1 id2020_1 using `cross_2019_2020_u', update
	assert _merge != 2
	
	preserve
		keep if _merge == 1 // unmerged villages are amalgamations
		drop _merge
		merge 1:m id2020_1 using `cross_2019_2020_n', update
			assert _merge >= 3
			drop _merge
		tempfile m1
		save `m1'
	restore
	
drop if _merge == 1	
drop _merge

append using `m1'

order *2019* *2020*
sort id2019_2 id2020_1 id2020_2 id2021_1 id2022_1 id2023_1 id2024_1, stable

* 2014-2019 crosswalk - obs w/ unique values of id2019_2

preserve
	use "$work/cross_2014_2019.dta", clear
	bys id2019_2: gen nvals = _N
	keep if nvals == 1
	drop nvals
	tempfile cross_2014_2019_u
	save `cross_2014_2019_u'
restore

* 2014-2019 crosswalk - obs w/ nonunique values of id2019_2

preserve
	use "$work/cross_2014_2019.dta", clear
	bys id2019_2: gen nvals = _N
	keep if nvals > 1 & !mi(id2019_2)
	drop nvals
	sort id2019_2 id2014_2
	by id2019_2: gen tempid = _n
	tempfile cross_2014_2019_n
	save `cross_2014_2019_n'
restore

merge m:1 id2019_2 using `cross_2014_2019_u', update
	
	bys id2019_2: gen nvals = _N
	
	preserve
		keep if nvals > 1 & _merge == 1
			// unmerged villages that split, amalgamated, then split again
		drop _merge
		sort id2019_2 id2021_1
		by id2019_2: gen tempid = _n
		recode tempid (1 = 2) (2 = 1) if id2019_2 == 9413050007
		merge 1:1 id2019_2 tempid using `cross_2014_2019_n', update	
			assert _merge != 1
			keep if _merge >= 3
			drop _merge
		tempfile m1
		save `m1'
	restore
	
	drop if nvals > 1 & _merge == 1 
	
	preserve
		keep if _merge == 1 // unmerged villages are amalgamations
		drop _merge
		merge 1:m id2019_2 using `cross_2014_2019_n', update
			assert _merge != 1
			keep if _merge >= 3
			drop _merge
		tempfile m2
		save `m2'
	restore

drop if _merge == 1	
drop _merge

append using `m1'
append using `m2'

drop tempid nvals

order *2014* *2015* *2016* *2017* *2018* *2019* *2020* *2021* *2022* *2023* ///
	  *2024*
sort id2014* id2015* id2016* id2017* id2018* id2019_1 id2019_2 ///
	 id2020_1 id2020_2 id2021_1 id2022_1 id2023_1 id2024_1, stable	 

* Filling in missing IDs and names

foreach x in id nm {
	replace `x'2014_2 = `x'2018_1 ///
		if mi(`x'2014_2) & ///
		( inrange(id2018_1,9432010031,9432010061) | ///
		  inrange(id2018_1,9432020044,9432020053) )
}

replace id2014_2 = 1312020001 if id2018_1 == 1312020003
replace nm2014_2 = "DESA BARU" if id2018_1 == 1312020003

replace id2014_2 = 1312020002 if inrange(id2018_1,1312020004,1312020007)
replace nm2014_2 = "BATAHAN" if inrange(id2018_1,1312020004,1312020007)

replace id2014_2 = 1312030001 if inrange(id2018_1,1312030002,1312030006)
replace nm2014_2 = "PARIK" if inrange(id2018_1,1312030002,1312030006)

replace id2014_2 = 1312040001 if inrange(id2018_1,1312040002,1312040007)
replace nm2014_2 = "SUNGAI AUA" if inrange(id2018_1,1312040002,1312040007)

replace id2014_2 = 1312050001 if inrange(id2018_1,1312050002,1312050009)
replace nm2014_2 = "UJUANG GADIANG" if inrange(id2018_1,1312050002,1312050009)

replace id2014_2 = 1312060001 if inrange(id2018_1,1312060003,1312060004)
replace nm2014_2 = "MUARO KIAWAI" if inrange(id2018_1,1312060003,1312060004)

replace id2014_2 = 1312060002 if inrange(id2018_1,1312060005,1312060007)
replace nm2014_2 = "RABI JONGOR" if inrange(id2018_1,1312060005,1312060007)

replace id2014_2 = 1312070001 if inrange(id2018_1,1312070004,1312070005)
replace nm2014_2 = "KAJAI" if inrange(id2018_1,1312070004,1312070005)

replace id2014_2 = 1312070002 if inrange(id2018_1,1312070006,1312070007)
replace nm2014_2 = "TALU" if inrange(id2018_1,1312070006,1312070007)

replace id2014_2 = 1312070003 if id2018_1 == 1312070008
replace nm2014_2 = "SINURUIK" if id2018_1 == 1312070008

replace id2014_2 = 1312080001 if inrange(id2018_1,1312080004,1312080010)
replace nm2014_2 = "LINGKUANG AUA" if inrange(id2018_1,1312080004,1312080010)

replace id2014_2 = 1312080002 if inrange(id2018_1,1312080011,1312080014)
replace nm2014_2 = "AUA KUNIANG" if inrange(id2018_1,1312080011,1312080014)

replace id2014_2 = 1312080003 if inrange(id2018_1,1312080015,1312080016)
replace nm2014_2 = "AIA GADANG" if inrange(id2018_1,1312080015,1312080016)

replace id2014_2 = 1312090001 if inrange(id2018_1,1312090003,1312090009)
replace nm2014_2 = "KOTO BARU" if inrange(id2018_1,1312090003,1312090009)

replace id2014_2 = 1312100001 if inrange(id2018_1,1312100002,1312100004)
replace nm2014_2 = "SASAK" if inrange(id2018_1,1312100002,1312100004)

replace id2014_2 = 1312110002 if inrange(id2018_1,1312110003,1312110017)
replace nm2014_2 = "KINALI" if inrange(id2018_1,1312110003,1312110017)
	
	// for PASAMAN BARAT (1312), see merge notes

replace id2014_2 = 1309070001 if id2018_1 == 1309070005
replace nm2014_2 = "NAGARI KOTO KACIAK" if id2018_1 == 1309070005

replace id2014_2 = 1309071002 if id2018_1 == 1309071004
replace nm2014_2 = "NAGARI LADANG PANJANG" if id2018_1 == 1309071004

replace id2014_2 = 1309071003 if id2018_1 == 1309071005
replace nm2014_2 = "NAGARI MALAMPAH" if id2018_1 == 1309071005

replace id2014_2 = 1309072001 if id2018_1 == 1309072003
replace nm2014_2 = "NAGARI ALAHAN MATI" if id2018_1 == 1309072003

replace id2014_2 = 1309072002 if id2018_1 == 1309072004
replace nm2014_2 = "NAGARI SIMPANG" if id2018_1 == 1309072004

replace id2014_2 = 1309080001 if inrange(id2018_1,1309080007,1309080008)
replace nm2014_2 = "NAGARI TANJUNG BERINGIN" ///
	if inrange(id2018_1,1309080007,1309080008)

replace id2014_2 = 1309080005 if inrange(id2018_1,1309080009,1309080011)
replace nm2014_2 = "NAGARI AIA MANGGIH" ///
	if inrange(id2018_1,1309080009,1309080011)

replace id2014_2 = 1309080006 if inrange(id2018_1,1309080012,1309080013)
replace nm2014_2 = "NAGARI SUNDATA" if inrange(id2018_1,1309080012,1309080013)

replace id2014_2 = 1309100001 if inrange(id2018_1,1309100003,1309100005)
replace nm2014_2 = "NAGARI CUBADAK" if inrange(id2018_1,1309100003,1309100005)

replace id2014_2 = 1309100002 if inrange(id2018_1,1309100006,1309100007)
replace nm2014_2 = "NAGARI SIMPANG TONANG" ///
	if inrange(id2018_1,1309100006,1309100007)

replace id2014_2 = 1309121001 if inrange(id2018_1,1309121003,1309121004)
replace nm2014_2 = "NAGARI TARUANG-TARUANG" ///
	if inrange(id2018_1,1309121003,1309121004)

replace id2014_2 = 1309121002 if id2018_1 == 1309121005
replace nm2014_2 = "NAGARI PADANG MANTINGGI" if id2018_1 == 1309121005

replace id2014_2 = 1309122003 if id2018_1 == 1309122004
replace nm2014_2 = "NAGARI MUARO TAIS" if id2018_1 == 1309122004
		
replace id2014_2 = 1309124001 if id2018_1 == 1309124004
replace nm2014_2 = "NAGARI LANSEK KADOK" if id2018_1 == 1309124004 
		
replace id2014_2 = 1309124002 if inrange(id2018_1,1309124005,1309124006)
replace nm2014_2 = "NAGARI TANJUNG BETUNG" ///
	if inrange(id2018_1,1309124005,1309124006)

recode id2014_2 ///
	(9432010031 = 9432010006) (9432010032 = 9432010007) ///
	(9432010033 = 9432010008) (9432010034 = 9432010009) ///
	(9432010035 = 9432010010) (9432010036 = 9432010011) ///
	(9432010037 = 9432010012) (9432010038 = 9432010013) ///
	(9432010039 = 9432010014) (9432010040 = 9432010015) ///
	(9432010041 = 9432010030) (9432010042 = 9432010031) ///
	(9432010043 = 9432010032) (9432010044 = 9432010033) ///
	(9432010045 = 9432010035) (9432010046 = 9432010036) ///
	(9432010047 = 9432010034) (9432010048 = 9432010016) ///
	(9432010049 = 9432010017) (9432010050 = 9432010018) ///
	(9432010051 = 9432010019) (9432010052 = 9432010020) ///
	(9432010053 = 9432010021) (9432010054 = 9432010023) ///
	(9432010055 = 9432010024) (9432010056 = 9432010025) ///
	(9432010057 = 9432010026) (9432010058 = 9432010027) ///
	(9432010059 = 9432010029) (9432010060 = 9432010028) ///
	(9432010061 = 9432010022) (9432020044 = 9432020037) ///
	(9432020045 = 9432020036) (9432020049 = 9432020057) ///
	(9432020051 = 9432020055)
	
foreach i in 1214036014 1214036003 7325060019 7325060019  9419022002 9419022005 ///
			 9419033001 9419033010 9419033009 9419033002 {	
	foreach x in id nm {
		foreach v in `x'2014_2 `x'2015_1 `x'2015_2 `x'2016_1 {
			replace `v' = `x'2016_2 if id2016_2 == `i'
		}
	}
}
	
* 2010-2015 crosswalk - obs w/ unique values of id2014_2

preserve
	use "$work/cross_2010_2015.dta", clear
	bys id2014_2: gen nvals = _N
	keep if nvals == 1
	drop nvals
	tempfile cross_2010_2015_u
	save `cross_2010_2015_u'
restore

* 2010-2015 crosswalk - obs w/ nonunique values of id2014_2

preserve
	use "$work/cross_2010_2015.dta", clear
	bys id2014_2: gen nvals = _N
	keep if nvals > 1 & !mi(id2014_2)
	drop nvals
	tempfile cross_2010_2015_n
	save `cross_2010_2015_n'
restore

merge m:1 id2014_2 using `cross_2010_2015_u', update

	preserve
		keep if _merge == 1 & !mi(id2015_1) & ///
				!inlist(id2015_1,1214036014,7325060019,9419033009,9419033010)
			// unmerged villages are amalgamations
		drop _merge
		merge 1:m id2015_1 using `cross_2010_2015_n', update	
			assert _merge != 1
			keep if _merge >= 3
			drop _merge
		tempfile m1
		save `m1'
	restore
	
drop if _merge == 1 & !mi(id2015_1) & ///
		!inlist(id2015_1,1214036014,7325060019,9419033009,9419033010)
drop _merge

append using `m1'

drop if inlist(id2014,9419022009,9419022010) & mi(id2013_2)

order *2010* *2011* *2012* *2013* *2014* *2015* *2016* *2017* *2018* *2019* ///
	  *2020* *2021* *2022* *2023* *2024*
sort id2010* id2011* id2012* id2013* id2014* id2015* id2016* id2017* id2018* ///
	 id2019_1 id2019_2 id2020_1 id2020_2 id2021_1 id2022_1 id2023_1 id2024_1, ///
	 stable

sort id2014_2, stable
	 
* Fill in missing values in problematic subdistricts

foreach x in id nm {
	replace `x'2014_1 = `x'2014_2 ///
		if mi(`x'2014_1) & inrange(id2014_2,9432010006,9432010036)
}

foreach i of numlist 9432010030/9432010036 {
	replace id2013_1 = 9432010002 if id2014_1 == `i'
	replace nm2013_1 = "MABUALEM" if id2014_1 == `i'
}

foreach i of numlist 9432010016/9432010029 {
	replace id2013_1 = 9432010003 if id2014_1 == `i'
	replace nm2013_1 = "WERINGGIK" if id2014_1 == `i'
}

foreach i of numlist 9432010006/9432010010 {
	replace id2013_1 = 9432010004 if id2014_1 == `i'
	replace nm2013_1 = "WELAREK" if id2014_1 == `i'
}

foreach i of numlist 9432010011/9432010015 {
	replace id2013_1 = 9432010005 if id2014_1 == `i'
	replace nm2013_1 = "PISANGGO" if id2014_1 == `i'
}	

foreach x in id nm {
	replace `x'2013_2 = `x'2013_1 ///
		if mi(`x'2013_2) & inrange(id2013_1,9432010001,9432010005)
}
	
* 1998-2013 crosswalk - obs w/ unique values of id2013_1

preserve
	use "$work/cross_1998_2013.dta", clear
	bys id2013_1: gen nvals = _N
	keep if nvals == 1
	drop nvals
	tempfile cross_1998_2013_u
	save `cross_1998_2013_u'
restore

* 1998-2013  crosswalk - obs w/ nonunique values of id2013_1

preserve
	use "$work/cross_1998_2013.dta", clear
	bys id2013_1: gen nvals = _N
	keep if nvals != 1
	drop nvals
	recode id2013_1 (1302010001 = 1302011001)
	tempfile cross_1998_2013_n
	save `cross_1998_2013_n'	
restore

merge m:1 id2013_1 using `cross_1998_2013_u', update replace

	forval x = 10/13 {
		bys id20`x'_1: gen nvals20`x' = _N if !mi(id20`x'_1)
	}
	
	preserve
		keep if _merge == 1 & nvals2013 == 1
		drop _merge
		merge 1:m id2013_1 using `cross_1998_2013_n', update replace
			assert _merge != 1
			keep if _merge >= 3
			drop _merge
		tempfile m2013
		save `m2013'
	restore
	
	drop if _merge == 1 & nvals2013 == 1
	
	forval yr = 2010/2012 {
		
		preserve
			keep if _merge == 1 & nvals`yr' == 1 & nvals2013 > 1 ///
					& !mi(nvals2013)
			drop _merge		
			merge 1:m id`yr'_1 using `cross_1998_2013_n', update replace
				assert _merge != 1
				keep if _merge >= 3
				drop _merge
			tempfile m`yr'
			save `m`yr''
		restore
		
		drop if _merge == 1 & nvals`yr' == 1 & nvals2013 > 1 & !mi(nvals2013)
	}
	
drop _merge 
	
forval yr = 2010/2013 {
	append using `m`yr''
}
  
foreach yr of numlist 2024(-1)1998 1996 {
	order *`yr'*
}	  

* Merge in manual crosswalk for 2013-2014

preserve
	local filename "manual_village_crosswalk_podes_2013_2014"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	tempfile manual_2013_2014
	save `manual_2013_2014'
restore

merge m:1 idpodes14 nmpodes14 using `manual_2013_2014', update
	assert _merge != 2
	gen manual_cross_1314 = _merge >= 3
	
	* Filling in earlier IDs and names
	sort id2013_1 id2012_1
	forval yr = 1998/2012 {
		foreach v of varlist *`yr'* {
			by id2013_1: replace `v' = `v'[_n-1] ///
				if mi(`v') & _merge >= 3 & id2013_1 == id2013_1[_n-1]
		}
	}
	
	drop _merge

* Fix cases where crosswalk got the timing of splits wrong
	* Splits happened by 2014, as child villages appear in PODES 2014
	* Below: child village names start with 2016_2
	
foreach i of numlist ///
		9429040001/9429040004 9429010004 9429020004 9429050003 9429060001 ///
		9429060004 9429070002 9429030002 9429030004 9419040001 ///
		9429010001/9429010003 9429020001/9429020003 9429030001 9429030003 ///
		9429050001 9429050002 9429050004 9429060002 9429060003 9429070001 ///
		9429070004 9429080001/9429080004 9429070003 9402110028 9402110009 ///
		9402111003 9402181005 9402181002 9402221003 9402221009 9402222003 ///
		9402222004 9402220034 9402220030 9402220001 9402112018 9402112008 ///
		9402120011 9402112017 9408043011 9408044002 9408044004 9408044005 ///
		9408050024 9408051001/9408051003 9408051006 9408051009 9408061008 ///
		9408061009 9408070010 9408070013 9408072001 9408080001 9418044002 ///
		9418044004 9418044005 9418045001 9418045002 9418045004 9418045006 ///
		9418122001/9418122005 9418044001 9418020058 9419021005 9419021008 ///
		9419022001 9419021001 9419021011 9419031004 9419050008 9104051004 ///
		9104100004 7403071006 7403071004 7403073002 7403073004 7403074010 ///
		1214031012 1214080040 1408050009 6107210003 6107210005/6107210007 ///
		6107210014 6107210015 7106060018 7106070015 7106070011 7106080015 ///
		7106080018 7106080020 7403141001 7403141002 7403141012 7410070025 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2016_2 if id2013_1 == `i'
		replace `x'2014_1  = `x'2016_2 if id2013_1 == `i'
		replace `x'2014_2  = `x'2016_2 if id2013_1 == `i'
		replace `x'podes14 = `x'2016_2 if id2013_1 == `i'
		replace `x'2015_1  = `x'2016_2 if id2013_1 == `i'
		replace `x'2016_1  = `x'2016_2 if id2013_1 == `i'
	}
} 

* Cases where I need to condition on id2016_1

foreach i of numlist ///
		9415040017 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2016_1 if id2016_1 == `i'
		replace `x'2014_1  = `x'2016_1 if id2016_1 == `i'
		replace `x'2014_2  = `x'2016_1 if id2016_1 == `i'
		replace `x'podes14 = `x'2016_1 if id2016_1 == `i'
		replace `x'2015_1  = `x'2016_1 if id2016_1 == `i'
		replace `x'2016_1  = `x'2016_1 if id2016_1 == `i'
	}
}

* Cases where I need to condition on id2016_2

foreach i of numlist ///
		9414011012 9419053006 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2016_2 if id2016_2 == `i'
		replace `x'2014_1  = `x'2016_2 if id2016_2 == `i'
		replace `x'2014_2  = `x'2016_2 if id2016_2 == `i'
		replace `x'podes14 = `x'2016_2 if id2016_2 == `i'
		replace `x'2015_1  = `x'2016_2 if id2016_2 == `i'
		replace `x'2016_1  = `x'2016_2 if id2016_2 == `i'
	}
}

* Cases where I need to condition on id2017_1

foreach i of numlist ///
		9414063009 7412010015 7412040020 7412040021 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2017_1 if id2017_1 == `i'
		replace `x'2014_1  = `x'2017_1 if id2017_1 == `i'
		replace `x'2014_2  = `x'2017_1 if id2017_1 == `i'
		replace `x'podes14 = `x'2017_1 if id2017_1 == `i'
		replace `x'2015_1  = `x'2017_1 if id2017_1 == `i'
		replace `x'2016_1  = `x'2017_1 if id2017_1 == `i'
		replace `x'2017_1  = `x'2017_1 if id2017_1 == `i'
	}
} 

* Cases where I need to condition on id2017_2

foreach i of numlist ///
		7403102016 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2017_2 if id2017_2 == `i'
		replace `x'2014_1  = `x'2017_2 if id2017_2 == `i'
		replace `x'2014_2  = `x'2017_2 if id2017_2 == `i'
		replace `x'podes14 = `x'2017_2 if id2017_2 == `i'
		replace `x'2015_1  = `x'2017_2 if id2017_2 == `i'
		replace `x'2016_1  = `x'2017_2 if id2017_2 == `i'
		replace `x'2017_1  = `x'2017_2 if id2017_2 == `i'
	}
} 

* Cases where I need to condition on id2018_1

foreach i of numlist ///
		9107101006 9107101007 9107112009 9107170016 9412032010/9412032014 ///
		9412032015 8103143013 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2018_1 if id2018_1 == `i'
		replace `x'2014_1  = `x'2018_1 if id2018_1 == `i'
		replace `x'2014_2  = `x'2018_1 if id2018_1 == `i'
		replace `x'podes14 = `x'2018_1 if id2018_1 == `i'
		replace `x'2015_1  = `x'2018_1 if id2018_1 == `i'
		replace `x'2016_1  = `x'2018_1 if id2018_1 == `i'
		replace `x'2017_1  = `x'2018_1 if id2018_1 == `i'
	}
} 

* Cases where I need to condition on id2018_2

foreach i of numlist ///
		9107122009 9107172009 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2018_2 if id2018_2 == `i'
		replace `x'2014_1  = `x'2018_2 if id2018_2 == `i'
		replace `x'2014_2  = `x'2018_2 if id2018_2 == `i'
		replace `x'podes14 = `x'2018_2 if id2018_2 == `i'
		replace `x'2015_1  = `x'2018_2 if id2018_2 == `i'
		replace `x'2016_1  = `x'2018_2 if id2018_2 == `i'
		replace `x'2017_1  = `x'2018_2 if id2018_2 == `i'
		replace `x'2018_1  = `x'2018_2 if id2018_2 == `i'
	}
} 

* Fix cases where crosswalk got the timing of splits wrong
	* Splits happened by 2014, as child villages appear in PODES 2014
	* Below: child village names start with 2017_2
	
foreach i of numlist ///
		9432010001 9432020001 9432020002 9432030001/9432030009 ///
		9432040001/9432040004 9432050001/9432050004 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2017_2 if id2013_1 == `i'
		replace `x'2014_1  = `x'2017_2 if id2013_1 == `i'
		replace `x'2014_2  = `x'2017_2 if id2013_1 == `i'
		replace `x'podes14 = `x'2017_2 if id2013_1 == `i'
		replace `x'2015_1  = `x'2017_2 if id2013_1 == `i'
		replace `x'2016_1  = `x'2017_2 if id2013_1 == `i'
		replace `x'2016_2  = `x'2017_2 if id2013_1 == `i'
		replace `x'2017_1  = `x'2017_2 if id2013_1 == `i'
	}
} 	

* Fix cases where crosswalk got the timing of splits wrong
	* Splits happened by 2014, as child villages appear in PODES 2014
	* Below: child village names start with 2018_1
	
foreach i of numlist ///
		9402121002 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2018_1 if id2013_1 == `i'
		replace `x'2014_1  = `x'2018_1 if id2013_1 == `i'
		replace `x'2014_2  = `x'2018_1 if id2013_1 == `i'
		replace `x'podes14 = `x'2018_1 if id2013_1 == `i'
		replace `x'2015_1  = `x'2018_1 if id2013_1 == `i'
		replace `x'2016_1  = `x'2018_1 if id2013_1 == `i'
		replace `x'2016_2  = `x'2018_1 if id2013_1 == `i'
		replace `x'2017_1  = `x'2018_1 if id2013_1 == `i'
	}
} 

foreach i of numlist ///
		9432020028 9432020029 9432010012 9432010023 9432030001 9432030022 ///
		9432030034 9432030054 9432030060/9432030062 9432030072 9432030077 ///
		9432030081 9432030082 9432030087 9432030089/9432030092 9432030094 ///
		9432030095 9432030105/9432030108 9432040013 9432040022 9432040030 ///
		9432040038 9432040042/9432040045 9432040050 9432050006 ///
		9432050011/9432050013 9432050018 9432050019 9432050022 ///
		9432050025/9432050029 9432050032/9432050034 {
	foreach x in id nm {
		cap replace `x'2014 = `x'2013_1 if id2017_2 == `i'
		replace `x'2014_1  = `x'2013_1 if id2017_2 == `i'
		replace `x'2014_2  = `x'2013_1 if id2017_2 == `i'
		replace `x'podes14 = `x'2013_1 if id2017_2 == `i'
	}
}

foreach x in id nm {
	replace `x'2014_1 = `x'2014_2 ///
		if mi(`x'2014_1) & inrange(id2014_2,9432020046,9432020050)
}

foreach i of numlist ///
		9429040010/9429040018 9429041002/9429041006 9429042002/9429042005 ///
		9429043002/9429043013 9429010021/9429010023 9429023002/9429023005 /// 
		9429052002/9429052014 9429061002/9429061006 9429063002/9429063008 ///
		9429070008/9429070011 9429070029 9429072001/9429072006 ///
		9429073001/9429073005 9429034003/9429034014 9419041004 ///
		9429011002/9429011008 9429012002/9429013005 9429020013/9429020025 ///
		9429021003/9429021009 9429022001/9429022006 9429030008 9429030009 ///
		9429031002/9429031004 9429032001/9429032004 9429033001/9429033004 ///
		9429050018/9429050028 9429050053/9429050058 9429051003/9429051020 ///
		9429060034/9429060037 9429060010/9429060015 9429062001/9429062010 ///
		9429090007 9429060020/9429060029 9429071002/9429071006 ///
		9429080006/9429080010 9429081002/9429081004 9429082002/9429082004 ///
		9429090002/9429090007 9432010038/9432010043 9432010045/9432010054 ///
		9432010055 9432010057/9432010060 9432010062 9432010064 ///
		9432020040/9432020051 9432020024/9432020035 9432030011/9432030033 ///
		9432030036/9432030042 9432030046/9432030056 9432030044 ///
		9432030028/9432030032 9432030058/9432030062 9432030099/9432030106 ///
		9432030074 9432030076 9432030065/9432030067 9432030069 9432030071 ///
		9432030072 9432030086/9432030089 9432030091 9432030095 9432030110 ///
		9432030077/9432030084 9432040005/9432040012 9432040014 9432040045 ///
		9432040015/9432040020 9432040022/9432040028 9432040030 9432040031 ///
		9432040047 9432040032/9432040035 9432040037/9432040039 9432040044 ///
		9432040046 9432040049 9432040050 9432050021 9432050005/9432050008 ///
		9432050015/9432050035 9402114008 9402114009 9402118019 9402181009 ///
		9402181010 9402221018 9402221019 9402222013 9402222014 9402223043 ///
		9402223044 9402225009 9402611009 9402612008 9402612009 9402123007 ///
		9402124008 9402611008 9408043111 9408044021 9408044041 9408044051 ///
		9408050241 9408051111 9408051211 9408051212 9408051311 9408051611 ///
		9408051911 9408061811 9408061912 9408061913 9408070019 9408070019 ///
		9408072111/9408072114 9408070023 9418044007 9418044009 9418044010 ///
		9418045007/9418045009 9418545003/9418545010 9418044006 9418020059 ///
		9419021012 9419021013 9419022008 9419023001 9419023002 9419023005 ///
		9419031013 9419053003 9419053005 9419033004 ///
		9419033005 9104051011 9104100010 9107101006 9107101007 9107112009 ///
		9107122008 9107170017 9107172005 9110070025 9110071008 9110071009 ///
		9110071010 9110081006 9110081007 9110081008 9409092003/9409092005 ///
		9412032010 9412032015 9412032010/9412032015 9414011012 9414011012 ///
		9414063007 9415040017 7412010015 7412040021 7412040024 7412050010 ///
		7412050011 7412060011 7412060012 7412010014 1214031012 1214080042 ///
		1214035013 1408050023 6107210024/6107210029 7106060020 7106070019 ///
		7106070020 7106080023/7106080025 7403102015 7403141002 7403141027 ///
		7403141028 7410070031 8103143013 {
	drop if mi(id2014_1) & id2014 == `i'
}

drop if id2014_1 == 9418040001 & id2014 == 9418044006

foreach v in id2014 id2014_1 id2014_2 idpodes14 {
	recode `v' (9429011006 = 9429011002) (9429011007 = 9429011003) ///
			   (9429011008 = 9429011004) (9429011002 = 9429011005) ///
			   (9429011003 = 9429011006) (9429011004 = 9429011007) ///
			   (9429011005 = 9429011008) (9429020008 = 9429020013) ///
			   (9429020009 = 9429020014) (9429020010 = 9429020015) ///
			   (9429020011 = 9429020016) (9429020012 = 9429020017) ///
			   (9429020013 = 9429020018) (9429020014 = 9429020019) ///
			   (9429021007 = 9429021003) (9429021008 = 9429021004) ///
			   (9429021009 = 9429021008) (9429021002 = 9429021005) ///
			   (9429021003 = 9429021006) (9429021004 = 9429021007) ///
			   (9429021005 = 9429021009) (9429030005 = 9429030008) ///
			   (9429030006 = 9429030009) (9429050034 = 9429050053) ///
			   (9429050035 = 9429050054) (9429050036 = 9429050055) ///
			   (9429050037 = 9429050056) (9429050038 = 9429050057) ///
			   (9429050039 = 9429050058) (9429051002 = 9429051003) ///
			   (9429051003 = 9429051004) (9429051004 = 9429051005) ///
			   (9429051005 = 9429051006) (9429051006 = 9429051007) ///
			   (9429051007 = 9429051008) (9429051008 = 9429051009) ///
			   (9429051009 = 9429051010) (9429051010 = 9429051011) ///
			   (9429051011 = 9429051012) (9429051012 = 9429051013) ///
			   (9429051013 = 9429051014) (9429051014 = 9429051015) ///
			   (9429060034 = 9429060020) (9429060035 = 9429060021) ///
			   (9429060036 = 9429060022) (9429060037 = 9429060023) ///
			   (9429060010 = 9429060024) (9429060011 = 9429060025) ///
			   (9429060012 = 9429060026) (9429060013 = 9429060027) ///
			   (9429060014 = 9429060028) (9429060015 = 9429060029) ///
			   (9429074007 = 9429090007) (9429080005 = 9429080006) ///
			   (9429080006 = 9429080007) (9429074002 = 9429090002) ///
			   (9429074003 = 9429090003) (9429074004 = 9429090004) ///
			   (9429074005 = 9429090005) (9429074006 = 9429090006) ///
			   (9432010006 = 9432010038) (9432010007 = 9432010039) ///
			   (9432010008 = 9432010040) (9432010009 = 9432010041) ///
			   (9432010010 = 9432010042) (9432010011 = 9432010043) ///
			   (9432010013 = 9432010045) (9432010014 = 9432010046) ///
			   (9432010015 = 9432010047) (9432010016 = 9432010048) ///
			   (9432010017 = 9432010049) (9432010018 = 9432010050) ///
			   (9432010019 = 9432010051) (9432010020 = 9432010052) ///
			   (9432010021 = 9432010054) (9432010022 = 9432010055) ///
			   (9432010024 = 9432010057) (9432010025 = 9432010058) ///
			   (9432010026 = 9432010059) (9432010027 = 9432010060) ///
			   (9432010030 = 9432010053) ///
			   (9432010028 = 9432010064) (9432020005 = 9432020040) ///
			   (9432020006 = 9432020041) (9432020007 = 9432020042) ///
			   (9432020008 = 9432020043) (9432020009 = 9432020044) ///
			   (9432020010 = 9432020045) (9432020011 = 9432020046) ///
			   (9432020012 = 9432020047) (9432020013 = 9432020048) ///
			   (9432020014 = 9432020049) (9432020015 = 9432020050) ///
			   (9432020016 = 9432020051) (9432020017 = 9432020024) ///
			   (9432020018 = 9432020025) (9432020019 = 9432020026) ///
			   (9432020020 = 9432020027) (9432020021 = 9432020028) ///
			   (9432020022 = 9432020029) (9432020023 = 9432020030) ///
			   (9432020024 = 9432020031) (9432020025 = 9432020032) ///
			   (9432020026 = 9432020033) (9432020027 = 9432020035) ///
			   (9432030036 = 9432030012) ///
			   (9432030037 = 9432030013) (9432030038 = 9432030014) ///
			   (9432030039 = 9432030015) (9432030040 = 9432030016) ///
			   (9432030041 = 9432030017) (9432030042 = 9432030018) ///
			   (9432030043 = 9432030019) (9432030055 = 9432030058) ///
			   (9432030056 = 9432030059) ///
			   (9432040016 = 9432040015) (9432040017 = 9432040016) ///
			   (9432040018 = 9432040017) (9432040019 = 9432040018) ///
			   (9432040020 = 9432040019) (9432040021 = 9432040020) ///
			   (9432040023 = 9432040022) (9432040024 = 9432040023) ///
			   (9432040025 = 9432040024) (9432040026 = 9432040025) ///
			   (9432040027 = 9432040026) (9432040028 = 9432040027) ///
			   (9432040029 = 9432040028) (9432040031 = 9432040030) ///
			   (9432040032 = 9432040031) (9432040033 = 9432040047) ///
			   (9432040034 = 9432040032) (9432040035 = 9432040033) ///
			   (9432040036 = 9432040034) (9432040037 = 9432040035) ///
			   (9432040039 = 9432040037) (9432040040 = 9432040038) ///
			   (9432040041 = 9432040039) (9432050007 = 9432050018) ///
			   (9432050008 = 9432050019) (9432050017 = 9432050035) ///
			   (9432050023 = 9432050008) (9432050024 = 9432050009) ///
			   (9432050037 = 9432050031) ///
			   (9402120029 = 9402124008) (9408043012 = 9408043111) ///
			   (9408044007 = 9408044021) (9408044008 = 9408044041) ///
			   (9408044009 = 9408044051) (9408050026 = 9408050241) ///
			   (9408051017 = 9408051111) (9408051018 = 9408051211) ///
			   (9408051019 = 9408051212) (9408051020 = 9408051311) ///
			   (9408051021 = 9408051021) (9408051022 = 9408051911) ///
			   (9408061014 = 9408061811) (9408061015 = 9408061913) ///
			   (9408061016 = 9408061912) (9408070023 = 9408070019) ///
			   (9408070024 = 9408070023) (9408072002 = 9408072111) ///
			   (9408072003 = 9408072112) (9408072004 = 9408072114) ///
			   (9408072005 = 9408072113) (9418543009 = 9418545003) ///
			   (9418543010 = 9418545004) (9418543011 = 9418545005) ///
			   (9418543012 = 9418545006) (9418543013 = 9418545007) ///
			   (9418543014 = 9418545008) (9418543015 = 9418545009) ///
			   (9418543016 = 9418545010) (9419021017 = 9419021012) ///
			   (9419021018 = 9419021013) (9419022007 = 9419022008) ///
			   (9419025001 = 9419023001) (9419025002 = 9419023002) ///
			   (9419025005 = 9419023005) (9419053005 = 9419053003) ///
			   (9419053006 = 9419053005) (9107122009 = 9107122008) ///
			   (9107170016 = 9107170017) (9107172009 = 9107172005) ///
			   (9412032012 = 9412032010) (9412032010 = 9412032015) ///
			   (9412032013 = 9412032012) (9412032014 = 9412032013) ///
			   (9412032015 = 9412032014) (9419053006 = 9419053007) ///
			   (7412050011 = 7412050010) (7412050010 = 7412050011) ///
			   (7412060012 = 7412060011) (7412060011 = 7412060012) ///
			   (7403102016 = 7403102015) (7403141029 = 7403141027) ///
			   (7403143006 = 7403141028) ///
			   (7403143007 = 7403141012)  ///
			   (9110071010 = 9110071008) (9408051021 = 9408051611) ///
			   (9408061013 = 9408061911) (9408070020 = 9408070021) ///
			   (9408070021 = 9408070020) (9408080007 = 9408080111) ///
			   (9418543008 = 9418545002) (9418543014 = 9418545008) ///
			   (9419025003 = 9419023003) (1408050012 = 1408050013) ///
			   (1408050013 = 1408050012) (5321110005 = 5321110006) ///
			   (5321110006 = 5321110005) ///
			   if !manual_cross_1314
			   
}

foreach v in id2014 id2014_1 id2014_2 idpodes14 {
	recode `v' (9432030011 = 9432030023) (9432030020 = 9432030033) ///
			   (9432030021 = 9432030027) (9432030023 = 9432030054) ///
			   (9432030024 = 9432030055) (9432030025 = 9432030056) ///
			   (9432030035 = 9432030011) ///
			   (9432030063 = 9432030099) (9432030064 = 9432030100) ///
			   (9432030065 = 9432030101) (9432030066 = 9432030102) ///
			   (9432030067 = 9432030103) (9432030068 = 9432030104) ///
			   (9432030071 = 9432030074) (9432030073 = 9432030076) ///
			   (9432030074 = 9432030065) (9432030075 = 9432030066) ///
			   (9432030076 = 9432030067) ///
			   (9432030079 = 9432030071) (9432030080 = 9432030072) ///
			   (9432030083 = 9432030086) (9432030084 = 9432030087) ///
			   (9432030085 = 9432030088) ///
			   (9432030093 = 9432030095) ///
			   (9432030096 = 9432030110) (9432030097 = 9432030077) ///
			   (9432030098 = 9432030078) (9432030099 = 9432030079) ///
			   (9432030100 = 9432030080) (9432030101 = 9432030081) ///
			   (9432030102 = 9432030082) (9432030103 = 9432030083) ///
			   (9432030104 = 9432030084) ///
			   (9432040049 = 9432040050) (9432030045 = 9432030036) ///
			   (9432050030 = 9432050015) ///
			   (9432050005 = 9432050016) ///
			   (9432050009 = 9432050020) (9432050020 = 9432050005) ///
			   (9432050010 = 9432050021) (9432050021 = 9432050006)
}

foreach v in id2014 id2014_1 id2014_2 idpodes14 {
	recode `v' (9432030012 = 9432030024) if nm2014_1 == "SOHOMBUNU"
	recode `v' (9432030013 = 9432030025) if nm2014_1 == "BUMBUM"
	recode `v' (9432030014 = 9432030026) if nm2014_1 == "BURIM"
	recode `v' (9432030015 = 9432030028) if nm2014_1 == "MASANAHIKMA"
	recode `v' (9432030016 = 9432030029) if nm2014_1 == "ABAGIMA"
	recode `v' (9432030017 = 9432030030) if nm2014_1 == "WAGHASILIMO"
	recode `v' (9432030018 = 9432030031) if nm2014_1 == "WILEROMA"
	recode `v' (9432030019 = 9432030032) if nm2014_1 == "OBABIN"
	recode `v' (9432030026 = 9432030046) if nm2014_1 == "LILINMUHUK"
	recode `v' (9432030046 = 9432030037) if nm2014_1 == "YANAMIK"
	recode `v' (9432030027 = 9432030047) if nm2014_1 == "HULHUE"
	recode `v' (9432030047 = 9432030038) if nm2014_1 == "LANGONGKOK"
	recode `v' (9432030028 = 9432030048) if nm2014_1 == "MAHIAL"
	recode `v' (9432030048 = 9432030039) if nm2014_1 == "HELAKSILI"
	recode `v' (9432030029 = 9432030049) if nm2014_1 == "ALUGI"
	recode `v' (9432030049 = 9432030040) if nm2014_1 == "BUKURIK"
	recode `v' (9432030030 = 9432030050) if nm2014_1 == "SAHIKMA"
	recode `v' (9432030050 = 9432030041) if nm2014_1 == "KEWI"
	recode `v' (9432030031 = 9432030051) if nm2014_1 == "BONAHIK"
	recode `v' (9432030051 = 9432030042) if nm2014_1 == "YAMBAIKMA"
	recode `v' (9432030032 = 9432030052) if nm2014_1 == "ELIEKMA"
	recode `v' (9432030033 = 9432030053) if nm2014_1 == "YABUSUP"
	recode `v' (9432030057 = 9432030060) if nm2014_1 == "WILAK"
	recode `v' (9432030058 = 9432030061) if nm2014_1 == "WANGKUN"
	recode `v' (9432030059 = 9432030062) if nm2014_1 == "HOMBANMAN"
	recode `v' (9432030078 = 9432030069) if nm2014_1 == "MULIP"
	recode `v' (9432030086 = 9432030089) if nm2014_1 == "KESUWI"
	recode `v' (9432030088 = 9432030091) if nm2014_1 == "WABUHUK"
	recode `v' (9432030069 = 9432030105) if nm2014_1 == "MALEO"
	recode `v' (9432030070 = 9432030106) if nm2014_1 == "USABIYE"
	recode `v' (9432040046 = 9432040044) if nm2014_1 == "PASIMBOLO"
	recode `v' (9432040015 = 9432040045) if nm2014_1 == "BULMU"
	recode `v' (9432040047 = 9432040046) if nm2014_1 == "WEKOLANI"
	recode `v' (9432040048 = 9432040049) if nm2014_1 == "FIMA"
	recode `v' (9432050031 = 9432050025) if nm2014_1 == "KAMIKA"
	recode `v' (9432050035 = 9432050029) if nm2014_1 == "YAKWA"
	recode `v' (9432050036 = 9432050030) if nm2014_1 == "WERMAS"
	recode `v' (9432050014 = 9432050032) if nm2014_1 == "IKON"
	recode `v' (9432050015 = 9432050033) if nm2014_1 == "KEY"
	recode `v' (9432050016 = 9432050034) if nm2014_1 == "LAWE"
	
}

foreach i in 9432030047 9432030053 9432030060 9432030061 9432030062 9432030089 ///
			 9432030091 9432030105 9432030103 9432030106 9432030107 9432030108 ///
			 9432040044 9432040045 9432050025 9432050029 9432050032 9432050033 ///
			 9432050034 9432050036 9432030052 {
	foreach x in id nm {
		foreach y in 2014 2014_1 2014_2 podes14 {
			cap replace `x'`y' = `x'2013_1 if id2016_1 == `i'
		}
	}  
}

foreach v in id2014 id2014_1 id2014_2 idpodes14 {
	recode `v' (9402123006 = 9402123007) if nm2018_1 == "ENTAGEKOMA"
	recode `v' (7412040020 = 7412040021) if nm2017_1 == "SAWAH INDAH"
	recode `v' (7412040021 = 7412040024) if nm2017_1 == "TEPOLAWA"
}

* Fix names
replace nmpodes14 = "NAIN BARU" ///
	if idpodes14 == 7106060020 & nmpodes14 == "NAIN SATU"
	
foreach v of varlist nm*14* {
	replace `v' = "GUNUNG BINANGA" ///
		if `v' == "MOMBANG BORU" & id2014 == 1203101041
}	

foreach v of varlist nm*18* nm*19* nm*20* nm*21* {
	replace `v' = "GUNUNG BINANGA" ///
		if `v' == "MOMBANG BORU" & id2021_1 == 1203101041
}

foreach v of varlist nm*18* nm*19* {
	replace `v' = nm2017_1 if `v' == "TOBING TINGGI" & id2019_1 == 1221090045
	replace `v' = nm2017_1 if `v' == "PARAN TONGA" & id2019_1 == 1221090082
}
	
* Fill in missing code and names
replace idpodes14 = id2014 if mi(idpodes14) & id2014 == 1704010012
replace id2013_2 = id2013_1 if mi(id2013_2) & id2013_1 == 1704010012
replace nm2013_2 = nm2013_1 if mi(nm2013_2) & id2013_1 == 1704010012
replace bps_2014 = 1704 if mi(bps_2014) & id2013_1 == 1704010012
sort id2013_1 id2014
forval yr = 14/21 {
	foreach v of varlist nm*`yr'* {
		replace `v' = nm2013_1 if mi(`v') & id2013_1 == 1704010012
	}
}	

* Fill in missing names when code is nonmissing
foreach x in 2013_2 2014_1 2014_2 podes14 2015_1 2015_2 2016_1 2016_2 ///
			 2017_1 2017_2 2018_1 2018_2 2019_1 2019_2 2020_1 2020_2 ///
			 2021_1 {
	replace nm`x' = nm2013_1 if mi(nm`x') & id`x' == id2013_1		 	
}

* Fill in remaining missing names when code is nonmissing
gsort id2013_1 id2014_1 -nm2014_1
foreach x in 2014_1 2014_2 podes14 2015_1 2015_2 2016_1 2016_2 ///
			 2017_1 2017_2 2018_1 2018_2 2019_1 2019_2 2020_1 2020_2 ///
			 2021_1 {
	by id2013_1: replace nm`x' = nm`x'[_n-1] ///
		if mi(nm`x') & id2013_1 == id2013_1[_n-1] & id`x' == id`x'[_n-1] 
}

* Generate name for merge with PODES 2014
gen nm2014 = nmpodes14
replace nm2014 = nm2014_1 if mi(nm2014)

* Fill in missing id2014
replace id2014 = id2014_1 if mi(id2014)

* Fixing codes
foreach i of numlist ///
		5321010009/5321010012 5321020001/5321020016 5321030001/5321030014 ///
		5321040001/5321040020 5321080001/5321080009 5321050001/5321050007 ///
		5321070001/5321070017 5321100001/5321100006 5321090001/5321090009 ///
		5321120001/5321120004 8208030006 8208030007 8208060002/8208060004 {
	replace id2014 = id2014_1 if id2014_1 == `i'
}

foreach i of numlist ///
		9110081004 {
	replace id2014 = id2013_1 if id2013_1 == `i'
}

foreach v of varlist id2020* {
	recode `v' ///
		(5208030007 = 5208030006) (5208030006 = 5208030008) ///
		(5208030008 = 5208030007) (5208040009 = 5208040010) ///
		(5208040010 = 5208040009)
}

foreach v of varlist id2019* {
	recode `v' ///
		(8206041010 = 8206041014) (8206041014 = 8206041010) ///
		(9411090008 = 9411090010) (9411090010 = 9411090008)
}

replace id_sp2010 = id2010_1 if mi(id_sp2010) & id2010_1 == 9402110028
replace nm_sp2010 = nm2010_1 if mi(nm_sp2010) & id2010_1 == 9402110028

* Tidying
order *96* *98* *99* *2000* *2001* *2002* *2003* *2004* *2005* *2006* *06* ///
	  *2007* *2008* *08* *2009* *2010* *11* *12* *13* *14* *2015* *2016* *2017* ///
	  *2018* *2019* *2020* *2021* *2022* *2023* *2024*
	  
* BITAUNI / AINIUT (kec 5305040) and KULOLAME / LOSMEN / WANIMO (kec 9418020): the BPS
	* links between 2011 and 2014 are crossed, so each pair of villages has three rows
	* here, two of them mixing the two lineages. Lineages by code, name and households:
	* - 2011 BITAUNI 5305040032 (BISAIN in PODES 2011, 220 hh) = 2014 BITAUNI 5305040032
	*   (221 hh); AINIUT 5305040008 in both years (338 and 321 hh)
	* - 2008 WANIMO 9418020058 = 2011 LOSMEN 9418020058 (38 hh) = 2014 LOSMEN 9418020063
	*   (38 hh) = 2018 WANIMO 9418020063 = 2025 WANIMO/LOSMEN; KULOLAME 9418020059 in
	*   2008-2014 = 2018-2025 KULUNAME
	* Row a: own 2011 lineage, other village's later codes; row b: the reverse; row c:
	* repeats a lineage. Swap the later codes of rows a and b, drop row c.
gen long __o = _n
qui ds id* nm*
local v1424
foreach v in `r(varlist)' {
	if regexm("`v'", "^(id|nm)(20(1[4-9]|2[0-4])|podes14)") local v1424 `v1424' `v'
}
foreach k in BITAUNI KULOLAME {
	if "`k'" == "BITAUNI" {
		gen byte __a = id2011_1 == 5305040032 & id2014 == 5305040008
		gen byte __b = id2011_1 == 5305040008 & id2014 == 5305040032
		gen byte __c = id2011_1 == 5305040008 & id2014 == 5305040008 ///
			& id2013_2 == 5305040008
		local swap id2013_2 nm2013_2 `v1424'
	}
	if "`k'" == "KULOLAME" {
		gen byte __a = id2011_1 == 9418020058 & id2014 == 9418020059
		gen byte __b = id2011_1 == 9418020059 & id2014 == 9418020063
		gen byte __c = id2011_1 == 9418020059 & id2014 == 9418020059
		local swap `v1424'
	}
	foreach x in a b c {
		qui count if __`x'
		assert r(N) == 1
	}
	gsort -__a -__b
	foreach v of local swap {
		clonevar __t = `v'
		qui replace __t = `v'[2] in 1
		qui replace __t = `v'[1] in 2
		qui replace `v' = __t in 1/2
		drop __t
	}
	drop if __c
	drop __a __b __c
}
sort __o
drop __o	  

* Save
save "$work/cross_1998_2024.dta", replace

********************************************************************************
**# MERGE 05-25
* Merging villages: 2005-2025
********************************************************************************

preserve
	local filename "manual_village_crosswalk_podes_2005_2008"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	replace notes = notes[_n-1] if mi(notes)
	bys id2008_1 nm2008_1: gen nvals=_N
	tab nm2008_1 if nvals > 1
	assert nvals == 1
restore

* Divide 2024-2025 temporary crosswalk into splitters and non-splitters

use "$work/cross_2024_2025.dta", clear

bys id2024_1 nm2024_1: gen nvals = _N

preserve
	keep if nvals == 1
	drop nvals
	tempfile nonsplit2425
	save `nonsplit2425'
restore

preserve
	keep if nvals > 1	
	gen byte notcont = id2025 != id2024_1
	bys id2024_1 (notcont id2025 nm2025): gen tempid = _n
	drop nvals notcont
	tempfile split2425
	save `split2425'
restore

* Merge 1998-2024 crosswalk w/ 2024-2025 temporary crosswalk
* Splitters: each 2025 village gets a copy of every crosswalk row of its 2024
* village (one row per 2024 village, or one per 2021 component if it amalgamated)

use `split2425', clear
joinby id2024_1 nm2024_1 using "$work/cross_1998_2024.dta", ///
	unmatched(master) update
	assert _merge == 3
	drop _merge

tempfile splitters
save `splitters'

keep id2024_1 nm2024_1
duplicates drop
tempfile splitvlg
save `splitvlg'

use `nonsplit2425', clear
merge 1:m id2024_1 nm2024_1 using "$work/cross_1998_2024.dta", update
	assert _merge != 1
	drop _merge

* Drop the crosswalk rows of 2024 villages that split in 2025 (in `splitters')
merge m:1 id2024_1 nm2024_1 using `splitvlg', keep(master) nogenerate

append using `splitters'

* 2025

merge m:1 id2025 nm2025 using "$work/podes2025.dta", update
	assert _merge != 2
	drop _merge

* 2024

merge m:1 id2024_1 using "$work/podes2024.dta", update replace
	assert _merge != 2
	drop _merge

* 2021: preliminaries

foreach i in 1108120025 1308030011 1308051003 1505020008 1505021003 1505021007 ///
			 5206091002 8205021016 9426030015 9426030016 9426030011 9426030007 ///
			 9426030012 9426030006 1102032002 {
	foreach yr in 2021_1 {
		foreach x in id nm {
			replace `x'`yr' = `x'2024_1 if id2024_1 == `i'
		}
	}
}

* 2021

merge m:1 id2021_1 using "$work/podes2021.dta", update replace
	assert _merge != 2	
	drop _merge	
	
* 2020: preliminaries

gen tochange = 0

foreach b in 5208 5302 5313 {
	replace tochange = 1 if inrange(id2020_2,`b'000000,`b'999999)
}

foreach i in 6311050018 7403181002 7403181003 7403181017 7315042006 7403181010 {
	replace tochange = 1 if id2020_2 == `i'
}

foreach x in id nm {
	replace `x'2020_1 = `x'2020_2 if tochange
}	

drop tochange

foreach x in id nm {
	replace `x'2020_1 = `x'2019_1 if id2019_1 == 9430010030
}

foreach i in 8205021016 {
	foreach yr in 2020_1 2020_2 {
		foreach x in id nm {
			replace `x'`yr' = `x'2021_1 if id2024_1 == `i'
		}
	}
}


* 2020: merge										

merge m:1 id2020_1 using "$work/podes2020.dta", update replace
	assert _merge != 2
	drop _merge	

* 2019: preliminaries	

gen tochange = 0

foreach i in 9412032011 9412032012 9412032013 9412032014 9412032015 8272041002 {
	replace tochange = 1 if id2019_2 == `i'
}

foreach x in id nm {
	replace `x'2019_1 = `x'2019_2 if tochange
	replace `x'2019_1 = `x'2019_2 if mi(`x'2019_1)
}

foreach i in 9410092007 9410073005 9430010030 9410080016 9410091006 9410091007 ///
			 8205021016 {
	replace id2019_1 = id2020_1 if id2020_1 == `i'
	replace id2019_2 = id2020_1 if id2020_1 == `i'
}

drop tochange

preserve
	local filename "manual_village_crosswalk_podes_2019_2020"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	tempfile manual_2019_2020
	save `manual_2019_2020'
restore

merge m:1 id2020_1 nm2020_1 using `manual_2019_2020', update replace
	drop _merge
										
* 2019: merge										

merge m:1 id2019_1 using "$work/podes2019.dta", update replace
	drop _merge

format %10.0f id2019

* 2018: preliminaries

foreach i in 9108044007 9402222002 9430010030 8272041002 {
	replace id2018_1 = id2019_1 if mi(id2018_1) & id2019_1 == `i'
	replace nm2018_1 = nm2019_1 if mi(id2018_1) & id2019_1 == `i'
}

* Fake village with 6 residents and 3 village officials
	//https://www.indonesiana.id/read/135809/jokowi-bicara-desa-siluman-inilah-faktanya-dihuni-6-orang-tapi-punya-4-rt-dan-2-rw
foreach v in nm2019_1 nm2019_2 {
	replace `v' = "NESOWI UTAMA (fake village)" if `v' == "NESOWI UTAMA"
}

replace nm2018_1 = nm2018_2 if id2018_2 == 9107122009
recode id2018_1 (9107122009 = 9107122008) if id2018_2 == 9107122009

replace nm2018_1 = nm2018_2 if id2018_2 == 9107172009
recode id2018_1 (9107172009 = 9107172010) if id2018_2 == 9107172009

* 2018: merge										

merge m:1 id2018_1 using "$work/podes2018.dta", update replace
	drop _merge

* 2014: preliminaries

foreach i of numlist ///
		9408070020 9408070021 7325060019 {
	foreach x in id nm {
		foreach v in `x'2014 `x'2014_1 `x'podes14 {
			replace `v' = `x'2014_2 if id2014_2 == `i'
		}
	}
}

foreach i of numlist ///
		6107060025/6107060038 6107070014/6107070016 6107080030 6107080031 ///
		6107110034 6107200021/6107200029 6107210019/6107210023 7403143011 ///
		9418543014 9427030010 9432030103 {
	foreach x in id nm {
		foreach v in `x'2014 `x'2014_1 `x'2014_2 `x'podes14 ///
					 `x'2015_1 `x'2015_2 {
			replace `v' = `x'2016_1 if id2016_1 == `i'
		}
	}
}

foreach i of numlist ///
		6107070017/6107070033 6107110035/6107110040 6107140016/6107140029 ///
		6107150021 6107150025 6107150027 6107160027/6107160043 ///
		6107190018/6107190024 9402222012 9408051021 9414011012 {
	foreach x in id nm {
		foreach v in `x'2014 `x'2014_1 `x'2014_2 `x'podes14 `x'2015_1 `x'2015_2 ///
					 `x'2016_1 `x'2016_2 {
			replace `v' = `x'2017_2 if id2017_2 == `i'
		}
	}
}

foreach i of numlist ///
		9110070025 9110071008/9110071010 9110081006/9110081008 1214036014 ///
		9432010062 9432020038 9432020030 9432020031/9432020043 9432020050 ///
		9432030120 9432030121 9432030122 9432030116 9432030110 9432050039 {
	foreach x in id nm {
		foreach v in `x'2014 `x'2014_1 `x'2014_2 `x'podes14 `x'2015_1 `x'2015_2 ///
					 `x'2016_1 `x'2016_2 `x'2017_1 `x'2017_2 {
			replace `v' = `x'2018_1 if id2018_1 == `i'
		}
	}
	foreach x in id nm {
		foreach v in `x'2014 `x'2014_1 `x'2014_2 `x'podes14 `x'2015_1 `x'2015_2 ///
					 `x'2016_1 `x'2016_2 `x'2017_1 `x'2017_2 `x'2018_1 {
			replace `v' = `x'2018_2 if mi(`v') & id2018_2 == `i'
		}
	}
}

recode id2014 (9419053003 = 9419053001) if nm2014 == "NANOT"
recode id2014 (9409092003 = 9427030010) if id2014_1 == 9427030010

foreach v in id2014 id2014_1 id2014_2 idpodes14 {
	recode `v' (1214036014 = 1214036004) if nm2014 == "HILIKARA"
	recode `v' (9432010062 = 9432010063) if nm2014 == "NANGGKULAMULAM"
	recode `v' (9432010029 = 9432010062) if nm2014 == "AMULUK"
	recode `v' (9432020038 = 9432020052) if nm2014 == "HAROHON NAMIK"
	recode `v' (9432020030 = 9432020053) if nm2014 == "YOHUL"
	recode `v' (9432020031 = 9432020009) if nm2014 == "LILINSALUK"
	recode `v' (9432020032 = 9432020010) if nm2014 == "NATOKSILI"
	recode `v' (9432020033 = 9432020011) if nm2014 == "HINONGKOAMBUT"
	recode `v' (9432020034 = 9432020012) if nm2014 == "WIYUKWILIK"
	recode `v' (9432020035 = 9432020013) if nm2014 == "FARI"
	recode `v' (9432020036 = 9432020014) if nm2014 == "WASALALO"
	recode `v' (9432020037 = 9432020015) if nm2014 == "SUERELIHIM"
	recode `v' (9432020039 = 9432020017) if nm2014 == "HABALO"
	recode `v' (9432020040 = 9432020018) if nm2014 == "SABIKALEM"
	recode `v' (9432020041 = 9432020019) if nm2014 == "WANAMALO"
	recode `v' (9432020042 = 9432020020) if nm2014 == "KUNDIKELE"
	recode `v' (9432020043 = 9432020021) if nm2014 == "KELAMPURIM"
	recode `v' (9432020050 = 9432020022) if nm2014 == "HOLUKALEM"
	recode `v' (9432030120 = 9432030020) if nm2014 == "JINGGIWI"
	recode `v' (9432030121 = 9432030021) if nm2014 == "HURUALMA"
	recode `v' (9432030122 = 9432030022) if nm2014 == "HUMALMA"
	recode `v' (9432030116 = 9432030034) if nm2014 == "ELESIM"
	recode `v' (9432030110 = 9432030073) if nm2014 == "YANGKIKALMA"
	recode `v' (9432030103 = 9432030083) if nm2014 == "SENGIKMA"
	recode `v' (9432050023 = 9432050008) if nm2014 == "KUTAKURUK"
	recode `v' (9432050024 = 9432050009) if nm2014 == "NARAU"
	recode `v' (9432050039 = 9432050030) if nm2014 == "WERMAS"
	recode `v' (9432050017 = 9432050035) if nm2014 == "KUKDOMOL"
}

replace nm2014 = "OROHON" if nm2014 == "HAROHON NAMIK" & id2014 == 9432020052
 
foreach v of varlist nm*14* {
	replace `v' = "GUNUNG BINANGA" ///
		if `v' == "MOMBANG BORU" & id2014 == 1203101041
}

foreach v of varlist nm*14* nm*15* nm*16* nm*17* {
	replace `v' = "BLAU" ///
		if `v' == "DUSUN BARU/SUKASERI" & id2014 == 1707040005
}

recode id2014 (9429021001 = 9429021002) if nm2014 == "URUGI"
recode id2014 (9429021006 = 9429021001) if nm2014 == "PARIS"

foreach v in id*14* {
	recode `v' (9429051015 = 9429051002) if nm2014 == "YIMOGI"
}

foreach v in id2014 id2014_1 id2014_2 idpodes14 {
	recode `v' ///
		(9110071008 = 9110071010) (9110071010 = 9110071008) ///
		(9110081008 = 9110081007) (9110081007 = 9110081008) ///
		(7403143011 = 7403141029) (9429070012 = 9429070029) ///
		(9429074001 = 9429090001) 
}

preserve
	local filename "manual_village_crosswalk_podes_2014_2018"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	replace notes = notes[_n-1] if mi(notes)	
	tempfile manual_2014_2018
	save `manual_2014_2018'
restore

merge m:1 id2018 nm2018 using `manual_2014_2018', update replace
	gen manual_cross_1418 = _merge >= 3
	drop _merge
	
local fillvars
foreach x in 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2018 manual_cross_1418 id2014 id2014_1 nm2014 nm2018 id2024_1 nm2024_1 ///
	id2025 nm2025 id2011_1 nm2011_1	`fillvars'
	
foreach x in 17 16 15 14 13 12 11 10 09 08 07 06 05 04 03 02 01 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2018 == id2018[_n-1] & manual_cross_1418 ///
				& !mi(id2018)
	}
}

local fillvars
foreach x in 14 13 12 11 10 09 08 07 06 05 04 03 02 2001 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2014 manual_cross_1418 id2014_1 nm2014 id2018 nm2018 id2024_1 nm2024_1 ///
	id2025 nm2025 id2011_1 nm2011_1	`fillvars'
	
foreach x in 14 13 12 11 10 09 08 07 06 05 04 03 02 2001 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2014 == id2014[_n-1] & manual_cross_1418 ///
				& !mi(id2014)
	}
}

sort id2014 id2018 nm2014 nm2018 id2024_1 nm2024_1 id2025 nm2025 ///
	id2011_1 nm2011_1
foreach i in 9432020017 9432020011 9432020021 9432020013 9432020020 9432020009 ///
			 9432020010 9432020018 9432020015 9432020019 9432020014 9432020049 ///
			 9432020012 9432020022 {
	foreach x in 14 13 12 11 10 09 08 07 06 05 04 03 02 2001 000 999 98 96 {
		foreach v of varlist id*`x'* nm*`x'* {
			if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
			replace `v' = `v'[_n+1] ///
				if mi(`v') & id2014 == id2014[_n+1] & id2014 == `i'
		}
	}
	drop if mi(id2018) & id2014 == `i'
}	

replace id2014 = id2015_1 if id2015_1 == 7325060019

* 2014-only rows of 2014 villages that the manual 2014-2018 crosswalk linked to a 2018
	* row (the fill above has copied their earlier codes to that row). Without this
	* drop both rows get the 2014 data and later fills copy the 2018-2025 codes into
	* the 2014-only row, so the village appears twice (the second time w/o 2018+ data)
bys id2014: egen byte __lk = max(manual_cross_1418 & !mi(id2018))
drop if __lk & mi(id2018) & !mi(id2014)
drop __lk

foreach i of numlist ///
		7412070011 {
	foreach x in id nm {
		foreach v in `x'2014 `x'2014_1 `x'2014_2 `x'podes14 `x'2015_1 `x'2015_2 ///
					 `x'2016_1 `x'2016_2 `x'2017_1 `x'2017_2 {
			replace `v' = `x'2018_1 if id2018_1 == `i'
		}
	}
}

replace id2014 = idpodes14 if idpodes14 == 9107122008
replace nm2014 = nmpodes14 if idpodes14 == 9107122008

foreach x in 2014 2014_1 2014_2 {
	recode id`x' (9101060012 = 9101060007)
	replace nm`x' = "WAGOM" if nm`x' == "WAGOM UTARA"
}

* 2014: merge

merge m:1 id2014 using "$work/podes2014.dta", update replace
	* Rows w/ a 2014 record and no 2013 code in crosswalk: assume no code change
	replace id2013_1 = id2014 if mi(id2013_1) & _merge >= 2
	replace nm2013_1 = nm2014 if mi(nm2013_1) & _merge >= 2
	drop _merge
	
* 2011: preliminaries	

* 2011: Replacing missing id2008_1 in crosswalk
	* (Assuming no amalgamations)
	
local id id1998 id2000 id2002 id2003 id2005 id2008_1
local nm nm1998 nm2000 nm2002 nm2003 nm2005 nm2008_1

sort id2011_1 id2008_1 id2014 nm2014 id2018 nm2018 id2024_1 nm2024_1 ///
	id2025 nm2025 nm2011_1

foreach x of local id {
	gen double temp = `x'
	by id2011_1: replace temp = temp[_n-1] ///
		if mi(temp) & id2011_1 == id2011_1[_n-1]	
	by id2011_1: replace `x' = temp[_N] ///
		if mi(`x') & id2011_1 == id2011_1[_n-1] & !mi(id2011_1)
	qui drop temp
}

foreach x of local nm {
	gen temp = `x'
	by id2011_1: replace temp = temp[_n-1] ///
		if mi(temp) & id2011_1 == id2011_1[_n-1]	
	by id2011_1: replace `x' = temp[_N] ///
		if mi(`x') & id2011_1 == id2011_1[_n-1] & !mi(id2011_1)
	qui drop temp
}

* 2011: Fill in missing values of crosswalk assuming no splits or code changes

foreach x in nm id {
	qui replace `x'2011_1 = `x'2013_1 if mi(`x'2011_1)
}

recode id2011_1 (9408061811 = 9408061008)

* 2011: manual crosswalk

preserve
	local filename "manual_village_crosswalk_podes_2011_2014"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	replace notes = notes[_n-1] if mi(notes)	
	tempfile manual_2011_2014
	save `manual_2011_2014'
restore

merge m:1 id2014 nm2014 using `manual_2011_2014', update replace
	gen manual_cross_1114 = _merge >= 3
	drop _merge
	
local fillvars
foreach x in 13 12 11 10 09 08 07 06 05 04 03 02 01 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2014 manual_cross_1114 id2011_1 nm2014 id2018 nm2018 id2024_1 ///
	nm2024_1 id2025 nm2025 nm2011_1 `fillvars'
	
foreach x in 13 12 11 10 09 08 07 06 05 04 03 02 01 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2014 == id2014[_n-1] & manual_cross_1114 ///
				& !mi(id2014)
	}
}

local fillvars
foreach x in 11 10 09 08 07 06 05 04 03 02 2001 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2011_1 manual_cross_1114 id2014 nm2014 id2018 nm2018 id2024_1 nm2024_1 ///
	id2025 nm2025 nm2011_1 `fillvars'
	
foreach x in 11 10 09 08 07 06 05 04 03 02 2001 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2011_1 == id2011_1[_n-1] & manual_cross_1114 ///
				& !mi(id2011_1)
	}
}

* 2011: fixing timing of split

forval i = 9107172001/9107172003 {
	replace nm2011_1 = "AIMAS" if id2011_1 == `i'
	recode id2011_1 (`i' = 9107170005)
}

replace nm2011_1 = "AYATA" if id2011_1 == 9110031005
recode id2011_1 (9110031005 = 9110111002)

recode id2011_1 (9418024011	= 9418027003) if nm2011_1 == "GUBURINI"

foreach x in 2011_1 2011_2 {
	recode id`x' (9101060012 = 9101060007)
	replace nm`x' = "WAGOM SELATAN" if nm`x' == "WAGOM UTARA"
}

* 2011: merge

* PODES 2011 records, with a match key and a marker
preserve
	use "$work/podes2011.dta", clear
	gen byte in2011 = 1
	gen double id11_key = id2011_1
	* Keep record's own 2011 code and name, so they travel through merges below
	clonevar p11_id = id2011_1
	clonevar p11_nm = nm2011_1
	tempfile podes2011_m
	save `podes2011_m'
	keep id2011_1 nm2011_1 id2011_2 id_podes11 id_ppls11
	rename (id2011_1 nm2011_1) (r11_id r11_nm)
	tempfile podes2011_keys
	save `podes2011_keys'
restore

* Match key: the crosswalk's 2011 code, except for villages that have their own PODES
	* 2011 record although the crosswalk gives them another village's 2011 code (the
	* crosswalk's 2011 codes lag PODES 2011, and some 2011 codes were reused). A
	* record that no row's 2011 code claims, and that the alternative-ID merges below
	* would not give to a row without a record, goes to
	* (1) the rows whose 2012, 2013 or 2014 code and name equal its code and name,
	*     unless the record their 2011 code claims has that name or their 2014 name;
	* (2) else the one lineage (2014 code and name) whose 2014 name equals its name in
	*     the same kecamatan (of the 2014 or the crosswalk 2011 code), if the lineage
	*     holds no record or a record with another name, and the match is one-to-one;
	* (3) else the same within the kabupaten.
	* Repeated, because a row that takes its own record releases the one its 2011
	* code claimed.
local maxstage11 3
gen double id11_key = id2011_1
gen long __row11 = _n
preserve
	keep __row11 id2011_1 nm2011_1 id2012_1 nm2012_1 id2013_1 nm2013_1 id2014 ///
		nm2014 id2011_2 id_podes11 id_ppls11
	gen double r11_id = id2011_1
	merge m:1 r11_id using `podes2011_keys', ///
		keep(master match) keepusing(r11_nm)
	gen claimed_nm = r11_nm if _merge == 3
	gen byte claim11 = _merge == 3
	drop _merge r11_id r11_nm
	* Rows whose 2011 code claims no record: the record an alternative ID claims
	tempfile rows11
	save `rows11'
	foreach idvar in id2011_2 id_podes11 id_ppls11 {
		use `idvar' r11_nm using `podes2011_keys', clear
		drop if mi(`idvar')
		bys `idvar': keep if _N == 1
		rename r11_nm alt_nm
		tempfile alt
		save `alt'
		use `rows11', clear
		merge m:1 `idvar' using `alt', keep(master match) nogenerate
		replace claimed_nm = alt_nm if mi(claimed_nm)
		drop alt_nm
		save `rows11', replace
	}

	clear
	gen long __row11 = .
	gen double r11_id = .
	gen byte stage11 = .
	gen byte round11 = .
	tempfile pairs11
	save `pairs11'

	forval round = 1/3 {

		* Rows not yet paired
		use `rows11', clear
		merge 1:1 __row11 using `pairs11', ///
			keep(master) keepusing(__row11) nogenerate
		tempfile unp11
		save `unp11'

		* Free records: not claimed by an unpaired row's 2011 code or (if that row
		* has no record) its alternative IDs, and not yet paired
		use `podes2011_keys', clear
		drop if mi(r11_nm)
		gen double id2011_1 = r11_id
		merge 1:m id2011_1 using `unp11', ///
			keep(master) keepusing(id2011_1) nogenerate
		drop id2011_1
		tempfile free11
		save `free11'
		foreach idvar in id2011_2 id_podes11 id_ppls11 {
			use `unp11', clear
			keep if !claim11 & !mi(`idvar')
			keep `idvar'
			if _N duplicates drop
			tempfile alt
			save `alt'
			use `free11', clear
			merge m:1 `idvar' using `alt', keep(master) nogenerate
			save `free11', replace
		}
		use `pairs11', clear
		keep r11_id
		if _N duplicates drop
		merge 1:1 r11_id using `free11', keep(using) nogenerate
		keep r11_id r11_nm
		save `free11', replace

		* (1) Exact code and name
		clear
		gen long __row11 = .
		tempfile new11
		save `new11'
		local s 0
		foreach k in 2012_1 2013_1 2014 {
			local ++s
			use `unp11', clear
			keep if !mi(id`k') & !(id`k' == id2011_1 & nm`k' == nm2011_1) ///
				& (mi(claimed_nm) | !inlist(claimed_nm, nm`k', nm2014))
			gen double r11_id = id`k'
			gen r11_nm = nm`k'
			merge m:1 r11_id r11_nm using `free11', keep(match) nogenerate
			keep __row11 r11_id
			gen byte ord = `s'
			append using `new11'
			save `new11', replace
		}
		bys __row11 (ord): keep if _n == 1
		drop ord
		gen byte stage11 = 1
		save `new11', replace

		* (2), (3) 2014 name within the kecamatan, then within the kabupaten
		foreach d in 1000 1000000 {
			local st = cond(`d' == 1000, 2, 3)
			if `st' > `maxstage11' continue
			use `new11', clear
			keep r11_id
			if _N duplicates drop
			merge 1:1 r11_id using `free11', keep(using) nogenerate
			tempfile left11
			save `left11'
			use `unp11', clear
			merge 1:1 __row11 using `new11', ///
				keep(master) keepusing(__row11) nogenerate
			keep if !mi(id2014, nm2014) & (mi(claimed_nm) | claimed_nm != nm2014)
			gen r11_nm = nm2014
			joinby r11_nm using `left11'
			keep if floor(r11_id/`d') == floor(id2014/`d') ///
				| floor(r11_id/`d') == floor(id2011_1/`d')
			egen long g = group(id2014 nm2014)
			gen byte ok = 1
			bys r11_id (g): replace ok = 0 if g[1] != g[_N]
			bys g (r11_id): replace ok = 0 if r11_id[1] != r11_id[_N]
			keep if ok
			keep __row11 r11_id
			gen byte stage11 = `st'
			append using `new11'
			save `new11', replace
		}

		gen byte round11 = `round'
		append using `pairs11'
		save `pairs11', replace
	}
restore

merge 1:1 __row11 using `pairs11', keep(master match) nogenerate
replace id11_key = r11_id if !mi(r11_id)
tab stage11 round11
drop __row11 r11_id stage11 round11

merge m:1 id11_key using `podes2011_m', update
drop id11_key

	* Exact merge on alternative ID

	foreach idvar in id2011_2 id_podes11 id_ppls11 {

		gen unmerged = mi(in2011) | _merge == 2

		preserve
			tempfile temp
			keep if _merge == 2
			drop _merge
			save `temp'
		restore

		drop if _merge == 2
		drop _merge

		merge m:1 `idvar' unmerged using `temp', update
		
		drop unmerged

	}

	* Merge if id2011_1 == id2013_1 AND desa name matches
	
	tempvar desaID
	gen `desaID' = id2013_1
	replace `desaID' = id2011_1 if mi(id2013_1)
	
	gen unmerged = mi(in2011) | _merge == 2

	preserve
		tempfile temp
		keep if _merge == 2 & !mi(`desaID',desa)
		drop _merge
		save `temp'
	restore

	drop if _merge == 2 & !mi(`desaID',desa)
	drop _merge

	merge m:1 `desaID' desa unmerged using `temp', update
	
	drop unmerged
	
	* Fix missing id2008_1 and nm2008_1
	
	recode id2002 id2003 id2005 id2006 id2007 id2007_2 id2008_1 id2008_2 ///
		id2009_1 id2009_2 ///
		(. = 1302010001) if id2011_1 == 1302010001
		
	foreach v in nm2002 nm2003 nm2005 nm2007 nm2007_2 nm2008_1 nm2008_2 ///
				 nm2009_1 nm2009_2 {
		qui replace `v' = "SILAUT" if mi(`v') & id2011_1 == 1302010001
	} 	
	
	qui replace nm2006 = "NAGARI SILAUT" if mi(nm2006) & id2011_1 == 1302010001
	
	foreach v in id2005 id2006 id2007 id2007_2 id2008_1 id2008_2 id2009_1 ///
				 id2009_2 {
		qui replace `v' = id2011_1 ///
			if mi(`v') & inlist(id2011_1,1309110001,1309111001)
	}
	
	foreach v in nm2009_1 nm2009_2 {
		qui replace `v' = "PANTI" if mi(`v') & id2011_1 == 1309110001
		qui replace `v' = "PADANG GALUGUA" if mi(`v') & id2011_1 == 1309111001
	}
	
	foreach v in nm2005 nm2007 nm2007_2 nm2008_1 nm2008_2 {
		qui replace `v' = "NAGARI PANTI" if mi(`v') & id2011_1 == 1309110001
		qui replace `v' = "NAGARI PADANG GALUGUA" ///
			if mi(`v') & id2011_1 == 1309111001
	}	
	
drop _merge

* 2010: manual crosswalk

preserve
	local filename "manual_village_crosswalk_podes_2010_2011"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	replace notes = notes[_n-1] if mi(notes)	
	tempfile manual_2010_2011
	save `manual_2010_2011'
restore

merge m:1 id2011_1 nm2011_1 using `manual_2010_2011', update replace
	gen manual_cross_1011 = _merge >= 3
	drop _merge
	
* 2010: fix timing of amalgamations

foreach i in 1971010016 1971041007 {
	replace nm2011_1 = nm2010_1 if id2011_1 == `i'
	replace id2011_1 = id2010_1 if id2011_1 == `i'
}	

* 2010: fix timing of splits and recodings

foreach i of numlist ///
		9417032002 9417032005 9417032007 9417032008 9417032010 ///
		9417032016/9417032019 9417032021/9417032024 {
	replace nm2010_1 = nm_sp2010 if id_sp2010 == `i'
	replace id2010_1 = id_sp2010 if id_sp2010 == `i'
}

foreach x in "2008_1" "2008_2" "_sp2010" {
	
	replace nm`x' = "WAISAI" if inrange(id`x',9108043002,9108043004)
	replace id`x' = 9108040021 if inrange(id`x',9108043002,9108043004)
	
	replace nm`x' = "RAUKI" if inrange(id`x',9108062002,9108062003)
	replace id`x' = 9108060009 if inrange(id`x',9108062002,9108062003)
	
}

foreach x in "2005" "2008_1" "2008_2" "_sp2010" {
	
	replace nm`x' = "PRINGGASELA" if id_sp2010 == 5203051007
	replace id`x' = 5203051002 ///
		if id_sp2010 == 5203051007 & nm2011_1 == "PRINGGASELA SELATAN"
		
	replace nm`x' = "LANDAU KUMPANG" if id_sp2010 == 6108030015	
	replace id`x' = 6108030004 ///
		if id_sp2010 == 6108030015 & nm2011_1 == "KARYA MANDIRI"	
		
	replace nm`x' = "MAPURA" if id_sp2010 == 9110081004	
	replace id`x' = 9110080008 ///
		if id_sp2010 == 9110081004 & nm2011_1 == "UTWET"	
	
}

recode id_sp2010 (9110081002 = 9110080008)

foreach x in "2005" "2008_1" "2008_2" "_sp2010" {
	
	replace id`x' = 6108010009 ///
		if id_sp2010 == 6108010013 & nm2011_1 == "BUKIT PENAI"
	replace nm`x' = "PENAI" if id`x' == 6108010009	
	
}

replace nm2005 = "MOHIYOLO" if id_sp2010 == 7502043009
replace id2005 = 7502042006 ///
	if id_sp2010 == 7502043009 & nm2011_1 == "BIHE"	
	
foreach x in "2008_1" "2008_2" "_sp2010" {

	replace nm`x' = "MOHIYOLO" if id_sp2010 == 7502043009
	replace id`x' = 7502043002 ///
		if id_sp2010 == 7502043009 & nm2011_1 == "BIHE"	
		
}	

replace nm_sp2010 = "AIMAS" if id2011_1 == 9107170016
replace id_sp2010 = 9107170005 if id2011_1 == 9107170016

* 2010: merge

* Add a marker so rows with a record from this wave can be identified
preserve
	use "$work/pop2010.dta", clear
	gen byte in2010 = 1
	clonevar p10_id = id2010_1
	clonevar p10_nm = nm2010_1
	clonevar sp10_id = id_sp2010
	clonevar sp10_nm = nm_sp2010
	tempfile pop2010_m
	save `pop2010_m'
restore

merge m:1 id2010_1 using `pop2010_m', update

foreach idvar in id2010_2 id_sp2010 id_rd2010 {

	gen unmerged = mi(in2010) | _merge == 2

	preserve
		tempfile temp
		keep if _merge == 2
		drop _merge
		save `temp'
	restore

	drop if _merge == 2
	drop _merge

	merge m:1 `idvar' unmerged using `temp', update
	
	drop unmerged

}

drop _merge

* 2008: Preliminaries

recode id2008_2 (9108011010 = 9108011001)
replace nm2008_2 = "YELLU" if nm2008_2 == "DABATAN"

recode id2008_2 (9108021004 = 9108021003)
replace nm2008_2 = "DEER" if nm2008_2 == "MIKIRAN"

recode id2008_1 (9417060002 = 9417051008)
recode id2008_2 (9417060002 = 9417051008)

* 2008: Fill in missing values of crosswalk assuming no splits or code changes

foreach x in nm id {
	qui replace `x'2008_1 = `x'2011_1 if mi(`x'2008_1)
	qui replace `x'2008_1 = `x'2011_2 if mi(`x'2008_1)	
}

recode id2008_1 (7303031002 = 7303031015) if id2011_1 == 7303031021

* 2008: manual crosswalk

preserve
	local filename "manual_village_crosswalk_podes_2008_2011"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	replace notes = notes[_n-1] if mi(notes)
	tempfile manual_2008_2011
	save `manual_2008_2011'
restore

merge m:1 id2011_1 nm2011_1 using `manual_2008_2011', update replace
	gen manual_cross_0811 = _merge >= 3
	drop _merge
	
* Yalimo (9432): the 2011 villages KULET, WAMBO, WAMBALFAK, HUBLIKI, LANDIKMA &
	* TRIKORA each have crosswalk rows with the 2011 code and no 2014-2025 codes 
	* (their 2012-2013 children; the 2014 villages are linked by the manual 
	* 2011-2014 crosswalk on other rows, which also carry the 2005-2011 records). 
	* The fill below (wildcard id*01*) would copy the 2014-2025 codes of the 
	* last child into these rows (FOREKALO, WANWALU, WAMBAL, USABIYE, SAPIWAREK, 
	* KUKDOMOL), which then appear twice, the second time without 2014+ data. 
	* Drop them
drop if inlist(id2011_1, 9432020001, 9432030001, 9432030002, 9432030006, ///
	9432030007, 9432050002) & mi(id2014) & mi(id2018_1)	

local fillvars
foreach x in 10 09 08 07 06 05 04 03 02 01 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2011_1 manual_cross_0811 id2008_1 id2014 nm2014 id2018 nm2018 id2024_1 ///
	nm2024_1 id2025 nm2025 nm2011_1 `fillvars'
	
foreach x in 10 09 08 07 06 05 04 03 02 01 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2011_1 == id2011_1[_n-1] & manual_cross_0811 ///
				& !mi(id2011_1)
	}
}

local fillvars
foreach x in 08 07 06 05 04 03 02 2001 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}	
sort id2008_1 manual_cross_0811 id2014 nm2014 id2018 nm2018 id2024_1 nm2024_1 ///
	id2025 nm2025 id2011_1 nm2011_1	`fillvars'
	
foreach x in 08 07 06 05 04 03 02 2001 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2008_1 == id2008_1[_n-1] & manual_cross_0811 ///
				& !mi(id2008_1)
	}
}	

* PALUAN / TALUAN (kec 6408020): PODES 2005 and 2008 have codes 027 and 042 the 
	* other way round from the BPS lists and PODES 2010-2011 
	* (027 = PALUAN, 042 = TALUAN). Population: PALUAN 95 (2005, code 042), 
	* 96 (2008, 042 "PALUAN"), 92 (2010, 027),
	* 99 (2011, 027); TALUAN 87 (2005, 027), 72 (2008, 027 "TALUAN"), 
	* 70 (2010, 042), 61 (2011, 042). 
	* Village characteristics agree (author's analysis).
	* Both PODES 2005 records are named PALUAN; TALUAN row gets record's name
gen byte __pal = id2011_1 == 6408020027 & id2008_1 == 6408020027
gen byte __tal = id2011_1 == 6408020042 & id2008_1 == 6408020042
foreach x in pal tal {
	qui count if __`x'
	assert r(N) == 1
}
foreach v in id2005 id2008_1 id2008_2 {
	replace `v' = 6408020042 if __pal
	replace `v' = 6408020027 if __tal
}
replace nm2005 = "PALUAN" if __tal
drop __pal __tal

* 2008: merge

* PODES 2008 records, with match keys and a marker
preserve
	use "$work/podes2008.dta", clear
	gen double id08_key = id2008_1
	gen nm08_key = nm2008_1
	gen byte in2008 = 1
	clonevar p08_id = id2008_1
	clonevar p08_nm = nm2008_1
	tempfile podes2008
	save `podes2008'
	keep id08_key nm08_key
	gen byte rec08 = 1
	tempfile podes2008_keys
	save `podes2008_keys'
restore

* Match key: semester-1 code and name, except for villages created during 2008
	* (semester-2 code or name differs) that have their own PODES 2008 record
	* under the semester-2 code and name
gen double id08_key = id2008_2
gen nm08_key = nm2008_2
merge m:1 id08_key nm08_key using `podes2008_keys', keep(master match) nogenerate
gen byte use_sem2 = rec08 == 1 & (id2008_2 != id2008_1 | nm2008_2 != nm2008_1)
replace id08_key = id2008_1 if !use_sem2
replace nm08_key = nm2008_1 if !use_sem2
drop rec08 use_sem2

cap drop idusing
cap drop idmaster
gen idmaster = _n

reclink2 id08_key nm08_key using `podes2008', ///
	idmaster(idmaster) idusing(idusing) gen(score) required(id08_key) ///
	manytoone minscore(.97)

cap drop Uid08_key
drop _merge
drop id

preserve
	use `podes2008', clear
	gen Unm08_key = nm08_key
	tempfile podes2008U
	save `podes2008U'
restore

merge m:1 id08_key Unm08_key using `podes2008U'

foreach idvar in id2008_1 id2008_2 idpodes08 {
    
	foreach namevar in nm2008_1 nm2008_2 {

		gen unmerged = mi(in2008) | _merge == 2

		preserve
			keep if _merge == 2
			drop _merge
			tempfile temp
			save `temp'
		restore

		drop if _merge == 2
		drop _merge
		replace unmerged = 0 if mi(`namevar') | mi(`idvar')
		
		merge m:1 `idvar' `namevar' unmerged using `temp', update
		
		drop unmerged

	}
	
}

drop _merge
gen _merge = 3 if !mi(in2008, in2011)
replace _merge = 1 if mi(in2008) & !mi(in2011)
replace _merge = 2 if !mi(in2008) & mi(in2011) & mi(in2010)

tempvar tempid
tostring id2008_1, gen(`tempid')
replace `tempid' = substr(`tempid',1,7)

foreach name in nm2008_1 nm2008_2 nmpodes08 {

	cap drop _merge
	gen _merge = 3 if !mi(in2008, in2011)
	replace _merge = 1 if mi(in2008) & !mi(in2011)
	replace _merge = 2 if !mi(in2008) & mi(in2011) & mi(in2010)
	gen unmerged = mi(in2008) | _merge == 2

	preserve
		tempfile temp temp1 temp2
		keep if _merge == 2
		drop _merge
		bys `tempid' `name': gen nprkd = _N if unmerged
		replace nprkd = . if mi(`name') | `tempid' == "."
		save `temp'
		keep if nprkd == 1
		save `temp1'
		use `temp', clear
		keep if nprkd != 1
		save `temp2'
	restore

	drop if _merge == 2
	drop _merge

	bys `tempid' `name': gen nprkd = _N if unmerged
	replace nprkd = . if mi(`name') | `tempid' == "."
	
	merge m:1 `tempid' `name' unmerged nprkd using `temp1', update
	
	append using `temp2'

	drop unmerged nprkd

}

tempvar tempid
tostring id2008_1, gen(`tempid')
replace `tempid' = substr(`tempid',1,4)

foreach name in nm2008_1 nm2008_2 nmpodes08 {

	cap drop _merge
	gen _merge = 3 if !mi(in2008, in2011)
	replace _merge = 1 if mi(in2008) & !mi(in2011)
	replace _merge = 2 if !mi(in2008) & mi(in2011) & mi(in2010)
	gen unmerged = mi(in2008) | _merge == 2

	preserve
		tempfile temp temp1 temp2
		keep if _merge == 2
		drop _merge
		bys `tempid' `name': gen nprkd = _N if unmerged
		replace nprkd = . if mi(`name') | `tempid' == "."
		save `temp'
		keep if nprkd == 1
		save `temp1'
		use `temp', clear
		keep if nprkd != 1
		save `temp2'
	restore

	drop if _merge == 2
	drop _merge

	bys `tempid' `name': gen nprkd = _N if unmerged
	replace nprkd = . if mi(`name') | `tempid' == "."
	
	merge m:1 `tempid' `name' unmerged nprkd using `temp1', update
	
	append using `temp2'

	drop unmerged nprkd

}

* 2005: Fill in missing values of crosswalk assuming no splits or code changes

foreach x in nm id {
	qui replace `x'2005 = `x'2008_1 if mi(`x'2005)
	qui replace `x'2005 = `x'2008_2 if mi(`x'2005)	
}

tostring id2005, gen(temp_id2005)
replace temp_id2005 = subinstr(temp_id2005,"8109","8104",1) ///
	if substr(temp_id2005,1,4) == "8109"
replace temp_id2005 = subinstr(temp_id2005,"7201012","7201010",1) ///
	if substr(temp_id2005,1,7) == "7201012"	
replace temp_id2005 = subinstr(temp_id2005,"7201022","7201020",1) ///
	if substr(temp_id2005,1,7) == "7201022"	
replace temp_id2005 = subinstr(temp_id2005,"7201023","7201020",1) ///
	if substr(temp_id2005,1,7) == "7201023"	
	
destring temp_id2005, replace
replace id2005 = temp_id2005 //if inrange(id2005,8109000000,8109999999)
drop temp_id2005

tostring id2005, gen(temp_id2005)

foreach i of numlist 1221020097 1221040098 {
    replace temp_id2005 = subinstr(temp_id2005,"1221","1203",1) if id2005 == `i'
}

foreach i of numlist 1218011109 1218150101 {
    replace temp_id2005 = subinstr(temp_id2005,"1218","1212",1) if id2005 == `i'
}

replace temp_id2005 = subinstr(temp_id2005,"2171","2071",1) ///
	if inrange(id2005,2171040005,2171081004)

destring temp_id2005, replace

foreach i of numlist 1221020097 1221040098 1218011109 1218150101 {
	replace id2005 = temp_id2005 if id2005 == `i'
}

replace id2005 = temp_id2005 if inrange(id2005,2171040005,2171081004)

drop temp_id2005

recode id2005 (7201060006 = 7201061006) (1210051005 = 1210051003) ///
			  (7104010000 = 7104010008) (1607051002 = 1607050008) ///
			  (1608061006 = 1608060006) 

recode id2005 (6106110004 = 6106110003) if nm2005 == "BENGARAS"

replace id2005 = id2008_1 if id2008_1 == 1218011009

* 2005: more fixes to improve merge:

	* Idea below is to manually create crosswalk when the last village
		* of a kecamatan did not merge and another village in same kecamatan
		* shows drop in pop that is similar to pop of unmerged village
										
recode id2005 (150105016  = 1501050016) (170202109  = 1702021009) ///
			  (1609011001 = 1609010001) (1609012006 = 1609010006) ///
			  (3202180006 = 3202180005) (3202201007 = 3202201006) ///
			  (3202211007 = 3202211002) (3202212009 = 3202212007) ///
			  (3202221005 = 3202220012) (3202280012 = 3202280003) ///
			  (3202290018 = 3202290004) (3202291008 = 3202291004) ///
			  (3202300006 = 3202300001) (3208060018 = 3208060007) ///
			  (3211020011 = 3211020007) (3211080020 = 3211080003) ///
			  (3211090007 = 3211090003) (3211171009 = 3211171008) ///
			  (3211180015 = 3211180009) (3212150018 = 3212150015) ///
			  (3212160016 = 3212160015) (3212220008 = 3212220006) ///
			  (1209010014 = 1209010005) (1209180014 = 1209180010) ///
			  (5205010006 = 5205010003) (5206041007 = 5206040015) ///
			  (5304013004 = 5304011001) (5305022006 = 5305020008) ///
			  (5305022007 = 5305020008) (5305051004 = 5305050004) ///
			  (5305052006 = 5305050016) (5305052007 = 5305050016) ///
			  (5311031006 = 5311030009) (1609050001 = 1609030040) ///
			  (7201020001 = 7201020002) (7201020002 = 7201020004) ///
			  (7201060017 = 7201060003) (7201060002 = 7201061002) ///
			  (7201060015 = 7201060001)
			  
replace nm2005 = "AMASING KOTA" ///
	if nm2005 == "AMASING KOTA BARAT" & id2005 == 8204030044
recode id2005 (8204030044 = 8204030036) if nm2005 == "AMASING KOTA"			   
			  
replace nm2005 = "GUNUNGSARI" ///
	if nm2005 == "TANJUNG REJO" & id2005 == 1803020035
recode id2005 (1803020035 = 1803020008) if nm2005 == "GUNUNGSARI"
	
replace nm2005 = "KARAWANG" ///
	if nm2005 == "PERBAWATI" & id2005 == 3202180005
replace nm2005 = "CIBOLANG" ///
	if nm2005 == "MANGKALAYA" & id2005 == 3202201006
replace nm2005 = "CICANTAYAN" ///
	if nm2005 == "SUKADAMAI" & id2005 == 3202211002
replace nm2005 = "SUKAMULYA" ///
	if nm2005 == "PASIRDATAR INDAH" & id2005 == 3202212007
replace nm2005 = "CIAMBAR" ///
	if nm2005 == "CIBUNARJAYA" & id2005 == 3202220012
replace nm2005 = "CIKIRAY" ///
	if nm2005 == "CIKARAE THOYIBAH" & id2005 == 3202280003
replace nm2005 = "KARANGPAPAK" ///
	if nm2005 == "SUKARAME" & id2005 == 3202290004
replace nm2005 = "CILEUNGSING" ///
	if nm2005 == "GANDASOLI" & id2005 == 3202291004
replace nm2005 = "MEKARJAYA" ///
	if nm2005 == "CIANAGA" & id2005 == 3202300001
replace nm2005 = "SUMBERJAYA" ///
	if nm2005 == "CITIKUR" & id2005 == 3208060007
replace nm2005 = "SINDANGPAKUON" ///
	if nm2005 == "PASIRNANJUNG" & id2005 == 3211020007
replace nm2005 = "NEGLASARI" ///
	if nm2005 == "RANGGON" & id2005 == 3211080003
replace nm2005 = "CIBUGEL" ///
	if nm2005 == "JAYAMANDIRI" & id2005 == 3211090003
replace nm2005 = "JINGKANG" ///
	if nm2005 == "TANJUNGMEDAR" & id2005 == 3211171008
replace nm2005 = "GENDEREH" ///
	if nm2005 == "CIAWITALI" & id2005 == 3211180009
replace nm2005 = "PAOMAN" ///
	if nm2005 == "TAMBAK" & id2005 == 3212150015
replace nm2005 = "BABADAN" ///
	if nm2005 == "WANANTARA" & id2005 == 3212160015
replace nm2005 = "SUMURADEM" ///
	if nm2005 == "KARANGLAYUNG" & id2005 == 3212220006	
replace nm2005 = "PURBA SINOMBAH" ///
	if nm2005 == "SINAR BARU" & id2005 == 1209010005
replace nm2005 = "KANDANGAN" ///
	if nm2005 == "WONOREJO" & id2005 == 1209180010
replace nm2005 = "RASABOU" ///
	if nm2005 == "PERSIAPAN SAWE" & id2005 == 5205010003
replace nm2005 = "TONGGORISA" ///
	if nm2005 == "TONGGONDOA" & id2005 == 5206040015
replace nm2005 = "NOEBESI" ///
	if nm2005 == "TANEOTOP" & id2005 == 5304011001	
replace nm2005 = "MAURISU" ///
	if nm2005 == "MAURISU UTARA" & id2005 == 5305020008
replace nm2005 = "MAURISU" ///
	if nm2005 == "MAURISU SELATAN" & id2005 == 5305020008
replace nm2005 = "T'EBA" ///
	if nm2005 == "T'EBA TIMUR" & id2005 == 5305050004
replace nm2005 = "OEPUAH" ///
	if nm2005 == "OEPUAH UTARA" & id2005 == 5305050016
replace nm2005 = "OEPUAH" ///
	if nm2005 == "OEPUAH SELATAN" & id2005 == 5305050016
replace nm2005 = "REWARANGGA" ///
	if nm2005 == "KEL. REWARANGGA SELATAN" & id2005 == 5311030009

foreach d in "W A I T A" {
	replace nm2005 = subinstr(nm2005," ","",.) if nm2005 == "`d'"
}

* 2005: facilitate merge of villages that later amalgamated 
	* (missed in crosswalk)

recode id2005 (5306032001 = 5306031001) if id2009_1 == 5306031011
replace nm2005 = "UPT TNIUMANU" ///
	if id2005 == 5306031001 & nm2009_1 == "UPT TNIUMANU"
	
recode id2005 (5306032001 = 5306031002) if id2009_1 == 5306031002
	
* 2005: manual crosswalk

cap drop _merge

preserve
	local filename "manual_village_crosswalk_podes_2005_2008"
	import excel "$cross/manual_podes/`filename'", ///
		firstrow clear
	replace notes = notes[_n-1] if mi(notes)
	tempfile manual_2005_2008
	save `manual_2005_2008'
restore

merge m:1 id2008_1 nm2008_1 using `manual_2005_2008', update replace
	gen manual_cross_0508 = _merge >= 3
	drop _merge
	 
local fillvars
foreach x in 07 06 05 04 03 02 01 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2008_1 manual_cross_0508 id2005 id2014 nm2014 id2018 nm2018 id2024_1 ///
	 nm2024_1 id2025 nm2025 id2011_1 nm2011_1 `fillvars'	 
	 
foreach x in 07 06 05 04 03 02 01 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2008_1 == id2008_1[_n-1] & manual_cross_0508 ///
				& !mi(id2008_1)
	}
}

local fillvars
foreach x in 05 04 03 02 2001 000 999 98 96 {
	local fillvars `fillvars' id*`x'* nm*`x'*
}
sort id2005 manual_cross_0508 id2014 nm2014 id2018 nm2018 id2024_1 nm2024_1 ///
	 id2025 nm2025 id2011_1 nm2011_1 `fillvars'
foreach x in 05 04 03 02 2001 000 999 98 96 {
	foreach v of varlist id*`x'* nm*`x'* {
		if regexm("`v'", "20(1[89]|2[0-9])|_podes20") continue
		replace `v' = `v'[_n-1] ///
			if mi(`v') & id2005 == id2005[_n-1] & manual_cross_0508 ///
				& !mi(id2005)
	}
}

* 2005: crosswalk names that differ from the PODES 2005 record under the same 
	* code (reclink2 needs the names to agree). Evidence: same 2005 code; the 
	* PODES 2005 record's 2004 name, or the same name spelled differently; 
	* similar n_hh
replace nm2005 = "GUNUNG TUA PANGGORENGAN" ///
	if nm2005 == "PANGGORENGAN" & id2005 == 1202050074
replace nm2005 = "MANGOLI" if nm2005 == "UPT MANGOLI" & id2005 == 8203040008
replace nm2005 = "BATU REDI" if nm2005 == "MUARA PANTUN*" & id2005 == 6404021006
replace nm2005 = "TIBUL" if nm2005 == "TIMBUL" & id2005 == 9416030022
replace nm2005 = "ALOPUR" if nm2005 == "ALAPUR" & id2005 == 9418020018

* 2005: pairs of villages whose crosswalk 2005 codes are crossed relative to 
	* PODES 2005 (crosswalk gives village A the code under which PODES 2005 has 
	* village B, and the reverse). The PODES 2005 record with the village's own 
	* name fits its PODES 2008 record better, on households and on the other 
	* village characteristics (author's analysis). TUHEGAFOA I: its 
	* own record is otherwise held by no village with later data
replace id2005 = 7171020012 ///
	if id2005 == 7171020011 & nm2005 == "TITIWUNGEN SELATAN"
replace id2005 = 7171020011 ///
	if id2005 == 7171020012 & nm2005 == "TITIWUNGEN UTARA"
replace id2005 = 1311020003 ///
	if id2005 == 1311020002 & nm2005 == "NAGARI KOTO SALAK"
replace id2005 = 1311020002 ///
	if id2005 == 1311020003 & nm2005 == "NAGARI KOTO BARU"
replace id2005 = 1201150042 ///
	if id2005 == 1201150006 & nm2005 == "LASARA SAWO"
replace id2005 = 1201150006 ///
	if id2005 == 1201150042 & nm2005 == "LASARA SOWU"
replace id2005 = 1805080016 ///
	if id2005 == 1805080015 & nm2005 == "BANDAR JAYA TIMUR"
replace id2005 = 1805080015 ///
	if id2005 == 1805080016 & nm2005 == "BANDAR JAYA BARAT"
replace id2005 = 1201130015 ///
	if id2005 == 1201130024 & nm2005 == "TUHEGAFOA I"

* Append PODES 2005 and PODES 2005 Nias; add match keys and a marker

preserve
	use "$work/podes2005.dta", clear
	append using "$work/podes2005nias.dta"
	isid id_podes2005
	sort id2005
	cap drop idusing
	gen idusing = _n
	gen byte in2005 = 1
	clonevar p05_id = id2005
	clonevar p05_nm = nm2005
	gen double id05_key = id2005
	gen nm05_key = nm2005
	tempfile podes2005combined
	save `podes2005combined'
	keep id05_key nm05_key
	gen byte rec05 = 1
	tempfile podes2005_keys
	save `podes2005_keys'
restore

* Match key: 2005 code and name, except for villages whose own PODES 2005
	* record is under their 2008 code and name while the crosswalk gives them
	* another 2005 code or name (e.g. the parent's)
foreach s in 1 2 {
	preserve
		use `podes2005_keys', clear
		ren (id05_key nm05_key rec05) (id2008_`s' nm2008_`s' rec05_`s')
		tempfile keys05_`s'
		save `keys05_`s''
	restore
	merge m:1 id2008_`s' nm2008_`s' using `keys05_`s'', ///
		keep(master match) nogenerate
}
gen byte use08_1 = rec05_1 == 1 & (id2008_1 != id2005 | nm2008_1 != nm2005)
gen byte use08_2 = rec05_2 == 1 & (id2008_2 != id2005 | nm2008_2 != nm2005) ///
				   & !use08_1
gen double id05_key = id2005
gen nm05_key = nm2005
foreach s in 1 2 {
	replace id05_key = id2008_`s' if use08_`s'
	replace nm05_key = nm2008_`s' if use08_`s'
}

* Villages without their own record follow their parent (same 2005 code and
	* name in the crosswalk, same name in 2008) when the crosswalk's 2005 code
	* and name have no PODES 2005 record and the parent is matched on its
	* 2008 code (pre-split waves carry the parent's record)
preserve
	use `podes2005_keys', clear
	ren (id05_key nm05_key rec05) (id2005 nm2005 rec05_0)
	tempfile keys05_0
	save `keys05_0'
restore
merge m:1 id2005 nm2005 using `keys05_0', keep(master match) nogenerate
gen double par05 = id05_key if (use08_1 | use08_2) & nm05_key == nm2005
bys id2005 nm2005: egen double par05_g = max(par05)
replace id05_key = par05_g if !use08_1 & !use08_2 & rec05_0 != 1 & !mi(par05_g)
drop rec05_0 par05 par05_g
drop rec05_1 rec05_2 use08_1 use08_2

* 2005: merge (combined incl. Nias)

cap drop _merge
cap drop score
cap drop idusing
cap drop idmaster
gen idmaster = _n

reclink2 id05_key nm05_key using `podes2005combined', ///
	idmaster(idmaster) idusing(idusing) gen(score) required(id05_key) ///
	manytoone minscore(.97)

preserve
	use `podes2005combined', clear
	gen Unm05_key = nm05_key
	tempfile podes2005combinedU
	save `podes2005combinedU'
restore

merge m:1 id05_key Unm05_key using `podes2005combinedU', gen(_merge2)
	
recode id2005 (1405021002 = 1404011006) if nm2005 == "MAKMUR"
recode id2005 (1406021003 = 1407020012) if nm2005 == "TANDUN"
recode id2005 (1406021005 = 1407021006) if nm2005 == "GITI"
recode id2005 (1610030017 = 1602060025) if nm2005 == "TANJUNG RANCING"

replace bps_2005 = 1218 if id2008_1 == 1218011009 & nm2008_1 == "BATU MASAGI"

drop _merge
gen _merge = 3 if !mi(in2005, in2008)
replace _merge = 1 if mi(in2005) & !mi(in2008)
replace _merge = 2 if !mi(in2005) & mi(in2008) & mi(in2010) & mi(in2011)

tempvar tempid
tostring id2005, gen(`tempid')
replace `tempid' = substr(`tempid',1,7)

foreach name in nm2005 {

	cap drop _merge
	gen _merge = 3 if !mi(in2005, in2008)
	replace _merge = 1 if mi(in2005) & !mi(in2008)
	replace _merge = 2 if !mi(in2005) & mi(in2008) & mi(in2010) & mi(in2011)
	gen unmerged = mi(in2005) | _merge == 2

	preserve
		tempfile temp temp1 temp2
		keep if _merge == 2
		drop _merge
		bys `tempid' `name': gen nprkd = _N if unmerged
		replace nprkd = . if mi(`name') | `tempid' == "."
		save `temp'
		keep if nprkd == 1
		save `temp1'
		use `temp', clear
		keep if nprkd != 1
		save `temp2'
	restore

	drop if _merge == 2
	drop _merge

	bys `tempid' `name': gen nprkd = _N if unmerged
	replace nprkd = . if mi(`name') | `tempid' == "."
	
	merge m:1 `tempid' `name' unmerged nprkd using `temp1', update
	
	append using `temp2'

	drop unmerged nprkd

}

drop _merge
gen _merge = 3 if !mi(in2005, in2008)
replace _merge = 1 if mi(in2005) & !mi(in2008)
replace _merge = 2 if !mi(in2005) & mi(in2008) & mi(in2010) & mi(in2011)

tempvar tempid
tostring id2005, gen(`tempid')
replace `tempid' = substr(`tempid',1,4)
replace `tempid' = string(bps_2005) if `tempid' == "."

foreach name in nm2005 nm2008_1 {

	cap drop _merge
	gen _merge = 3 if !mi(in2005, in2008)
	replace _merge = 1 if mi(in2005) & !mi(in2008)
	replace _merge = 2 if !mi(in2005) & mi(in2008) & mi(in2010) & mi(in2011)
	gen unmerged = mi(in2005) | _merge == 2

	preserve
		tempfile temp temp1 temp2
		keep if _merge == 2
		drop _merge
		bys `tempid' `name': gen nprkd = _N if unmerged
		replace nprkd = . if mi(`name') | `tempid' == "."
		save `temp'
		keep if nprkd == 1
		save `temp1'
		use `temp', clear
		keep if nprkd != 1
		save `temp2'
	restore

	drop if _merge == 2
	drop _merge
		
	bys id2005 `name': gen firstnm = _n == 1 if unmerged
	bys id2005 `name': egen sumnm = total(firstnm) if unmerged
	gen nprkd = sumnm == 1 if unmerged
	
	replace nprkd = . if mi(`name') | `tempid' == "."
	
	merge m:1 `tempid' `name' unmerged nprkd using `temp1', update
	
	append using `temp2'

	drop unmerged firstnm sumnm nprkd

}
	
drop _merge
gen _merge = 3 if !mi(in2005, in2008)
replace _merge = 1 if mi(in2005) & !mi(in2008)
replace _merge = 2 if !mi(in2005) & mi(in2008) & mi(in2010) & mi(in2011)

tempvar tempid tempid1 tempid2
tostring id2005, gen(`tempid1')
tostring id2008_1, gen(`tempid2')
gen `tempid'     = substr(`tempid1',1,4)
replace `tempid' = string(bps_2005) if `tempid' == "."
replace `tempid' = substr(`tempid2',1,4) if `tempid' == "."	

foreach idvar in id2005 id2008_1 id2008_2 idpodes08 {
	foreach name in nm2005 nm2008_1 nm2008_2 {
		
		if !(regexm("`idvar'","2008") & regexm("`name'","2005")) {

			cap drop _merge
			gen _merge = 3 if !mi(in2005, in2008)
			replace _merge = 1 if mi(in2005) & !mi(in2008)
			replace _merge = 2 if !mi(in2005) & mi(in2008) & mi(in2010) & mi(in2011)
			gen unmerged = mi(in2005) | _merge == 2			
			
			preserve
				tempfile temp temp1 temp2
				keep if _merge == 2
				drop _merge
				bys `tempid' `name': gen nprkd = _N if unmerged
				replace nprkd = . if mi(`name') | `tempid' == "."
				save `temp'
				keep if nprkd == 1
				save `temp1'
				use `temp', clear
				keep if nprkd != 1
				save `temp2'
			restore		

			drop if _merge == 2
			drop _merge

			bys `idvar' `name': gen firstnm = _n == 1 if unmerged
			bys `idvar': egen sumnm = total(firstnm) if unmerged
			bys `idvar': gen nprkd = sumnm == 1 if unmerged
			
			replace nprkd = . if mi(`name') | `tempid' == "."
			
			merge m:1 `tempid' `name' unmerged nprkd using `temp1', update
			
			append using `temp2'		

			drop unmerged nprkd firstnm sumnm
		
		}

	}
}

cap drop _merge
cap drop _merge2

drop Uid05_key Unm05_key id05_key nm05_key Unm08_key id08_key nm08_key ///
	 u_r2000 kode2000 nama2000 ur2000 u_r2001 nama2004 ///
	 stat2004 v12 nvals2013 Notes provno kabno kecno desano no_dashuk ket ///
	 kodekec namkel nama namkec keterangan newfield2 newfield3 f kel_desa idppls ///
	 nmppls notes K L tempid nvals* manual_cross*
	 
drop in2011 in2010 in2008 in2005

********************************************************************************
* Examine Merge
********************************************************************************

* Main waves up to 2024
count if !mi(type_2024)
// 85,548
count if !mi(type_2024,type_2021)
// 85,547
count if !mi(type_2024,type_2021,type_2018)
// 85,524
count if !mi(type_2024,type_2021,type_2018,type_2014)
// 85,437
count if !mi(type_2024,type_2021,type_2018,type_2014,type_2011)
// 85,311
count if !mi(type_2024,type_2021,type_2018,type_2014,type_2011,pop_2010)
// 85,257
count if !mi(type_2024,type_2021,type_2018,type_2014,type_2011,pop_2010,type_2008)
// 85,106
count if !mi(type_2024,type_2021,type_2018,type_2014,type_2011,pop_2010,type_2008,type_2005)
// 84,248
	
	// UPDATE BELOW
	// 2008-2024: 85,114/85,565 = 0.99473
	// 2005-2024: 84,249/85,565 = 0.98462

********************************************************************************
* Tidy and Save Dataset 
********************************************************************************

* PODES codes: a row holding a PODES record of 2011, 2010, 2008 or 2005 under 
	* another code (the crosswalk's codes lag splits and code changes, and the 
	* merges keep the crosswalk's code) takes the record's code and name; so do 
	* its other codes of that wave that equal the replaced code. 2005: also the 
	* name where only the name differs, because PODES 2005 codes are not unique 
	* (code and name are the key)
local main11 id2011_1
local alt11  id2011_2 id_podes11 id_ppls11
local main10 id2010_1
local alt10  id2010_2 id_sp2010 id_rd2010
local main08 id2008_1
local alt08  id2008_2 idpodes08
local main05 id2005
local alt05
foreach w in 11 10 08 05 {
	local m `main`w''
	local mn = subinstr("`m'", "id", "nm", 1)
	gen byte __fix = !mi(p`w'_id) & `m' != p`w'_id
	if "`w'" == "05" replace __fix = 1 if !mi(p`w'_id) & `mn' != p`w'_nm
	di as txt "20`w': rows whose `m' changes to the PODES record's"
	tab __fix
	foreach v of local alt`w' {
		local n = subinstr("`v'", "id", "nm", 1)
		replace `n' = p`w'_nm if __fix & `v' == `m'
		replace `v' = p`w'_id if __fix & `v' == `m'
	}
	replace `mn' = p`w'_nm if __fix
	replace `m' = p`w'_id if __fix
	drop p`w'_* __fix
}

* SP2010 code: a row holding an SP2010 record whose id_sp2010 differs from
	* the record's takes the record's code and name. Rows without a
	* crosswalk id_sp2010 (villages split off in 2011) otherwise get it from
	* PODES 2011, where id_sp2010 is a copy of the 2011 code (the child's),
	* while they hold the parent's SP2010 record
replace nm_sp2010 = sp10_nm if !mi(sp10_id) & id_sp2010 != sp10_id
replace id_sp2010 = sp10_id if !mi(sp10_id) & id_sp2010 != sp10_id
drop sp10_*

* Tidying 
cap drop __000*
drop id type province region kec desa idusing idmaster

* Drop duplicates
duplicates drop

gen double id2011 = id2011_1
gen double id2008 = id2008_1
gen nm2011 = nm2011_1
gen nm2008 = nm2008_1

format %15s nm*	
format %10.0f id*

sort id2024 id2025 _all

save "$work/podes_05_25", replace
