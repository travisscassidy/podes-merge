
foreach d in "A L E N" "B A Y U A" "S A R I A K" "J A M B A K" "S A D A R" ///
			 "B I L A" "S U M O" "O K H I M" "" "" "" "" "" {
	replace nm1996 = subinstr(nm1996," ","",.) if nm1996 == "`d'"
}

foreach v in nm1996 {

	replace `v' = subinstr(`v',"SEI ","SUNGAI ",1) ///
		if substr(`v',1,4) == "SEI "
		
	replace `v' = subinstr(`v',"SEI.","SUNGAI ",1) ///
		if substr(`v',1,4) == "SEI."
		
	replace `v' = subinstr(`v',"TG ","TANJUNG ",1) ///
		if substr(`v',1,3) == "TG "
		
	replace `v' = subinstr(`v',"TG.","TANJUNG ",1) ///
		if substr(`v',1,3) == "TG."	
		
	replace `v' = subinstr(`v',"TJ ","TANJUNG ",1) ///
		if substr(`v',1,3) == "TJ "
		
	replace `v' = subinstr(`v',"TJ.","TANJUNG ",1) ///
		if substr(`v',1,3) == "TJ."		
		
	replace `v' = subinstr(`v',"PERK ","PERKEBUNAN ",1) ///
		if substr(`v',1,5) == "PERK "
		
	replace `v' = subinstr(`v',"PERK.","PERKEBUNAN ",1) ///
		if substr(`v',1,5) == "PERK."
		
	replace `v' = subinstr(`v',"KAMP.","KAMPUNG ",1) ///
		if substr(`v',1,5) == "KAMP."
		
	replace `v' = subinstr(`v',"PEM.","PEMATANG ",1) ///
		if substr(`v',1,4) == "PEM."	
		
	replace `v' = subinstr(`v',"SEUNEUBOK ","SEUNEBOK ",1)		
		
	replace `v' = subinstr(`v',"  "," ",.)		
	
}	


replace nm1996 = "CIPAR PARE" if nm1996 == "SKP-B SP II/CIPAR PARE"
replace nm1996 = "MUKTI MAKMUR" if nm1996 == "SKP-B SP I/MUKTI MAKMUR"
replace nm1996 = "SEPADAN" if nm1996 == "SKP-B SP IV/SEPADAN"
replace nm1996 = "SUKAMULIA BD / S.IYU" if nm1996 == "SUKAMULIA/UPAH"
replace nm1996 = "GEULUMPANG PAYONG" if nm1996 == "GEULUMPANG PAYUNG"
replace nm1996 = "SEULEUMAK" if nm1996 == "SELEMAK"
replace nm1996 = "UJUNG TARING" if nm1996 == "UMAH TARING"
replace nm1996 = "AFD.II BUKET" if nm1996 == "AFD.II BUKIT"
replace nm1996 = "ALUE GADENG SATU" if nm1996 == "PERKEBUNAN ALUE GADING I"
replace nm1996 = "ALUE GADENG DUA" if nm1996 == "PERKEBUNAN ALUE GADING II"
replace nm1996 = "BAYEUN" if nm1996 == "GP. BAYEUM"
replace nm1996 = "DATA CUT" if nm1996 == "DATAI CUT"
replace nm1996 = "UPT II PANCA" if nm1996 == "UPT. II PANCA"
replace nm1996 = "SUKA TANI (EX UPT.III JALIN)" if nm1996 == "UPT.III JALIN"
replace nm1996 = "BAK AGHU" if nm1996 == "BAK AGU"
replace nm1996 = "LEUTEUNG" if nm1996 == "LEUTUENG"
replace nm1996 = "SEUNEBOK DRIEN" if nm1996 == "SEUNEUBOK DRIEN"
replace nm1996 = "SEUNEBOK PUNTI" if nm1996 == "SEUNEUBOK PUNTI"
replace nm1996 = "BABAH LUENG" if nm1996 == "BABAH LUENG BERHANG"
replace nm1996 = "BLANG PAOH SATU" if nm1996 == "BLANG PAUH I"
replace nm1996 = "BLANG PAOH DUA" if nm1996 == "BLANG PAUH II"
replace nm1996 = "PUTOH DUA" if nm1996 == "GAMPONG PUTOH II"
replace nm1996 = "RANTAU SELAMAT" if nm1996 == "UPT II LAMI/GAGAK/RANTO SLAMET"
replace nm1996 = "KRUENG ITAM" if nm1996 == "UPT I LAMI /GAGAK/KRUNG ITAM"
replace nm1996 = "SUMBER DAYA" if nm1996 == "UPT III SUMBER DAYA"
replace nm1996 = "SIMPANG JAYA" if nm1996 == "UPT I SIMPANG JAYA"
replace nm1996 = "BATU RAJA" if nm1996 == "UPT II BATU RAJA"
replace nm1996 = "BUMI SARI" if nm1996 == "UPT IV KR TADU/BUMI SARI"
replace nm1996 = "BLANG NEUANG" if nm1996 == "BLANG NEUNANG"
replace nm1996 = "RUNDENG" if nm1996 == "RUNDING"
replace nm1996 = "BUKIT JAYA" if nm1996 == "BUKIT JAYA TRANS SPI/BUKITJAYA"
replace nm1996 = "SUMBER BATU" if nm1996 == "SUMBER BATU SP.II/SUMBER BATU"
replace nm1996 = "BATU JAYA" if nm1996 == "BATU JAYA SP.III/BATU JAYA"
replace nm1996 = "BLANG RAMEE" if nm1996 == "UPT I TEUNOM / BLANG RAMEE"
replace nm1996 = "WEU GAJAH" if nm1996 == "U P T II TEUNOM / WEU GAJAH"
replace nm1996 = "LAMTEH DAYAH" if nm1996 == "LAMTEUDAYAH"
replace nm1996 = "JULI SEUPENG/LAMPOH" if nm1996 == "SEUPENG LAMPOH"
replace nm1996 = "TAMBOI TANJONG" if nm1996 == "JULI TAMBO TANJONG"
replace nm1996 = "ALUE GLUMPANG SBL.K" if nm1996 == "ALUE GLUMPANG SBL K."
replace nm1996 = "COT KEUMUNING" if nm1996 == "COT KEUMUNENG"
replace nm1996 = "MATANG TEUNGOH LS" if nm1996 == "MATANG TEUNGOH LS."
replace nm1996 = "ALUE BILI GEULUMPANG" if nm1996 == "ALUE BILI GLUMPANG"
replace nm1996 = "MATANG CEUBREK" if nm1996 == "MATANG CEUBREY"
replace nm1996 = "ALUE ABEE" if nm1996 == "ALUE ABEI"
replace nm1996 = "TANJONG KLENG" if nm1996 == "TANJUNG KLENG"
replace nm1996 = "TEUPIN BEULANGAN" if nm1996 == "TEUPIN BLANGAN"
replace nm1996 = "AWAAI" if nm1996 == "AWA'AI"
replace nm1996 = "SILENJENG" if nm1996 == "SILONJANG"
replace nm1996 = "SALESE" if nm1996 == "SALESE (SALOSO)"
replace nm1996 = "SAMPEAN" if nm1996 == "SAMPEAN (POLDUNG)"
replace nm1996 = "SUGA SUGA/HUTA GODANG" ///
	if nm1996 == "GAB SUGA SUGA HUTA GADANG"
