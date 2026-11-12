
foreach d in "S E R A S A M" "B A N G U N" "P A N D A N" "J A N J I" "R A Y A" ///
			 "D A U L U" "DOKAN" "M A N G G A" "A M P L A S" "B I N J A I" ///
			 "D E N A I" "M E S J I D" "J A T I" "H A M D A N" "A U R" ///
			 "D A R A T" "S E K I P" "B A N T A N" "T E M B U N G" "M A B A R" ///
			 "B E S A R" "T E R J U N" "S U L I G I" "R O K A N" "HU U" ///
			 "BAKA JAYA" "K I W U" "TOLO KALO" "SUKA DAMAI" "S O N D O" "S I E" ///
			 "T I M U" "L  E  U" "T A M B E" "R A T O" "W O R O" "M P U R I" ///
			 "R A D E" "K E L I" "N A R U" "N I S A" "T E N T E" "S A M I L I" ///
			 "R  I  S  A" "P A N D A I" "D O D U" "N U N G G A" "K U M B E" ///
			 "N I T U" "R O N T U" "N T O B O" "R O G A" "P E M O" "K U R U" ///
			 "N I D A" "W A J O" "B A G O K" "B A M B A N" "S A R A P A T" ///
			 "M A I P E" "D O R O N G" "D I D I" "D A Y U" "P U T A I" ///
			 "P U R I" "U N S U M" "B A R U Y A N" "N E T A P I N" "N I H I" ///
			 "M O O L O" "B O U" "L A N A" "B A L A" "M A M B U" "K E A N G" ///
			 "L A R A" "A D U" "I N A R I" "U R I S A" "W A I T A" "W A B O" ///
			 "L U B I S" "L A R A S" "D O K A N" "L A M A" "P E R L I S" ///
			 "K A B U B U" "O M A" "J I K O" "B A I" "W O" "W A I T A" ///
			 "" "" "" "" "" "" "" "" "" "" "" "" "" {
	replace nm2005 = subinstr(nm2005," ","",.) if nm2005 == "`d'"
}

replace nm2005 = subinstr(nm2005,"  "," ",.)

replace nm2005 = subinstr(nm2005,"SEI ","SUNGAI ",1) ///
	if substr(nm2005,1,4) == "SEI "
	
replace nm2005 = subinstr(nm2005,"SEI. ","SUNGAI ",1) ///
	if substr(nm2005,1,5) == "SEI. "	
	
replace nm2005 = subinstr(nm2005,"NAGARI SEI ","NAGARI SUNGAI ",1) ///
	if substr(nm2005,1,11) == "NAGARI SEI "	

replace nm2005 = subinstr(nm2005,"NAGARI SEI. ","NAGARI SUNGAI ",1) ///
	if substr(nm2005,1,12) == "NAGARI SEI. "	
	
replace nm2005 = subinstr(nm2005,"PERK ","PERKEBUNAN ",1) ///
	if substr(nm2005,1,5) == "PERK "
	
replace nm2005 = subinstr(nm2005,"PERK. ","PERKEBUNAN ",1) ///
	if substr(nm2005,1,6) == "PERK. "		
	
