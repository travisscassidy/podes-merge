********************************************************************************
* Cleans World Bank's District Proliferation Crosswalk

/*
	Uses corrected crosswalk
*/
********************************************************************************

clear all
set more off 

* Paths: globals set in master.do

** Import and Clean District Crosswalk **
	
import excel ///
"$cross/district_proliferation/District_Proliferation_Crosswalk_Revised_YearEndBPS.xlsx", ///
	clear firstrow
		
drop WB_Combined_Names	
	
rename FAO_Adm_Name FAO_adm_name  
rename Country_Code cross_region_code
rename GAUL_code 	gaul_code

replace cross_region_code = subinstr(cross_region_code,"Kota_","",.)

replace cross_region_code = "IDN_Banda_Aceh_73705" ///
	if cross_region_code == "IDN_Bandaaceh_73705"
	
replace cross_region_code = "IDN_Banten_ID.BT_73610_IDN031" ///
	if cross_region_code == "IDN_Banten_ID.BT_73610_IDN030"

replace cross_region_code = "IDN_Biak_Numfor_73655" ///
	if cross_region_code == "IDN_Biaknumfor_73655"
	
replace cross_region_code = "IDN_Bintan_73698" ///
	if cross_region_code == "IDN_Bintan_18241"
	
replace cross_region_code = "IDN_Bukittinggi_73716" ///
	if cross_region_code == "IDN_Bukitinggi_73716"
	
replace cross_region_code = "IDN_DI_Yogyakarta_ID.DY_1515_IDN005" ///
	if cross_region_code == "IDN_D_I_Yogyakarta_ID.DY_1515_IDN005"
	
replace cross_region_code = "IDN_DKI_Jakarta_ID.DJ_1516_IDN007" ///
	if cross_region_code == "IDN_Dki_Jakarta_ID.DJ_1516_IDN007"
	
replace cross_region_code = "IDN_Jawa_Timur_ID.TI_1521_IDN009" ///
	if cross_region_code == "IDN_Jawa_Timur_ID.JA_1521_IDN009"	

replace cross_region_code = "IDN_Kalimantan_Utara_ID.KU_1519_IDN039" ///
	if cross_region_code == "IND_Kalimantan_Utara_ID.KU_1519_IDN039"
	
replace cross_region_code = "IDN_Kendari_73695" ///
	if cross_region_code == "IDN_Kendari_73729"	

replace cross_region_code = "IDN_Kep_Bangka-Belitung_ID.BB_73609_IDN004" ///
	if cross_region_code == "IDN_Bangka_Belitung_ID.BB_73609_IDN004"
	
replace cross_region_code = "IDN_Kep_Siau_Tagulandang_Biaro_18296" ///
	if cross_region_code == "IDN_Kep._Siau_Tagulandang_Biaro_18296"	

replace cross_region_code = "IDN_Kepulauan_Selayar_18182" ///
	if cross_region_code == "IDN_Kepulauan_Selayar_73700.55"
	
replace cross_region_code = "IDN_Kepulauan_Talaud_73701" ///
	if cross_region_code == "IDN_Kepulauan-talaud_73701"	

replace cross_region_code = "IDN_Limapuluh_18208" ///
	if cross_region_code == "IDN_Limapuluhkoto_18208"
	
replace cross_region_code = "IDN_Lubuklinggau_73734" ///
	if cross_region_code == "IDN_Lubuk_Linggau_73734"	

replace cross_region_code = "IDN_Maluku_Utara_ID.MU_73616_IDN016" ///
	if cross_region_code == "IDN_Maluku_Utara_ID.LA_73616_IDN016"
	
replace cross_region_code = "IDN_Muara_Enim_73802" ///
	if cross_region_code == "IDN_Muara_Eenim_73802"	

replace cross_region_code = "IDN_Nanggroe_Aceh_Darussala_ID.AD_1512_IDN020" ///
	if cross_region_code == "IDN_Nangroe_Aceh_Darussalam_ID.AD_1512_IDN020"
	
replace cross_region_code = "IDN_Nusa_Tenggara_Barat_ID.NB_1528_IDN022" ///
	if cross_region_code == "IDN_Nusa_Tenggara_Barat_ID.NB_1528_IDN021"	

replace cross_region_code = "IDN_Nusa_Tenggara_Timur_ID.NT_1529_IDN025" ///
	if cross_region_code == "IDN_Nusa_Tenggara_Timur_ID.NT_1529_IDN022"	
	
replace cross_region_code = "IDN_Pangkajene_Kepulauan_18179" ///
	if cross_region_code == "IDN_Pangkajene_Dan_Kepulauan_18179"	
	
replace cross_region_code = "IDN_Pangkal_Pinang_73742" ///
	if cross_region_code == "IDN_Pangkalpinang_73742"	

replace cross_region_code = "IDN_Papua_ID.PA_73617_IDN030" ///
	if cross_region_code == "IDN_Papua_ID.PA_73617_IDN029"	

replace cross_region_code = "IDN_Sulawesi_Selatan_ID.SS_73620_IDN021" ///
	if cross_region_code == "IDN_Sulawesi_Selatan_ID.SS_73620_IDN020"	
	
replace cross_region_code = "IDN_Sulawesi_Tengah_ID.ST_1532_IDN023" ///
	if cross_region_code == "IDN_Sulawesi_Tengah_ID.ST_1532_IDN021"	
	
replace cross_region_code = "IDN_Sulawesi_Tenggara_ID.TE_1533_IDN029" ///
	if cross_region_code == "IDN_Sulawesi_Tenggara_ID.TE_1533_IDN022"	

replace cross_region_code = "IDN_Sulawesi_Utara_ID.SU_1537_IDN024" ///
	if cross_region_code == "IDN_Sulawesi_Utara_ID.SU_73621_IDN023"	

replace cross_region_code = "IDN_Sumatera_Barat_ID.BR_1535_IDN026" ///
	if cross_region_code == "IDN_Sumatera_Barat_ID.SB_1535_IDN024"	
	
replace cross_region_code = "IDN_Sumatera_Selatan_ID.SM_73622_IDN027" ///
	if cross_region_code == "IDN_Sumatera_Selatan_ID.SM_73622_IDN025"	
	
replace cross_region_code = "IDN_Sumatera_Utara_ID.SA_73621_IDN028" ///
	if cross_region_code == "IDN_Sumatera_Utara_ID.SA_1537_IDN026"

replace cross_region_code = "IDN_Tanah_Bumbu_73860" ///
	if cross_region_code == "IDN_Tanah_bumbu_73860"
	
replace cross_region_code = "IDN_Tanah_Datar_18215" ///
	if cross_region_code == "IDN_Tanahdatar_18215"
	
replace cross_region_code = "IDN_Tanjung_Jabung_Barat_73862" ///
	if cross_region_code == "IDN_Tanjungjabung_Barat_73862"
	
replace bps_2008 = 6400 ///
 if cross_region_code == "IND_Kalimantan_Utara_ID.KU_1519_IDN039" & mi(bps_2008)
 
* Drop districts that are missing code
	* (Drops 3 districts created in 2014)
	
drop if mi(cross_region_code)	

* Drop early codes and names

foreach x in bps name {
	forval y = 1970/1989 {
		qui drop `x'_`y'
	}
}
 
* Rename district name variable
 
forval y = 1990/2014 {
	qui rename name_`y' region_`y'
}

* Filling in missing bps code

replace bps_2008 = bps_2007 if mi(bps_2008) & bps_2007 == bps_2009

* Year established

gen year_est = year(Established_Date)

* Save

save "$work/district_cross_1990_2014", replace

