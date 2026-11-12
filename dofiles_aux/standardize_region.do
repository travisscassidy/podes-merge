********************************************************************************
* Standardize Region Names
********************************************************************************

replace region = "Kotabaru" if region == "Kota Baru" & region_type == "Kab."
replace region = "Batam" if region == "B A T A M" & region_type == "Kota"
replace region = "Banjarbaru" if region == "Banjar Baru" & region_type == "Kota"
replace region = "Banyuasin" if region == "Banyu Asin" & region_type == "Kab."
replace region = "Batanghari" if region == "Batang Hari" & region_type == "Kab."
replace region = "Bau-bau" if region == "Baubau" & region_type == "Kota"
replace region = "Dumai" if region == "D U M A I" & region_type == "Kota"
replace region = "Gunung Sitoli" if region == "Gunungsitoli" ///
	& region_type == "Kota"
replace region = "Karangasem" if region == "Karang Asem" & region_type == "Kab."
replace region = "Adm. Kepulauan Seribu" if region == "Kepulauan Seribu" ///
	& region_type == "Kab."
replace region = "Limapuluh Kota" if region == "Lima Puluh Kota" ///
	& region_type == "Kab."
replace region = "Padang Sidempuan" if region == "Padangsidimpuan" ///
	& region_type == "Kota"
replace region = "Palangkaraya" if region == "Palangka Raya" ///
	& region_type == "Kota"
replace region = "Pangkajene Kepulauan" ///
	if region == "Pangkajene Dan Kepulauan" & region_type == "Kab."
replace region = "Siak" if region == "S I A K" & region_type == "Kab."
replace region = "Sawahlunto" if region == "Sawah Lunto" & region_type == "Kota"
replace region = "Kep. Siau Tagulandang Biaro" ///
	if region == "Siau Tagulandang Biaro" & region_type == "Kab."
replace region = "Kepulauan Tidore" if region == "Tidore Kepulauan" ///
	& region_type == "Kota"
replace region = "Tulang Bawang" if region == "Tulangbawang" ///
	& region_type == "Kab."