replace nm1996 = "GORAT PALLOMBUAN" if nm1996 == "SATAHI PARLOMBUAN GORAT"
replace nm1996 = "PERKEBUNAN TOLAN I/II" if nm1996 == "TOLAN SATU/DUA"
replace nm1996 = "SIDOMULYO" if nm1996 == "PERS SIDOMULYO"
replace nm1996 = "SUNGAI TAROLAT" if nm1996 == "PERS SEI TAROLAT"
replace nm1996 = "SUNGAI KASIH" if nm1996 == "PERS SEI KASIH"
replace nm1996 = "MERANTI" if nm1996 == "PERS MERANTI"
replace nm1996 = "PERKEBUNAN HALIMBE" if nm1996 == "PERS PERK HALIMBE"
replace nm1996 = "AIR HITAM" if nm1996 == "PERS AIR HITAM"
replace nm1996 = "DANO BALE" if nm1996 == "PERS DANO BALE"
replace nm1996 = "SIDOREJO" if nm1996 == "PERS SIDOREJO"
replace nm1996 = "SIRANDORUNG" if nm1996 == "SIRANDURUNG (SIRONDANG)"
replace nm1996 = "BUNTU MARAJA" if nm1996 == "BUNTU MARAJA (BANDAR MARAJA)"
replace nm1996 = "MUNTEI" if nm1996 == "MUNTEI (SIBERUT ULU)"
replace nm1996 = "SILAGUMA" if nm1996 == "SILAGUMA (SILACINAN TNG"
replace nm1996 = "MATOTONAN" if nm1996 == "SARAREKET ULU/MATOTONAN"
replace nm1996 = "KAMULYAN" if nm1996 == "KEMULYAN"
replace nm1996 = "KEMAWI" if nm1996 == "KENAWI"
replace nm1996 = "PAKUNDEN" if nm1996 == "PEKUNDEN"
replace nm1996 = "PULAU BUNGIN" if nm1996 == "P BUNGIN"
replace nm1996 = "LABUAN AJI" if nm1996 == "LAB AJI"
replace nm1996 = "LABUAN KURIS" if nm1996 == "LB KURIS"
replace nm1996 = "TELUK SANTONG" if nm1996 == "TL SANTONG"
replace nm1996 = "LABUAN BONTONG" if nm1996 == "LB BONTONG"
replace nm1996 = "LABUAN AJI" if nm1996 == "LB AJI"
replace nm1996 = "LABUAN JAMBU" if nm1996 == "LB JAMBU"
replace nm1996 = "REDONTENA" if nm1996 == "RENDOTENA"
replace nm1996 = "KENAWAN" if nm1996 == "KANAWAN"
replace nm1996 = "LAYAP BARU" if nm1996 == "TATAH LAYAP BARU"
replace nm1996 = "RIMBAYU III (EX UPT KT BNG 3)" ///
	if nm1996 == "UPT KOTA BANGUN III"
