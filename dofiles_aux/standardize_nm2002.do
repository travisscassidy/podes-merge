
foreach d in "H U N O" "D E K H A" "B U L O" "W U L A" "W U N A" "N I H I" ///
			 "B U N G I" "W A L I" "D A N A" "B O L O" "L O H I A" "M O O L O" ///
			 "H A R O W U" "J A A R" "M A I P E" "D I D I" "D A Y U" "L E B O" ///
			 "N I T I" "N A N I N" "N A E T" "K U F E U" "" "" "" "" "" "" "" "" "" "" {
	replace nm2002 = subinstr(nm2002," ","",.) if nm2002 == "`d'"
}

foreach v in nm2002 nm2003 {

	replace `v' = subinstr(`v',"SEI ","SUNGAI ",1) ///
		if substr(`v',1,4) == "SEI "
		
	replace `v' = subinstr(`v',"SEI. ","SUNGAI ",1) ///
		if substr(`v',1,5) == "SEI. "
		
	replace `v' = subinstr(`v',"PERK ","PERKEBUNAN ",1) ///
		if substr(`v',1,5) == "PERK "
		
	replace `v' = subinstr(`v',"PERK. ","PERKEBUNAN ",1) ///
		if substr(`v',1,6) == "PERK. "	
	
}	
	
foreach c in 1507 {	
	replace nm2002 = subinstr(nm2002,"UPT. ","",1) ///
		if substr(nm2002,1,5) == "UPT. " & inrange(id2002,`c'000000,`c'999999)
	replace nm2002 = subinstr(nm2002,"UPT ","",1) ///
		if substr(nm2002,1,4) == "UPT " & inrange(id2002,`c'000000,`c'999999)	
}

replace nm2002 = "KAMPONG SUBULUSSALAM" ///
	if id2002 == 1102040026 & nm2002 == "SUBULUSSALAM"
	
replace nm2002 = "AWAAI" if nm2002 == "AWA'AI"
replace nm2002 = "HILIWAELE II" if nm2002 == "HILIWAELE I I"
replace nm2002 = "BATOM BAWO" if nm2002 == "BOTOMBAWO"
replace nm2002 = "UPT KAMPUNG KAPAS I" if nm2002 == "UPT.KAMPUNG KAPAS I"
replace nm2002 = "UPT KAMPUNG KAPAS II" if nm2002 == "UPT.KAMPUNG KAPAS II"
replace nm2002 = "WEK VI P SIDIMPUAN" if nm2002 == "WEK VI"
replace nm2002 = "WEK V P SIDIMPUAN" if nm2002 == "WEK V"
replace nm2002 = "WEK IV P SIDIMPUAN" if nm2002 == "WEK IV"
replace nm2002 = "WEK III P SIDIMPUAN" if nm2002 == "WEK III"
replace nm2002 = "WEK II P SIDIMPUAN" if nm2002 == "WEK II"
replace nm2002 = "WEK I P SIDIMPUAN" if nm2002 == "WEK - I"
replace nm2002 = "LEMBAH L.MANIK" if nm2002 == "L.LUBUK MANIK"
replace nm2002 = "LANDOM" if nm2002 == "LAM DOM"
replace nm2002 = "KEBUN JATI" if nm2002 == "KEBUNJATI"
replace nm2002 = "HILIMBAWO DESOLO" if nm2002 == "HILIMBOWO DESOLO"
replace nm2002 = "LASARA BAGAMU" if nm2002 == "LASARA BAGAWU"
replace nm2002 = "SIKARA KARA IV" if nm2002 == "SIKARA-KARA IV"
replace nm2002 = "PAO PAO" if nm2002 == "PAO-PAO"
replace nm2002 = "WEE TANA" if nm2002 == "WETANA"
replace nm2002 = "PRAI MADETA" if nm2002 == "PRAIMADETA"
replace nm2002 = "WANGGA WAINYENGU" if nm2002 == "WANGGA WAYENGU"
replace nm2002 = "PRAISALURA" if nm2002 == "PRAI SALURA"
replace nm2002 = "WANGGA METI" if nm2002 == "WANGGAMETI"
replace nm2002 = "KATIKU WAI" if nm2002 == "KATIKUWAI"
replace nm2002 = "KATIKU TANA" if nm2002 == "KATIKUTANA"
replace nm2002 = "MEORUMBA" if nm2002 == "MEO RUMBA"
replace nm2002 = "KATIKU LUKU" if nm2002 == "KATIKULUKU"
replace nm2002 = "LAIPANDAK" if nm2002 == "LAI PANDAK"
replace nm2002 = "TADO' KALUA" if nm2002 == "TADO' KALUA'"
replace nm2002 = "KALANA" if nm2002 == "KALAMA'"
replace nm2002 = "EEN SUMALA" if nm2002 == "EENSUMALA"
replace nm2003 = "EEN SUMALA" if nm2003 == "EENSUMALA"
replace nm2002 = "KAMPUNG KUALA" if nm2002 == "GAMPONG KUALA"
replace nm2002 = "REUSEB" if nm2002 == "RUSEB"
replace nm2002 = "GUNUNG PARA" if nm2002 == "GN PARA"
replace nm2002 = "KAMPUNG PAKU" if nm2002 == "KP PAKU"
replace nm2002 = "TRIDARMAYOGA" if nm2002 == "TRI DHARMA YOGA"
replace nm2002 = "KOTABUMI TENGAH BARAT" if nm2002 == "PERS KTB TENGAH BARAT"
replace nm2002 = "MEKARSARI" if nm2002 == "MAKASARI"
replace nm2002 = "SIDAREJA" if nm2002 == "SIDOREJO"
replace nm2002 = "GELAPAN" if nm2002 == "GLAPAN"
replace nm2002 = "TAMBAKREJO" if nm2002 == "TEMBOKREJO"
replace nm2002 = "MERAWAN" if nm2002 == "MRAWAN"
replace nm2002 = "SERUNI" if nm2002 == "SRUNI"
replace nm2002 = "DARMO LEMAHBANG" if nm2002 == "DERMOLEMAHBANG"
replace nm2002 = "UPT TOLI OI" if nm2002 == "TOLO'OI"
replace nm2002 = "UPT OITUI" if nm2002 == "OI TUI"
replace nm2002 = "MENNE ATE" if nm2002 == "MANE ATE"
replace nm2002 = "TANJUNG PONTIANAK" if nm2002 == "PONTIANAK@"
replace nm2002 = "SUNGAI PADUAN" if nm2002 == "SIE PADUAN"
replace nm2002 = "RAU" if nm2002 == "RA'U"
replace nm2002 = "LA BO" if nm2002 == "LA'BO"
replace nm2002 = "AO'GADING" if nm2002 == "SA'DAN AO'GADING"
replace nm2002 = "UHAIDAO" if nm2002 == "UHAI DAO"
replace nm2002 = "UPT.TAMBUA I" if nm2002 == "ASEMI NUNULAI (UPT.TAMBU"
replace nm2002 = "UPT HIALU I" if nm2002 == "PAKA INDAH (UPT.HIALU I)"
replace nm2002 = "UPT.HIALU III" if nm2002 == "LANGGIKIMA (UPT.HIALU II"
replace nm2002 = "HIALU UTAMA" if nm2002 == "HIALU UTAMA (UPT.HIALU I"
replace nm2002 = "UPT.LAMONAE III" if nm2002 == "CULAMBATU (UPT.LAMONAE I"
replace nm2002 = "UPT PADALERE" if nm2002 == "LAMPARINGA (UPT PADALERE"
replace nm2002 = "UPT LAMBALE X (RAHMAT BARU)" if nm2002 == "UPT LAMBALE X (RAHMAT BA"
replace nm2002 = "TUNGGU RONO" if nm2002 == "TUNGGURONO"
replace nm2002 = "NAGARI KATIAGAN/MANDIANGI" ///
	if nm2002 == "NAGARI KATIAGAN/MANDIANG"
replace nm2002 = "MUARO TAIS" if nm2002 == "MUARATAIS"
replace nm2002 = "MUARO SEI LOLO" if nm2002 == "MA SUNGAI LOLO"
replace nm2002 = "PAYU PUTAT" if nm2002 == "PAYUPUTAT"
replace nm2002 = "OEKMURAK" if nm2002 == "OETMURAK"
replace nm2002 = "BANI BANI" if nm2002 == "BANI-BANI"
replace nm2002 = "AS MANULEA" if nm2002 == "AS MANLEA"
replace nm2002 = "TALANG BULAWAN" if nm2002 == "TALLANG BULAWAN"
replace nm2002 = "BATU PAPAN" if nm2002 == "BATUPAPAN"
replace nm2002 = "DATU BARINGAN" if nm2002 == "DATUBARINGIN"
replace nm2002 = "MASUPU" if nm2002 == "MASUPPU"
replace nm2002 = "ARALE UTARA" if nm2002 == "ARALLE UTARA"
replace nm2002 = "RALLEANAK" if nm2002 == "RALLE ANAK"
replace nm2002 = "UHAILANU" if nm2002 == "UHAI LANU"
replace nm2002 = "TUE TUE" if nm2002 == "TUE-TUE"
replace nm2002 = "MATA BENUA (UPT LAMONAE I)" ///
	if nm2002 == "MATA BENUA (UPT LAMONAE"
replace nm2002 = "MEE PANYANG BUSU" if nm2002 == "ME PANYANG BUSU"
replace nm2002 = "BALEE BARO" if nm2002 == "BALE BARO"
replace nm2002 = "ALUM ANGGOTA" if nm2002 == "ALUE ANGGOTA"
replace nm2002 = "TAPIAN NAULI SAUR MANGGIT" ///
	if nm2002 == "TAPIAN NAULI/SAUR MANGGI"
replace nm2002 = "ALANG BOMBON" if nm2002 == "ALANG BONBON"
replace nm2002 = "UPT RANTAU KUMPAI II" if nm2002 == "PANAI MAKMUR/ RNT. KUMPA"
replace nm2002 = "UPT RANTAU KUMPAI III" if nm2002 == "GUNA MAKMUR/UPT"
replace nm2002 = "PROYEK BANPRES" if nm2002 == "BANPRES@"
replace nm2002 = "TEBAJAWA" if nm2002 == "TEBA JAWA"
replace nm2002 = "SIDOMAKMUR" if nm2002 == "SIDO MAKMUR"
replace nm2002 = "PULAU PANGGUNG" if nm2002 == "PULAUPANGGUNG"
replace nm2002 = "GEDONG MENENG" if nm2002 == "GEDUNG MENENG"
replace nm2002 = "TIANG TARA" if nm2002 == "TIANG TARAH"
replace nm2002 = "SOLOKANJERUK" if nm2002 == "SOLOKAN JERUK"
replace nm2002 = "PUCUNG WETAN" if nm2002 == "PUCUNGWETAN"
replace nm2002 = "KECEPIT" if nm2002 == "KACEPIT"
replace nm2002 = "PUDAKKULON" if nm2002 == "PUDAK KULON"
replace nm2002 = "TEGALJATI" if nm2002 == "TEGAL JATI"
replace nm2002 = "REJOAGUNG" if nm2002 == "REJO AGUNG"
replace nm2002 = "SUMBERWARU" if nm2002 == "SUMBER WARU"
replace nm2002 = "SUMBERTENGAH" if nm2002 == "SUMBER TENGAH"
replace nm2002 = "TEGALINGGAH" if nm2002 == "TEGALLINGGAH"
replace nm2002 = "NANGATUMPU" if nm2002 == "NANGA TUMPU"
replace nm2002 = "UPT DORO O'O" if nm2002 == "UPT DORO OO"
replace nm2002 = "DORO O'O" if nm2002 == "DORO OO"
replace nm2002 = "LABUHAN KANANGA" if nm2002 == "LABUAN KANANGA"
replace nm2002 = "WAILA BUBUR" if nm2002 == "WAILABUBUR"
replace nm2002 = "BILA CENGE" if nm2002 == "BILLA CENGE"
replace nm2002 = "WAI RASA" if nm2002 == "WAIRASA"
replace nm2002 = "LAILUNGGI" if nm2002 == "LAI LUNGGI"
replace nm2002 = "WANGGA MBEWA" if nm2002 == "WANGGA BEWA"
replace nm2002 = "BLIKO" if nm2002 == "BELIKO"
replace nm2002 = "BANGKAJONG" if nm2002 == "BANGKA JONG"
replace nm2002 = "JELMU SIBAK" if nm2002 == "JELMU SIBAG"
replace nm2002 = "PURWADADI" if nm2002 == "PURWODADI"
replace nm2002 = "LEBAHO ULAQ" if nm2002 == "LEBAHO ULAK"
replace nm2002 = "KANDUNGA JAYA" if nm2002 == "KADUNGAN JAYA"
replace nm2002 = "KOPIWANGKER" if nm2002 == "KOPI WANGKER"
replace nm2002 = "MAMINASAE" if nm2002 == "MAMMINASAE"
replace nm2002 = "ABBOKONGENG" if nm2002 == "ABBOKONGAN"
replace nm2002 = "PULE JIWA" if nm2002 == "POLE JIWA"
replace nm2002 = "BLANG KEKUMUR" if nm2002 == "BELANG KEKUMUR"
replace nm2002 = "BARAMBANG" if nm2002 == "BARANGBANG"
replace nm2002 = "BANGUN HARJA" if nm2002 == "BANGUN HARJO"
replace nm2002 = "KEDUNG MALANG" if nm2002 == "KEDUNGMALANG"
replace nm2002 = "BALIURA" if nm2002 == "BALEURA"
replace nm2002 = "WARBINSI" if nm2002 == "WORBINSI"
replace nm2002 = "BARERAI" if nm2002 == "BARAREIPI"
replace nm2002 = "WAISOPI" if nm2002 == "WOINSUPI"
replace nm2002 = "PURWASARI" if nm2002 == "PURWASARI KUAMANG KUNING"
replace nm2002 = "RANTAU RASAU" if nm2002 == "RANTAU RASAU DESA"
replace nm2002 = "UPT K / WAFLAN" if nm2002 == "UPT K. WAVLAN"
replace nm2002 = "TANAH TUKAN" if nm2002 == "TANA TUKAN"




















