foreach c in 9420 9426 1603 {	
	replace nm2005 = subinstr(nm2005,"UPT. ","",1) ///
		if substr(nm2005,1,5) == "UPT. " & inrange(id2005,`c'000000,`c'999999)
	replace nm2005 = subinstr(nm2005,"UPT ","",1) ///
		if substr(nm2005,1,4) == "UPT " & inrange(id2005,`c'000000,`c'999999)	
}
	
replace nm2005 = subinstr(nm2005,"PERS ","",1) ///
	if substr(nm2005,1,5) == "PERS " ///
	& ( inrange(id2005,7323000000,7324999999) | ///
		inrange(id2005,7603000000,7603999999) | ///
		inrange(id2005,7605000000,7605999999) ) ///
	& nm2005 != "PERS SALURINDUK"
	
replace nm2005 = "SUNGAI MUSAM KENDIT" if nm2005 == "S.MUSAM KENDIT"
replace nm2005 = "NAGARI PARIT" if nm2005 == "NAGARI PARIK"
replace nm2005 = "NAGARI SUNGAI AUR" if nm2005 == "NAGARI SUNGAI AUA"
replace nm2005 = "NAGARI MUARA KAIWAI" if nm2005 == "NAGARI MUARA KAWAI"
replace nm2005 = "NAGARI RABI JONGGOR" if nm2005 == "NAGARI ROBI JONGGOR"
replace nm2005 = "NAGARI KATIAGAN/MANDIANGIN" ///
	if nm2005 == "NAGARI KATIAGAN/MANDIANGI"
replace nm2005 = "PAYA BAKAL" if nm2005 == "PAYABAKAL"
replace nm2005 = "SUKA JAYA" if nm2005 == "SUKAJAYA"
replace nm2005 = "WEAIN" if nm2005 == "WE AIN"
replace nm2005 = "NANEBOT" if nm2005 == "NENO BOT"
replace nm2005 = "BANJAR BARU KOTA" if nm2005 == "BANJARBARU KOTA"
replace nm2005 = "BANJAR BARU UTARA" if nm2005 == "BANJARBARU UTARA"
replace nm2005 = "MUNTEI" if nm2005 == "MUNTEI (SIBERUT ULU)"
replace nm2005 = "SILAGUMA" if nm2005 == "SILAGUMA (SILACINAN TANGA"
replace nm2005 = "MATOTONAN" if nm2005 == "SARAREKET ULU/MATOTONAN"
replace nm2005 = "NAGARI GERAGAHAN" if nm2005 == "NAGARI GARAGAHAN"
replace nm2005 = "NAGARI MANGGOPOH" if nm2005 == "NAGARI NANGGOPOH"
replace nm2005 = "NAGARI KUBANG PUTIAH" if nm2005 == "NAGARI KUMBANG PUTIAH"
replace nm2005 = "NAGARI TIGO KOTO SILUNGKANG" ///
	if nm2005 == "NAGARI TIGO KOTO SILUNGKA"
replace nm2005 = "NAGARI GANGGO MUDIAK" if nm2005 == "NAGARI GANGGO MUPIAK"
replace nm2005 = "NAGARI MUARO TAIS" if nm2005 == "MUARA TAIS"
replace nm2005 = "NAGARI PAKAN RABA'A" if nm2005 == "PAKAN RABAA"
replace nm2005 = "ELAAR LAMAGORANG" if nm2005 == "ELAAR LAMAGORONG"
replace nm2005 = "PAYAOMBOR" if nm2005 == "PAYA OMBUR"
replace nm2005 = "PERGAJAHAN HULU" if nm2005 == "PENGAJARAN HULU"
replace nm2005 = "WAI MILI" if nm2005 == "WAY MILI"
replace nm2005 = "WAY TERUSAN SP 1" if nm2005 == "UPT WAY TERUSAN SP.1"
replace nm2005 = "BA'ENGAS" if nm2005 == "BA ENGAS"
replace nm2005 = "KO'OLAN" if nm2005 == "KO OLAN"
replace nm2005 = "RA'AS" if nm2005 == "RA AS"
replace nm2005 = "KO'OL" if nm2005 == "KO OL"
replace nm2005 = "GRO'OM" if nm2005 == "GRO OM"
replace nm2005 = "TA'A" if nm2005 == "TA A"
replace nm2005 = "DORO O'O" if nm2005 == "UPT DORO O O"
replace nm2005 = "OITUI" if nm2005 == "OI TUI"
replace nm2005 = "OEUBAN" if nm2005 == "OEBAN"
replace nm2005 = "SO'E" if nm2005 == "SO E"
replace nm2005 = "T'EBA" if nm2005 == "T EBA"
replace nm2005 = "O'AMATE" if nm2005 == "O AMATE"
replace nm2005 = "ATI'IM" if nm2005 == "ATI IM"
replace nm2005 = "JU'UH" if nm2005 == "JU UH"
replace nm2005 = "HA'UWAI" if nm2005 == "HA UWAI"
replace nm2005 = "PO'O" if nm2005 == "PO O"
replace nm2005 = "O'O" if nm2005 == "O O"
replace nm2005 = "TETE-A" if nm2005 == "TETE A"
replace nm2005 = "UNA-UNA" if nm2005 == "UNA UNA"
replace nm2005 = "KO'MARA" if nm2005 == "KO_MARA"
replace nm2005 = "TA'" if nm2005 == "TA_"
replace nm2005 = "LA'LOA" if nm2005 == "LA_LOA"
replace nm2005 = "TO'LONG" if nm2005 == "TO_LONG"
replace nm2005 = "TO'BALO" if nm2005 == "TO_BALO"
replace nm2005 = "TO'LEMO" if nm2005 == "TO_LEMO"
replace nm2005 = "SE'PON" if nm2005 == "SE_PON"
replace nm2005 = "TO'PONGO" if nm2005 == "TO_PONGO"
replace nm2005 = "WATU NDOLU" if nm2005 == "WATUNDOLU/BATU JAYA"
replace nm2005 = "TUE-TUE" if nm2005 == "TUE TUE"
replace nm2005 = "MARIO JAYA" if nm2005 == "MARID RAYA"
replace nm2005 = "MORAME" if nm2005 == "MOROME"
replace nm2005 = "AONUPE" if nm2005 == "AUNUPE"
replace nm2005 = "LANDONO I" if nm2005 == "KEL. LANDONO"
replace nm2005 = "OLIMOO'O" if nm2005 == "ONIMOO"
replace nm2005 = "HUYULA" if nm2005 == "HAYULA"
replace nm2005 = "SOGITIA" if nm2005 == "SEGITIA"
replace nm2005 = "EMPALWAS" if nm2005 == "EMPLAWAS"
replace nm2005 = "WADANGKAU" if nm2005 == "WADANKOU"
replace nm2005 = "SIFLURU" if nm2005 == "SEFLURU"
replace nm2005 = "MESIDANG" if nm2005 == "MASIDANG"
replace nm2005 = "UTIIA" if nm2005 == "UTHA"
replace nm2005 = "PURWASAK" if nm2005 == "PERWASAK"
replace nm2005 = "LASARA BAGAMU" if nm2005 == "LASARA BAGAWU"
replace nm2005 = "ELA ELA" if nm2005 == "ELA-ELA"
replace nm2005 = "K WAVLAN" if nm2005 == "UPT K WAFLAN"
replace nm2005 = "TAPIAN BALAI" if nm2005 == "TEPIAN BALAI"
replace nm2005 = "BANJARSARI" if nm2005 == "BANJAR SARI"
replace nm2005 = "YALTUBUNG" if nm2005 == "YALTUBUN"
replace nm2005 = "TELALORA" if nm2005 == "TELALORA / LETODA"
replace nm2005 = "RUMAH SALUT" if nm2005 == "RUMA SALUT"
replace nm2005 = "PEKON UNGGAK" if nm2005 == "PEKONUNGGAK"
replace nm2005 = "TEGALJATI" if nm2005 == "TEGAL JATI"
replace nm2005 = "REJOAGUNG" if nm2005 == "REJO AGUNG"
replace nm2005 = "SUMBERWARU" if nm2005 == "SUMBER WARU"
replace nm2005 = "SUMBERTENGAH" if nm2005 == "SUMBER TENGAH"
replace nm2005 = "API API" if nm2005 == "API-API"
replace nm2005 = "HATI'IF" if nm2005 == "HATI IF"
replace nm2005 = "SATUI TIMUR" if nm2005 == "SATU TIMUR"
replace nm2005 = "MANTEWE" if nm2005 == "MENTEWE"
replace nm2005 = "KARYA BAKTI" if nm2005 == "KARYA BHAKTI"
replace nm2005 = "TEMPAKAN" if nm2005 == "TAMPAKAN"
replace nm2005 = "WANA SARI" if nm2005 == "WANASARI"
replace nm2005 = "SENGATTA UTARA" if nm2005 == "SANGATTA UTARA"
replace nm2005 = "BA BINUANG" if nm2005 == "BA BIMUANG"
replace nm2005 = "SAMBALI-WALI" if nm2005 == "SAMBALI WALI"
replace nm2005 = "KULER" if nm2005 == "KULER (TUNAS BARU)"
replace nm2005 = "YASA MULYA" if nm2005 == "JOSO MULIA"
replace nm2005 = "NILEME" if nm2005 == "NILIME"
replace nm2005 = "YUGWA" if nm2005 == "YUKWA"
replace nm2005 = "TOKGIRIK" if nm2005 == "TOGIRIK ( YINAGA )"
replace nm2005 = "WANILOK ( YELAM )" if nm2005 == "YELAM / WANILOK"
replace nm2005 = "AGISIGA" if nm2005 == "ASIGITA"
replace nm2005 = "SUMBER GADING" if nm2005 == "SUMBERGADING"
replace nm2005 = "YOWIED" if nm2005 == "YOWIT (YOWIED)"
replace nm2005 = "SALAMEPE" if nm2005 == "SALAMEPE (SALAM-EPE)"
replace nm2005 = "LUAREN" if nm2005 == "LUAREM"
replace nm2005 = "YIGEMILI" if nm2005 == "YIGEMILII"
replace nm2005 = "LOGOM" if nm2005 == "LUGOM"
replace nm2005 = "KUMULUME" if nm2005 == "KAMULUME"
replace nm2005 = "BUMI SAHAJA" if nm2005 == "UPT-SP II / BUMI SAHAJA"
replace nm2005 = "NAWA MULYA" if nm2005 == "UPT-SP III / NAWAMULIA"
replace nm2005 = "NAWA MUKTI" if nm2005 == "UPT-SP IV / NAWA MURTI"
replace nm2005 = "TAKWA BANGUN" if nm2005 == "UPT-SP V / TAKWA BANGUN"
replace nm2005 = "PURNAWAJATI" if nm2005 == "UPT SP VI / PUMAWA JATI"
replace nm2005 = "MABUNA" if nm2005 == "MABUMA"
replace nm2005 = "SUNYAR" if nm2005 == "SAMBERBINSARI/SUNYAR"
replace nm2005 = "PIR SOSA PLASMA MONDANG" if nm2005 == "PIR SOSA PLASMA MOND"
replace nm2005 = "UPT. TEBING TINGGI IV" ///
	if nm2005 == "UPT TEBING TINGGI IV (RAWASARI"
replace nm2005 = "KEL. SUNGAI PINANG" if nm2005 == "KEL. SEI PINANG"
replace nm2005 = "PANDAN SARI I" if nm2005 == "PANDAN SARI 1"
replace nm2005 = "KARANG DOYO" if nm2005 == "KERANG DAYU"
replace nm2005 = "UPT K WAVLAN" if nm2005 == "K WAVLAN"
replace nm2005 = "UPT J P. BURU" if nm2005 == "J P. BURU"
replace nm2005 = "JAYA LOKA" if nm2005 == "JAYALOKA"
replace nm2005 = "SUKARAJA LAMA" if nm2005 == "SUKA RAJA LAMA"
replace nm2005 = "TRI TUNGGAL BHAKTI" if nm2005 == "TRI TUNGGAL BAKTI"
replace nm2005 = "SRI KATON" if nm2005 == "SRIKATON"
replace nm2005 = "PEPALAH" if nm2005 == "PEPELAH"
replace nm2005 = "SEI DADAP III/IV" if nm2005 == "PERKEBUNAN SEI DADAP III/IV"
replace nm2005 = "DOLOK KATARAN" if nm2005 == "DOLOG HATARAN"
replace nm2005 = "PURBATUA" if nm2005 == "PURBATUA BN"
replace nm2005 = "PUDAK KULON" if nm2005 == "PUDAKKULON"
replace nm2005 = "IKAN TUNABIS" if nm2005 == "IKAN TUANBEIS"
replace nm2005 = "SANGGAU KOLOR" if nm2005 == "SANGGAU KULOR"
replace nm2005 = "TINGKWOIKIU" if nm2005 == "TINGWOIKWO"
replace nm2005 = "TIGAU COMTI" if nm2005 == "TIGAU CONTI"
replace nm2005 = "LEIHEAK" if nm2005 == "LIEHAK"
replace nm2005 = "SIRA TAU" if nm2005 == "SIRATAU"
replace nm2005 = "ASMURUF 'U'" if nm2005 == "ASMURUF U"
replace nm2005 = "JOSHIRO" if nm2005 == "JOHSIRO"
replace nm2005 = "KAPUTJUL" if nm2005 == "KAPATJOL"
replace nm2005 = "PO-EPE" if nm2005 == "PO EPE"
replace nm2005 = "KALIBURSE" if nm2005 == "KAIBURSE (KALIBURSE)"
replace nm2005 = "WAJAU / WAYAO" if nm2005 == "WAYAO (WAJAU)"
replace nm2005 = "TABBEYAN" if nm2005 == "TABEYAN"
replace nm2005 = "KWADEWARE / KANDA" if nm2005 == "KANDA/KWADEWARE"
replace nm2005 = "SABRON YORU" if nm2005 == "SABRON YARU"
replace nm2005 = "IFALE / AJAU" if nm2005 == "AJAU/IFALE"
replace nm2005 = "TIPAUGI" if nm2005 == "TIBAUGI"
replace nm2005 = "ABGOIGI / DOGIMANI" if nm2005 == "ABGOIGI"
replace nm2005 = "YAMETADI" if nm2005 == "YAWETADI"
replace nm2005 = "EKIMANI" if nm2005 == "EKIWANI"
replace nm2005 = "LOKODIMI" if nm2005 == "LOKODIMI/BOKOMIDI"
replace nm2005 = "TAGAUTO" if nm2005 == "TADAUTU"
replace nm2005 = "HARITI" if nm2005 == "BARITI/HARITI"
replace nm2005 = "MAKIMI" if nm2005 == "MAESPAWA/MAKIMI"
replace nm2005 = "MABOU" if nm2005 == "MABUA/MABOU"
replace nm2005 = "YENBURWO" if nm2005 == "YEMBURWO"
replace nm2005 = "AMPEREM" if nm2005 == "AMBERPAREM"
replace nm2005 = "PARAI" if nm2005 == "MOKMER PARAY"
replace nm2005 = "SWAIPAK" if nm2005 == "SWAIDAK/SWAIPAK"
replace nm2005 = "GAKOKEBO" if nm2005 == "DAGOKEBO"
replace nm2005 = "AYAIGO / KAGUPAIDA" if nm2005 == "KAGUPAIDA/AYAIGO"
replace nm2005 = "IBOMOMAIDA / IBUMAIDA" if nm2005 == "IBOMOMAIDA"
replace nm2005 = "MUJAIYEPA / MUNAYEPA / MUNIYEPA" ///
	if nm2005 == "MUJAIYEPA (MUNAYEPA)"
replace nm2005 = "NIGOLEME / NIKOAME" if nm2005 == "NIKOAME/NIGOLOME"
replace nm2005 = "BOKOMA / POGOMA" if nm2005 == "POGOMA/BOKOMA"
replace nm2005 = "KEMBRU / YIMUK" if nm2005 == "YIMUK/KEMBRU"
replace nm2005 = "BABE / JAMBUL" if nm2005 == "JAMBUL/BABE"
replace nm2005 = "PUBET / GIMORIT" if nm2005 == "GIMORIT/PUBET"
replace nm2005 = "JINDAK" if nm2005 == "ALFALIN/JINDAK"
replace nm2005 = "BINAGE II" if nm2005 == "BIWAGE II"
replace nm2005 = "TAREO" if nm2005 == "TAERO / TAREO"
replace nm2005 = "PIRIMAPUN" if nm2005 == "FIRIMAPUN/FIRIMAPON"
replace nm2005 = "KABIANGGEMA" if nm2005 == "KABIANGGENMA"
replace nm2005 = "DINMOT" if nm2005 == "DIMNOT"
replace nm2005 = "TOPOPION" if nm2005 == "TUPOPLOM"
replace nm2005 = "DUMPASIK" if nm2005 == "DAMPASIK"
replace nm2005 = "OKKETUR" if nm2005 == "OKETUR"
replace nm2005 = "OKYOB" if nm2005 == "OKYOP"
replace nm2005 = "EHIPTEM" if nm2005 == "OHIPTEM"
replace nm2005 = "KUMBUR" if nm2005 == "KEMBUR"
replace nm2005 = "MANUGAME" if nm2005 == "MUNAGAME"
replace nm2005 = "KAYI / KAY SETA" if nm2005 == "KAYI"
replace nm2005 = "JAMBER / BENERAF" if nm2005 == "BENERAF"
replace nm2005 = "UPT-SP IV" if nm2005 == "UPT-SP IV GWIN JAYA"
replace nm2005 = "UPT-SP V" if nm2005 == "UPT-SP V TAMAR SARI"
replace nm2005 = "UPT-SP VI" if nm2005 == "UPT-SP VI MAWES MUKTI"
replace nm2005 = "UPT-SP VII" if nm2005 == "UPT-SPVII RIMSER SARI"
replace nm2005 = "TAMAYA" if nm2005 == "TAMAJA"
replace nm2005 = "WOSIAY" if nm2005 == "WOSLAY"
replace nm2005 = "WABERFONDI" if nm2005 == "WARBEPONDI"
replace nm2005 = "KORIAKAM" if nm2005 == "KORIAKAM / KOIRYAKAM"
replace nm2005 = "KABORI JAYA" if nm2005 == "KOBARI JAYA"
replace nm2005 = "SKOW MABO" if nm2005 == "SKOUWMABO"
replace nm2005 = "SKOW SAE" if nm2005 == "SKOUWSAE"
replace nm2005 = "SAWINGGRAI" if nm2005 == "SAWINGGGRAI"
replace nm2005 = "KAROAIPI" if nm2005 == "KARUEPI"
replace nm2005 = "EKNEMBA / ELENEMBA" if nm2005 == "EKNEMBA/ELENEMBA"
replace nm2005 = "NUGARIL" if nm2005 == "PANGGUWI/ NUGARIL"
replace nm2005 = "JAAR" if nm2005 == "J A � A R"

* Line breaks, invalid UTF-8 bytes, and double quotes used as apostrophes
foreach v of varlist nm2005 {
	replace `v' = subinstr(`v', char(10), " ", .)
	replace `v' = subinstr(`v', char(13), " ", .)
	replace `v' = ustrfix(`v', "'")
	replace `v' = strtrim(stritrim(`v'))
}






















































	

