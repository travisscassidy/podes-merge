
foreach d in "T E M B U N G" "M A B A R" "B E S A R" "A M P L A S" ///
			 "B I N J A I" "D E N A I" "M E S J I D" "H A M D A N" "D A R A T" ///
			 "D I L A M" "B A Y U A" "D A L K O" "S A R I A K" "J A M B A K" "" "" "" "" "" "" "" "" "" "" "" "" {
	replace nm2000 = subinstr(nm2000," ","",.) if nm2000 == "`d'"
}

foreach v in nm2000 nm1999 nm1998 {

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
		
	replace `v' = subinstr(`v',"  "," ",.)		
	
}	

replace nm2000 = "BADA TIMUR" if nm2000 == "BADA TIMU"
replace nm2000 = "AWAAI" if nm2000 == "AWA'AI"
replace nm2000 = "MARGO MULIA SOSA IV" if nm2000 == "MARGAMULYO SOSA IV"
replace nm2000 = "PEKAN KUALA" if nm2000 == "PKN KUALA"
replace nm2000 = "TANJUNG BULUH" if nm2000 == "TG BULUH"
replace nm2000 = "KAMPUNG PAKU" if nm2000 == "KP PAKU"
replace nm2000 = "SIPINGGAN LUMBAN SIANTAR" if nm2000 == "SIPINGGAN LBN SIANTAR"
replace nm2000 = "AFDELING I RANTAU PRAPAT" ///
	if nm2000 == "PERKEBUNAN AFD I RT PRAPAT"
replace nm2000 = "AFDELING II RANTAU PRAPAT" ///
	if nm2000 == "PERKEBUNAN AFD II RT PRAPAT"
replace nm2000 = "UPT XV SUBULUSSALAM" if nm2000 == "UPT -XV SUBULUSSALAM"
replace nm2000 = "UPT XVII SKP-D-IV / MUKTI" ///
	if nm2000 == "UPT XVII SKP-D-IV / MUK"
replace nm2000 = "MUNTEI" if nm2000 == "MUNTEI (SIBERUT ULU)"
replace nm2000 = "SILAGUMA" if nm2000 == "SILAGUMA (SILACINAN TNG"
replace nm2000 = "MATOTONAN" if nm2000 == "SARAREKET ULU/MATOTONAN"
replace nm2000 = "BINUANG KAMPUNG DALAM" if nm2000 == "BIRUANG/KOTO DALAM"
replace nm2000 = "LAMBUNG BUKIT" if nm2000 == "LBG. BUKIK"
replace nm2000 = "LUBUK KEMBANG SARI" if nm2000 == "UPT IV UKUI II LB.K.SAR"
replace nm2000 = "KAMPUNG BARU" if nm2000 == "UPT III UKUI II KP.BARU"
replace nm2000 = "RAWANG SARI" if nm2000 == "UPT III UKUI II RWG.SAR"
replace nm2000 = "SARI MAKMUR" if nm2000 == "UPT VI UKUI II SARI MKR"
replace nm2000 = "MAYANG SARI" if nm2000 == "UPT IV MAYANG SARI"
replace nm2000 = "SURYA INDAH" if nm2000 == "UPT I SOREK SURYA INDAH"
replace nm2000 = "DELIMA JAYA" if nm2000 == "UPT I SEI BUATAN/DEL.JA"
replace nm2000 = "SUNGAI SIMPANG DUA" if nm2000 == "UPT III PIR.TRAN SIMP.D"
replace nm2000 = "BANGUN SARI" if nm2000 == "UPT I HTI SUNGAI PAGAR"
replace nm2000 = "SUNGAI LEMBU MAKMUR" if nm2000 == "UPT.IV.BKN X/G (SEI LEM"
replace nm2000 = "MUARA MAHAT BARU" if nm2000 == "UPT.III.BKN X/G(MUARA M"
replace nm2000 = "KINANTAN" if nm2000 == "UPT I BKN X/G(KINANTAN)"
replace nm2000 = "SIBUAK" if nm2000 == "UPT.II.BKN X/G (SIBUAK)"
replace nm2000 = "UPT 7 SP 5 TB. LESTARI" if nm2000 == "UPT VII SP.5TB. LESTARI"
replace nm2000 = "TERKUL" if nm2000 == "TERKOL"
replace nm2000 = "RIMBA MAKMUR" if nm2000 == "UPTN11 (RIMBA MAKMUR)"
replace nm2000 = "PENGUDANG" if nm2000 == "PENGUNDANG"
replace nm2000 = "KIJANG" if nm2000 == "KIJANG/GUNUNG KIJANG"
replace nm2000 = "PELANGIRAN" if nm2000 == "PLANG IERAN"
replace nm2000 = "UPT NATUNA V SP 3 (SEDARAT BARU)" ///
	if nm2000 == "UPT. V NATUNA (SP.3)"
replace nm2000 = "GUNUNG PUTRI (SP 2)" if nm2000 == "GUNUNG PUTRI (SP.2)"
replace nm2000 = "BATU UBI JAYA" if nm2000 == "BETUBI JAYA (SP.1)"
replace nm2000 = "BADAK TEKURUNG" if nm2000 == "BD TEKURUNG"
replace nm2000 = "KEL PASAR RANTAU PANJANG" ///
	if inlist(nm2000,"KEL PASAR RANTAU PANJAN","KELURAHAN PASAR RANTAU PANJANG")
replace nm2000 = "SIMPANG TIGA MUARA PANCO" ///
	if nm2000 == "SIMPANG TIGA MUARA PANC"
replace nm2000 = "SERENTAK B REGAM/UJUNG TA" ///
	if nm2000 == "SERENTAK B REGAM/UJUNG"
