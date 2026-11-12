
foreach d in "J I K O" "B A I" "" "" "" "" "" "" "" "" "" "" "" "" "" {
	replace nm2008_1 = subinstr(nm2008_1," ","",.) if nm2008_1 == "`d'"
}

replace nm2008_1 = "LUKSAGU" if nm2008_1 == "LUK SAGU"
replace nm2008_1 = "LOGOM" if nm2008_1 == "LUGOM"
replace nm2008_1 = "PIR SOSA PLASMA MONDANG" ///
	if nm2008_1 == "PIR SOSA PLASMA MOND"
replace nm2008_1 = "KEL. SUNGAI PINANG" if nm2008_1 == "KELURAHAN SUNGAI PINANG"
replace nm2008_1 = "NONAPAN DUA" if nm2008_1 == "NONAPAN II"
replace nm2008_1 = "KOLONGAN ATAS II" if nm2008_1 == "KOLONGAN ATAS DUA"
replace nm2008_2 = "KOLONGAN ATAS II" if nm2008_2 == "KOLONGAN ATAS DUA"
replace nm2008_1 = "UPT K WAVLAN" if nm2008_1 == "UPT K WAFLAN"
replace nm2008_1 = "INDOSUFA" if nm2008_1 == "INDO OUFA / INDOSUFA"
replace nm2008_1 = "NGINYBOU" if nm2008_1 == "NGUNIBOUW"
replace nm2008_1 = "IKIMABOW" if nm2008_1 == "IKIMABOUW"
replace nm2008_1 = "KEMIULUME" if nm2008_1 == "KAMULUME"
replace nm2008_1 = "SAMABEGULIK" if nm2008_1 == "SEMBEGULIK"
replace nm2008_1 = "AMBAI III" if nm2008_1 == "MAMBAWI/AMBAI III"
replace nm2008_1 = "BURUNGKOP" if nm2008_1 == "BULANGKOP"
replace nm2008_1 = "UPT-SP III / TETOM" if nm2008_1 == "UPT - SP III / TETOM"