replace nm1996 = "RIMBAYU I (EX.UPT KOTA BANGUN" ///
	if nm1996 == "UPT KOTA BANGUN I"
replace nm1996 = "RIMBAYU II (EX UPT KOTA BNG II" ///
	if nm1996 == "UPT KOTA BANGUN II"
replace nm1996 = "LABANAN JAYA ( EX UPT)" if nm1996 == "UPT LABANAN (JAYA)"
replace nm1996 = "LABANAN MAKMUR (EX UPT)" if nm1996 == "UPT LABANAN (MAKMUR)"
replace nm1996 = "LABANAN MAKARTI (EX UPT)" if nm1996 == "UPT LABANAN (MAKARTI)"
replace nm1996 = "BUKIT HARAPAN" if nm1996 == "UPT WONGGARASI I/BUKIT HARAPAN"
replace nm1996 = "BOHUSAMI" if nm1996 == "UPT WONGGARASI I/BOHUSAMI"
replace nm1996 = "MOMALIA" if nm1996 == "MAMALIA"
replace nm1996 = "DAYOW" if nm1996 == "ONGGUNOI (DAYOW)"
replace nm1996 = "ADOW" if nm1996 == "TOROSIK (ADOW)"
replace nm1996 = "DOLODUO" if nm1996 == "DOLUDUO"
replace nm1996 = "TRANS.MAYAYAP" if nm1996 == "UPT. MAYAYAP"
replace nm1996 = "BAHOMAKMUR" if nm1996 == "UPT BAHODOPI SP. I"
replace nm1996 = "MAYA SARI" if nm1996 == "UPT MAYOA I (MAYA SARI)"
replace nm1996 = "KEUNO" if nm1996 == "UPT PIR TRANS I KEUNO"
replace nm1996 = "SIMALILI" if nm1996 == "TRANS TONGGOLOBIBI/SIMALILI"
replace nm1996 = "MODO" if nm1996 == "UPT MODO"
replace nm1996 = "PANNANRANG" if nm1996 == "PANANRANG"
replace nm1996 = "KALITATA" if nm1996 == "MALANGKE I/KALITATA"
replace nm1996 = "GIRIKUSUMA" if nm1996 == "MALANGKE II/GIRIKUSUMA"
replace nm1996 = "POMBAKKA" if nm1996 == "PONBAKKA"
replace nm1996 = "BERINGIN JAYA" if nm1996 == "LARA I/BERINGIN JAYA"
replace nm1996 = "MUKTI JAYA" if nm1996 == "LARA II/MUKTI JAYA"
replace nm1996 = "MEKAR SARI JAYA" if nm1996 == "LARA III/MEKAR SARI JAYA"
replace nm1996 = "MUKTI UTAMA" if nm1996 == "LARA IV/MUKTI UTAMA"
replace nm1996 = "HARAPAN" if nm1996 == "HARAPAN/KAMPUNG BARU"
replace nm1996 = "SAMASUNDU" if nm1996 == "SAMANSUMDU"
replace nm1996 = "SALUTIWO" if nm1996 == "UPT. SALUTIWO"
replace nm1996 = "TOPOYO II/K A B U B U" if nm1996 == "TOPOYO II"
replace nm1996 = "PIR BARAS SP I/BALANTI" if nm1996 == "UPT PIR BARAS SP I"
replace nm1996 = "PIR BARAS SP II/MOTU" if nm1996 == "UPT PIR BARAS SP II"
replace nm1996 = "BONGAYA" if nm1996 == "BUNGAYA"
replace nm1996 = "TRI WACU-WACU" if nm1996 == "UPT LAMB.UNIT I/TRI WACU-WACU"
replace nm1996 = "DAMPALA JAYA" if nm1996 == "UPT LAMB.UNIT II/DAMPALA JAYA"
replace nm1996 = "KARYA BAKTI" if nm1996 == "UPT LAMB.UNIT III/KARYA BAKTI"
replace nm1996 = "MARGA KARYA" if nm1996 == "UPT LAMB.UNIT IV/MARGA KARYA"
replace nm1996 = "KESSILAMPE" if nm1996 == "KASILAMPE"
replace nm1996 = "MOIIONGSEL" if nm1996 == "MOHONGSEL"
replace nm1996 = "KOIRYAKAM" if nm1996 == "KORIAKAM"
replace nm1996 = "SEULEUMAK MUDA" if nm1996 == "SEUNEBOK MUDA"
replace nm1996 = "LEUBUK PEMPENG" if nm1996 == "LUBUK PIMPIENG"



























