replace nm2000 = "PINANG BALAI/BATANG SUMAI" if nm2000 == "PINANG BALAI/BATANG SUM"
replace nm2000 = "BATANG SUMAY II" if nm2000 == "BATANG SUMAI II"
replace nm2000 = "BATANG SUMAY III" if nm2000 == "BATANG SUMAI"
replace nm2000 = "BATANG SUMAY IV/ SP V" if nm2000 == "BATANG SUMAI IV/ SP V"
replace nm2000 = "KEL. TANJUNG GEDANG" if nm2000 == "KELURAHAN TANJUNG GEDAN"
replace nm2000 = "KEL. SUNGAI PINANG" if nm2000 == "KEL. SUNGAI  PINANG"
replace nm2000 = "KELURAHAN SUNGAI BENGKAL" ///
	if nm2000 == "KELURAHAN SUNGAI BENGKA"
replace nm2000 = "PELANCU INDAH (SP.I)/LOKA" if nm2000 == "PELANCU INDAH (SP.I)/LO"
replace nm2000 = "JLN JEND ACHMAD YANI" if nm2000 == "JLN JEND A YANI"
replace nm2000 = "PAKAN RABA'A" if nm2000 == "PAKAN RABAA"
replace nm2000 = "KOTO TANGAH SIMALANGGANG" if nm2000 == "KOTO TANGAH SIMALANGGAN"
replace nm2000 = "TANJUNG BUNGO" if nm2000 == "TANJUANG BUNGO"
replace nm2000 = "MUARO PAITI" if nm2000 == "MUARA PAITI"
replace nm2000 = "TANJUNG PAUAH" if nm2000 == "III KOTO TANJUNG PAUH"
replace nm2000 = "SEBERANG PALINGGAM" if nm2000 == "SBR PALINGGAM"
replace nm2000 = "UPT/SP3 SUKARAJA" if nm2000 == "UPT SUKARAJA III"
replace nm2000 = "MUNTAI UPT/ SP4. SUKARAJA" if nm2000 == "UPT SUKARAJA IV"
replace nm2000 = "UPT GAHANG / MEKAR JAYA" if nm2000 == "UPT.MEKAR JAYA"
replace nm2000 = "UPT PARENGGEAN II L" if nm2000 == "WONO SARI (UPT.II-L)"
replace nm2000 = "UPT JONGGON B/JONGGON JA" ///
	if nm2000 == "UPT JONGGON B/JONGGON J"
replace nm2000 = "UPT IV TG. AGUNG/JEL.SEL" ///
	if nm2000 == "UPT IV TG. AGUNG/JEL.SE"
replace nm2000 = "WONO MULYO (EX UPT III J" ///
	if nm2000 == "WONO MULYO (EX UPT III"
replace nm2000 = "GUNUNG SARI (EX UPT II JE" ///
	if nm2000 == "GUNUNG SARI (EX UPT II"
replace nm2000 = "BUMI RAHAYU (EX UPT I JEL" ///
	if nm2000 == "BUMI RAHAYU (EX UPT I J"
replace nm2000 = "SILVA RAHAYU (EX UPT VI S" ///
	if nm2000 == "SILVA RAHAYU (EX UPT VI"
replace nm2000 = "KELUBIR (SALIM BATU III)" ///
	if nm2000 == "KELUBIR (SALIM BATU III"
replace nm2000 = "KARANG AGUNG (SALIM BATU" ///
	if nm2000 == "KARANG AGUNG (SALIM BAT"
replace nm2000 = "PANCA AGUNG (SALIM BATU I" ///
	if nm2000 == "PANCA AGUNG (SALIM BATU"
replace nm2000 = "ARDI MULYO ( EX UPT IV AM" ///
	if nm2000 == "ARDI MULYO ( EX UPT IV"
replace nm2000 = "ABBANUANGE" if nm2000 == "ABBANUANGNGE"
replace nm2000 = "PERS RANTE LABI" if nm2000 == "RANTELA'BI'"
replace nm2000 = "MINAKE" if nm2000 == "PERSIAPAN MINAKE"
replace nm2000 = "UPT. MARISA V" if nm2000 == "UPT.MARISA V"
replace nm2000 = "GALAYDUBU" if nm2000 == "KEL.GALAYDUBU"
replace nm2000 = "SIWALIMA" if nm2000 == "KEL. SIWALIMA"
replace nm2000 = "UBO-UBO" if nm2000 == "UBO UBO"
replace nm2000 = "HILIMBAWO DESOLO" if nm2000 == "HILIMBOWO DESOLO"
replace nm2000 = "LASARA BAGAMU" if nm2000 == "LASARA BAGAWU"
replace nm2000 = "HILIWAELE II" if nm2000 == "HILIWAELE I I"
replace nm2000 = "AEK BURU SELATAN" if nm2000 == "PERKEBUNAN AEK BURU SELATAN"
replace nm2000 = "SUNGAI SELAN" if nm2000 == "SUNGAISELAN"
replace nm2000 = "JATI WARINGIN" if nm2000 == "JATIWARINGIN"
replace nm2000 = "KALOBBA" if nm2000 == "KALOBRA"
replace nm2000 = "AMBEKAERI UTAMA" if nm2000 == "AMBEKAERI UTAM"
replace nm2000 = "PANDAN SARI I" if nm2000 == "PANDAN SARI 1"
replace nm2000 = "JATIWARINGIN" if nm2000 == "JATI WARINGIN"
replace nm2000 = "JATIBENING" if nm2000 == "JATI BENING"
replace nm2000 = "ULAPATO 'B'" if nm2000 == "ULAPATO.B"




























