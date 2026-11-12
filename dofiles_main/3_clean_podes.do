********************************************************************************
* Cleans PODES Data for Village Law Paper 
	* Care about: 2024, 2021, 2020, 2019, 2018, 2014, 2011, 2008, 2005 ...?
********************************************************************************

clear all
set more off 

* Paths: globals set in master.do

********************************************************************************
**# 2005
* 2005
********************************************************************************

** Merging raw data and renaming geographic names/IDs **

tempfile mfd
import dbase "$names/PODES 2005/MFD_PODES06-FIN", clear case(lower)
destring prop kabu keca desa klas prop_old kabu_old keca_old desa_old klas_old, ///
	replace
replace desa = 25 if prop == 53 & kabu == 2 & keca == 30 & desa == 10 ///
	& nama == "WINU MURU"	
ren prop prov_id
ren kabu region_id
ren keca kec_id
ren desa desa_id
ren nama desa
ren klas status
ren prop_old prov_id_2004
ren kabu_old region_id_2004
ren keca_old kec_id_2004
ren desa_old desa_id_2004
ren nama_old desa_2004
ren klas_old status_2004
drop lockedby flag 
drop if desa_id == 0
save `mfd'

foreach x in a b c {
	tempfile `x'
	import dbase "$podes_raw/PODES 2005/pod06_`x'", clear case(lower)
	destring exp-r104b, replace
	replace r104b = 25 if exp == 530203010
	ren r101b prov_id
	ren r102b region_id
	ren r103b kec_id
	ren r104b desa_id
	if "`x'" == "a" {
		ren r101a prov_id_2004
		ren r102a region_id_2004
		ren r103a kec_id_2004
		ren r104a desa_id_2004
	}
	save ``x''
}

use `mfd', clear

merge 1:1 prov_id region_id kec_id desa_id using `a', update replace nogenerate
merge 1:1 prov_id region_id kec_id desa_id using `b', update replace nogenerate
merge 1:1 prov_id region_id kec_id desa_id using `c', update replace nogenerate

* Raw PODES code (unique)
gen double id_podes2005 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2005
isid id_podes2005
la var id_podes2005 "PODES 2005 code (raw file)"
gen nm_podes2005 = desa
la var nm_podes2005 "PODES 2005 name (raw file)"

foreach v in r105a r105b {
	replace `v' = "" if inlist(`v',"1","M")
	destring `v', replace
}

foreach v of varlist status status_2004 status_m r106-r303b2 r304a-r403b ///
					 r405-r1302 {
	cap destring `v', replace
}

la var status "Urban/Rural Status"
la var status_2004 "Urban/Rural Status (2004)"
la def status 1 "Urban" 2 "Rural"
la val status* status

ren r105a area_2004
	la var area_2004 "Area Type"
	la def area_2004 1 "Urban" 2 "Rural"
	la val area_2004 area_2004

ren r105b area
	la var area "Area Type"
	la def area 1 "Urban" 2 "Rural"
	la val area area

ren r301 type	
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other"
	la val type type

gen vlg_consult = r302 == 1 if !mi(r302)
	la var vlg_consult "Presence of a Village Consultative Body"
	
gen coastal = r304a == 1 if !mi(r304a)
	la var coastal "Village is adjacent to sea"	
	
local x r304b	
gen topog = .
	replace topog = 1 if `x' == 2
	replace topog = 2 if `x' == 1
	replace topog = 3 if `x' == 3
	la var topog "Topography"
	la def topog 1 "Slope/peak" 2 "Valley" 3 "Plain"
	la val topog topog
	drop `x'
	
assert mi(topog) if coastal == 1

gen geog = topog
	recode geog (. = 4) if coastal == 1
	la var geog "Geography"
	la def geog 1 "Slope/peak" 2 "Valley" 3 "Plain" 4 "Coast"
	la val geog geog
	
ren r305 forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest

drop exp
replace desa = strupper(desa)
replace desa = subinstr(desa,"  "," ",.)	
replace desa = subinstr(desa,"   "," ",.)	
replace desa = subinstr(desa,"    "," ",.)

** Generating social and infrastructure variables **

gen pop  = r401a + r401b
gen n_hh = r401c

* Doctors, midwives, health facilities

gen n_dr = r604a1 + r604a2
gen n_mwiv = r604c 
gen n_mwiv_all = r604c 

gen n_dr_off 	 = r603fk2
gen n_mwiv_off 	 = r603gk2
gen n_hosp       = r603ak2
gen n_hosp_mat   = r603bk2
gen n_poliklinik = r603ck2
gen n_puskesmas  = r603dk2 + r603ek2
gen n_polindes   = r603ik2
gen n_posyandu   = r603hk2
gen n_pharm		 = r603jk2

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes // poskesdes did not exist yet

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen mwiv_avail = n_mwiv > 0 if !mi(n_mwiv)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)
gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Proxies for number of poor people

gen n_sktm = r606
la var n_sktm "Number of poverty letters issued in the last year"

* Disease outbreaks

gen outbreak_diar = r607ak2 == 1 if !mi(r607ak2)
gen outbreak_deng = r607bk2 == 1 if !mi(r607bk2)
gen outbreak_meas = r607ck2 == 1 if !mi(r607ck2)
gen outbreak_resp = r607dk2 == 1 if !mi(r607dk2)
gen outbreak_mala = r607ek2 == 1 if !mi(r607ek2)
gen outbreak_othr = r607fk2 == 1 if !mi(r607fk2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_resp ///
	"Upper respiratory tract infection outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r607ak2 == 2
replace deaths_diar = r607ak3 if r607ak2 == 1

gen deaths_deng = 0 if r607bk2 == 2
replace deaths_deng = r607bk3 if r607bk2 == 1

gen deaths_meas = 0 if r607ck2 == 2
replace deaths_meas = r607ck3 if r607ck2 == 1

gen deaths_resp = 0 if r607dk2 == 2
replace deaths_resp = r607dk3 if r607dk2 == 1

gen deaths_mala = 0 if r607ek2 == 2
replace deaths_mala = r607ek3 if r607ek2 == 1

gen deaths_othr = 0 if r607fk2 == 2
replace deaths_othr = r607fk3 if r607fk2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Schools 

gen n_schl_kind_pub  = r601ak2
gen n_schl_prm_pub   = r601bk2
gen n_schl_jrsec_pub = r601ck2
gen n_schl_srsec_pub = r601dk2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r601ak3
gen n_schl_prm_prv   = r601bk3
gen n_schl_jrsec_prv = r601ck3
gen n_schl_srsec_prv = r601dk3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x b
local type hosp_mat
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x c
local type poliklinik
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

gen dist_puskesmas = min(r603dk31,r603ek31) if !mi(r603dk31) | !mi(r603ek31)
gen easy_puskesmas = max( inlist(r603dk4,1,2), inlist(r603ek4,1,2) ) ///
	if !mi(r603dk4) | !mi(r603ek4)

local x f
local type dr_off
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x g
local type mwiv_off
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x h
local type posyandu
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x i
local type polindes
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x j
local type pharm
gen dist_`type' = r603`x'k31
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x a
local type kind
gen dist_schl_`type'_pub = r601`x'k41 + r601`x'k42/10 
	// second variable is number after decimal

local x b
local type prm
gen dist_schl_`type'_pub = r601`x'k41 + r601`x'k42/10 

local x c
local type jrsec
gen dist_schl_`type'_pub = r601`x'k41 + r601`x'k42/10 

local x d
local type srsec
gen dist_schl_`type'_pub = r601`x'k41 + r601`x'k42/10 

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)

* Roads

gen rd_asph = r901b1 == 1 if !mi(r901b1) //& r901b1 != 0
gen rd_grvl = r901b1 == 2 if !mi(r901b1) //& r901b1 != 0
gen rd_dirt = r901b1 == 3 if !mi(r901b1) //& r901b1 != 0
gen rd_othr = r901b1 == 4 if !mi(r901b1) //& r901b1 != 0

gen rd_pass = r901b2 == 1 if !mi(r901b2) //& r901b2 != 0

* Phone, internet, TV

gen n_hh_phn = r904 
gen pubphn   = r905 == 1 if !mi(r905)

gen n_phnstall = r906	
gen phnstall = r906 > 0 if !mi(r906)

gen n_internet = r907   
gen internet = r907 > 0 if !mi(r907)   

gen TVRI 	 = r910a == 1 if !mi(r910a) 
gen natcomTV = r910b1 == 1 | r910b2 == 3 | r910b3 == 5 | r910b4 == 7 | ///
			   r910b5 == 1 | r910b6 == 3 | r910b7 == 5 | r910b8 == 7 | ///
			   r910b9 == 1 | r910b10 == 3
gen forTV 	 = r910c == 1
gen locTV 	 = r910d == 1			   

gen mblphn   = inlist(r911,1,2) 
gen mblphn_strng = r911 == 1 

* Main source of income

local var r402
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_services = `var' == 5 if !mi(`var')
gen main_income_other	 = `var' == 6 if !mi(`var')

* Land use

gen land_area = r10011
	la var land_area "Land area"
/*
gen land_area_industr = 	
gen land_area_shops = 	

foreach x in industry shops {	
	gen frac_area_`x' = land_area_`x'/land_area
	replace frac_area_`x' = 0 if land_area == 0
	assert inrange(frac_area_`x',0,1)
}
*/

* Presence of industry

gen ind_area = r1103 == 1 if !mi(r1103)
la var ind_area "Industrial area in village"
	/*
	Industrial area is an area where industrial activities are concentrated with 
	an area of ​​at least 20 hectares that is equipped with supporting 
	infrastructure and facilities that are developed and managed by Industrial 
	Estate Companies that already have Industrial Estate Business Licenses.
	Example:
	- Pulo Gadung Industrial Estate in DKI Jakarta.
	- Rungkut Industri area in Surabaya City
	*/
	
gen ind_center = r1104 == 1 if !mi(r1104)	
la var ind_center "Industrial center in village"
	/*
	Industrial center is the gathering or convergence in a certain area 
	(agglomeration), an industrial company in a location in which consists of 
	various business activities that are mutually bound by strategic cooperation 
	that are complementary and mutually supportive, which are bound in a spirit 
	of togetherness / strong collective commitment. Example: Cibaduyut, Bandung.
	*/	

gen small_ind_area = r1105 == 1 if !mi(r1105)
la var small_ind_area "Small industrial area in village"
	/*
	Small industrial environment (LIK) is a location built by the government and 
	private sector specifically designated for small industries (generally of 
	the same type) where the place of business is separate from the residence of 
	entrepreneurs and generally under the auspices of the Ministry of Industry 
	and Trade. Small industrial village (PIK) is similar to LIK, but the 
	residence of the entrepreneur is not separate from his place of business. 
	For example PIK Milling in DKI Jakarta.
	*/
	
gen n_estab_lg = r1106 if r1106 != 998
la var n_estab_lg ///
	"Number of large manufacturing establishments (100+ employees)"
	/*
	Large number of industries (> / = 100 workers)
	Leather crafts: making bags, shoes, sandals, etc.
	Wood crafts: making cupboards, tables, chairs, furniture making and 
	children's toys from wood. Metal crafts: making pans, stoves, nuts, bolts, 
	machetes, hoes, other agricultural tools and making equipment from other 
	metals. Crafts of precious metals: making earrings, bracelets, rings and 
	other jewelry making from gold or silver.
	*/
	
gen n_estab_md = r1107 if r1107 != 998
la var n_estab_md ///
	"Number of medium-sized manufacturing establishments (20-99 employees)"
	/*
	Medium number of industries (20-99 workers)
	(Same types of goods as above)
	*/	
	
* Small manufacturing establishments
	
gen n_estab_sm_leather 	= r1108a if !inlist(r1108a,998,999)
gen n_estab_sm_wood 	= r1108b if !inlist(r1108b,998,999)
gen n_estab_sm_metal 	= r1108c if !inlist(r1108c,998,999)
gen n_estab_sm_woven 	= r1108d if !inlist(r1108d,998,999)
gen n_estab_sm_pottery 	= r1108e if !inlist(r1108e,998,999)
gen n_estab_sm_fabric 	= r1108f if !inlist(r1108f,998,999)
gen n_estab_sm_foodbev 	= r1108g if !inlist(r1108g,998,999)
gen n_estab_sm_other 	= r1108h if !inlist(r1108h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"

* Cooperatives

gen n_coop_kud 	  = r1121a if !inlist(r1121a,98,99)
gen n_coop_smmanu = r1121b if !inlist(r1121b,98,99)
gen n_coop_save   = r1121c if !inlist(r1121c,98,99)
gen n_coop_othr   = r1121d if !inlist(r1121d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Agricultural production stalls

gen n_agprod_stall_kud	  = r1102a if !inlist(r1102a,98,99)
gen n_agprod_stall_nonkud = r1102b if !inlist(r1102b,98,99)
gen n_agprod_stall = n_agprod_stall_kud + n_agprod_stall_nonkud

la var n_agprod_stall_kud "Number of agricultural production stalls, KUD-owned"
la var n_agprod_stall_nonkud "Number of agricultural production stalls, non-KUD-owned"
la var n_agprod_stall "Number of agricultural production stalls"

gen agprod_stall_kud_avail = n_agprod_stall_kud > 0 if !mi(n_agprod_stall_kud)
gen agprod_stall_nonkud_avail = n_agprod_stall_nonkud > 0 ///
	if !mi(n_agprod_stall_nonkud)
gen agprod_stall_avail = n_agprod_stall > 0 if !mi(n_agprod_stall)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_nonkud_avail ///
	"Non-KUD-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Markets

gen shop_cntr_avail = r1110a == 1 if !mi(r1110a)
gen mkt_perm_avail = r1111a == 1 if !mi(r1111a)
gen n_mkt_temp = r1112 if !inlist(r1112,98,99)

la var shop_cntr_avail "Shopping center exists"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1113
gen n_restaur = r1114 if r1114 != 96
gen n_foodstall = r1115 if r1115 != 96
gen n_cornerstore = r1116 if r1116 != 998
gen n_hotel = r1117 if r1117 != 98 
gen n_motel = r1118 if r1118 != 98 

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_cornerstore "Number of corner stores"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Banks

gen n_bank_com = r1119
gen n_bank_rur = r1120a

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r1124a == 1 | r1124b == 3 | r1124c == 5 | r1124d == 7
la var microfin_avail "Formal microfinance programs exist"

* Private electricity firms

gen n_priv_elec_firms = r1109
	/*
	Non-PLN electricity companies are electricity companies that are not managed 
	by the government (private).
	*/

* Main village road has electric lighting

gen rd_light = r502a == 1 & inlist(r502b,1,2) if !mi(r502a) //& r901b1 != 0

* Main village road has lighting provided by govt./non-govt.

gen rd_light_gov = r502a == 1 & r502b == 1 if !mi(r502a) //& r901b1 != 0
gen rd_light_nongov = r502a == 1 & r502b == 2 if !mi(r502a) //& r901b1 != 0

* Household electricity access

gen n_hh_elec_pln = 0 if r501a == 2
	replace n_hh_elec_pln = r501b1 if r501a == 1
	la var n_hh_elec_pln "# Households using PLN electricity"

gen n_hh_elec_nonpln = 0 if r501a == 2
	replace n_hh_elec_nonpln = r501b2 if r501a == 1
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"

foreach x in pln nonpln {	
	replace n_hh_elec_`x' = n_hh ///
		if !mi(n_hh,n_hh_elec_`x') & n_hh < n_hh_elec_`x'	
}	
	
gen n_hh_noelec = n_hh - n_hh_elec_pln - n_hh_elec_nonpln
	//replace n_hh_noelec = 0 if n_hh_noelec < 0
	assert n_hh_noelec >= 0
	replace n_hh_noelec = n_hh if r501a == 2
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = r501a == 1
	
gen share_hh_elec = (n_hh_elec_pln + n_hh_elec_nonpln)/n_hh
	la var share_hh_elec "Share of households using electricity"

gen share_hh_elec_pln = n_hh_elec_pln/n_hh
	la var share_hh_elec_pln "Share of households using PLN electricity"
	
gen share_hh_elec_nonpln = n_hh_elec_nonpln/n_hh
	la var share_hh_elec_nonpln "Share of households using non-PLN electricity"
	
* Waste disposal

gen garbage_collect = r504 == 1 if !mi(r504)
	la var garbage_collect "Gabage disposed using bins that are transported"
	
gen toilet = inrange(r505,1,3) if !mi(r505)
	la var toilet "Most families defecate in a toilet (private, shared, public)"
	
* Safe Drinking Water
	
gen safe_drink_water = r608a == 1 if !mi(r608a) 
	la var safe_drink_water "Access to safe drinking water"		
	
* Diversity

gen multi_ethnic = r710 == 1 if !mi(r710)
	la var multi_ethnic "Multiple ethnic groups in village"	
	
ren r711 eth_code_majority
	la var eth_code_majority "Code of majority ethnicity"	

* Fight against govt

gen fight_sec = 0
replace fight_sec = r1203a == 2 if r1202a == 1

* Police

local x	r1207bk2
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"

* Distance to district capital

local x r902bk21
gen dist_distr_cap = `x' if `x' < 998 & !inlist(`x',98,99)
	la var dist_distr_cap "Distance to district capital (km)"	
	
local x r902ck21
gen dist_nearest_distr_cap = `x' if `x' < 998 & !inlist(`x',98,99)
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"

** Characteristics of village officials **
	* Village head
	* Village secretary
	* Chair of BPD/Dewan Kelurahan (Village Consultative Body/Kelurahan Council)
	* Chair of LPMD/K (Village/Kelurahan Community Empowerment Institution)	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	*/
	
foreach stub in vlghead vlgsec bpdchair lpmdchair {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	else if "`stub'" == "bpdchair" {
		local row  "c"
		local name "Chair of BPD/Dewan Kelurahan"
	}
	else if "`stub'" == "lpmdchair" {
		local row  "d"
		local name "Chair of LPMD/K"
	}
	
	local x r1301`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1301`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1301`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1301`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 2  if `x' == 1
		replace `stub'_educ = 6  if `x' == 2
		replace `stub'_educ = 9  if `x' == 3
		replace `stub'_educ = 12 if `x' == 4
		replace `stub'_educ = 14 if `x' == 5
		replace `stub'_educ = 16 if `x' == 6
		la var `stub'_educ "`name' years of education"
			
	gen `stub'_highschl = inrange(`x',4,6) if !mi(`x') & `stub'_exists == 1
	gen `stub'_college  = `x' == 6 if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	
}

** Fix incorrect kecamatan codes - id2005 **	

recode kec_id (10 = 11) (20 = 10) (40 = 31) (50 = 21) (60 = 22) (70 = 40) ///
			  (80 = 41) (90 = 71) (100 = 72) (110 = 73) (120 = 50) (130 = 60) ///
			  (140 = 80) (150 = 81) ///
	if prov_id == 53 & region_id == 1

recode kec_id (60 = 10) (61 = 20) (100 = 30) (101 = 50) (102 = 40) (110 = 60) ///
			  (111 = 80) (112 = 70) (120 = 100) (121 = 90) ///
	if prov_id == 16 & region_id == 9

recode kec_id (10 = 12) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,17,21)
	
recode kec_id (10 = 11) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,18,27)	
	
recode kec_id (20 = 21) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,1,11)	
	
recode kec_id (40 = 62) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,49,50)	

recode kec_id (50 = 52) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,1,18)	
	
recode kec_id (60 = 62) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,1,4)	
	
recode kec_id (60 = 61) ///
	if prov_id == 16 & region_id == 10 & inrange(desa_id,20,28)	

recode kec_id (120 = 12) (160 = 31) (180 = 51) (190 = 71) (200 = 81) (150 = 32) ///
	if prov_id == 94 & region_id == 10

** Fix incorrect desa codes - id2005 **	

recode desa_id (1 = 3) (3 = 6) (4 = 7) (6 = 1) (7 = 4) (8 = 14) (9 = 8) ///
			   (10 = 9) (11 = 12) (12 = 13) (13 = 10) (14 = 11) (17 = 19) ///
			   (18 = 17) (19 = 18) ///
	if prov_id == 63 & region_id == 2 & kec_id == 20

recode desa_id (1 = 9) (2 = 1) (3 = 2) (4 = 3) (5 = 4) (6 = 5) (7 = 6) (9 = 10) ///
			   (10 = 11) (11 = 7) (12 = 14) (13 = 12) (14 = 13) (15 = 16) ///
			   (16 = 15) (17 = 18) (18 = 17) ///
	if prov_id == 63 & region_id == 3 & kec_id == 51

recode desa_id (4 = 2) (5 = 6) (6 = 7) (7 = 9) (9 = 10) ///
	if prov_id == 63 & region_id == 3 & kec_id == 52
	
replace desa_id =  desa_id - 1 ///
	if prov_id == 94 & region_id == 10 & kec_id == 12 & desa_id >= 7

* For crosswalk

foreach v in nm2005 nm2008_1 nm2008_2 nmpodes08 {
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

* 7319 to 7602 (incorrectly coded)
gen new_prov_id = 76 if prov_id == 73 & regstr == "19"
gen new_regstr = "02" if prov_id == 73 & regstr == "19"
	
* 7320 to 7601 (incorrectly coded)
replace new_prov_id = 76 if prov_id == 73 & regstr == "20"
replace new_regstr = "01" if prov_id == 73 & regstr == "20"
	
replace prov_id = new_prov_id if !mi(new_prov_id)
replace regstr = new_regstr if !mi(new_regstr)
drop new_prov_id new_regstr	

gen id2005 = string(prov_id) + regstr + kecstr + desastr
destring id2005, replace

* For crosswalk: id2004_alt and nm2004_alt (helpful when merge fails)

tostring region_id_2004, gen(regstr_2004)
tostring kec_id_2004, gen(kecstr_2004)
tostring desa_id_2004, gen(desastr_2004)

replace regstr_2004 = "0" + regstr_2004 if strlen(regstr_2004) == 1

foreach v in kecstr_2004 desastr_2004 {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

gen id2004_alt = string(prov_id_2004) + regstr_2004 + kecstr_2004 + desastr_2004
destring id2004_alt, replace

gen nm2004_alt = desa_2004
replace nm2004_alt = "" if nm2004_alt == "DURIANKARI"

* Using BPS crosswalk to aid in merging 2003 & 2005

**
cap drop bps_* _merge
**

tempvar id
tostring id2005, gen(`id')
gen bps_2005 = substr(`id',1,4)
destring bps_2005, replace

preserve
	tempfile bpscross
	use "$work/district_cross_1990_2014", clear
	keep bps_1998 bps_1999 bps_2000 bps_2001 bps_2002 bps_2003 bps_2004 bps_2005
	bys bps_2005: keep if _n == 1
	save `bpscross'
restore

merge m:1 bps_2005 using `bpscross'

replace bps_2005 = 2001 if bps_2005 == 2101 & _merge == 1
replace bps_2005 = 2002 if bps_2005 == 2102 & _merge == 1
replace bps_2005 = 2004 if bps_2005 == 2104 & _merge == 1
replace bps_2005 = 2071 if bps_2005 == 2171 & _merge == 1
replace bps_2005 = 2072 if bps_2005 == 2172 & _merge == 1
replace bps_2005 = 7602 if bps_2005 == 7319 & _merge == 1
replace bps_2005 = 7601 if bps_2005 == 7320 & _merge == 1
replace bps_2005 = 7604 if bps_2005 == 7321 & _merge == 1
replace bps_2005 = 7603 if bps_2005 == 7323 & _merge == 1
replace bps_2005 = 7605 if bps_2005 == 7324 & _merge == 1
replace bps_2005 = 9101 if bps_2005 == 9405 & _merge == 1
replace bps_2005 = 9107 if bps_2005 == 9406 & _merge == 1
replace bps_2005 = 9105 if bps_2005 == 9407 & _merge == 1
replace bps_2005 = 9102 if bps_2005 == 9421 & _merge == 1
replace bps_2005 = 9106 if bps_2005 == 9422 & _merge == 1
replace bps_2005 = 9108 if bps_2005 == 9423 & _merge == 1
replace bps_2005 = 9104 if bps_2005 == 9424 & _merge == 1
replace bps_2005 = 9103 if bps_2005 == 9425 & _merge == 1
replace bps_2005 = 9171 if bps_2005 == 9472 & _merge == 1

drop if _merge == 2
drop _merge bps_1998 bps_1999 bps_2000 bps_2001 bps_2002 bps_2003 bps_2004

merge m:1 bps_2005 using `bpscross'

drop if _merge == 2
drop _merge

/* 
bps_2005 unmerged from crosswalk: 1201 1214 
(Survey missing island of Nias. Will use extension dataset later.)
*/

foreach v in nm2008_1 {

	replace `v' = "BLANGTEMUNG" ///
		if `v' == "BLANG TEMUNG" & bps_2005 == 1113

	replace `v' = "KUBANGAN PANDAN SARI" ///
		if `v' == "KUBANG PANDAN SARI" & bps_2005 == 1202
	replace `v' = "WIDO DAREN" ///
		if `v' == "WIDODAREN" & bps_2005 == 1202
	replace `v' = "WONO SARI" ///
		if `v' == "WONOSARI" & bps_2005 == 1202
	replace `v' = "LUBUK BONDAR PANJANG" ///
		if `v' == "LUBUK BANDAR PANJANG" & bps_2005 == 1202
	replace `v' = "BONCA BAYUON" ///
		if `v' == "BONCA BAIYON" & bps_2005 == 1202
	replace `v' = "SALI BARU" ///
		if `v' == "SALE BARU" & bps_2005 == 1202
	replace `v' = "HITETANO" ///
		if `v' == "HITE TANO" & bps_2005 == 1206
	replace `v' = "AEK UNSIN" ///
		if `v' == "AEK UNSIM" & bps_2005 == 1206		
	replace `v' = "LOBUSONA" ///
		if `v' == "LOBU SONA" & bps_2005 == 1207
	replace `v' = "RANTAU PRAPAT" ///
		if `v' == "RANTAUPRAPAT" & bps_2005 == 1207
	replace `v' = "SI UMBUT BARU" ///
		if `v' == "SIUMBUT BARU" & bps_2005 == 1208
	replace `v' = "SIUMBUT - UMBUT" ///
		if `v' == "SIUMBUT-UMBUT" & bps_2005 == 1208
	
	replace `v' = "PURBA DOLOK" ///
		if `v' == "PURBA DOLOG" & bps_2005 == 1209
	replace `v' = "NAGORI SIHALPE" ///
		if `v' == "SIHALPE" & bps_2005 == 1209
	replace `v' = "PURBA HARISOAN" ///
		if `v' == "PURBA HARISAN" & bps_2005 == 1209
	replace `v' = "NAGORI PURBA" ///
		if `v' == "PURBA SARIBU" & bps_2005 == 1209
	replace `v' = "PEMATANG TAMBUN RAYA" ///
		if `v' == "TAMBUN RAYA" & bps_2005 == 1209
	replace `v' = "BAH BALON TONGAH" ///
		if `v' == "BAH BOLON TONGAH" & bps_2005 == 1209
	replace `v' = "PANOMBEAN" ///
		if `v' == "PANOMBEIAN" & bps_2005 == 1209
	replace `v' = "PEMATANG PANOMBEAN" ///
		if `v' == "PEMATANG PANOMBEIAN" & bps_2005 == 1209
	replace `v' = "PURBASARI" ///
		if `v' == "PURBA SARI" & bps_2005 == 1209
	replace `v' = "MARGOMULYO" ///
		if `v' == "MARGO MULYO" & bps_2005 == 1209
	replace `v' = "HUTA DIPAR" ///
		if `v' == "HUTADIPAR" & bps_2005 == 1209
	replace `v' = "L A R A S" ///
		if `v' == "LARAS" & bps_2005 == 1209
	replace `v' = "TELUK TAMPAN" ///
		if `v' == "TELUK TAPIAN" & bps_2005 == 1209
	replace `v' = "TANJUNG RAPIAN" ///
		if `v' == "TANJUNG RAPUAN" & bps_2005 == 1209
	replace `v' = "SARINGAN RINGAN" ///
		if `v' == "RINGAN RINGAN" & bps_2005 == 1209
	
	replace `v' = "BATUNAJAGAR" ///
		if `v' == "BATU NAGAJAR" & bps_2005 == 1215
	replace `v' = "LOBUTUA" ///
		if `v' == "LOBU TUA" & bps_2005 == 1215
	replace `v' = "SIBORUTORUP" ///
		if `v' == "SIBORUTOROP" & bps_2005 == 1215
	replace `v' = "HUTA BAGASAN" ///
		if `v' == "HUTABAGASAN" & bps_2005 == 1215
	replace `v' = "RIA RIA" ///
		if `v' == "RIA-RIA" & bps_2005 == 1215
	replace `v' = "SIUNONG UNONG JULU" ///
		if `v' == "SIUNONG-UNONG JULU" & bps_2005 == 1215
		
	replace `v' = "SURUNG MERSADA" ///
		if `v' == "SURUNG MARSADA" & bps_2005 == 1216
		
	replace `v' = "PERKEBUNAN P KOLING" ///
		if `v' == "PERK P KOLING" & bps_2005 == 1277
	replace `v' = "SIMATOHIR" ///
		if `v' == "SIMATOHIR BN" & bps_2005 == 1277
		
	replace `v' = "NAGARI SAKO PASIA TALANG" ///
		if `v' == "NAGARI SAKO PASIR TALANG" & bps_2005 == 1310
	replace `v' = "NAGARI PASIA TALANG" ///
		if `v' == "NAGARI PASIR TALANG" & bps_2005 == 1310
		
	replace `v' = "PULAU PANJANG HILIR" ///
		if `v' == "PL PANJANG HILIR" & bps_2005 == 1401
		
	replace `v' = "PULAU BUAYO" ///
		if `v' == "PULAO BUAYO" & bps_2005 == 1503
	replace `v' = "BATU PENYABUNG" ///
		if `v' == "BATU PENYAMBUNG" & bps_2005 == 1503
	replace `v' = "TELUK KECIMBUNG" ///
		if `v' == "TELUK KECIBUNG" & bps_2005 == 1503
		
	replace `v' = "PINANG BELAI" ///
		if `v' == "PINANG BALAI" & bps_2005 == 1508
		
	replace `v' = "PURWO SARI" ///
		if `v' == "PURWOSARI" & bps_2005 == 1602
		
	replace `v' = "PASAR BAYANGKARA" ///
		if `v' == "PSR.BAYANGKARA" & bps_2005 == 1603
	replace `v' = "HANDAYANI MULIA" ///
		if `v' == "HANDAYANI MULYA" & bps_2005 == 1603
		
	replace `v' = "REMANAM JAYA" ///
		if `v' == "RENANAM JAYA" & bps_2005 == 1608
	replace `v' = "SUMBER MULIA" ///
		if `v' == "SUMBER MULYA" & bps_2005 == 1608
		
	replace `v' = "TAMBANG RAMBANG" ///
		if `v' == "TAMBANGAN RAMBANG" & bps_2005 == 1610
	replace `v' = "SUKARAJA LAMA" ///
		if `v' == "SUKA RAJA LAMA" & bps_2005 == 1610
		
	replace `v' = "PERAHU DIPO" ///
		if `v' == "PRAHU DIPO" & bps_2005 == 1673
	replace `v' = "ULU RURAH" ///
		if `v' == "ULU LURAH" & bps_2005 == 1673
		
	replace `v' = "PALAK BENGKERUNG" ///
		if `v' == "PALAK BENGKRUNG" & bps_2005 == 1701
		
	replace `v' = "MULYA SARI" ///
		if `v' == "MULYO SARI" & bps_2005 == 1808	
		
	replace `v' = "KABAN JULU" ///
		if `v' == "KABANJULU" & bps_2005 == 1210
	replace `v' = "SILEUH-LEUH PARSAORAN" ///
		if `v' == "SILEUH LEUH PARSAORAN" & bps_2005 == 1210
		
		
	replace `v' = "BANTAYAN" ///
		if `v' == "BANTAIAN" & bps_2005 == 1409
	replace `v' = "BANTAYAN BARU" ///
		if `v' == "BANTAIAN BARU" & bps_2005 == 1409
	replace `v' = "BANTAYAN HILIR" ///
		if `v' == "BANTAIAN HILIR" & bps_2005 == 1409
		
	replace `v' = "PURWO ASRI" ///
		if `v' == "PURWO SARI" & bps_2005 == 1602
		
	replace `v' = "PASAR BHAYANGKARA" ///
		if `v' == "PASAR BAYANGKARA" & bps_2005 == 1603

	replace `v' = "KUNDUR" ///
		if `v' == "KUNDUR." & bps_2005 == 2001		
	replace `v' = "HARJOSARI" ///
		if `v' == "KP. HARAPAN > HARJOSARI" & bps_2005 == 2001		
	replace `v' = "DARUSALAM" ///
		if `v' == "JELUTUNG > DARUSALAM" & bps_2005 == 2001

	replace `v' = "BATUBI JAYA" ///
		if `v' == "BATU UBI JAYA" & bps_2005 == 2003
	replace `v' = "PAYA LAMAN" ///
		if `v' == "PAYA LAMAN" & bps_2005 == 2003
		
	replace `v' = "MANDALA HURIP" ///
		if `v' == "MANDALAHURIP" & bps_2005 == 3206
		
	replace `v' = "LINGGA JAYA" ///
		if `v' == "LINGGAJAYA" & bps_2005 == 3208
	replace `v' = "SIMPAY JAYA" ///
		if `v' == "SIMPAYJAYA" & bps_2005 == 3208

	replace `v' = "JATIBENING BARU" ///
		if `v' == "JATIBARU" & bps_2005 == 3275
	replace `v' = "MUSTIKA JAYA" ///
		if `v' == "MUSTIKAJAYA" & bps_2005 == 3275		
	replace `v' = "MUSTIKA SARI" ///
		if `v' == "MUSTIKASARI" & bps_2005 == 3275		

	replace `v' = "TOERJEK" ///
		if `v' == "TORJEK" & bps_2005 == 3529
		
	replace `v' = "KARANG BAJO" ///
		if `v' == "PERSIAPAN KARANG BAJO" & bps_2005 == 5201
		
	replace `v' = "TANATUKU" ///
		if `v' == "TANA TUKU" & bps_2005 == 5302
		
	replace `v' = "ABI" ///
		if `v' == "ABII" & bps_2005 == 5304
	replace `v' = "ENO NETTEN" ///
		if `v' == "ENONETE" & bps_2005 == 5304
	replace `v' = "KUATAE" ///
		if `v' == "KWATAE" & bps_2005 == 5304
		
	replace `v' = "DESA ADMEN" ///
		if `v' == "DESA ATMEN" & bps_2005 == 5305
		
	replace `v' = "BAANG KOOR" ///
		if `v' == "BAANG KO OR" & bps_2005 == 5310
	replace `v' = "BAOPAAT" ///
		if `v' == "BAO PAAT" & bps_2005 == 5310
	replace `v' = "DOBO NUA PUU" ///
		if `v' == "DOBO NUA PU U" & bps_2005 == 5310
	replace `v' = "ILINMEDO" ///
		if `v' == "ILIN MEDO" & bps_2005 == 5310
	replace `v' = "TIMUTAWA" ///
		if `v' == "TIMU TAWA" & bps_2005 == 5310
	
	replace `v' = "NYEMPEN" ///
		if `v' == "NYEMPEM" & bps_2005 == 6102
		
	replace `v' = "RIAM PIYANG" ///
		if `v' == "RIAM PIANG" & bps_2005 == 6108
		
	replace `v' = "KARANGMULYA" ///
		if `v' == "KARANG MULYA" & bps_2005 == 6201
		
	replace `v' = "TUMBANG KOLING" ///
		if `v' == "TUMBANG KULING" & bps_2005 == 6202
		
	replace `v' = "PADURAN SABANGAU" ///
		if `v' == "PADURAN SEBANGAU" & bps_2005 == 6210
		
	replace `v' = "SIAYUH" ///
		if `v' == "SI AYUH" & bps_2005 == 6302
		
	replace `v' = "KOLAM KIRI DALAM" ///
		if `v' == "BARAMBAI KOLAM KIRI DALAM" & bps_2005 == 6304
		
	replace `v' = "PELELOAN" ///
		if `v' == "PALELOAN" & bps_2005 == 7102
		
	replace `v' = "TEWESAN" ///
		if `v' == "TEAWESAN" & bps_2005 == 7105
		
	replace `v' = "PA RASANGANG BERU" ///
		if `v' == "PARASANGANG BERU" & bps_2005 == 7304
		
	replace `v' = "BORONG PA'LALA" ///
		if `v' == "BORONG PA LALA" & bps_2005 == 7306
	replace `v' = "PARANG LAMPOA" ///
		if `v' == "PARANGLOMPOA" & bps_2005 == 7306
		
	replace `v' = "WUNGGULOKO" ///
		if `v' == "WUNGGOLOKO" & bps_2005 == 7404
		
	replace `v' = "ARALLE UTARA" ///
		if `v' == "ARALE UTARA" & bps_2005 == 7603
	replace `v' = "RANTE KAMASE" ///
		if `v' == "RANTEKAMASE" & bps_2005 == 7603
	replace `v' = "PASAPA' MAMBU" ///
		if `v' == "PASAPA MAMBU" & bps_2005 == 7603
	replace `v' = "TALANG BULLAWAN" ///
		if `v' == "TALLANG BULLAWAN" & bps_2005 == 7603
	replace `v' = "BAKADISURA" ///
		if `v' == "BAKADI SURA" & bps_2005 == 7603
	replace `v' = "TADO' KALUA" ///
		if `v' == "TADO KALUA" & bps_2005 == 7603
	replace `v' = "KALAMA'" ///
		if `v' == "KALAMA" & bps_2005 == 7603
	replace `v' = "BALA BATU" ///
		if `v' == "BALABATU" & bps_2005 == 7603
	replace `v' = "BALLA SATANETEAN" ///
		if `v' == "BALLA SATENETEAN" & bps_2005 == 7603
	replace `v' = "BALLA TUMUKA'" ///
		if `v' == "BALLA TUMUKA" & bps_2005 == 7603
	replace `v' = "BAMBAPUANG" ///
		if `v' == "BAMBA PUANG" & bps_2005 == 7603
	replace `v' = "MELANGKENA PADANG" ///
		if `v' == "MALANGKENA PADANG" & bps_2005 == 7603
	replace `v' = "LISUAN ADA'" ///
		if `v' == "LISUANADA" & bps_2005 == 7603
	replace `v' = "SALUMOKANAN UTARA" ///
		if `v' == "SALUMOKAN UTARA" & bps_2005 == 7603
	replace `v' = "SALUMOKANAN BARAT" ///
		if `v' == "SALUMOKAN BARAT" & bps_2005 == 7603
	replace `v' = "SALUMAKAK" ///
		if `v' == "SALUMAKA" & bps_2005 == 7603
	replace `v' = "PAMMOSEANG" ///
		if `v' == "PAMOSEANG" & bps_2005 == 7603
	replace `v' = "SONDONG LAJUK" ///
		if `v' == "SONDONG LAYUK" & bps_2005 == 7603
	replace `v' = "BUJUNGMANURUNG" ///
		if `v' == "BUJUNG MANURUNG" & bps_2005 == 7603
	replace `v' = "RANTELEMO" ///
		if `v' == "RANTE LEMO" & bps_2005 == 7603
	replace `v' = "LIMBADEBATA" ///
		if `v' == "LIMBA DEBATA" & bps_2005 == 7603
	replace `v' = "LEMBANGMOKALLANG" ///
		if `v' == "LEMBANG MOKALLANG" & bps_2005 == 7603
	replace `v' = "SALURURU" ///
		if `v' == "SALURURUH" & bps_2005 == 7603
	replace `v' = "RANTETARIMA" ///
		if `v' == "RANTE TARIMA" & bps_2005 == 7603
	replace `v' = "BALATANA" ///
		if `v' == "BELATANA" & bps_2005 == 7603
	replace `v' = "BUNTU MALANGKA" ///
		if `v' == "BUNTUMALANGKA" & bps_2005 == 7603
	replace `v' = "RANTEBERANG" ///
		if `v' == "RANTE BERANG" & bps_2005 == 7603
	replace `v' = "PAMMOSEANG PANGGA" ///
		if `v' == "PAMOSEANG PANGGA" & bps_2005 == 7603
	replace `v' = "BARURU" ///
		if `v' == "BURURU" & bps_2005 == 7603
	replace `v' = "BATU PAPAN" ///
		if `v' == "BATUPAPAN" & bps_2005 == 7603
	replace `v' = "RAMBU SARATU" ///
		if `v' == "RAMBUSARATU" & bps_2005 == 7603
	replace `v' = "PEBASSIAN" ///
		if `v' == "PEBASIAN" & bps_2005 == 7603
	replace `v' = "BUNTUBUDA" ///
		if `v' == "BUNTU BUDA" & bps_2005 == 7603
	replace `v' = "MAMBULILLING" ///
		if `v' == "MABBULILING" & bps_2005 == 7603
		
	replace `v' = "TAAN" ///
		if `v' == "TA AN" & bps_2005 == 7604
	replace `v' = "PASA'BU" ///
		if `v' == "PASA BU" & bps_2005 == 7604
	replace `v' = "KARAMPUANG" ///
		if `v' == "KARAMPUAN" & bps_2005 == 7604
	replace `v' = "SALOKAYU I" ///
		if `v' == "SALOKAYU" & bps_2005 == 7604
	replace `v' = "K A B U B U" ///
		if `v' == "KABUBU" & bps_2005 == 7604
	replace `v' = "SULOBAJA" ///
		if `v' == "SALO BAJA" & bps_2005 == 7604
	replace `v' = "PALONGAN" ///
		if `v' == "PALONGAAN" & bps_2005 == 7604
	replace `v' = "BATU PARIGI" ///
		if `v' == "BATUPARIGI" & bps_2005 == 7604
		
	replace `v' = "BULU MARIO" ///
		if `v' == "BULUMARIO" & bps_2005 == 7605
	replace `v' = "SUMBERSARI" ///
		if `v' == "SUMBER SARI" & bps_2005 == 7605
	replace `v' = "KASTA BUANA" ///
		if `v' == "KASTABUANA" & bps_2005 == 7605
		
	replace `v' = "REWAV" ///
		if `v' == "REVAV" & bps_2005 == 8102
		
	replace `v' = "MNGESWAEN" ///
		if `v' == "MANGESWAIN" & bps_2005 == 8104
	replace `v' = "WAEPANDAN" ///
		if `v' == "WAIPANDAN" & bps_2005 == 8104
		
	replace `v' = "GOSOMA" ///
		if `v' == "PERSIAPAN GOSOMA" & bps_2005 == 8205
	replace `v' = "RAWAJAYA" ///
		if `v' == "PERSIAPAN RAWAJA" & bps_2005 == 8205

}

replace nm2005 = "JAAR" if nm2005 == "J A æ A R"
replace nm2005 = "KISAM KUTE" ///
	if nm2005 == "KISAM GABUNGAN" & id2005 == 1104030035
replace nm2005 = "PERAPAT HILIR" ///
	if nm2005 == "KUTACANE LAMA" & id2005 == 1104040003
replace nm2005 = "AIR ASIN KEMERLENG" ///
	if nm2005 == "KEMERLENG" & id2005 == 1106010018
replace nm2005 = "KELITU" ///
	if nm2005 == "KELITU SINTEP" & id2005 == 1106020013
replace nm2005 = "BUR BIAH" ///
	if nm2005 == "BUT BIAH" & id2005 == 1106050030
replace nm2005 = "PETUKEL" ///
	if nm2005 == "PETUKEL BLAN JORONG" & id2005 == 1117050011
replace nm2005 = "LOT BENER KELIPAH" ///
	if nm2005 == "BENER KELIPAH UTARA" & id2005 == 1117050025
replace nm2005 = "PINTU WIH RESEP" ///
	if nm2005 == "WIH RESAP" & id2005 == 1117060003	
replace nm2005 = "CEMPARAN JAYA" ///
	if nm2005 == "CEMPARAM LAMA" & id2005 == 1117060005
replace nm2005 = "SAIT NIHUTA KALANGAN II" ///
	if nm2005 == "S. KALANGAN II" & id2005 == 1204031004
replace nm2005 = "KUTAGERAT" ///
	if nm2005 == "KUTA GREAT" & id2005 == 1211050022	
replace nm2005 = "TIMBANG LAWAN" ///
	if nm2005 == "TB. LAWAN" & id2005 == 1213010003	
replace nm2005 = "BUKIT LAWANG" ///
	if nm2005 == "PERK.BKT.LAWANG" & id2005 == 1213010005
replace nm2005 = "SIMP PULAU RAMBUNG" ///
	if nm2005 == "SP.P.RAMBUNG" & id2005 == 1213010010	
replace nm2005 = "SIMPANG KUTA BULUH" ///
	if nm2005 == "SP. KUTA BULUH" & id2005 == 1213030006
replace nm2005 = "NAGARI UNGGAN" ///
	if nm2005 == "UNGGAN" & id2005 == 1304110008
replace nm2005 = "MUARO SENTAJO" ///
	if nm2005 == "MUARO" & id2005 == 1401030013
replace nm2005 = "KAMPUNG BESAR KOTA" ///
	if nm2005 == "KP BESAR KOTA" & id2005 == 1402060006
replace nm2005 = "KAMPUNG PAKU" ///
	if nm2005 == "KP PAKU" & id2005 == 1212190001
replace nm2005 = "PEKAN BAHOROK" if id2005 == 1213010007
replace nm2005 = "PERK SEI MUSAM" if id2005 == 1213010017
replace nm2005 = "TAMBUNAN" if id2005 == 1213020007
replace nm2005 = "GLUGUR LANGKAT" if id2005 == 1213020010
replace nm2005 = "MARIKE" if id2005 == 1213020012
replace nm2005 = "NAMO TONGAN" if id2005 == 1213020014
replace nm2005 = "TG. KELILING" if id2005 == 1213020021
replace nm2005 = "TANJUNG GUNUNG" if id2005 == 1213030002
replace nm2005 = "PASAR VIII NAMO TRASI" if id2005 == 1213030011
replace nm2005 = "EMPLASMEN PASAR IV NAMO TRASI" if id2005 == 1213030012
replace nm2005 = "KWALA MENCIRIM PS 6" if id2005 == 1213030013
replace nm2005 = "PEKAN SELESAI" if id2005 == 1213050006
replace nm2005 = "TANJUNG JATI" if id2005 == 1213060001
replace nm2005 = "SAMBIREJO" if id2005 == 1213060004
replace nm2005 = "KUALA BEGUMIT" if id2005 == 1213060005
replace nm2005 = "KWALA BINGAI" if id2005 == 1213070002
replace nm2005 = "BUKIT MELINTANG" if id2005 == 1213080004
replace nm2005 = "SAWIT SEBERANG" if id2005 == 1213100002
replace nm2005 = "KWALA GEBANG" if id2005 == 1213150009
replace nm2005 = "BRANDAN TIMUR BARU" if id2005 == 1213160005
replace nm2005 = "RABASA HAERAIN" if id2005 == 5306010032
replace nm2005 = "TUNES KELADEN" ///
	if nm2005 == "KELADEN" & id2005 == 6401021001
replace nm2005 = "LEMAHABANG WETAN" ///
	if nm2005 == "LEMAHABANG" & id2005 == 3209060007

foreach i of numlist 5306010033/5306010036 5306011014/5306011018 5306012010 ///
		5306013003/5306013008 5306020013/5306020017 5306031005 5306031006 {
	replace nm2005 = subinstr(nm2005,"PERSIAPAN ","",1) if id2005 == `i'
	replace nm2005 = subinstr(nm2005," PERSIAPAN","",1) if id2005 == `i'
}



foreach i of numlist 1213110003 1213110004 1213120008 1213140004 1274020011 {
	replace nm2005 = subinstr(nm2005,"TG.","TANJUNG",1) if id2005 == `i'
}

foreach i of numlist 1213030003 1213040012 1213140004 {
	replace nm2005 = subinstr(nm2005,"PKN","PEKAN",1) if id2005 == `i'
}

foreach i of numlist 1215010011 {
	replace nm2005 = subinstr(nm2005,"LBN.","LUMBAN",1) if id2005 == `i'
}

replace bps_2005 = 7604 if bps_2005 == 7321		
replace bps_2005 = 7603 if bps_2005 == 7323		
replace bps_2005 = 7605 if bps_2005 == 7324

* Remove prefixes "DESA" and "KELURAHAN"

foreach v in nm2005 nm2008_1 {
	replace `v' = subinstr(`v',"DESA ","",1) ///
		if substr(`v',1,5) == "DESA " & ///
		!inlist(id2005,1702040011,1702040049,1406080010,1501050009,1501071008) ///
		& !inlist(id2005,1502040023,1503020002,1508010007)
	replace `v' = subinstr(`v',"KELURAHAN ","",1) ///
		if substr(`v',1,10) == "KELURAHAN " & ///
		!inrange(id2005,1501060016,1501060031) & ///
		!inlist(id2005,1502060026,1508010012,1508040014)
}

* Remove "KAMPONG"/"KAMPUNG" prefixes which prevent successful merges

foreach v in nm2005 nm2008_1 {
	foreach x in "KAMPONG" "KAMPUNG" {
		replace `v' = subinstr(`v',"`x' ","",1) if ///
			inrange(id2005,1102010001,1102046009) & ///
			!inlist(id2005,1102021005,1102041002,1102040012,1102045005)
	}
}

* Incorrect kecamatan codes 

tostring id2005, gen(temp_id2005)

forval i = 1215021001/1215021009 {
	replace temp_id2005 = subinstr(temp_id2005,"021","030",1) if id2005 == `i'
}

forval i = 1215140001/1215140019 {
	replace temp_id2005 = subinstr(temp_id2005,"140","050",1) if id2005 == `i'
}

forval i = 1215141001/1215141008 {
	replace temp_id2005 = subinstr(temp_id2005,"141","060",1) if id2005 == `i'
}

forval i = 1215150001/1215150027 {
	replace temp_id2005 = subinstr(temp_id2005,"150","040",1) if id2005 == `i'
}

forval i = 1215160006/1215160018 {
	replace temp_id2005 = subinstr(temp_id2005,"160","090",1) if id2005 == `i'
}

forval i = 1215170001/1215170012 {
	replace temp_id2005 = subinstr(temp_id2005,"170","080",1) if id2005 == `i'
}

forval i = 1215181001/1215181006 {
	replace temp_id2005 = subinstr(temp_id2005,"181","070",1) if id2005 == `i'
}

forval i = 1215190001/1215190005 {
	replace temp_id2005 = subinstr(temp_id2005,"190","100",1) if id2005 == `i'
}

forval i = 1217040001/1217040012 {
	replace temp_id2005 = subinstr(temp_id2005,"040","050",1) if id2005 == `i'
}

forval i = 1217050001/1217050012 {
	replace temp_id2005 = subinstr(temp_id2005,"050","040",1) if id2005 == `i'
}

forval i = 1218020001/1218020030 {
	replace temp_id2005 = subinstr(temp_id2005,"020","010",1) if id2005 == `i'
}

forval i = 1218030001/1218030020 {
	replace temp_id2005 = subinstr(temp_id2005,"030","020",1) if id2005 == `i'
}

forval i = 1218040001/1218040017 {
	replace temp_id2005 = subinstr(temp_id2005,"040","030",1) if id2005 == `i'
}

forval i = 1218050001/1218050024 {
	replace temp_id2005 = subinstr(temp_id2005,"050","040",1) if id2005 == `i'
}

forval i = 1218060001/1218060008 {
	replace temp_id2005 = subinstr(temp_id2005,"060","050",1) if id2005 == `i'
}

forval i = 1218070001/1218070008 {
	replace temp_id2005 = subinstr(temp_id2005,"070","060",1) if id2005 == `i'
}

forval i = 1218080001/1218080027 {
	replace temp_id2005 = subinstr(temp_id2005,"080","070",1) if id2005 == `i'
}

forval i = 1218090001/1218090029 {
	replace temp_id2005 = subinstr(temp_id2005,"090","080",1) if id2005 == `i'
}

forval i = 1218110001/1218110041 {
	replace temp_id2005 = subinstr(temp_id2005,"110","090",1) if id2005 == `i'
}

forval i = 1218120001/1218120012 {
	replace temp_id2005 = subinstr(temp_id2005,"120","100",1) if id2005 == `i'
}

forval i = 1218130001/1218130012 {
	replace temp_id2005 = subinstr(temp_id2005,"130","110",1) if id2005 == `i'
}

forval i = 1218140101/1218140109 {
	replace temp_id2005 = subinstr(temp_id2005,"140","011",1) if id2005 == `i'
}

forval i = 1503041001/1503041008 {
	replace temp_id2005 = subinstr(temp_id2005,"041","040",1) if id2005 == `i'
}

foreach i of numlist 1205061003/1205061007 1205061014/1205061018 {
	replace temp_id2005 = subinstr(temp_id2005,"061","060",1) if id2005 == `i'
}

forval i = 1608010001/1608010035 {
	replace temp_id2005 = subinstr(temp_id2005,"010","020",1) if id2005 == `i'
}

forval i = 1608011001/1608011012 {
	replace temp_id2005 = subinstr(temp_id2005,"011","010",1) if id2005 == `i'
}

forval i = 1608020001/1608020024 {
	replace temp_id2005 = subinstr(temp_id2005,"020","100",1) if id2005 == `i'
}

forval i = 1608041001/1608041023 {
	replace temp_id2005 = subinstr(temp_id2005,"041","060",1) if id2005 == `i'
}

forval i = 1608051001/1608051014 {
	replace temp_id2005 = subinstr(temp_id2005,"051","030",1) if id2005 == `i'
}

forval i = 1608050008/1608050021 {
	replace temp_id2005 = subinstr(temp_id2005,"050","040",1) if id2005 == `i'
}

forval i = 1608031001/1608031015 {
	replace temp_id2005 = subinstr(temp_id2005,"031","080",1) if id2005 == `i'
}

destring temp_id2005, replace

foreach i of numlist 1215021001/1215021009 1215140001/1215140019 ///
		1215141001/1215141008 1215150001/1215150027 1215160006/1215160018 ///
		1215170001/1215170012 1215181001/1215181006 1215190001/1215190005 ///
		1217040001/1217040012 1217050001/1217050012 1218020001/1218020030 ///
		1218030001/1218030020 1218040001/1218040017 1218050001/1218050024 ///
		1218060001/1218060008 1218070001/1218070008 1218080001/1218080027 ///
		1218090001/1218090029 1218110001/1218110041 1218120001/1218120012 ///
		1218130001/1218130012 1218140101/1218140109 1503041001/1503041008 ///
		1205061003/1205061007 1205061014/1205061018 1608010001/1608010035 ///
		1608011001/1608011012 1608041001/1608041023 1608051001/1608051014 ///
		1608020001/1608020024 1608050008/1608050021 1608031001/1608031015 {
	replace id2005 = temp_id2005 if id2005 == `i'
}

drop temp_id2005

* Incorrect district and/or kecamatan codes 

tostring id2005, gen(temp_id2005)

foreach i of numlist 7321010001/7321010010 7321011001/7321011005 ///
		7321020003/7321020007 7321030001/7321030009 7321031001/7321031006 ///
		7321032001/7321032006 7321033001/7321033009 7321040011/7321040013 ///
		7321040007/7321040009 7321050005/7321050018 7321051001/7321051007 ///
		7321052001/7321052012 7321053001/7321053011 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7321","7604",1) if id2005 == `i'
}

foreach i of numlist 7324010001/7324010007 7324020001/7324020011 ///
		7324030019/7324030024 7324030031 7324040001/7324040006 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7324","7605",1) if id2005 == `i'
}

foreach i of numlist 7323010007/7323010010 7323020006/7323020009 ///
		7323030007/7323030019 7323031007 7323040001/7323040006 7323050012 ///
		7323060001/7323060018 7323061007 7323061008 7323070013 7323070014 ///
		7323080017 7323080033 7323080034 7323081008 7323081009 ///
		7323081016/7323081020 7323090014/7323090020 7323100001/7323100014 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323","7603",1) if id2005 == `i'
}

forval i = 7323010001/7323010006 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323010","7603020",1) if id2005 == `i'
}

forval i = 7323020001/7323020005 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323020","7603010",1) if id2005 == `i'
}

forval i = 7323031001/7323031006 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323031","7603030",1) if id2005 == `i'
}

forval i = 7323050001/7323050011 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323050","7603090",1) if id2005 == `i'
}

forval i = 7323061001/7323061006 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323061","7603060",1) if id2005 == `i'
}

forval i = 7323070001/7323070012 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323070","7603050",1) if id2005 == `i'
}

foreach i of numlist 7323080001/7323080016 7323080018 7323080030/7323080032 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323080","7603070",1) if id2005 == `i'
}

foreach i of numlist 7323081001/7323081007 7323081010/7323081015 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323081","7603070",1) if id2005 == `i'
}

forval i = 7323090001/7323090013 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7323090","7603080",1) if id2005 == `i'
}

forval i = 7321021001/7321021006 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7321021","7604020",1) if id2005 == `i'
}

foreach i of numlist 7321041001/7321041003 7321041005 7321041006 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7321041","7604040",1) if id2005 == `i'
}

forval i = 7321054001/7321054008 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7321054","7604050",1) if id2005 == `i'
}

foreach i of numlist 7321011005 {
	replace temp_id2005 = ///
		subinstr(temp_id2005,"7321011","7604010",1) if id2005 == `i'
}

destring temp_id2005, replace

foreach i of numlist 7324010001/7324010007 7324020001/7324020011 ///
		7324030019/7324030024 7324030031 7324040001/7324040006 ///
		7323010007/7323010010 7323020006/7323020009 ///
		7323030007/7323030019 7323031007 7323040001/7323040006 7323050012 ///
		7323060001/7323060018 7323061007 7323061008 7323070013 7323070014 ///
		7323080017 7323080033 7323080034 7323081008 7323081009 ///
		7323081016/7323081020 7323090014/7323090020 7323100001/7323100014 ///
		7323010001/7323010006 7323020001/7323020005 7323031001/7323031006 ///
		7323050001/7323050011 7323061001/7323061006 7323070001/7323070012 ///
		7323080001/7323080016 7323080018 7323080030/7323080032 ///
		7323081001/7323081007 7323081010/7323081015 7323090001/7323090013 ///
		7321010001/7321010010 7321011001/7321011005 7321020003/7321020007 ///
		7321021001/7321021006 7321030001/7321030009 7321031001/7321031006 ///
		7321032001/7321032006 7321033001/7321033009 7321040007/7321040009 ///
		7321040011/7321040013 7321041001/7321041003 7321041005 7321041006 ///
		7321050005/7321050018 7321051001/7321051007 7321052001/7321052012 ///
		7321053001/7321053011 7321054001/7321054008 7321011005 {
	replace id2005 = temp_id2005 if id2005 == `i'
}

drop temp_id2005

* Incorrect district codes in Papua island and elsewhere

tostring id2005, gen(temp_id2005)

replace temp_id2005 = subinstr(temp_id2005,"9405","9101",1) ///
	if inrange(id2005,9405050006,9405083053)

replace temp_id2005 = subinstr(temp_id2005,"9406","9107",1) ///
	if inrange(id2005,9406050001,9406220004)

replace temp_id2005 = subinstr(temp_id2005,"9407","9105",1) ///
	if inrange(id2005,9407040008,9407170045)
	
replace temp_id2005 = subinstr(temp_id2005,"9421","9102",1) ///
	if inrange(id2005,9421010001,9421040011)
	
replace temp_id2005 = subinstr(temp_id2005,"9422","9106",1) ///
	if inrange(id2005,9422010001,9422140009)	
	
replace temp_id2005 = subinstr(temp_id2005,"9423","9108",1) ///
	if inrange(id2005,9423010001,9423100004)
	
replace temp_id2005 = subinstr(temp_id2005,"9424","9104",1) ///
	if inrange(id2005,9424010001,9424100007)
	
replace temp_id2005 = subinstr(temp_id2005,"9425","9103",1) ///
	if inrange(id2005,9425010001,9425070007)

replace temp_id2005 = subinstr(temp_id2005,"2101","2001",1) ///
	if inrange(id2005,2101010003,2101033008)
	
replace temp_id2005 = subinstr(temp_id2005,"2102","2002",1) ///
	if inrange(id2005,2102040001,2102070006)
	
replace temp_id2005 = subinstr(temp_id2005,"2103","2003",1) ///
	if inrange(id2005,2103010001,2103061004)
	
replace temp_id2005 = subinstr(temp_id2005,"2104","2004",1) ///
	if inrange(id2005,2104010002,2104030006)	

replace temp_id2005 = subinstr(temp_id2005,"2171","2071",1) ///
	if inrange(id2005,2171010001,2171080008)
	
replace temp_id2005 = subinstr(temp_id2005,"2172","2072",1) ///
	if inrange(id2005,2172010001,2172040004)	

replace temp_id2005 = subinstr(temp_id2005,"9472","9171",1) ///
	if inrange(id2005,9472010003,9472030004)

destring temp_id2005, replace

replace id2005 = temp_id2005 if inrange(id2005,9405050006,9405083053) ///
	| inrange(id2005,9406050001,9406220004) ///
	| inrange(id2005,9407040008,9407170045) ///
	| inrange(id2005,9421010001,9421040011) ///
	| inrange(id2005,9422010001,9422140009) ///
	| inrange(id2005,9423010001,9423100004) ///
	| inrange(id2005,9424010001,9424100007) ///
	| inrange(id2005,9425010001,9425070007) ///
	| inrange(id2005,2101010003,2101033008) ///
	| inrange(id2005,2102040001,2102070006) ///
	| inrange(id2005,2103010001,2103061004) ///
	| inrange(id2005,2104010002,2104030006) ///
	| inrange(id2005,2171010001,2171080008) ///
	| inrange(id2005,2172010001,2172040004) ///
	| inrange(id2005,9472010003,9472030004)

drop temp_id2005

* Further tweak names

replace nm2005 = "KALANA" ///
	if id2005 == 7603040006 & nm2005 == "KALAMA" 
replace nm2005 = "BUBUN BATU" ///
	if id2005 == 7603050012 & nm2005 == "PERS BABUA BATU"
replace nm2005 = "RANTELEMO" ///
	if id2005 == 7603070006 & nm2005 == "RANTE LEMO"
replace nm2005 = "BALLA SATANETEAN" ///
	if id2005 == 7603060004 & nm2005 == "BALLA SATENETEAN"	
replace nm2005 = "BAMBAPUANG" ///
	if id2005 == 7603061007 & nm2005 == "PERS BAMBA PUANG"
replace nm2005 = "ULU MAMBI" ///
	if id2005 == 7603070007 & nm2005 == "ULUMAMBI"	
replace nm2005 = "LEMBANG MAKOLANG" ///
	if id2005 == 7603070011 & nm2005 == "LEMBANG MOKALLANG"
replace nm2005 = "MOSOSO" ///
	if id2005 == 7603070012 & nm2005 == "MASOSO"	
replace nm2005 = "SALUKEPOPOK" ///
	if id2005 == 7603070015 & nm2005 == "SALUKEPOPO"
replace nm2005 = "BARURU" ///
	if id2005 == 7603080002 & nm2005 == "BURURU"	
replace nm2005 = "SALURINDU" ///
	if id2005 == 7603080011 & nm2005 == "PERS SALURINDUK"
replace nm2005 = "LIMBADEBATA" ///
	if id2005 == 7603081009 & nm2005 == "LIMBA DEBATA"
replace nm2005 = "SALURURU" ///
	if id2005 == 7603081017 & nm2005 == "PERS SALURURUH"
replace nm2005 = "BALATANA" ///
	if id2005 == 7603081020 & nm2005 == "PERS BELATANA"
replace nm2005 = "PAMOSEANGPANGGA" ///
	if id2005 == 7603090015 & nm2005 == "PAMOSEANG PANGGA"
replace nm2005 = "SAPTAMARGA" ///
	if id2005 == 7605010006 & nm2005 == "SAPTANAJAYA"
replace nm2005 = "KARABE" ///
	if id2005 == 7605020004 & nm2005 == "KARAVE"
replace nm2005 = "UPT BARAS X" ///
	if id2005 == 7605020009 & nm2005 == "SUMBER SARI"	
replace nm2005 = "SALUBULO" ///
	if id2005 == 7603070002 & nm2005 == "SALUBALO"
replace nm2005 = "MANANGA" ///
	if id2005 == 7603081016 & nm2005 == "MINANGA"
replace nm2005 = "PASA'BU" ///
	if id2005 == 7604011001 & nm2005 == "PASA BU"
replace nm2005 = "UPT LARA I" ///
	if id2005 == 7604053003 & nm2005 == "LARA I"
replace nm2005 = "SALUWADAK" ///
	if id2005 == 7604050001 & nm2005 == "SALO ADAK"
replace nm2005 = "SULOBAJA" ///
	if id2005 == 7604050003 & nm2005 == "SALO BAJA"
replace nm2005 = "BATU PARIGI" ///
	if id2005 == 7604050008 & nm2005 == "BATUPARIGI"	
replace nm2005 = "TAAN" ///
	if id2005 == 7604010010 & nm2005 == "TA AN"
replace nm2005 = "BALABALAKAN" ///
	if id2005 == 7604020006 & nm2005 == "BALABALAKANG"
replace nm2005 = "POLO" ///
	if id2005 == 7604051005 & nm2005 == "POLO LERENG"
replace nm2005 = "PALONGAN" ///
	if id2005 == 7604050007 & nm2005 == "PALONGAAN"	
replace nm2005 = "NAGORI SIHALPE" ///
	if id2005 == 1209021001 & nm2005 == "SIHALPE"
replace nm2005 = "NAGORI PURBA" ///
	if id2005 == 1209021005 & nm2005 == "PURBA SARIBU"	
replace nm2005 = "NAGORI BOSAR" ///
	if id2005 == 1209091005 & nm2005 == "BOSAR"
replace nm2005 = "NEGERI DOLOK" ///
	if id2005 == 1209120006 & nm2005 == "NAGORI DOLOK"	
replace nm2005 = "LASARA BAGAMU" ///
	if id2005 == 1201120029 & nm2005 == "LASARA BAGAWU"
replace nm2005 = "PAYA OMBUR" ///
	if id2005 == 1203041069 & nm2005 == "PAYAOMBOR"
replace nm2005 = "NAGARI SALAYO TANANG BUKIK SILEH" ///
	if id2005 == 1303070001 & nm2005 == "NAGARI SELAYU TANANG BUKI"
replace nm2005 = "NAGARI SIMPANG TANJUNG NAN IV" ///
	if id2005 == 1303071001 & nm2005 == "NAGARI SIMPANG TANJUNG NA"	
replace nm2005 = "NAGARI KOTO GAEK GUGUAK" ///
	if id2005 == 1303080003 & nm2005 == "NAGARI KOTO GAEK GUGUK"					
replace nm2005 = "NAGARI JAWI-JAWI GUGUAK" ///
	if id2005 == 1303080005 & nm2005 == "NAGARI JAWI-JAWI"
replace nm2005 = "NAGARI MUARO PANAS" ///
	if id2005 == 1303090004 & nm2005 == "NAGARI MUARA PANAS"
replace nm2005 = "NAGARI BUKIT BAIS" ///
	if id2005 == 1303100002 & nm2005 == "NAGARI BAKIT BAIS"
replace nm2005 = "NAGARI GUGUAK SARAI" ///
	if id2005 == 1303100007 & nm2005 == "NAGARI GUGUK SARAI"
replace nm2005 = "NAGARI TANJUANG BINGKUANG" ///
	if id2005 == 1303110008 & nm2005 == "NAGARI TANJUANG BINGKUNG"			
replace nm2005 = "NAGARI KUNCIA" ///
	if id2005 == 1303120001 & nm2005 == "NAGARI KUNCIR"		
replace nm2005 = "NAGARI TANJUNG BALIK" ///
	if id2005 == 1303120006 & nm2005 == "NAGARI TANJUNG BALIT"
replace nm2005 = "NAGARI SUNGAI JAMBUA" ///
	if id2005 == 1303100006 & nm2005 == "NAGARI SUNGAI JAMBUR"	
replace nm2005 = "NAGARI GANTUANG CIRI" ///
	if id2005 == 1303110001 & nm2005 == "NAGARI GANTUNG CIRI"
replace nm2005 = "NAGARI GAUNG" ///
	if id2005 == 1303110006 & nm2005 == "NAGARI GAUANG"
replace nm2005 = "NAGARI BUKIK KANDUANG" ///
	if id2005 == 1303120009 & nm2005 == "NAGARI BUKIT"	
replace nm2005 = "RANI PASAI" ///
	if id2005 == 1603061006 & nm2005 == "RAMIPASAI"
replace nm2005 = "MODONG" ///
	if id2005 == 1603092009 & nm2005 == "SUKA DANA"
replace nm2005 = "SUKA CINTA" ///
	if id2005 == 1603092011 & nm2005 == "PAYA ANGUS"
replace nm2005 = "PENANDINGAN" ///
	if id2005 == 1603092012 & nm2005 == "DANAU TAMPANG"
replace nm2005 = "DANAU RATA" ///
	if id2005 == 1603092013 & nm2005 == "KASAI"
replace nm2005 = "SUKA MAJU" ///
	if id2005 == 1603092014 & nm2005 == "SUNGAI ROTAN"
replace nm2005 = "MODONG" ///
	if id2005 == 1603092017 & nm2005 == "MUARA LEMATANG"
replace nm2005 = "KELURAHAN KETSOBLAK" ///
	if id2005 == 8102015002 & nm2005 == "KETSOBLAK"
replace nm2005 = "KELURAHAN MASRUM" ///
	if id2005 == 8102015004 & nm2005 == "MASRUM"
replace nm2005 = "KELURAHAN LODAR EL" ///
	if id2005 == 8102015005 & nm2005 == "LODAR EL"
replace nm2005 = "SATHER" ///
	if id2005 == 8102022008 & nm2005 == "SETHER"
replace nm2005 = "TONETANAH" ///
	if id2005 == 8103060015 & nm2005 == "UPT TONE T"
replace nm2005 = "SERESAM" ///
	if id2005 == 1402020031 & nm2005 == "SERASAM"	
replace nm2005 = "TEBING TINGI III" ///
	if id2005 == 1507010036 & nm2005 == "UPT TEBING TINGGI III (BRASAU)"
replace nm2005 = "SAUD" ///
	if id2005 == 1606021005 & nm2005 == "SAUT"
replace nm2005 = "BUMIJAYA /PANCA TUNGGAL" ///
	if id2005 == 1606090024 & nm2005 == "PANCA TUNGGAL"
replace nm2005 = "NILAM SARI (TENGGULANG JAYA)" ///
	if id2005 == 1606090031 & nm2005 == "TENGGULANG JAYA"
replace nm2005 = "AIR TENGGULANG SP 4" ///
	if id2005 == 1606090033 & nm2005 == "SUMBER JAYA"
replace nm2005 = "BUANA MURTI (AIR SENDA III)" ///
	if id2005 == 1607030004 & nm2005 == "BUANA MURTI"
replace nm2005 = "PAGAR BANYU SP II" ///
	if id2005 == 1705033002 & nm2005 == "UPT PAGAR BANYU SP II BANYU KE"
replace nm2005 = "GELOMBANG PANJANG" ///
	if id2005 == 1807030010 & nm2005 == "PANJANG"
replace nm2005 = "KACANG PEDANG KEJAKSAAN" ///
	if id2005 == 1971041001 & nm2005 == "K.P KEJAKSAAN"
replace nm2005 = "DAUH PURI" ///
	if id2005 == 5102050013 & nm2005 == "MARGA DAUH PURI"
replace nm2005 = "DAJAN PURI" ///
	if id2005 == 5102050014 & nm2005 == "MARGA DAJAN PURI"
replace nm2005 = "JORONG" ///
	if id2005 == 5203070005 & nm2005 == "KELAYU JORONG"
replace nm2005 = "KELAYU" ///
	if id2005 == 5203070013 & nm2005 == "KELAYU SELATAN"
replace nm2005 = "OO" ///
	if id2005 == 5205020010 & nm2005 == "O O"
replace nm2005 = "O'O'" ///
	if id2005 == 5206080004 & nm2005 == "O O"
replace nm2005 = "SAMBET" ///
	if id2005 == 5304111004 & nm2005 == "SANBET"				
replace nm2005 = "SEBANTE" ///
	if id2005 == 6102041009 & nm2005 == "SEBENTE"
replace nm2005 = "JESAFE" ///
	if id2005 == 6102050018 & nm2005 == "JESAPE"
replace nm2005 = "DABUNG" ///
	if id2005 == 6104030001 & nm2005 == "DABONG"
replace nm2005 = "SUNGAI BEMBAN" ///
	if id2005 == 6104030017 & nm2005 == "BEMBAN"	
replace nm2005 = "SUNGAI DURIAN" ///
	if id2005 == 6104070001 & nm2005 == "DURIAN"
replace nm2005 = "WONOSARI" ///
	if id2005 == 6202200015 & nm2005 == "WONOSARI (UPT. II-L)"
replace nm2005 = "MAMPUAK II(PANTUNG)" ///
	if id2005 == 6205040015 & nm2005 == "PANTUNG"
replace nm2005 = "PULAU KERAYAAN" ///
	if id2005 == 6302030001 & nm2005 == "P. KERAYAAN"		
replace nm2005 = "PULAU KERASIAN" ///
	if id2005 == 6302030004 & nm2005 == "P. KERASIAN"
replace nm2005 = "BEPARA" ///
	if id2005 == 6302200005 & nm2005 == "BAPARA"
replace nm2005 = "MUARA ADANG I" ///
	if id2005 == 6401060023 & nm2005 == "SPI MUARA ADANG"
replace nm2005 = "P4HDR" ///
	if id2005 == 6402010012 & nm2005 == "UPT P4HDR"
replace nm2005 = "LUNG MELAH (MARAH KENYAH)" ///
	if id2005 == 6404021005 & nm2005 == "MARAH KENYAH"
replace nm2005 = "BENO HARAPAN (SP 1)" ///
	if id2005 == 6404030006 & nm2005 == "BENUA HARAPAN"
replace nm2005 = "BADAN BIKIS" ///
	if id2005 == 6407041004 & nm2005 == "BIKIS/BANDAN"
replace nm2005 = "BUNYU BARAT" ///
	if id2005 == 6407050002 & nm2005 == "PULAU BUNYU BARAT"	
replace nm2005 = "BUNYU TIMUR" ///
	if id2005 == 6407050003 & nm2005 == "PULAU BUNYU TIMUR"	
replace nm2005 = "LONG TUGUL" ///
	if id2005 == 6408010032 & nm2005 == "PA TUGUL"	
replace nm2005 = "KUYO" ///
	if id2005 == 6408020066 & nm2005 == "KUYAU"	
replace nm2005 = "SANUR" ///
	if id2005 == 6408041017 & nm2005 == "UPT SEBUKU I/ SANUR"	
replace nm2005 = "API API" ///
	if id2005 == 6409020001 & nm2005 == "API-API"	
replace nm2005 = "LEMARU" ///
	if id2005 == 6471020003 & nm2005 == "LAMARU"	
replace nm2005 = "DUDEPO" ///
	if id2005 == 7101010022 & nm2005 == "DODEPO"	
replace nm2005 = "KAMPUNG BARU" ///
	if id2005 == 7314051006 & nm2005 == "BINA BARU"	
replace nm2005 = "AWO-GADI" ///
	if id2005 == 7317090014 & nm2005 == "AWO_ GADING"	
replace nm2005 = "LAHUMOKO" ///
	if id2005 == 7402101007 & nm2005 == "TRI MULYA"	
replace nm2005 = "SAMPARA/MOROSI" ///
	if id2005 == 7403101007 & nm2005 == "MOROSI"	
replace nm2005 = "PUUNDAIPA" ///
	if id2005 == 7404011012 & nm2005 == "PERSIAPAN PUUNDAIPA"	
replace nm2005 = "NAPAR" ///
	if id2005 == 8105030073 & nm2005 == "NAFAR"	
replace nm2005 = "TRANS GOAL/GOLAGO KUSUMA" ///
	if id2005 == 8201100028 & nm2005 == "GOLAKO KUSUMA"	
replace nm2005 = "MANGOLI" ///
	if id2005 == 8203040008 & nm2005 == "UPT MANGOLI"	
replace nm2005 = "MODAPIA (DB)" ///
	if id2005 == 8203040011 & nm2005 == "MADAPIA"	
replace nm2005 = "WAYA KUBA (DB)" ///
	if id2005 == 8204040019 & nm2005 == "WAYAKUBA"	
replace nm2005 = "SIGUNTUR" ///
	if id2005 == 1302110009 & nm2005 == "NAGARI SIGUNTUA"
replace nm2005 = "DATARAN BULAN I" ///
	if id2005 == 7209040014 & nm2005 == "BULAN JAYA"	
replace nm2005 = "DATARAN BULAN II" ///
	if id2005 == 7204100015 & nm2005 == "GIRI MULYO"
replace nm2005 = "BETELEN" ///
	if id2005 == 7105050010 & nm2005 == "BETELAN"	
replace nm2005 = "TINIAWANGKO" ///
	if id2005 == 7105090008 & nm2005 == "TINIWANGKO"
replace nm2005 = "TEWASEN" ///
	if id2005 == 7105100022 & nm2005 == "TEAWESAN"	
replace nm2005 = "DATARAN BULAN II" ///
	if id2005 == 7209040015 & nm2005 == "GIRI MULYA"
replace nm2005 = "DATARAN BULAN III" ///
	if id2005 == 7209040016 & nm2005 == "WANASARI"
replace nm2005 = "J P. BURU" ///
	if id2005 == 8104021009 & nm2005 == "WAELEMAN"	
replace nm2005 = "PELAAH" ///
	if id2005 == 6407010002 & nm2005 == "LONG YIIN"					
replace nm2005 = "UPT. BATUMEA" ///
	if id2005 == 7403072004 & nm2005 == "TUMBU-TUMBU JAYA"
replace nm2005 = "UPT SEI KERAWANG" ///
	if id2005 == 6104010011 & nm2005 == "SEI KERAWANG"
replace nm2005 = "LARA II" ///
	if id2005 == 7604053005 & nm2005 == "LEMBAH HOPO"
replace nm2005 = "NGADA BOLU" ///
	if nm2005 == "NGADU MBOLU" & id2005 == 5301081011	
replace nm2005 = "SINAR MULYA" ///
	if nm2005 == "SINAR MULYO" & id2005 == 1608040020
replace nm2005 = "WATES" ///
	if nm2005 == "WATAS" & id2005 == 1608100023
replace nm2005 = "TEBAT LAYANG" ///
	if nm2005 == "TABAT LAYANG" & id2005 == 1608100024
replace nm2005 = "DUSUN BARU/SUKASERI" ///
	if nm2005 == "DUSUN BARU" & id2005 == 1707061005	
replace nm2005 = "SUKA MULYA" ///
	if nm2005 == "SUKATANI" & id2005 == 1803110032
replace nm2005 = "BINA KARYA JAYA" ///
	if nm2005 == "SEKIPI" & id2005 == 1806011002
replace nm2005 = "PERS BANYU ASIN" ///
	if nm2005 == "BANYUASIN" & id2005 == 1901131001
replace nm2005 = "DUA SEPAKAT" ///
	if nm2005 == "TORUSAN DUA SEPAKAT" & id2005 == 1202021031
replace nm2005 = "GUNUNG TUA PANGGORENGAN" ///
	if nm2005 == "PANGGORENGAN" & id2005 == 1202050074	
replace nm2005 = "TELUK LAPIAN" ///
	if nm2005 == "TELUK TAPIAN" & id2005 == 1209210012	
replace nm2005 = "PULAU TAGOR BARU" ///
	if nm2005 == "PULAU TAGOR" & id2005 == 1212190011
replace nm2005 = "TG. BERINGIN" ///
	if nm2005 == "PERKEBUNAN TG. BERINGIN" & id2005 == 1213120001
replace nm2005 = "DAMAR CONDONG" ///
	if nm2005 == "PERKEBUNAN DAMAR CONDONG" & id2005 == 1213200015
replace nm2005 = "NAGARI BATU KAMBING" ///
	if nm2005 == "NAGARI TIGO KOTO BATU KAMBING" & id2005 == 1307021002	
replace nm2005 = "SERESAM" ///
	if nm2005 == "SERASAM" & id2005 == 1402020031
replace nm2005 = "TELAGA LIMO" ///
	if nm2005 == "TELAGA LIMA" & id2005 == 1506041006
replace nm2005 = "GEROGOL" ///
	if nm2005 == "GROGOL" & id2005 == 3672022008
replace nm2005 = "LIFULEO" ///
	if nm2005 == "TALOITAN" & id2005 == 5303111002
replace nm2005 = "SIDOMULYO" ///
	if nm2005 == "SIDO MULYO" & id2005 == 6310050017
replace nm2005 = "UPT P4HDR" ///
	if nm2005 == "P4HDR" & id2005 == 6402010012
replace nm2005 = "GAS ALAM BADAK SATU" ///
	if nm2005 == "GAS ALAM BADAK" & id2005 == 6403130012
replace nm2005 = "BATU-BATU" ///
	if nm2005 == "BATU BATU" & id2005 == 6403130011	
replace nm2005 = "UEKULI" ///
	if nm2005 == "UPT KALEMBA II" & id2005 == 7209020029
replace nm2005 = "TONYAMAN" ///
	if nm2005 == "TONYAMANG" & id2005 == 7602051002
replace nm2005 = "AMASSANGAN" ///
	if nm2005 == "AMMASANGAN" & id2005 == 7602051003	
replace nm2005 = "GUAERIA" ///
	if nm2005 == "GUAIRIA" & id2005 == 8201090048
replace nm2005 = "TABA DAMAI (DB)" ///
	if nm2005 == "TABADAMAT" & id2005 == 8201091015
replace nm2005 = "ROPU TENGAH BALU" ///
	if nm2005 == "JERBUT" & id2005 == 8201100032	
replace nm2005 = "TALAPAO (TALAPAON)" ///
	if nm2005 == "TALAPAON" & id2005 == 8204070020	
replace nm2005 = "JIKOLAMO" ///
	if nm2005 == "FULAY" & id2005 == 8204080019
replace nm2005 = "MKCM" ///
	if nm2005 == "PERSIAPAN MKCM" & id2005 == 8205040028
replace nm2005 = "PANTAI SAGU" ///
	if nm2005 == "PANTE SAGU" & id2005 == 8271010023
replace nm2005 = "KWAMKWAMUR" ///
	if nm2005 == "KWAMKWAMOR" & id2005 == 9101082020
replace nm2005 = "BOMBERAY V (UPT) / PINANG AGUNG" ///
	if nm2005 == "PINANG AGUNG" & id2005 == 9101083048
replace nm2005 = "BOMBERAY VI (UPT) / BUMI MUROH INDAH" ///
	if nm2005 == "BUMI MUROH INDAH" & id2005 == 9101083049
replace nm2005 = "BOMBERAY VII (UPT) / WONODADI MULYA" ///
	if nm2005 == "WONODADI MULYA" & id2005 == 9101083050
replace nm2005 = "UNDURARA" ///
	if nm2005 == "UNDORARA" & id2005 == 9103010005
replace nm2005 = "WASIMO" ///
	if nm2005 == "WOSIMO" & id2005 == 9103010006
replace nm2005 = "ATIBO" ///
	if nm2005 == "MANIMERY/ATIBO" & id2005 == 9104050011
replace nm2005 = "SEBYAR REJOSARI" ///
	if nm2005 == "SP VATANIMERI/SEBYAR REJO" & id2005 == 9104070005
replace nm2005 = "MENIY" ///
	if nm2005 == "MANY/MENIY" & id2005 == 9105110004 
replace nm2005 = "GUEINTUY" ///
	if nm2005 == "QUINTUI" & id2005 == 9105110016	
replace nm2005 = "MATOA" ///
	if nm2005 == "MOTOA" & id2005 == 9105120015
replace nm2005 = "AYAU" ///
	if nm2005 == "AYOU" & id2005 == 9105130020
replace nm2005 = "KWOKWISNGUNG/KWOK II" ///
	if nm2005 == "KWOK" & id2005 == 9105130061
replace nm2005 = "SLOMIOU" ///
	if nm2005 == "SIOMID" & id2005 == 9105130009	
replace nm2005 = "MBATA" ///
	if nm2005 == "M BATA" & id2005 == 9105146003
replace nm2005 = "FIGOUD" ///
	if nm2005 == "FIGOID" & id2005 == 9105144011
replace nm2005 = "HOYOU" ///
	if nm2005 == "HIYOU" & id2005 == 9105040018	
replace nm2005 = "TUHUBEA" ///
	if nm2005 == "DUHUBEYA" & id2005 == 9105080004
replace nm2005 = "UNCEP" ///
	if nm2005 == "UMCEP" & id2005 == 9105130032
replace nm2005 = "DIHISU" ///
	if nm2005 == "DISIHU" & id2005 == 9105080028
replace nm2005 = "SISIR / SAYAL" ///
	if nm2005 == "SISIR" & id2005 == 9106130001
replace nm2005 = "WIAKSNO/KAMBUWIFA" ///
	if nm2005 == "WIAKSNO" & id2005 == 9106080006
replace nm2005 = "WABAN (SUN)" ///
	if nm2005 == "WABAN" & id2005 == 9106100004
replace nm2005 = "YADAUW" ///
	if nm2005 == "YADOW" & id2005 == 9403080008
replace nm2005 = "NAMEI" ///
	if nm2005 == "MAMEI" & id2005 == 9403140003
replace nm2005 = "BANGAI" ///
	if nm2005 == "BAGAI" & id2005 == 9403150011
replace nm2005 = "IMESTUM" ///
	if nm2005 == "IMUSTUM" & id2005 == 9403160017
replace nm2005 = "YOBOY / KEHUSA / KEHIRAN" ///
	if nm2005 == "KEHIRAN" & id2005 == 9403230008
replace nm2005 = "BABRONGKO" ///
	if nm2005 == "IFAR BABRONGKO" & id2005 == 9403230001
replace nm2005 = "SIMPORO / BABO / YOSIBA" ///
	if nm2005 == "YOSIBA" & id2005 == 9403230002
replace nm2005 = "KHAMEYAKA" ///
	if nm2005 == "KHAMAEKA" & id2005 == 9403230003
replace nm2005 = "PONA" ///
	if nm2005 == "SUKAMAJU" & id2005 == 9404030012
replace nm2005 = "KAMPUNG PAKU" ///
	if nm2005 == "KP PAKU" & id2005 == 1218150101

replace nm2004_alt = "SIOBAN" ///
	if id2005 == 1202050071 & nm2004_alt == "SIOBON"
replace nm2004_alt = "SIKARA KARA IV" ///
	if id2005 == 1202060028 & nm2004_alt == "SIKARA - KARA IV"
replace nm2004_alt = "LAKEAKELAMO" ///
	if id2005 == 8201100030 & nm2004_alt == "LAKO AKELAMO"

replace nm2004_alt = "UPT K / WAFLAN" if nm2004_alt == "UPT K. WAVLAN"
replace nm2004_alt = "WAIKASAR" if nm2004_alt == "WAEKASAR"

* Name with unrecognized character

replace nm2005 = "JAAR" if id2005 == 6212020006

* Cases where IDs were accidentally switched

replace id2005 = 1111070008 ///
	if id2005 == 1111070009 & nm2005 == "SEUPENG" 
replace id2005 = 1111070009 ///
	if id2005 == 1111070008 & nm2005 == "BEURANDANG DAYAH" 
					
* Apparently incorrect IDs

recode id2004_alt (1210050011 = 1210050014) (1210051004 = 1210050004) ///
				  (1210061006 = 1210061001) 

foreach i in 2001010009 2001020008 2002060010 2002061005 {
	qui replace id2005 = id2004_alt if id2005 == `i'
}

foreach i of numlist 1302100006 1302100007 {
	replace id2005 = id2004_alt if id2004_alt == `i'
}
			  
recode id2005 (1704042005 = 1704042004) if nm2005 == "TRI TUNGGAL BHAKTI"
recode id2005 (1604070013 = 1604070015) if nm2005 == "PAJAR MENANG"
recode id2005 (7321041004 = 7321040004) if nm2005 == "TALONDO I"
recode id2005 (1608020034 = 1608020036) if nm2005 == "TANJUNG HARAPAN"
recode id2005 (1303050001 = 1303050004) if nm2005 == "NAGARI AIA DINGIN"			
recode id2005 (1303050004 = 1303050002) if nm2005 == "NAGARI SUNGAI NANAM"
recode id2005 (1303070002 = 1303070006) if nm2005 == "NAGARI BATU BAJANJANG"				
recode id2005 (1303070006 = 1303070002) if nm2005 == "NAGARI BATU BANYAK"				
recode id2005 (1303090002 = 1303090003) if nm2005 == "NAGARI PARAMBAHAN"				
recode id2005 (1303100006 = 1303100009) if nm2005 == "NAGARI SUNGAI JAMBUA"
recode id2005 (1303100003 = 1303100006) if nm2005 == "NAGARI SUNGAI DURIAN"
recode id2005 (1303110001 = 1303110005) if nm2005 == "NAGARI GANTUANG CIRI"
recode id2005 (1303120004 = 1303120003) if nm2005 == "NAGARI PANINJAUAN"
recode id2005 (1303120005 = 1303120004) if nm2005 == "NAGARI LABUAN PANJANG"
recode id2005 (1303130003 = 1303130005) if nm2005 == "NAGARI SANING BAKAR"
recode id2005 (1303130004 = 1303130003) if nm2005 == "NAGARI SINGKARAK"
recode id2005 (1303130005 = 1303130008) if nm2005 == "NAGARI ARIPAN"
recode id2005 (1303130008 = 1303130001) if nm2005 == "NAGARI KACANG"
recode id2005 (1303130001 = 1303130006) if nm2005 == "NAGARI KOTO SANI"
recode id2005 (1303130006 = 1303130002) if nm2005 == "NAGARI TIKALAK"
recode id2005 (1303130002 = 1303130004) if nm2005 == "NAGARI SUMANI"
recode id2005 (1303080003 = 1303080005) if nm2005 == "NAGARI KOTO GAEK GUGUAK"
recode id2005 (1303080005 = 1303080006) if nm2005 == "NAGARI JAWI-JAWI GUGUAK"
recode id2005 (1303080006 = 1303080002) if nm2005 == "NAGARI TALANG"
recode id2005 (1303080002 = 1303080008) if nm2005 == "NAGARI AIA BATUMBUAK"
recode id2005 (1303080008 = 1303080001) if nm2005 == "NAGARI CUPAK"
recode id2005 (1303080001 = 1303080007) if nm2005 == "NAGARI BATANG BARUS"
recode id2005 (1303080007 = 1303080003) if nm2005 == "NAGARI SUNGAI JANIAH"
recode id2005 (1303120003 = 1303120001) if nm2005 == "NAGARI KATIALO"

recode id2005 (1216011003 = 1216030004) (1216011001 = 1216030002) ///
			  (1217030002 = 1217030001) (1408021007 = 1408021005) ///
			  (1408021006 = 1408021007)	(1408021005 = 1408021006) ///
			  (1409051014 = 1409051007) (1409051007 = 1409051006) ///
			  (1409051006 = 1409051005) (1409051015 = 1409051008) ///
			  (1409051016 = 1409051009) (1508041011 = 1508041004) ///
			  (1603010005 = 1603010003) (1603010003 = 1603010008) ///
			  (1603010008 = 1603010006) (1603010006 = 1603010005) ///
			  (1205061031 = 1205061010) (1205061032 = 1205061011) ///
			  (1203040097 = 1203020097) (1302080001 = 1302080003) ///
			  (1302080002 = 1302080001) (1302080003 = 1302080002) ///
			  (1302101001 = 1302100001) (1302101002 = 1302100002) ///
			  (1302101003 = 1302100003) (1302101004 = 1302100004) ///
			  (6401020002 = 6401021009) (1701042009 = 1701045008) ///
			  (1701050025 = 1701051004) (1802040009 = 1802043004) ///
			  (1802110033 = 1802112006) (3209141010 = 3209141011) ///
			  (3209141011 = 3209141012) (3209141012 = 3209141010) ///
			  (3215051005 = 3215050020) (3215081003 = 3215082003) ///
			  (3216061004 = 3216061007) (3216061005 = 3216061008) ///
			  (3216061006 = 3216061004) (3216061007 = 3216061006) ///
			  (3216061008 = 3216061005) (3216062006 = 3216062008) ///
			  (3216062007 = 3216062010) (3216062008 = 3216062009) ///
			  (3216062009 = 3216062011) (3216062010 = 3216062007) ///
			  (3216062011 = 3216062006) (3216150002 = 3216150003) ///
			  (3216150003 = 3216150004) (3216150004 = 3216150005) ///
			  (3216150005 = 3216150006) (3216150006 = 3216150002) ///
			  (1209200010 = 1209200009) (1209200009 = 1209200010) ///
			  (1213140017 = 1213140018) (1213140018 = 1213140017) ///
			  (1310040001 = 1310020001) (1310040002 = 1310020002) ///
			  (1310040003 = 1310020003) (1310020001 = 1310010001) ///
			  (1406012001 = 1406012006) (1406012002 = 1406012003) ///
			  (1406012003 = 1406012008) (1406012004 = 1406012007) ///
			  (1406012005 = 1406012004) (1406012006 = 1406012002) ///
			  (1406012007 = 1406012005) (1406012008 = 1406012001) ///
			  (3326130014 = 3326130030) (3326130030 = 3326130031) ///
			  (3601121002 = 3601121003) (3601121003 = 3601121002) ///
			  (3601121004 = 3601121005) (3601121005 = 3601121006) ///
			  (3601121006 = 3601121007) (3601121007 = 3601121008) ///
			  (3601121008 = 3601121009) (3601121009 = 3601121010) ///
			  (3601121010 = 3601121004) (3671011004 = 3671011001) ///
			  (3671011005 = 3671011003) (3671011006 = 3671011004) ///
			  (3671011007 = 3671011006) (3671011008 = 3671011005) ///
			  (3671011009 = 3671011007) (3671011010 = 3671011008) ///
			  (3671011011 = 3671011002) (5203030008 = 5203031001) ///
			  (5203031001 = 5203031006) (6201080003 = 6201062005) ///
			  (7103032002 = 7103030017) ///
			  (7103090010 = 7103090011) (7103090011 = 7103090010) ///
			  (9105040008 = 9105041001) (9105040009 = 9105041002) ///
			  (9105040015 = 9105041003) (9105040016 = 9105041004) ///
			  (9105040021 = 9105041005) (9105040030 = 9105041006) ///
			  (9105040031 = 9105041007) (9105040010 = 9105042001) ///
			  (9105040011 = 9105042002) (9105040012 = 9105042003) ///
			  (9105040013 = 9105042004) (9105040018 = 9105042005) ///
			  (9105040029 = 9105042007) (9105090005 = 9105091001) ///
			  (9105090006 = 9105091002) (9105090010 = 9105091003) ///
			  (9105090021 = 9105091004) (9105090022 = 9105091005) ///
			  (9105090023 = 9105091006) (9105090024 = 9105091007) ///
			  (9105090025 = 9105091008) (9105090026 = 9105091009) ///
			  (9105090036 = 9105091010) (9105090037 = 9105091011) ///
			  (9105090008 = 9105092001) (9105090032 = 9105092002) ///
			  (9105090030 = 9105092003) /*(9105090031 = 9105092004)*/ ///
			  (9105090011 = 9105092005) (9105090001 = 9105092008) ///
			  (9105130007 = 9105131001) (9105130009 = 9105131002) ///
			  (9105130010 = 9105131003) (9105130011 = 9105131004) ///
			  (9105130012 = 9105131005) (9105130016 = 9105131006) ///
			  (9105130018 = 9105131007) (9105130046 = 9105131008) ///
			  (9105130047 = 9105131009) (9105130048 = 9105131010) ///
			  (9105130049 = 9105131011) (9105130050 = 9105131012) ///
			  (9105130051 = 9105131013) (9105130052 = 9105131014) ///
			  (9105130053 = 9105131015) (9105130054 = 9105131016) ///
			  (9105130055 = 9105131017) (9105130056 = 9105131018) ///
			  (9105130057 = 9105131019) (9105130064 = 9105131020) ///
			  (9105130065 = 9105131021) (9105130082 = 9105131022) ///
			  (9105130014 = 9105131023) (9105130032 = 9105131024) ///
			  (9105170030 = 9105145014) (9105144011 = 9105146028) ///
			  (9105080009 = 9105190003) (9105080026 = 9105190005) ///
			  (9105080029 = 9105190006) (9105080034 = 9105190011) ///
			  (9105080035 = 9105190012) (9105080014 = 9105180004) ///
			  (9105080007 = 9105190001) (9105080030 = 9105190007) ///
			  (9105080032 = 9105190009) (9105080036 = 9105190013) ///
			  (9105130002 = 9105190014) (9105080001 = 9105200001) ///
			  (9105080002 = 9105200002) (9105080003 = 9105200003) ///
			  (9105080006 = 9105200004) (9105080011 = 9105200005) ///
			  (9105080012 = 9105200006) (9105080013 = 9105200007) ///
			  (9105080015 = 9105200008) (9105080028 = 9105200009) ///
			  (9105130070 = 9105200010) (9105130101 = 9105200011) ///
			  (9105090002 = 9105210002) (9105090003 = 9105210003) ///
			  (9105090012 = 9105210004) (9105090013 = 9105210005) ///
			  (9105090014 = 9105210006) (9105090015 = 9105210007) ///
			  (9105090018 = 9105092004) ///
			  (9105130004 = 9105220002) (9105130094 = 9105220025) ///
			  (9105130092 = 9105130210) (9105130037 = 9105145016) ///
			  (9105080008 = 9105190002) (9105080031 = 9105190008) ///
			  (9105130005 = 9105220003) (9105130058 = 9105220015) ///
			  (9105130005 = 9105220005) (9105130006 = 9105220004) ///
			  (9105130023 = 9105220008) (9105130024 = 9105220009) ///
			  (9105130040 = 9105220011) (9105130041 = 9105220012) ///
			  (9105130042 = 9105220013) (9105130044 = 9105220014) ///
			  (9105130059 = 9105220016) (9105130060 = 9105220017) ///
			  (9105130062 = 9105220019) (9105100012 = 9105220026) ///
			  (9105100017 = 9105220028) (9105130001 = 9105145015) ///
			  (9105080010 = 9105190004) (9105080022 = 9105210008) ///
			  (9105130013 = 9105220005) (9105130015 = 9105220007) ///
			  (9105130079 = 9105220023) (9105130003 = 9105220001) ///
			  (9105130075 = 9105220021) (9105130080 = 9105220024) ///
			  (9105146011 = 9105100018) (9105130061 = 9105131025) ///
			  (9105130078 = 9105220022) (9105100016 = 9105220027) ///
			  (9105080033 = 9105190010) (9105130063 = 9105220020) ///
			  (9105130039 = 9105080028) (9105130093 = 9105130220) ///
			  (9107100002 = 9107100005) (9107100003 = 9107100006) ///
			  (9107100004 = 9107100007) (9107100005 = 9107100008) ///
			  (9107100006 = 9107100009) (9107100007 = 9107100010) ///
			  (9107200002 = 9107111003) (9107200003 = 9107111007) ///
			  (9107200004 = 9107111005) (9107210008 = 9107053004)

* Drop duplicate
	* For some reason, 7304051012 and 7304051013 are duplicates
	
drop if id2005 == 7304051013

* Tidying

format %10.0f id?*

order id2005 id_podes2005 id2004_alt nm2005 nm_podes2005 nm2004_alt ///
	  prov_id region_id kec_id desa_id desa ///
	  area status type pop land_area vlg_consult vlghead* vlgsec* bpd* lpmd* ///
	  n_hh n_* share* *avail any_hh* rd_* garbage* toilet safe* police ///
	  main_income* pubphn phnstall internet TVRI natcomTV forTV locTV mblphn ///
	  mblphn_strng fight_sec outbreak* deaths* dist_*_cap topog geog forest ///
	  coastal	 
	    
drop r106 r302-r710 r801a1-r1302	 
drop prov_id region_id kec_id desa_id regstr kecstr desastr

ren desa desa_2005

foreach v of varlist area-coastal eth_code_majority-multi_ethnic {
	ren `v' `v'_2005
}

cap drop __00*

* "Type" without _2005 suffix to aid merge

gen type = type_2005

* Standardize nm2005 and nm2004_alt (remove gratuitous spaces, etc.)

qui do "$aux/standardize_nm2005"	
qui do "$aux/standardize_nm2004_alt"	

* ID for use with reclink2

gen idusing = _n

save "$work/podes2005.dta", replace

********************************************************************************
**# 2005 Nias
* 2005 Nias
	* Lacks data on number of doctors, midwives, puskesmas
	* Pop, # HH, Schls, Hosp measured before tsunami
********************************************************************************

** Identifiers **

forval i = 1/2 {
	tempfile p`i'
	import dbase "$podes_raw/PODES 2005 Nias/pds05_n`i'", clear case(lower)	
	ren r101a prov_id_2004
	ren r102a region_id_2004
	ren r103a kec_id_2004
	ren r104a desa_id_2004
	ren r101b prov_id
	ren r102b region_id
	ren r103b kec_id
	ren r104b desa_id
	save `p`i''
}

use `p1', clear
merge 1:1 prov_id region_id kec_id desa_id using `p2', update replace nogenerate

foreach v of varlist prov_id_2004-r105b r106a-r303b2 r304-r602 {
	cap destring `v', replace
}

ren namadesa desa	
replace desa = strupper(desa)
replace desa = subinstr(desa,"  "," ",.)	
replace desa = subinstr(desa,"   "," ",.)	
replace desa = subinstr(desa,"    "," ",.)

* Raw PODES code (unique)
gen double id_podes2005 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2005
isid id_podes2005
la var id_podes2005 "PODES 2005 code (raw file)"
gen nm_podes2005 = desa
la var nm_podes2005 "PODES 2005 name (raw file)"

ren r105a area_2004
	la var area_2004 "Area Type"
	la def area_2004 1 "Urban" 2 "Rural"
	la val area_2004 area_2004

ren r105b area
	la var area "Area Type"
	la def area 1 "Urban" 2 "Rural"
	la val area area
	
ren r301 type	
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other"
	la val type type
	
gen vlg_consult = r302 == 1 if !mi(r302)
	la var vlg_consult "Presence of a Village Consultative Body"	
	
ren r304 forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest

** Generating social and infrastructure variables **

gen pop  = r305b1 + r305b2
gen n_hh = r305b3

* Doctors, midwives, health facilities

gen n_dr_off = r504fk2
gen n_mwiv_off = r504gk2

gen n_hosp       = r504ak2
gen n_hosp_mat   = r504bk2
gen n_poliklinik = r504ck2
gen n_puskesmas  = r504dk2 + r504ek2
gen n_posyandu   = r504hk2
gen n_polindes   = r504ik2
gen n_pharm		 = r504kk2

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes // poskesdes did not exist yet

gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Disease outbreaks

gen outbreak_diar = r309ak2 == 1 if !mi(r309ak2)
gen outbreak_deng = r309bk2 == 1 if !mi(r309bk2)
gen outbreak_meas = r309ck2 == 1 if !mi(r309ck2)
gen outbreak_resp = r309dk2 == 1 if !mi(r309dk2)
gen outbreak_mala = r309ek2 == 1 if !mi(r309ek2)
gen outbreak_othr = r309fk2 == 1 if !mi(r309fk2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_resp ///
	"Upper respiratory tract infection outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r309ak2 == 2
replace deaths_diar = r309ak3 if r309ak2 == 1

gen deaths_deng = 0 if r309bk2 == 2
replace deaths_deng = r309bk3 if r309bk2 == 1

gen deaths_meas = 0 if r309ck2 == 2
replace deaths_meas = r309ck3 if r309ck2 == 1

gen deaths_resp = 0 if r309dk2 == 2
replace deaths_resp = r309dk3 if r309dk2 == 1

gen deaths_mala = 0 if r309ek2 == 2
replace deaths_mala = r309ek3 if r309ek2 == 1

gen deaths_othr = 0 if r309fk2 == 2
replace deaths_othr = r309fk3 if r309fk2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Schools 

gen n_schl_kind_pub  = r501a1k2
gen n_schl_prm_pub   = r501b1k2
gen n_schl_jrsec_pub = r501c1k2
gen n_schl_srsec_pub = r501d1k2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r501a2k2
gen n_schl_prm_prv   = r501b2k2
gen n_schl_jrsec_prv = r501c2k2
gen n_schl_srsec_prv = r501d2k2
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

* Roads

gen rd_asph = r310b1 == 1 if !mi(r310b1) //& inlist(r310a,1,3)
gen rd_grvl = r310b1 == 2 if !mi(r310b1) //& inlist(r310a,1,3)
gen rd_dirt = r310b1 == 3 if !mi(r310b1) //& inlist(r310a,1,3)
gen rd_othr = r310b1 == 4 if !mi(r310b1) //& inlist(r310a,1,3)

gen rd_pass = r310b2 == 1 if !mi(r310b2) //& r310b2 != 0

* Phone, internet, TV

gen n_phnstall = r507ak2	
gen phnstall = r507ak2 > 0 if !mi(r507ak2)

gen n_internet = r507bk2   
gen internet = r507bk2 > 0 if !mi(r507bk2)   

* Main source of income

local var r306
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_services = `var' == 5 if !mi(`var')
gen main_income_other	 = `var' == 6 if !mi(`var')

* Cooperatives

gen n_coop_kud 	  = r507lk2 if !inlist(r507lk2,98,99)
gen n_coop_smmanu = r507mk2 if !inlist(r507mk2,98,99) 
gen n_coop_save   = r507nk2 if !inlist(r507nk2,98,99)
gen n_coop_othr   = r507ok2 if !inlist(r507ok2,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Markets

gen mkt_perm_avail = r507dk2 > 0 == 1 if !mi(r507dk2)
gen n_mkt_temp = r507ek2 if !inlist(r507ek2,98,99)

la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_restaur = r507fk2 
gen n_foodstall = r507gk2
gen n_hotel = r507hk2 
gen n_motel = r507ik2

la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Banks

gen n_bank_com = r507jk2
la var n_bank_com "Number of commercial banks"

* Household electricity access

gen n_hh_elec_pln = 0 if r307a == 2
	replace n_hh_elec_pln = r307b1 if r307a == 1
	la var n_hh_elec_pln "# Households using PLN electricity"

gen n_hh_elec_nonpln = 0 if r307a == 2
	replace n_hh_elec_nonpln = r307b2 if r307a == 1
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"

foreach x in pln nonpln {	
	replace n_hh_elec_`x' = n_hh ///
		if !mi(n_hh,n_hh_elec_`x') & n_hh < n_hh_elec_`x'	
}	

gen n_hh_noelec = n_hh - n_hh_elec_pln - n_hh_elec_nonpln
	//replace n_hh_noelec = 0 if n_hh_noelec < 0
	replace n_hh_noelec = n_hh if r307a == 2
	la var n_hh_noelec "# Households without electricity"
	
foreach v in n_hh_elec_pln n_hh_elec_nonpln	n_hh_noelec {
	replace `v' = . if n_hh_noelec < 0
	replace `v' = . if mi(n_hh_elec_pln,n_hh_elec_nonpln)
}
assert n_hh_noelec >= 0	
	
gen any_hh_elec = r307a == 1
	
gen share_hh_elec = (n_hh_elec_pln + n_hh_elec_nonpln)/n_hh
	la var share_hh_elec "Share of households using electricity"

gen share_hh_elec_pln = n_hh_elec_pln/n_hh
	la var share_hh_elec_pln "Share of households using PLN electricity"
	
gen share_hh_elec_nonpln = n_hh_elec_nonpln/n_hh
	la var share_hh_elec_nonpln "Share of households using non-PLN electricity"

* Land use

gen land_area = r311a

** Characteristics of village officials **
	* Village head
	* Village secretary
	* Chair of BPD/Dewan Kelurahan (Village Consultative Body/Kelurahan Council)
	* Chair of LPMD/K (Village/Kelurahan Community Empowerment Institution)	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	*/
	
foreach stub in vlghead vlgsec bpdchair lpmdchair {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	else if "`stub'" == "bpdchair" {
		local row  "c"
		local name "Chair of BPD/Dewan Kelurahan"
	}
	else if "`stub'" == "lpmdchair" {
		local row  "d"
		local name "Chair of LPMD/K"
	}
	
	local x r601`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r601`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r601`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r601`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 2  if `x' == 1
		replace `stub'_educ = 6  if `x' == 2
		replace `stub'_educ = 9  if `x' == 3
		replace `stub'_educ = 12 if `x' == 4
		replace `stub'_educ = 14 if `x' == 5
		replace `stub'_educ = 16 if `x' == 6
		la var `stub'_educ "`name' years of education"
			
	gen `stub'_highschl = inrange(`x',4,6) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = `x' == 6 if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	
}

* For crosswalk

foreach v in nm2005 nm2008_1 nm2008_2 nmpodes08 {
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

gen id2005 = string(prov_id) + regstr + kecstr + desastr
destring id2005, replace

* Using BPS crosswalk to aid in merging 2003 & 2005

**
cap drop bps_* _merge
**

tempvar id
tostring id2005, gen(`id')
gen bps_2005 = substr(`id',1,4)
destring bps_2005, replace

preserve
	tempfile bpscross
	use "$work/district_cross_1990_2014", clear
	keep bps_1998 bps_1999 bps_2000 bps_2001 bps_2002 bps_2003 bps_2004 bps_2005
	bys bps_2005: keep if _n == 1
	save `bpscross'
restore

merge m:1 bps_2005 using `bpscross'
	assert _merge != 1
	drop if _merge == 2
	drop _merge

* Fixing IDs and names to improve merge

replace id2005 = 1201080037 if id2005 == 1201070037 & nm2005 == "AWAII"
replace id2005 = 1201150132 if id2005 == 1201150032 & nm2005 == "SANAWUYU"

replace nm2005 = "BAWO OMASIO" if id2005 == 1214010042 & nm2005 == "BAWO AMASIO"
replace nm2005 = "BAWO NAHONO" if id2005 == 1214020004 & nm2005 == "BAWONAHANO" 
replace nm2005 = "DOLI DOLI" if id2005 == 1214050021 & nm2005 == "DOLI-DOLI"
replace nm2005 = "DURU" if id2005 == 1214011001 & nm2005 == "DURU I/II"
replace nm2005 = "FANEDANU" if id2005 == 1214050024 & nm2005 == "FONEDANU"
replace nm2005 = "HILI AMAETALUO" ///
	if id2005 == 1214020012 & nm2005 == "HILIMAETALUO"
replace nm2005 = "LAWA LAWA LUO IDANOTAE" ///
	if id2005 == 1214050020 & nm2005 == "LAWA-LAWALUO IDANOTAE"
replace nm2005 = "PASAR TELUK DALAM" ///
	if id2005 == 1214020008 & nm2005 == "PASAR T. DALAM"	

* Remove prefixes "DESA" and "KELURAHAN"

foreach v in nm2005 nm2008_1 {
	replace `v' = subinstr(`v',"DESA ","",1) ///
		if substr(`v',1,5) == "DESA " & !inlist(id2005,1702040011,1702040049)
	replace `v' = subinstr(`v',"KELURAHAN ","",1) ///
		if substr(`v',1,10) == "KELURAHAN "
}	

* Incorrect kecamatan codes 

tostring id2005, gen(temp_id2005)

forval i = 1214010016/1214010061 {
	replace temp_id2005 = subinstr(temp_id2005,"010","020",1) if id2005 == `i'
}

forval i = 1214011001/1214011015 {
	replace temp_id2005 = subinstr(temp_id2005,"011","010",1) if id2005 == `i'
}

forval i = 1214020001/1214020039 {
	replace temp_id2005 = subinstr(temp_id2005,"020","030",1) if id2005 == `i'
}

forval i = 1214030001/1214030018 {
	replace temp_id2005 = subinstr(temp_id2005,"030","040",1) if id2005 == `i'
}

forval i = 1214040001/1214040015 {
	replace temp_id2005 = subinstr(temp_id2005,"040","050",1) if id2005 == `i'
}

forval i = 1214050001/1214050031 {
	replace temp_id2005 = subinstr(temp_id2005,"050","060",1) if id2005 == `i'
}

forval i = 1214090001/1214090018 {
	replace temp_id2005 = subinstr(temp_id2005,"090","070",1) if id2005 == `i'
}

forval i = 1214100001/1214100032 {
	replace temp_id2005 = subinstr(temp_id2005,"100","080",1) if id2005 == `i'
}

destring temp_id2005, replace

foreach i of numlist 1214010016/1214010061 1214011001/1214011015 ///
		1214020001/1214020039 1214030001/1214030018 1214040001/1214040015 ///
		1214050001/1214050031 1214090001/1214090018 1214100001/1214100032 {
	replace id2005 = temp_id2005 if id2005 == `i'
}

drop temp_id2005

* Other fixes to ID

recode id2005 (1201150005 = 1201130034)

* Tidying

format %10.0f id?*
cap drop __000*

order id2005 id_podes2005 nm2005 nm_podes2005 prov_id region_id kec_id desa_id ///
	  desa area type ///
	  pop forest vlg_consult vlghead* vlgsec* bpd* lpmd* ///
	  n_hh n_* share* *avail any_hh* rd_* phnstall internet main_inc* ///
	  outbreak* deaths* land_area nm* bps*

drop r106a-r602	 
drop prov_id region_id kec_id desa_id regstr kecstr desastr

ren desa desa_2005

foreach v of varlist area-land_area {
	ren `v' `v'_2005
}

* "Type" without _2005 suffix to aid merge

gen type = type_2005

* Standardize nm2005 (remove gratuitous spaces, etc.)

qui do "$aux/standardize_nm2005"

* ID for use with reclink2

gen idusing = _n

save "$work/podes2005nias.dta", replace

********************************************************************************
**# 2008
* 2008
********************************************************************************

** Merging raw data **

tempfile mfd
import dbase "$names/PODES 2008/mfd_podes08", clear case(lower)
save `mfd'

forval n = 1/3 {
	tempfile d`n'
	import dbase "$podes_raw/PODES 2008/pds2008_d`n'_new", clear case(lower)	
	save `d`n''
}

use `mfd'
forval n = 1/3 {
	merge 1:1 prop kab kec desa using `d`n'', nogenerate
}

foreach v of varlist prop kab kec desa kla-r14b {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren prop prov_id
ren provinsi province
ren kab region_id
ren kabupaten region
ren kec kec_id
ren kecamatan kec
ren desa desa_id
ren namadesa desa
ren kla status

* Raw PODES code (unique)
gen double id_podes2008 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2008
isid id_podes2008
la var id_podes2008 "PODES 2008 code (raw file)"
gen nm_podes2008 = desa
la var nm_podes2008 "PODES 2008 name (raw file)"

la var status "Urban/Rural Status"
la def status 1 "Urban" 2 "Rural"
la val status status

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

drop knkab knkec provkab

ren r301 type	
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other"
	la val type type

gen vlg_consult = r302 == 1 if !mi(r302)
	la var vlg_consult "Presence of a Village Consultative Body"
	
gen coastal = r304a == 1 if !mi(r304a)
	la var coastal "Village is adjacent to sea"	
	
local x r304c	
gen topog = .
	replace topog = 1 if `x' == 2
	replace topog = 2 if `x' == 1
	replace topog = 3 if `x' == 3
	la var topog "Topography"
	la def topog 1 "Slope/peak" 2 "Valley" 3 "Plain"
	la val topog topog
	drop `x'
	
assert mi(topog) if coastal == 1

gen geog = topog
	recode geog (. = 4) if coastal == 1
	la var geog "Geography"
	la def geog 1 "Slope/peak" 2 "Valley" 3 "Plain" 4 "Coast"
	la val geog geog	
	
ren r305 forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest	

** Generating social and infrastructure variables **

gen pop  = r401a + r401b
	recode pop (199996 = .)
gen n_hh = r401c if r401c < 99998

* Doctors, midwives, health facilities

gen n_dr   = r606a1 + r606a2
gen n_dent = r606b
gen n_mwiv = r606c
gen n_mwiv_all = r606c

gen n_pharm = 0
replace n_pharm = r604k_3 if r604k_2 == 1

gen n_poskesdes = 0
replace n_poskesdes = r604h_3 if r604h_2 == 1

gen n_polindes = 0
replace n_polindes = r604i_3 if r604i_2 == 1

gen n_posyandu = 0
replace n_posyandu = r604j_3 if r604j_2 == 1

gen n_polinposk = n_polindes + n_poskesdes

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_avail = n_mwiv > 0 if !mi(n_mwiv)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)

gen dr_off_avail = r604f_2 == 1 if !mi(r604f_2)
gen mwiv_off_avail = r604g_2 == 1 if !mi(r604g_2)
gen pharm_avail = r604k_2 == 1 if !mi(r604k_2)

gen hosp_avail = r604a_2 == 1 if !mi(r604a_2)
gen hosp_mat_avail = r604b_2 == 1 if !mi(r604b_2)
gen poly_avail = r604c_2 == 1 if !mi(r604c_2)
gen pusk_avail = r604d_2 == 1 | r604e_2 == 1 if !mi(r604d_2,r604e_2)
gen polin_avail = r604i_2 == 1 if !mi(r604i_2)
gen posy_avail = r604j_2 == 1 if !mi(r604j_2)
gen posk_avail = r604h_2 == 1 if !mi(r604h_2)

gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Disease outbreaks

gen outbreak_diar = r607a_2 == 1 if !mi(r607a_2)
gen outbreak_deng = r607b_2 == 1 if !mi(r607b_2)
gen outbreak_meas = r607c_2 == 1 if !mi(r607c_2)
gen outbreak_resp = r607d_2 == 1 if !mi(r607d_2)
gen outbreak_mala = r607e_2 == 1 if !mi(r607e_2)
gen outbreak_avia = r607f_2 == 1 if !mi(r607f_2)
gen outbreak_tubr = r607g_2 == 1 if !mi(r607g_2)
gen outbreak_othr = r607h_2 == 1 if !mi(r607h_2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_resp ///
	"Upper respiratory tract infection outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_tubr "Tuberculosis outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r607a_2 == 2
replace deaths_diar = r607a_4 if r607a_2 == 1

gen deaths_deng = 0 if r607b_2 == 2
replace deaths_deng = r607b_4 if r607b_2 == 1

gen deaths_meas = 0 if r607c_2 == 2
replace deaths_meas = r607c_4 if r607c_2 == 1

gen deaths_resp = 0 if r607d_2 == 2
replace deaths_resp = r607d_4 if r607d_2 == 1

gen deaths_mala = 0 if r607e_2 == 2
replace deaths_mala = r607e_4 if r607e_2 == 1

gen deaths_avia = 0 if r607f_2 == 2
replace deaths_avia = r607f_4 if r607f_2 == 1

gen deaths_tubr = 0 if r607g_2 == 2
replace deaths_tubr = r607g_4 if r607g_2 == 1

gen deaths_othr = 0 if r607h_2 == 2
replace deaths_othr = r607h_4 if r607h_2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r608
la var victims_malnutr "Number of malnutrition victims during the past 3 years"

* Proxies for number of poor people

gen n_sktm = r610
la var n_sktm "Number of poverty letters issued in the last year"

* Schools 

gen n_schl_kind_pub  = r601a_2
gen n_schl_prm_pub   = r601b_2	
gen n_schl_jrsec_pub = r601c_2
gen n_schl_srsec_pub = r601d_2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r601a_3
gen n_schl_prm_prv   = r601b_3	
gen n_schl_jrsec_prv = r601c_3
gen n_schl_srsec_prv = r601d_3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = r603b == 1 if !mi(r603b)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r603c == 1 if !mi(r603c)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x b
local type hosp_mat
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x c
local type poliklinik
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

gen dist_puskesmas = min(r604d_4,r604e_4) if !mi(r604d_4) | !mi(r604e_4)
gen easy_puskesmas = max( inlist(r604d_5,1,2), inlist(r604e_5,1,2) ) ///
	if !mi(r604d_5) | !mi(r604e_5)

local x f
local type dr_off
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x g
local type mwiv_off
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x h
local type poskesdes
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x i
local type polindes
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x k
local type pharm
gen dist_`type' = r604`x'_4
gen easy_`type' = inlist(r604`x'_5,1,2) if !mi(r604`x'_5)

local x a
local type kind
gen dist_schl_`type'_pub = r601`x'_4

local x b
local type prm
gen dist_schl_`type'_pub = r601`x'_4

local x c
local type jrsec
gen dist_schl_`type'_pub = r601`x'_4

local x d
local type srsec
gen dist_schl_`type'_pub = r601`x'_4

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)

* Roads

gen rd_asph = r901b1 == 1 if !mi(r901b1) //& r901b1 != 0
gen rd_grvl = r901b1 == 2 if !mi(r901b1) //& r901b1 != 0
gen rd_dirt = r901b1 == 3 if !mi(r901b1) //& r901b1 != 0
gen rd_othr = r901b1 == 4 if !mi(r901b1) //& r901b1 != 0

gen rd_pass = r901b2 == 1 if !mi(r901b2) //& r901b2 != 0 
	// widest road passable year round	
	
* Phone, internet, TV

gen n_hh_phn = r903 
gen pubphn   = r904 == 1 if !mi(r904)	// coin/card operated phone
gen phnstall = r905 == 1 if !mi(r905)   // telephone stall
gen internet = r906 == 1 if !mi(r906)   // internet stall/cafe
gen TVRI 	 = r909a == 1 if !mi(r909a) // TV Republik Indonesia
gen natcomTV = r909b == 3 if !mi(r909b) // national commercial TV
gen forTV 	 = r909c == 5 if !mi(r909c) // foreign TV
gen locTV 	 = r909d == 7 if !mi(r909d) // local TV
gen mblphn   = inlist(r910,1,2) if !mi(r910) // mobile phone signal/recept
gen mblphn_strng = r910 == 1 if !mi(r910)    // mobile phone strong signal

* Main source of income

local var r402
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_trans	 = `var' == 5 if !mi(`var')
	// Transportation, Warehousing, Communication Services
gen main_income_services = `var' == 6 if !mi(`var')
gen main_income_other	 = `var' == 7 if !mi(`var')
	// (Gas, Electricity, Banking, etc.)
	
* Small manufacturing establishments

gen n_estab_sm_leather 	= r1102a if !inlist(r1102a,998,999)
gen n_estab_sm_wood 	= r1102b if !inlist(r1102b,998,999)
gen n_estab_sm_metal 	= r1102c if !inlist(r1102c,998,999)
gen n_estab_sm_woven 	= r1102d if !inlist(r1102d,998,999)
gen n_estab_sm_pottery 	= r1102e if !inlist(r1102e,998,999)
gen n_estab_sm_fabric 	= r1102f if !inlist(r1102f,998,999)
gen n_estab_sm_foodbev 	= r1102g if !inlist(r1102g,998,999)
gen n_estab_sm_other 	= r1102h if !inlist(r1102h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"
	
* Cooperatives

gen n_coop_kud 	  = r1112a if !inlist(r1112a,98,99)
gen n_coop_smmanu = r1112b if !inlist(r1112b,98,99)
gen n_coop_save   = r1112c if !inlist(r1112c,98,99)
gen n_coop_othr   = r1112d if !inlist(r1112d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Agricultural production stalls

gen n_agprod_stall_kud	  = r1101a if !inlist(r1101a,98,99)
gen n_agprod_stall_nonkud = r1101b if !inlist(r1101b,98,99)
gen n_agprod_stall = n_agprod_stall_kud + n_agprod_stall_nonkud

la var n_agprod_stall_kud "Number of agricultural production stalls, KUD-owned"
la var n_agprod_stall_nonkud "Number of agricultural production stalls, non-KUD-owned"
la var n_agprod_stall "Number of agricultural production stalls"

gen agprod_stall_kud_avail = n_agprod_stall_kud > 0 if !mi(n_agprod_stall_kud)
gen agprod_stall_nonkud_avail = n_agprod_stall_nonkud > 0 ///
	if !mi(n_agprod_stall_nonkud)
gen agprod_stall_avail = n_agprod_stall > 0 if !mi(n_agprod_stall)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_nonkud_avail ///
	"Non-KUD-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Markets

gen shop_cntr_avail = r1103a == 1 if !mi(r1103a)
gen mkt_perm_avail = r1104a == 1 if !mi(r1104a)
gen n_mkt_temp = r1105 if !inlist(r1105,98,99)

la var shop_cntr_avail "Shopping center exists"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1106 if r1106 != 98
gen n_restaur = r1107 if r1107 != 98
gen n_foodstall = r1108 if r1108 != 98
gen n_cornerstore = r1109 if r1109 != 998
gen n_hotel = r1110 if r1110 != 98 
gen n_motel = r1111 if r1111 != 98 

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_cornerstore "Number of corner stores"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Microfinance

gen microfin_avail = r1113a == 1 | r1113b == 3 | r1113c == 5 | r1113d == 7
la var microfin_avail "Formal microfinance programs exist"
	
* Land use

gen land_area = r1001
	la var land_area "Land area"	
	
* Main village road has electric lighting

gen rd_light = r502a == 1 & inlist(r502b,1,2) if !mi(r502a) //& r901b1 != 0

* Main village road has lighting provided by govt./non-govt.

gen rd_light_gov = r502a == 1 & r502b == 1 if !mi(r502a) //& r901b1 != 0
gen rd_light_nongov = r502a == 1 & r502b == 2 if !mi(r502a) //& r901b1 != 0

* Household electricity access

gen n_hh_elec_pln = 0 if r501a == 2
	replace n_hh_elec_pln = r501b1 if r501a == 1
	la var n_hh_elec_pln "# Households using PLN electricity"

gen n_hh_elec_nonpln = 0 if r501a == 2
	replace n_hh_elec_nonpln = r501b2 if r501a == 1
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"

foreach x in pln nonpln {	
	replace n_hh_elec_`x' = n_hh ///
		if !mi(n_hh,n_hh_elec_`x') & n_hh < n_hh_elec_`x'	
}
	
gen n_hh_noelec = n_hh - n_hh_elec_pln - n_hh_elec_nonpln
	//replace n_hh_noelec = 0 if n_hh_noelec < 0
	assert n_hh_noelec >= 0
	replace n_hh_noelec = n_hh if r501a == 2
	la var n_hh_noelec "# Households without electricity"
	
foreach v in n_hh_elec_pln n_hh_elec_nonpln	n_hh_noelec {
	replace `v' = . if n_hh_noelec < 0
	replace `v' = . if mi(n_hh,n_hh_elec_pln,n_hh_elec_nonpln)
}
assert n_hh_noelec >= 0		
	
gen any_hh_elec = r501a == 1
	
gen share_hh_elec = (n_hh_elec_pln + n_hh_elec_nonpln)/n_hh
	la var share_hh_elec "Share of households using electricity"

gen share_hh_elec_pln = n_hh_elec_pln/n_hh
	la var share_hh_elec_pln "Share of households using PLN electricity"
	
gen share_hh_elec_nonpln = n_hh_elec_nonpln/n_hh
	la var share_hh_elec_nonpln "Share of households using non-PLN electricity"	

* Waste disposal

gen garbage_collect = r504b == 1 if !mi(r504b)
	la var garbage_collect "Gabage disposed using bins that are transported"	
	
gen toilet = inrange(r505,1,3) if !mi(r505)
	la var toilet "Most families defecate in a toilet (private, shared, public)"
	
* Safe Drinking Water
	
gen safe_drink_water = r612a == 1 if !mi(r612a) 
	la var safe_drink_water "Access to safe drinking water"	
	
* Diversity

gen multi_ethnic = r707 == 1 if !mi(r707)
	la var multi_ethnic "Multiple ethnic groups in village"	
	
ren r708 eth_code_majority
	la var eth_code_majority "Code of majority ethnicity"
	
* Fight against govt

gen fight_sec = 0
replace fight_sec = r1201bc_2 if r1201a == 1 // fights against security apparatus

gen fight_state = 0
replace fight_state = r1201bd_2 if r1201a == 1 // fights against state apparatus

* Police

local x	r1207b_2
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"
		
* Distance to district capital

local x r9022_2
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"	
	
local x r9023_2
gen dist_nearest_distr_cap = `x' if `x' < 998
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"	

** Village public finance **	
	* All data missing for kelurahan
	
* Own-source revenue	
	
local x pad	
	
ren r13011_2 rev_`x'_form
	la var rev_`x'_form "Form of own-source revenue"
	
ren r13011_3 rev_`x'	
	la var rev_`x' "Own-Source Revenue (Pendapatan Asli Desa) (IDR millions)"

//ren r13011_4 rev_`x'_use
//	la var rev_`x'_use "Utilization of own-source revenue"
	// utilization variable is continuous in data but supposed to be categorical
	
* Grant revenue from district	
	
local x kab

ren r13012a_2 rev_`x'_form
	la var rev_`x'_form "Form of grant revenue from district"
	
ren r13012a_3 rev_`x'
	la var rev_`x' "Grant revenue from district (IDR millions)"
	
* Grant revenue from province	
	
local x prov

ren r13012b_2 rev_`x'_form
	la var rev_`x'_form "Form of grant revenue from province"
	
ren r13012b_3 rev_`x'
	la var rev_`x' "Grant revenue from province (IDR millions)"	
	
* Grant revenue from central govt	
	
local x cent

ren r13012c_2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from central govt"
	
ren r13012c_3 rev_`x'
	la var rev_`x' "Grant revenue from central govt (IDR millions)"	
	
* Grant revenue from foreign country ("overseas")

local x for

ren r13012d_2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from overseas"
	
ren r13012d_3 rev_`x'
	la var rev_`x' "Grant revenue from overseas (IDR millions)"

* Grant revenue from private sources

local x priv

ren r13012e_2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from private sources"
	
ren r13012e_3 rev_`x'
	la var rev_`x' "Grant revenue from private sources (IDR millions)"	
	
* Grant revenue from other sources

local x othr

ren r13012f_2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from other sources"

ren r13012f_3 rev_`x'
	la var rev_`x' "Grant revenue from other sources (IDR millions)"

* Label values: form of revenue

foreach x in pad kab prov cent for priv othr {
	la def rev_`x'_form 1 "Money" 2 "Goods and Services" ///
						3 "Money, Goods and Services" 4 "No revenue"
	la val rev_`x'_form rev_`x'_form
}

* Replace missing value with zero when form is "no revenue"
	
foreach x in pad kab prov cent for priv othr {
	replace rev_`x' = 0 if mi(rev_`x') & rev_`x'_form == 4
}

* Total revenue

egen rev_tot = ///
	rowtotal(rev_pad rev_kab rev_prov rev_cent rev_for rev_priv rev_othr), ///
	missing
	la var rev_tot "Total Revenue (IDR millions)"

** Characteristics of village officials **
	* Village head
	* Village secretary
	* Chair of BPD/Dewan Kelurahan (Village Consultative Body/Kelurahan Council)
	* Chair of LPMD/K (Village/Kelurahan Community Empowerment Institution)	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec bpdchair lpmdchair {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	else if "`stub'" == "bpdchair" {
		local row  "c"
		local name "Chair of BPD/Dewan Kelurahan"
	}
	else if "`stub'" == "lpmdchair" {
		local row  "d"
		local name "Chair of LPMD/K"
	}
	
	local x r1401`row'_2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1401`row'_3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1401`row'_4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1401`row'_5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9	
		la var `stub'_educ "`name' years of education"
			
	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1
	replace `stub'_gradschl = .
		// codes 8 and 9 were not listed as options in PODES 2008

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}

* For crosswalk

foreach v in nm2008_1 nm2008_2 nmpodes08 {
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

foreach v in id2008_1 id2008_2 idpodes08 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

* Tidying

format %10.0f id?*

order id* nm* prov_id province region_id region kec_id kec desa_id desa ///
	  status type rev* pop land_area vlg_consult ///
	  vlghead* vlgsec* bpd* lpmd* ///
	  n_* share* any_hh* *_avail dist_* easy_* rd_* garbage* toilet safe* ///
	  police multi_ethnic eth* main_income* pubphn phnstall internet ///
	  TVRI locTV natcomTV forTV mblphn mblphn_strng fight_sec ///
	  fight_state outbreak* deaths* vic* dist_*_cap topog geog forest coastal 
	  
drop r302-r14b	  

foreach v of varlist rev* {
	ren `v' `v'_2007
}

drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	cap ren `v' `v'_2008
}

foreach v of varlist status type pop-coastal {
	ren `v' `v'_2008
}

* Improve merge to PODES 2011

recode id2008_1 (1115020005 = 1115020021) if nm2008_1 == "UJONG PADANG"

recode id2008_1 (7208050008 = 7208050007) (7208050009 = 7208050008) ///
				(7208050010 = 7208050009) (7208050011 = 7208050010) ///
				(7208050012 = 7208050011) ///
				(7201040024 = 7201042002) (7205053003 = 7205050010) ///
				(9426022008 = 9426020008)
				
replace nm2008_1 = "MODONG" if id2008_1 == 1603092009
replace nm2008_1 = "SUKA CINTA" if id2008_1 == 1603092011
replace nm2008_1 = "PENANDINGAN" if id2008_1 == 1603092012
replace nm2008_1 = "DANAU RATA" if id2008_1 == 1603092013
replace nm2008_1 = "SUKA MAJU" if id2008_1 == 1603092014
replace nm2008_1 = "MODONG" if id2008_1 == 1603092017
replace nm2008_1 = "KWOKWISNGUNG/KWOK II" if id2008_1 == 9105220029

* Standardize nm2008_1 (remove gratuitous spaces, etc.)

qui do "$aux/standardize_nm2008_1"

* Remove prefixes "DESA" and "KELURAHAN"

foreach i of numlist 1971030017 5303140017 {
	foreach v in nm2008_1 {
		replace `v' = subinstr(`v',"DESA ","",1) ///
			if substr(`v',1,5) == "DESA " & id2008_1 == `i'
		replace `v' = subinstr(`v',"KELURAHAN ","",1) ///
			if substr(`v',1,10) == "KELURAHAN " & id2008_1 == `i'
	}
}

* ID for use with reclink2

gen idusing = _n

save "$work/podes2008.dta", replace

********************************************************************************
**# 2011 INFR
* 2011 INFR
********************************************************************************

* Optional: World Bank PODES 2011 infrastructure files (not part of
	* the BPS purchase). Skipped if the folder is absent; they add
	* facility counts only, no codes or names.
local infr_dir "$podes_raw/PODES 2011 INFR"
cap confirm file "`infr_dir'/Podes11-Listing Faskesdik 1.dta"
local has_infr = !_rc
if `has_infr' {

tempfile polin posy pusk sek

use "`infr_dir'/Podes11-PoskesdesPolindes", clear

bys r101 r102 r103 r104: egen n_mwiv_polin = total(r302a)
bys r101 r102 r103 r104: keep if _n == 1
keep r101 r102 r103 r104 n_*

save `polin'

use "`infr_dir'/Podes11-PuskesmasPustu", clear

bys r101 r102 r103 r104: egen n_dr_pusk = total(r302al + r302ap)
bys r101 r102 r103 r104: egen n_dent_pusk = total(r302bl + r302bp)
bys r101 r102 r103 r104: egen n_mwiv_pusk = total(r302cl + r302cp)
bys r101 r102 r103 r104: keep if _n == 1
keep r101 r102 r103 r104 n_*

save `pusk'

use "`infr_dir'/Podes11-Listing Faskesdik 1", clear

gen n_puskesmas  = r205 + r206
gen n_polindes   = r208
gen n_poskesdes  = r207
gen n_posyandu   = r209

gen n_polinposk = n_polindes + n_poskesdes

gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)

gen n_schl_prm_pub   = r201
gen n_schl_jrsec_pub = r202
gen n_schl_srsec_pub = r203
gen n_schl_voc_pub   = r204
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

foreach x in prm_pub jrsec_pub srsec_pub sec_pub /*pub*/ { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

merge 1:1 r101 r102 r103 r104 using `polin', nogenerate
merge 1:1 r101 r102 r103 r104 using `pusk', nogenerate

ren r101 prov_id
ren r102 region_id
ren r103 kec_id
ren r104 desa_id
ren r105 status
	la var status "Urban/Rural Status"
	la def status 1 "Urban" 2 "Rural"
	la val status status

foreach v in n_mwiv_polin n_dr_pusk n_mwiv_pusk {
	replace `v' = 0 if mi(`v')
} 

* For crosswalk

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2011_1 id2011_2 id_podes11 id_ppls11 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

* Tidying

drop r??? 

format %10.0f id?*

order id* prov_id region_id kec_id desa_id status *_avail n_* 

foreach v of varlist status-n_mwiv_pusk {
	ren `v' `v'_2011
}

tempfile podes2011infr
save `podes2011infr'

}

********************************************************************************
**# 2011 Jorong
* 2011 - Jorong (Sumatera Barat)
********************************************************************************

local x jorong

tempfile mfd_`x'
import dbase "$names/PODES 2011/mfd_podes_`x'2011", clear case(lower)
save `mfd_`x''

forval n = 1/2 {
	tempfile `x'_d`n'
	import dbase "$podes_raw/PODES 2011/podes_`x'_2011_d`n'", ///
		clear case(lower)
	save ``x'_d`n''
}

use `mfd_`x''
forval n = 1/2 {
	merge 1:1 kode_prov kode_kab kode_kec kode_desa kode_joron using ``x'_d`n'', ///
		nogenerate
}

foreach v of varlist kode_* r301a-r1201bk5 {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren kode_prov 	prov_id
ren kode_kab  	region_id
ren kode_kec  	kec_id
ren kode_desa 	desa_id
ren kode_joron 	joron_id
ren nama_prov 	province
ren nama_kab  	region
ren nama_kec  	kec
ren nama_desa 	desa
ren nama_joron	joron

* Raw PODES code (unique)
gen double id_podes2011 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2011
la var id_podes2011 "PODES 2011 code (raw file)"
gen nm_podes2011 = desa
la var nm_podes2011 "PODES 2011 name (raw file)"

foreach v in province region kec desa joron {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

** Generating social and infrastructure variables **

gen pop  = r301a + r301b
gen n_hh = r301c

* Doctors, midwives, health facilities

gen n_dr = r602a1 + r602a2
gen n_dent = r602b
gen n_mwiv = r602c
gen n_mwiv_all = r602c

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_avail = n_mwiv > 0 if !mi(n_mwiv)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)

gen n_posyandu = r601a
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)

* Disease outbreaks

gen outbreak_diar = r603ak2 == 1 if !mi(r603ak2)
gen outbreak_deng = r603bk2 == 1 if !mi(r603bk2)
gen outbreak_meas = r603ck2 == 1 if !mi(r603ck2)
gen outbreak_resp = r603dk2 == 1 if !mi(r603dk2)
gen outbreak_mala = r603ek2 == 1 if !mi(r603ek2)
gen outbreak_avia = r603fk2 == 1 if !mi(r603fk2)
gen outbreak_tubr = r603gk2 == 1 if !mi(r603gk2)
gen outbreak_othr = r603hk2 == 1 if !mi(r603hk2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_resp ///
	"Upper respiratory tract infection outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_tubr "Tuberculosis outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r603ak2 == 2
replace deaths_diar = r603ak4 if r603ak2 == 1

gen deaths_deng = 0 if r603bk2 == 2
replace deaths_deng = r603bk4 if r603bk2 == 1

gen deaths_meas = 0 if r603ck2 == 2
replace deaths_meas = r603ck4 if r603ck2 == 1

gen deaths_resp = 0 if r603dk2 == 2
replace deaths_resp = r603dk4 if r603dk2 == 1

gen deaths_mala = 0 if r603ek2 == 2
replace deaths_mala = r603ek4 if r603ek2 == 1

gen deaths_avia = 0 if r603fk2 == 2
replace deaths_avia = r603fk4 if r603fk2 == 1

gen deaths_tubr = 0 if r603gk2 == 2
replace deaths_tubr = r603gk4 if r603gk2 == 1

gen deaths_othr = 0 if r603hk2 == 2
replace deaths_othr = r603hk4 if r603hk2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r604
la var victims_malnutr "Number of malnutrition victims during the past 3 years"

* Toddler and mother deaths

gen deaths_toddler = r605b
gen deaths_mother = r605c

la var deaths_toddler "Toddler deaths (under 5 years old)"
la var deaths_mother ///
	"Mother deaths during pregnancy, childbirth or postpartum (40 days after childbirth)"

* Roads

local var r801b
gen rd_hwy_asph = `var' == 1 if !mi(`var')
gen rd_hwy_grvl = `var' == 2 if !mi(`var')
gen rd_hwy_dirt = `var' == 3 if !mi(`var')
gen rd_hwy_othr = `var' == 4 if !mi(`var')
	/*
	Surface type of road to highway to nearest subdistrict office
	*/

gen rd_hwy_pass = r801c == 1 if !mi(r801c)
	/*
	All-weather road to highway to nearest subdistrict office
	*/

gen rd_hwy_qual = r801d
recode rd_hwy_qual (1 = 4) (2 = 3) (3 = 2) (4 = 1) 
	// higher numbers better
	// then aggregation using max makes sense
	la var rd_hwy_qual "Quality of main road"
	la def rd_hwy_qual 4 "No damage" 3 "Small part of road is damaged" ///
				   2 "Most of road is damaged" 1 "Entire road is damaged"
	la val rd_hwy_qual rd_hwy_qual
	
* Bridges

gen bridge_avail = r802a == 1 if !mi(r802a)

gen n_bridge = r802b
replace n_bridge = 0 if !bridge_avail

* Phone, internet, TV

gen n_hh_phn = 0
replace n_hh_phn = r803b if r803a == 1

* Cooperatives

gen n_coop_kud 	  = r1008a if !inlist(r1008a,98,99)
gen n_coop_smmanu = r1008b if !inlist(r1008b,98,99)
gen n_coop_save   = r1008c if !inlist(r1008c,98,99)
gen n_coop_othr   = r1008d if !inlist(r1008d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Markets

gen n_mkt_temp = r1001 if !inlist(r1001,98,99)
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1002
gen n_restaur = r1005
gen n_foodstall = r1004 if r1004 != 98
gen n_cornerstore = r1003 if r1003 != 998
gen n_hotel = r1006
gen n_motel = r1007

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_cornerstore "Number of corner stores"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Household electricity access

ren r401a n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r401b n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	

foreach x in pln nonpln {	
	replace n_hh_elec_`x' = n_hh ///
		if !mi(n_hh,n_hh_elec_`x') & n_hh < n_hh_elec_`x'	
}
	
gen n_hh_noelec = n_hh - n_hh_elec_pln - n_hh_elec_nonpln
	//replace n_hh_noelec = 0 if n_hh_noelec < 0
	la var n_hh_noelec "# Households without electricity"
	
foreach v in n_hh_elec_pln n_hh_elec_nonpln	n_hh_noelec {
	replace `v' = . if n_hh_noelec < 0
	replace `v' = . if mi(n_hh,n_hh_elec_pln,n_hh_elec_nonpln)
}
assert n_hh_noelec >= 0		
	
gen any_hh_elec = 0
	replace any_hh_elec = 1 if n_hh_elec_pln > 0 & !mi(n_hh_elec_pln)
	replace any_hh_elec = 1 if n_hh_elec_nonpln > 0 & !mi(n_hh_elec_nonpln)
	
gen share_hh_elec = (n_hh_elec_pln + n_hh_elec_nonpln)/n_hh
	la var share_hh_elec "Share of households using electricity"

gen share_hh_elec_pln = n_hh_elec_pln/n_hh
	la var share_hh_elec_pln "Share of households using PLN electricity"
	
gen share_hh_elec_nonpln = n_hh_elec_nonpln/n_hh
	la var share_hh_elec_nonpln "Share of households using non-PLN electricity"	

* Fuel used for cooking 

local v r402
gen cookfuel_gas  = `v' == 1 if !mi(`v')
gen cookfuel_LPG  = `v' == 2 if !mi(`v')
gen cookfuel_kero = `v' == 3 if !mi(`v')
gen cookfuel_wood = `v' == 4 if !mi(`v')
gen cookfuel_othr = `v' == 5 if !mi(`v')

la var cookfuel_gas  "Most families cook with city gas"
la var cookfuel_LPG  "Most families cook with LPG"
la var cookfuel_kero "Most families cook with kerosene"
la var cookfuel_wood "Most families cook with firewood"
la var cookfuel_othr "Most families cook with other fuel (coal, charcoal, etc.)"
	
* Fight against govt

gen fight_sec = 0
replace fight_sec = r1101bck2 if r1101a == 1 

gen fight_state = 0
replace fight_state = r1101bdk2 if r1101a == 1	

* Aggregate up to desa/nagari level

local codes prov_id region_id kec_id desa_id

sort `codes' joron_id

foreach v of varlist pop n_* deaths* {
	by `codes': egen temp = total(`v'), missing
	replace `v' = temp
	drop temp
}

foreach v of varlist *_avail any_* fight_* rd_* outbreak* vic* cook* {
	by `codes': egen temp = max(`v')
	replace `v' = temp
	drop temp
}

by `codes': keep if _n == 1

drop joron_id joron

* Tidying

order prov_id province region_id region kec_id kec desa_id id_podes2011 desa pop ///
	  n_hh n_* rd_* share* *avail any_hh* fight* outbreak* deaths* vic* cook*
	  
drop r107-r1201bk5

tempfile joron2011
save `joron2011'

********************************************************************************
**# 2011 Nagari
* 2011 - Nagari (Sumatera Barat)
********************************************************************************

local x nagari

tempfile mfd_`x'
import dbase "$names/PODES 2011/mfd_podes_`x'2011", clear case(lower)
save `mfd_`x''

forval n = 1/2 {
	tempfile `x'_d`n'
	import dbase "$podes_raw/PODES 2011/podes_`x'_2011_d`n'", ///
		clear case(lower)
	save ``x'_d`n''
}

use `mfd_`x''
forval n = 1/2 {
	merge 1:1 kode_prov kode_kab kode_kec kode_desa using ``x'_d`n'', ///
		nogenerate
}

foreach v of varlist kode_* r106-r1203bk5 {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren kode_prov 	prov_id
ren kode_kab  	region_id
ren kode_kec  	kec_id
ren kode_desa 	desa_id
ren nama_prov 	province
ren nama_kab  	region
ren nama_kec  	kec
ren nama_desa 	desa

* Raw PODES code (unique)
gen double id_podes2011 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2011
isid id_podes2011
la var id_podes2011 "PODES 2011 code (raw file)"
gen nm_podes2011 = desa
la var nm_podes2011 "PODES 2011 name (raw file)"

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

gen type = 3
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other"
	la val type type

local x r304a	
gen topog = .
	replace topog = 1 if inrange(`x',1,2)
	replace topog = 2 if `x' == 3
	replace topog = 3 if `x' == 4
	la var topog "Topography"
	la def topog 1 "Slope/peak" 2 "Valley" 3 "Plain"
	la val topog topog
	drop `x'	
	
ren r304b slope
	la var slope "Slope"
	la def slope 1 "Low (less than 15 degrees)" ///
				 2 "Medium (15 to 25 degrees)" ///
				 3 "Steep (more than 25 degrees)"
	la val slope slope

gen coastal = r304d == 1 if !mi(r304d)
	la var coastal "Village is adjacent to sea"	

ren r305a forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest
	
** Generating social and infrastructure variables **

gen n_dr_off = 0
replace n_dr_off = r604fk3 if r604fk2 == 1

gen n_mwiv_off = 0
replace n_mwiv_off = r604gk3 if r604gk2 == 1

gen n_hosp = 0
replace n_hosp = r604ak3 if r604ak2 == 1

gen n_hosp_mat = 0
replace n_hosp_mat = r604bk3 if r604bk2 == 1

gen n_puskesmas = 0
replace n_puskesmas = r604dk3 if r604dk2 == 1
replace n_puskesmas = n_puskesmas + r604ek3 if r604ek2 == 1

gen n_poliklinik = 0
replace n_poliklinik = r604ck3 if r604ck2 == 1

gen n_poskesdes = 0
replace n_poskesdes = r604hk3 if r604hk2 == 1

gen n_polindes = 0
replace n_polindes = r604ik3 if r604ik2 == 1

gen n_pharm = 0
replace n_pharm = r604kk3 if r604kk2 == 1

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen posy_avail = r604jk2 == 1
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Schools 

gen n_schl_kind_pub  = r601ak2 
gen n_schl_prm_pub   = r601bk2	
gen n_schl_jrsec_pub = r601ck2
gen n_schl_srsec_pub = r601dk2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r601ak3 
gen n_schl_prm_prv   = r601bk3	
gen n_schl_jrsec_prv = r601ck3
gen n_schl_srsec_prv = r601dk3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = r603c == 5 if !mi(r603c)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r603e == 1 if !mi(r603e)
la var lib_avail "Library in village"

* Roads

gen rd_asph = r901b1 == 1 if !mi(r901b1) //& r901b1 != 0
gen rd_grvl = r901b1 == 2 if !mi(r901b1) //& r901b1 != 0
gen rd_dirt = r901b1 == 3 if !mi(r901b1) //& r901b1 != 0
gen rd_othr = r901b1 == 4 if !mi(r901b1) //& r901b1 != 0

gen rd_pass = r901b2 == 1 if !mi(r901b2) //& r901b2 != 0

* Phone, internet, TV

gen pubphn   = r903 == 1 if !mi(r903) 
gen phnstall = r905 == 1 if !mi(r905)
gen internet = r906 == 1 if !mi(r906)

gen TVRI 	 = r909c == 5 if !mi(r909c) 
gen locTV 	 = r909a == 1 if !mi(r909a) 
gen natcomTV = r909b == 3 if !mi(r909b) 
gen forTV 	 = r909d == 7 if !mi(r909d) 

gen mblphn   = inlist(r904b,1,2) if !mi(r904b) 
gen mblphn_strng = r904b == 2 if !mi(r904b)

* Main source of income

local var r401a
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_trans	 = `var' == 5 if !mi(`var')
gen main_income_services = `var' == 6 if !mi(`var')
gen main_income_other	 = `var' == 7 if !mi(`var')

* Small manufacturing establishments

gen n_estab_sm_leather 	= r1002a if !inlist(r1002a,998,999)
gen n_estab_sm_wood 	= r1002b if !inlist(r1002b,998,999)
gen n_estab_sm_metal 	= r1002c if !inlist(r1002c,998,999)
gen n_estab_sm_woven 	= r1002d if !inlist(r1002d,998,999)
gen n_estab_sm_pottery 	= r1002e if !inlist(r1002e,998,999)
gen n_estab_sm_fabric 	= r1002f if !inlist(r1002f,998,999)
gen n_estab_sm_foodbev 	= r1002g if !inlist(r1002g,998,999)
gen n_estab_sm_other 	= r1002h if !inlist(r1002h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"

* Agricultural production stalls

gen agprod_stall_kud_avail 	  = r1001a == 1 if !mi(r1001a)
gen agprod_stall_nonkud_avail = r1001b == 3 if !mi(r1001b)
gen agprod_stall_avail = agprod_stall_kud_avail | agprod_stall_nonkud_avail ///
	if !mi(agprod_stall_kud_avail,agprod_stall_nonkud_avail)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_nonkud_avail ///
	"Non-KUD-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Markets

gen shop_cntr_avail = r1003a == 1 if !mi(r1003a)
gen kero_station_avail = r1004a == 1 if !mi(r1004a)
gen LPG_station_avail  = r1004b == 3 if !mi(r1004b)
gen mkt_perm_avail = r1005a == 1 if !mi(r1005a)

la var shop_cntr_avail "Shopping center exists"
la var kero_station_avail "Kerosene station/agent exists"
la var LPG_station_avail ///
	"LPG station/agent/seller exists (incl. stall, shops, supermarkets...)"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"

* Banks

gen n_bank_com = 0
replace n_bank_com = r1007ak3 if r1007ak2 == 1

gen n_bank_rur = 0
replace n_bank_rur = r1007bk3 if r1007bk2 == 1

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r1106a == 1 | r1106b == 3 | r1106c == 5 | r1106d == 7 | ///
					 r1106e == 1
la var microfin_avail "Formal microfinance programs exist"

* Main village road has electric lighting

gen rd_light = r501a == 1 & inlist(r501b,1,2) if !mi(r501a) //& r901b1 != 0

* Main village road has lighting provided by govt./non-govt.

gen rd_light_gov = r501a == 1 & r501b == 1 if !mi(r501a) //& r901b1 != 0
gen rd_light_nongov = r501a == 1 & r501b == 2 if !mi(r501a) //& r901b1 != 0

* Safe water

gen safe_drink_water = inrange(r608a,1,2) if !mi(r608a) 
	la var safe_drink_water "Access to safe drinking water"

* Distance to district capital

local x r902bk2
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"	
	
local x r902ck2
gen dist_nearest_distr_cap = `x' ///
	if `x' < 998 & !inlist(`x',98,98.8,98.9,99) & !inrange(`x',99.79,99.91)
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"

* For crosswalk

gen nm2011_1 = desa

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2011_1 id2011_2 id_podes11 id_ppls11 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

** Merge with jorong dataset **

merge 1:1 prov_id region_id kec_id desa_id using `joron2011'
	assert _merge == 3
	drop _merge
	
* Tidying

format %10.0f id?*

order id* nm2011* prov_id province region_id region kec_id kec ///
	  desa_id desa type /*year*/ pop topog slope coastal forest ///
	  n_* *avail any* rd_* share* safe* fight* outbreak* deaths* vic* ///
	  pubphn phnstall internet TVRI locTV natcomTV forTV ///
	  mblphn mblphn_strng main_inc* dist_*_cap cook*
	  
drop r106-r1203bk5	

foreach v of varlist type-cookfuel_othr {
	ren `v' `v'_2011
}

tempfile nagari2011
save `nagari2011'

********************************************************************************
**# 2011
* 2011 
********************************************************************************

** Merging raw data **

local x desa

tempfile mfd_`x'
import dbase "$names/PODES 2011/mfd_podes_`x'2011", clear case(lower)
save `mfd_`x''
	
forval n = 1/3 {
	tempfile desa_d`n'
	import dbase "$podes_raw/PODES 2011/podes_desa_2011_d`n'", ///
		clear case(lower)
	save `desa_d`n''
}

use `mfd_desa'
forval n = 1/3 {
	merge 1:1 kode_prov kode_kab kode_kec kode_desa using `desa_d`n'', ///
		nogenerate
}

foreach v of varlist kode_* r301 r302a r302b r303a r304a-r1501bk5 {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren kode_prov prov_id
ren kode_kab  region_id
ren kode_kec  kec_id
ren kode_desa desa_id
ren nama_prov province
ren nama_kab  region
ren nama_kec  kec
ren nama_desa desa

* Raw PODES code (unique)
gen double id_podes2011 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2011
isid id_podes2011
la var id_podes2011 "PODES 2011 code (raw file)"
gen nm_podes2011 = desa
la var nm_podes2011 "PODES 2011 name (raw file)"

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

ren nama_pulau isl_name
	la var isl_name "Name of island where village is located"

ren r301 type	
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other"
	la val type type

gen vlg_consult = r303a == 1 if !mi(r303a)
	la var vlg_consult "Presence of a Village Consultative Body"
	
local x r305a	
gen topog = .
	replace topog = 1 if inrange(`x',1,2)
	replace topog = 2 if `x' == 3
	replace topog = 3 if `x' == 4
	la var topog "Topography"
	la def topog 1 "Slope/peak" 2 "Valley" 3 "Plain"
	la val topog topog
	drop `x'	
	
ren r305b slope
	la var slope "Slope"
	la def slope 1 "Low (less than 15 degrees)" ///
				 2 "Medium (15 to 25 degrees)" ///
				 3 "Steep (more than 25 degrees)"
	la val slope slope

gen coastal = r305d == 1 if !mi(r305d)
	la var coastal "Village is adjacent to sea"	
	
	// Fix values for landlocked villages
	replace coastal = 0 ///
		if (prov_id == 94 & region_id == 29) | ///
		   (prov_id == 14 & region_id ==  1) 
		//& kec_id == 80 & desa_id == 1

ren r306a forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest
	
** Generating social and infrastructure variables **

gen pop  = r401a + r401b
gen n_hh = r401c 

* Doctors, midwives, health facilities

gen n_dr = r707a1 + r707a2
gen n_dent = r707b
gen n_mwiv = r707c
gen n_mwiv_all = r707c

gen n_hosp = 0
replace n_hosp = r704ak3 if r704ak2 == 1

gen n_hosp_mat = 0
replace n_hosp_mat = r704bk3 if r704bk2 == 1

gen n_poliklinik = 0
replace n_poliklinik = r704ck3 if r704ck2 == 1

gen n_puskesmas = 0
replace n_puskesmas = r704dk3 if r704dk2 == 1
replace n_puskesmas = n_puskesmas + r704ek3 if r704ek2 == 1

gen n_dr_off = 0
replace n_dr_off = r704fk3 if r704fk2 == 1

gen n_mwiv_off = 0
replace n_mwiv_off = r704gk3 if r704gk2 == 1

gen n_poskesdes = 0
replace n_poskesdes = r704hk3 if r704hk2 == 1

gen n_polindes = 0
replace n_polindes = r704ik3 if r704ik2 == 1

gen n_posyandu = 0
replace n_posyandu = r704jk3 if r704jk2 == 1

gen n_pharm = 0
replace n_pharm = r704kk3 if r704kk2 == 1

gen n_heal_cntr = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_avail = n_mwiv > 0 if !mi(n_mwiv)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)
gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Disease outbreaks

gen outbreak_diar = r708ak2 == 1 if !mi(r708ak2)
gen outbreak_deng = r708bk2 == 1 if !mi(r708bk2)
gen outbreak_meas = r708ck2 == 1 if !mi(r708ck2)
gen outbreak_resp = r708dk2 == 1 if !mi(r708dk2)
gen outbreak_mala = r708ek2 == 1 if !mi(r708ek2)
gen outbreak_avia = r708fk2 == 1 if !mi(r708fk2)
gen outbreak_tubr = r708gk2 == 1 if !mi(r708gk2)
gen outbreak_othr = r708hk2 == 1 if !mi(r708hk2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_resp ///
	"Upper respiratory tract infection outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_tubr "Tuberculosis outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r708ak2 == 2
replace deaths_diar = r708ak4 if r708ak2 == 1

gen deaths_deng = 0 if r708bk2 == 2
replace deaths_deng = r708bk4 if r708bk2 == 1

gen deaths_meas = 0 if r708ck2 == 2
replace deaths_meas = r708ck4 if r708ck2 == 1

gen deaths_resp = 0 if r708dk2 == 2
replace deaths_resp = r708dk4 if r708dk2 == 1

gen deaths_mala = 0 if r708ek2 == 2
replace deaths_mala = r708ek4 if r708ek2 == 1

gen deaths_avia = 0 if r708fk2 == 2
replace deaths_avia = r708fk4 if r708fk2 == 1

gen deaths_tubr = 0 if r708gk2 == 2
replace deaths_tubr = r708gk4 if r708gk2 == 1

gen deaths_othr = 0 if r708hk2 == 2
replace deaths_othr = r708hk4 if r708hk2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r709
la var victims_malnutr "Number of malnutrition victims during the past 3 years"

* Toddler and mother deaths

gen deaths_toddler = r710b
gen deaths_mother = r710c

la var deaths_toddler "Toddler deaths (under 5 years old)"
la var deaths_mother ///
	"Mother deaths during pregnancy, childbirth or postpartum (40 days after childbirth)"

* Proxies for number of poor people

gen n_jamkesmas = r711
gen n_sktm = r712 

la var n_jamkesmas ///
	"Number of residents receiving JAMKESMAS/JAMKESDA cards in 2010"
la var n_sktm "Number of poverty letters/SKTM issued by village in 2010"
	
* Schools 

gen n_schl_kind_pub  = r701ak2 
gen n_schl_prm_pub   = r701bk2	
gen n_schl_jrsec_pub = r701ck2
gen n_schl_srsec_pub = r701dk2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r701ak3 
gen n_schl_prm_prv   = r701bk3	
gen n_schl_jrsec_prv = r701ck3
gen n_schl_srsec_prv = r701dk3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = r703c == 5 if !mi(r703c)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r703e == 1 if !mi(r703e)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x b
local type hosp_mat
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x c
local type poliklinik
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

gen dist_puskesmas = min(r704dk4,r704ek4) if !mi(r704dk4) | !mi(r704ek4)
gen easy_puskesmas = max( inlist(r704dk5,1,2), inlist(r704ek5,1,2) ) ///
	if !mi(r704dk5) | !mi(r704ek5)

local x f
local type dr_off
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x g
local type mwiv_off
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x h
local type poskesdes
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x i
local type polindes
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x k
local type pharm
gen dist_`type' = r704`x'k4
gen easy_`type' = inlist(r704`x'k5,1,2) if !mi(r704`x'k5)

local x a
local type kind
gen dist_schl_`type'_pub = r701`x'k4

local x b
local type prm
gen dist_schl_`type'_pub = r701`x'k4

local x c
local type jrsec
gen dist_schl_`type'_pub = r701`x'k4

local x d
local type srsec
gen dist_schl_`type'_pub = r701`x'k4

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)

* Roads

local var r1001b1
gen rd_asph = `var' == 1 if !mi(`var')
gen rd_grvl = `var' == 2 if !mi(`var')
gen rd_dirt = `var' == 3 if !mi(`var')
gen rd_othr = `var' == 4 if !mi(`var')

gen rd_pass = r1001b2 == 1 if !mi(r1001b2) //& r1001b2 != 0

local var r1002b
gen rd_hwy_asph = `var' == 1 if !mi(`var')
gen rd_hwy_grvl = `var' == 2 if !mi(`var')
gen rd_hwy_dirt = `var' == 3 if !mi(`var')
gen rd_hwy_othr = `var' == 4 if !mi(`var')
	/*
	Surface type of road to highway to nearest subdistrict office
	*/

gen rd_hwy_pass = r1002c == 1 if !mi(r1002c)
	/*
	All-weather road to highway to nearest subdistrict office
	*/

gen rd_hwy_qual = r1002d
recode rd_hwy_qual (1 = 4) (2 = 3) (3 = 2) (4 = 1) 
	// higher numbers better
	// then aggregation using max makes sense
	la var rd_hwy_qual "Quality of main road"
	la def rd_hwy_qual 4 "No damage" 3 "Small part of road is damaged" ///
				   2 "Most of road is damaged" 1 "Entire road is damaged"
	la val rd_hwy_qual rd_hwy_qual
	
* Bridges

gen bridge_avail = r1003a == 1 if !mi(r1003a)

gen n_bridge = r1003b
replace n_bridge = 0 if !bridge_avail	

* Phone, internet, TV

gen n_hh_phn = 0
replace n_hh_phn = r1005b if r1005a == 1

gen pubphn   = r1006 == 1 if !mi(r1006) 
gen phnstall = r1008 == 1 if !mi(r1008)
gen internet = r1009 == 1 if !mi(r1009)

gen TVRI 	 = r1012c == 5 if !mi(r1012c) 
gen locTV 	 = r1012a == 1 if !mi(r1012a) 
gen natcomTV = r1012b == 3 if !mi(r1012b) 
gen forTV 	 = r1012d == 7 if !mi(r1012d) 

gen mblphn   = inlist(r1007b,1,2) if !mi(r1007b) 
gen mblphn_strng = r1007b == 2 if !mi(r1007b) 

la var n_hh_phn "# Households with Landline Phone"
la var pubphn "Public Payphone in Village"
la var phnstall "Phone Stall in Village"
la var internet "Internet Cafe in Village"
la var TVRI "TVRI Channel Received in Village"
la var locTV "Local TV Channels Received in Village"
la var natcomTV "National Private TV Channels Received in Village"
la var forTV "Foreign TV Channels Received in Village"
la var mblphn "Cellular Phone Signal in Village"
la var mblphn_strng "Strong Cellular Phone Signal in Village"

* Main source of income

local var r403a
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_trans	 = `var' == 5 if !mi(`var')
gen main_income_services = `var' == 6 if !mi(`var')
gen main_income_other	 = `var' == 7 if !mi(`var')

la var main_income_agri ///
	"Main Source of Income for Majority of Pop: Agriculture"
la var main_income_mining ///
	"Main Source of Income for Majority of Pop: Mining and Excavation"
la var main_income_industr ///
	"Main Source of Income for Majority of Pop: Manufacturing industry (factories, crafts, etc.)"
la var main_income_whretail ///
	"Main Source of Income for Majority of Pop: Wholesale/retail trade and restaurants"
la var main_income_trans ///
	"Main Source of Income for Majority of Pop: Transportation, warehousing, communication"
la var main_income_services ///
	"Main Source of Income for Majority of Pop: Services"
la var main_income_other ///
	"Main Source of Income for Majority of Pop: Other (water, gas, electricity, construction, banking, etc)"
		
* Small manufacturing establishments

gen n_estab_sm_leather 	= r1202a if !inlist(r1202a,998,999)
gen n_estab_sm_wood 	= r1202b if !inlist(r1202b,998,999)
gen n_estab_sm_metal 	= r1202c if !inlist(r1202c,998,999)
gen n_estab_sm_woven 	= r1202d if !inlist(r1202d,998,999)
gen n_estab_sm_pottery 	= r1202e if !inlist(r1202e,998,999)
gen n_estab_sm_fabric 	= r1202f if !inlist(r1202f,998,999)
gen n_estab_sm_foodbev 	= r1202g if !inlist(r1202g,998,999)
gen n_estab_sm_other 	= r1202h if !inlist(r1202h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"
	
* Cooperatives

gen n_coop_kud 	  = r1213a if !inlist(r1213a,98,99)
gen n_coop_smmanu = r1213b if !inlist(r1213b,98,99)
gen n_coop_save   = r1213c if !inlist(r1213c,98,99)
gen n_coop_othr   = r1213d if !inlist(r1213d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"	

* Agricultural production stalls

gen agprod_stall_kud_avail 	  = r1201a == 1 if !mi(r1201a)
gen agprod_stall_nonkud_avail = r1201b == 3 if !mi(r1201b)
gen agprod_stall_avail = agprod_stall_kud_avail | agprod_stall_nonkud_avail ///
	if !mi(agprod_stall_kud_avail,agprod_stall_nonkud_avail)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_nonkud_avail ///
	"Non-KUD-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Markets

gen shop_cntr_avail = r1203a == 1 if !mi(r1203a)
gen kero_station_avail = r1204a == 1 if !mi(r1204a)
gen LPG_station_avail  = r1204b == 3 if !mi(r1204b)
gen mkt_perm_avail = r1205a == 1 if !mi(r1205a)
gen n_mkt_temp = r1206 if !inlist(r1206,98,99)

la var shop_cntr_avail "Shopping center exists"
la var kero_station_avail "Kerosene station/agent exists"
la var LPG_station_avail ///
	"LPG station/agent/seller exists (incl. stall, shops, supermarkets...)"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1207 if r1207 != 98
gen n_cornerstore = r1208 if r1208 != 998
gen n_foodstall = r1209 if r1209 != 98
gen n_restaur = r1210 if r1210 != 98
gen n_hotel = r1211 if r1211 != 98 
gen n_motel = r1212 if r1212 != 98 

la var n_minimkt "Number of minimarkets"
la var n_cornerstore "Number of corner stores"
la var n_foodstall "Number of food and beverage stalls"
la var n_restaur "Number of restaurants/eating houses"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Banks

gen n_bank_com = 0
replace n_bank_com = r1215ak3 if r1215ak2 == 1

gen n_bank_rur = 0
replace n_bank_rur = r1215bk3 if r1215bk2 == 1

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r1214a == 1 | r1214b == 3 | r1214c == 5 | r1214d == 7 | ///
					 r1214e == 1
la var microfin_avail "Formal microfinance programs exist"
	
* Main village road has electric lighting

gen rd_light = r502a == 1 & inlist(r502b,1,2) if !mi(r502a) //& r1001b1 != 0

* Main village road has lighting provided by govt./non-govt.

gen rd_light_gov = r502a == 1 & r502b == 1 if !mi(r502a) //& r1001b1 != 0
gen rd_light_nongov = r502a == 1 & r502b == 2 if !mi(r502a) //& r1001b1 != 0

* Household electricity access

ren r501a n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501b n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	

foreach x in pln nonpln {	
	replace n_hh_elec_`x' = n_hh ///
		if !mi(n_hh,n_hh_elec_`x') & n_hh < n_hh_elec_`x'	
}	
	
gen n_hh_noelec = n_hh - n_hh_elec_pln - n_hh_elec_nonpln
	//replace n_hh_noelec = 0 if n_hh_noelec < 0
	la var n_hh_noelec "# Households without electricity"

foreach v in n_hh_elec_pln n_hh_elec_nonpln	n_hh_noelec {
	replace `v' = . if n_hh_noelec < 0
	replace `v' = . if mi(n_hh,n_hh_elec_pln,n_hh_elec_nonpln)
}
assert n_hh_noelec >= 0	
	
gen any_hh_elec = 0
	replace any_hh_elec = 1 if n_hh_elec_pln > 0 & !mi(n_hh_elec_pln)
	replace any_hh_elec = 1 if n_hh_elec_nonpln > 0 & !mi(n_hh_elec_nonpln)	

gen share_hh_elec = (n_hh_elec_pln + n_hh_elec_nonpln)/n_hh
	la var share_hh_elec "Share of households using electricity"

gen share_hh_elec_pln = n_hh_elec_pln/n_hh
	la var share_hh_elec_pln "Share of households using PLN electricity"
	
gen share_hh_elec_nonpln = n_hh_elec_nonpln/n_hh
	la var share_hh_elec_nonpln "Share of households using non-PLN electricity"	

* Fuel used for cooking 

local v r503
gen cookfuel_gas  = `v' == 1 if !mi(`v')
gen cookfuel_LPG  = `v' == 2 if !mi(`v')
gen cookfuel_kero = `v' == 3 if !mi(`v')
gen cookfuel_wood = `v' == 4 if !mi(`v')
gen cookfuel_othr = `v' == 5 if !mi(`v')

la var cookfuel_gas  "Most families cook with city gas"
la var cookfuel_LPG  "Most families cook with LPG"
la var cookfuel_kero "Most families cook with kerosene"
la var cookfuel_wood "Most families cook with firewood"
la var cookfuel_othr "Most families cook with other fuel (coal, charcoal, etc.)"
	
* Waste disposal

gen garbage_collect = r505a == 1 if !mi(r505a)
	la var garbage_collect "Gabage disposed using bins that are transported"	
	
gen toilet = inrange(r504,1,3) if !mi(r504)
	la var toilet "Most families defecate in a toilet (private, shared, public)"

* Safe water

gen safe_drink_water = inrange(r713a,1,2) if !mi(r713a) 
	la var safe_drink_water "Access to safe drinking water"
	
* River
	
gen river = r506ak2 == 1 if !mi(r506ak2)
	la var river "Existence of a river"
	
* Irrigation canal

gen irrigation = r506ak3 == 1 if !mi(r506ak3)
	la var irrigation "Existence of an irrigation canal"	

* Diversity: Ethnicity

gen multi_ethnic = r806 == 1 if !mi(r806)
	la var multi_ethnic "Multiple ethnic groups in village"	
	
ren r807_2 eth_code_majority
	la var eth_code_majority "Code of majority ethnicity"

ren nama_suku eth_name_majority	
	la var eth_name_majority "Name of majority ethnicity"	
	
* Diversity: Religion

assert !mi(r80101,r80102,r80103,r80104,r80105,r80106,r80107)
	
gen relig_exists_islam = r80101 == 1
	la var relig_exists_islam "Some residents practice Islam"

gen relig_exists_christ = r80102 == 3
	la var relig_exists_christ "Some residents practice Christianity"

gen relig_exists_cath = r80103 == 5
	la var relig_exists_cath "Some residents practice Catholicism"

gen relig_exists_budd = r80104 == 7
	la var relig_exists_budd "Some residents practice Buddhism"

gen relig_exists_hindu = r80105 == 1
	la var relig_exists_hindu "Some residents practice Hinduism"

gen relig_exists_conf = r80106 == 3
	la var relig_exists_conf "Some residents practice Confucianism"

gen relig_exists_othr = r80107 == 5
	la var relig_exists_othr "Some residents practice other religion"
	
ren r802 relig_majority	
	la var relig_majority "Majority religion"
	la def relig 1 "Islam" 2 "Christianity" 3 "Catholicism" 4 "Buddhism" ///
				 5 "Hinduism" 6 "Confucianism" 7 "Other"
	la val relig_majority relig	

* Fight against govt

gen fight_sec = 0
replace fight_sec = r1301b3k2 if r1301a == 1 

gen fight_state = 0
replace fight_state = r1301b4k2 if r1301a == 1

* Police

local x	r1309bk2
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"
		
* Distance to subdistrict office and district capital

local x r1004ak2
gen dist_subdi_off = `x' if `x' < 998
	la var dist_subdi_off "Distance to subdistrict office (km)"
	
local x r1004bk2
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"	
	
local x r1004ck2
gen dist_nearest_distr_cap = `x' ///
	if `x' < 998 & !inlist(`x',98,98.8,98.9,99) & !inrange(`x',99.79,99.91)
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"	

** Village public finance **	
	* All data missing for kelurahan
	
* Own-source revenue	
	
local x pad	
	
ren r1401ak2 rev_`x'_form
	la var rev_`x'_form "Form of own-source revenue"
	
ren r1401ak3 rev_`x'	
	la var rev_`x' "Own-Source Revenue (Pendapatan Asli Desa) (IDR millions)"
	
* Grant revenue from district	
	
local x kab

ren r1401b1k2 rev_`x'_form
	la var rev_`x'_form "Form of grant revenue from district"
	
ren r1401b1k3 rev_`x'
	la var rev_`x' "Grant revenue from district (IDR millions)"

* Grant revenue from province	
	
local x prov

ren r1401b2k2 rev_`x'_form
	la var rev_`x'_form "Form of grant revenue from province"
	
ren r1401b2k3 rev_`x'
	la var rev_`x' "Grant revenue from province (IDR millions)"	

* Grant revenue from central govt	
	
local x cent

ren r1401b3k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from central govt"
	
ren r1401b3k3 rev_`x'
	la var rev_`x' "Grant revenue from central govt (IDR millions)"	

* Grant revenue from foreign country ("overseas")

local x for

ren r1401b4k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from overseas"
	
ren r1401b4k3 rev_`x'
	la var rev_`x' "Grant revenue from overseas (IDR millions)"
	
* Grant revenue from private sources

local x priv

ren r1401b5k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from private sources"
	
ren r1401b5k3 rev_`x'
	la var rev_`x' "Grant revenue from private sources (IDR millions)"	
	
* Grant revenue from other sources

local x othr

ren r1401b6k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from other sources"

ren r1401b6k3 rev_`x'
	la var rev_`x' "Grant revenue from other sources (IDR millions)"	
	
* Label values 

foreach x in pad kab prov cent for priv othr {
	la def rev_`x'_form 1 "Money" 2 "Goods and Services" ///
						3 "Money, Goods and Services" 4 "No revenue"
	la val rev_`x'_form rev_`x'_form
}	

* Replace missing value with zero when form is "no revenue"
	
foreach x in pad kab prov cent for priv othr {
	replace rev_`x' = 0 if mi(rev_`x') & rev_`x'_form == 4
}

* Total revenue

egen rev_tot = rowtotal(rev_pad rev_kab rev_prov rev_cent rev_for rev_priv ///
						rev_othr), missing
	la var rev_tot "Total Revenue (IDR millions)"

* Set (small number of) apparently top-coded budget values to missing

foreach v in rev_pad rev_kab rev_prov rev_cent rev_for rev_priv rev_othr {
	replace rev_tot = . if inlist(`v',9999,9998,9980)
	replace `v' = . if inlist(`v',9999,9998,9980)
}

** Existence of community empowerment programs/activities, last 3 years **
	* "program" = "community empowerment program"
	* Broad categories: infrastructure, economic capacity, social capacity
	
local row_infr_trans  "a1"
local name_infr_trans "Comm. empower. program: infrastructure - transportation"
	
local row_infr_edu  "a2"
local name_infr_edu "Comm. empower. program: infrastructure - education"

local row_infr_heal  "a3"
local name_infr_heal "Comm. empower. program: infrastructure - health"

local row_infr_econ  "a4"
local name_infr_econ "Comm. empower. program: infrastructure - economy"

local row_econ_loanag  "b1"
local name_econ_loanag "Comm. empower. program: Econ. Capacity - agricultural loans"

local row_econ_loannonag  "b2"
local name_econ_loannonag "Comm. empower. program: Econ. Capacity - non-agri loans"

local row_econ_grantbiz  "b3"
local name_econ_grantbiz "Comm. empower. program: Econ. Capacity - grants to business"

local row_soc_prodskill  "c1"
local name_soc_prodskill "Comm. empower. program: Social Capacity - productive skills"

local row_soc_markskill  "c2"
local name_soc_markskill "Comm. empower. program: Social Capacity - marketing skills"

local row_soc_instit  "c3"
local name_soc_instit "Comm. empower. program: Social Capacity - marketing skills"
	
foreach stub in infr_trans infr_edu infr_heal infr_econ ///
				econ_loanag econ_loannonag econ_grantbiz ///
				soc_prodskill soc_markskill soc_instit {
					
	local x r1402`row_`stub''k
	gen prog_`stub' = `x'2 == 1 if !mi(`x'2)
		la var prog_`stub' "`name_`stub''"
	gen prog_`stub'_pnpm = inlist(`x'3,1,3) if !mi(`x'2) // !mi(`x'3) & `x'2 == 1
		la var prog_`stub'_pnpm "`name_`stub'' (funded by PNPM)"
					
}

egen prog_infr_any_pnpm = rowmax(prog_infr_*_pnpm)
egen prog_econ_any_pnpm = rowmax(prog_econ_*_pnpm)
egen prog_soc_any_pnpm =  rowmax(prog_soc_*_pnpm)
egen prog_any_pnpm = rowmax(prog_*_any_pnpm)

la var prog_infr_any_pnpm "Any infrastructure program funded by PNPM, 2008-10"	
la var prog_econ_any_pnpm "Any economic program funded by PNPM, 2008-10"	
la var prog_soc_any_pnpm  "Any social program funded by PNPM, 2008-10"	
la var prog_any_pnpm "Any program funded by PNPM, 2008-10"	

** Characteristics of village officials **
	* Village head
	* Village secretary
	/*
	Education coding (follows Martinez-Bravo 2017 appendix):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1501`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1501`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1501`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1501`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1
	replace `stub'_gradschl = .
		// codes 8 and 9 were not listed as options in PODES 2011	

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}

* For crosswalk

gen nm2011_1 = desa

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2011_1 id2011_2 id_podes11 id_ppls11 id2010_1 id_sp2010 id2009_1 ///
			 id2009_2 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

* Fixing names and codes

replace nm2011_1 = "KAMUNDAN II" if nm2011_1 == "KAMUNDAN 2"
	
* Tidying

format %10.0f id?*

order id* nm* prov_id province region_id region kec_id kec ///
	  desa_id desa type rev* prog_* pop vlg_consult vlghead* vlgsec* ///
	  n_* any_hh* cook* *_avail dist_* easy_* rd_* garbage* toilet safe* irrig* ///
	  police multi_ethnic eth* relig* main_income* pubphn phnstall internet ///
	  TVRI locTV natcomTV forTV mblphn mblphn_strng fight_sec ///
	  fight_state outbreak* deaths* vic* topog slope forest coastal river ///
	  dist_*_cap isl_name
	  
drop r106-r1501bk5		  	  

foreach v of varlist rev* {
	ren `v' `v'_2010
}

drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	cap ren `v' `v'_2011
}

foreach v of varlist type pop-isl_name share_hh_elec-share_hh_elec_nonpln ///
					 prog_* {
	ren `v' `v'_2011
}

* Append jorong/nagari datasets

append using `nagari2011'

* Merge world bank infrastructure dataset (if present)
if `has_infr' {
merge 1:1 id2011_1 using `podes2011infr', nogenerate update ///
	keep(master match match_update match_conflict)

* Health facilities that should be missing

replace n_posyandu_2011 = . if mi(posy_avail_2011)
replace n_polindes_2011 = . if mi(polin_avail_2011)
}
else {
	* Without the INFR files: the code components that the merge
	* above would fill, taken from the 2011 code
	replace prov_id   = floor(id2011_1/1e8) if mi(prov_id)
	replace region_id = mod(floor(id2011_1/1e6), 100) if mi(region_id)
	replace kec_id    = mod(floor(id2011_1/1e3), 1000) if mi(kec_id)
	replace desa_id   = mod(id2011_1, 1000) if mi(desa_id)
}
		
save "$work/podes2011.dta", replace

********************************************************************************
**# 2014
* 2014
********************************************************************************

** Merging raw data **

forval n = 1/3 {
	tempfile d`n'
	import dbase "$podes_raw/PODES 2014/podes_desa_2014_d`n'_new", ///
		clear case(lower)
	save `d`n''
}

use `d1'
merge 1:1 r101 r102 r103 r104 using `d2', nogenerate
merge 1:1 r101 r102 r103 r104 using `d3', nogenerate

foreach v of varlist r101 r102 r103 r104 r301-r1602 {
	cap destring `v', replace
}	

** Renaming geographic names/IDs **

ren r101  prov_id
ren r101n province
ren r102  region_id
ren r102n region
ren r103  kec_id
ren r103n kec
ren r104  desa_id
ren r104n desa

* Raw PODES code (unique)
gen double id_podes2014 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2014
isid id_podes2014
la var id_podes2014 "PODES 2014 code (raw file)"
gen nm_podes2014 = desa
la var nm_podes2014 "PODES 2014 name (raw file)"

ren r301 type	
	replace type = 6 if type == 3
	replace type = 3 if type == 5
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type	
	
gen vlg_consult = r302 == 1 if !mi(r302)
	la var vlg_consult "Presence of a Village Consultative Body"
	
ren r305a1 n_islands
	la var n_islands "Number of islands spanned by village"
	
ren r305b topog
	la var topog "Topography"
	la def topog 1 "Slope/peak" 2 "Valley" 3 "Plain"
	la val topog topog	
	
gen coastal = r307a == 1 if !mi(r307a)
	la var coastal "Village is adjacent to sea"
	
ren r308a forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest	
	
foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

replace province = "Nanggroe Aceh Darussalam" if province == "Aceh"
replace province = "DI Yogyakarta" if province == "D I Yogyakarta"
replace province = "DKI Jakarta" if province == "Dki Jakarta"
replace province = "Kepulauan Bangka-Belitung" ///
	if province == "Kepulauan Bangka Belitung"
	
replace province = province + ", Prop." 

** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"
	
** Generating social and infrastructure variables **

* Doctors, midwives, health facilities

gen n_dr = r706a1 + r706a2
gen n_dent = r706b
gen n_mwiv = r706c
gen n_mwiv_all = r706c

gen n_hosp = 0
replace n_hosp = r704a_k3 if r704a_k2 == 1

gen n_hosp_mat = 0
replace n_hosp_mat = r704b_k3 if r704b_k2 == 1

foreach x in c d e {
	gen n_pusk_`x' = 0
	replace n_pusk_`x' = r704`x'_k3 if r704`x'_k2 == 1
}

gen n_puskesmas = n_pusk_c + n_pusk_d + n_pusk_e
drop n_pusk_c n_pusk_d n_pusk_e

gen n_poliklinik = 0
replace n_poliklinik = r704f_k3 if r704f_k2 == 1

gen n_dr_off = 0
replace n_dr_off = r704g_k3 if r704g_k2 == 1

gen n_mwiv_off = 0
replace n_mwiv_off = r704h_k3 if r704h_k2 == 1

gen n_poskesdes = 0
replace n_poskesdes = r704i_k3 if r704i_k2 == 1

gen n_polindes = 0
replace n_polindes = r704j_k3 if r704j_k2 == 1

gen n_posyandu = 0
replace n_posyandu = r704k_k3 if r704k_k2 == 1

gen n_pharm = 0
replace n_pharm = r704l_k3 if r704l_k2 == 1

gen n_heal_cntr = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen mwiv_BDD_avail = r707 == 1 if !mi(r707)

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_avail = n_mwiv > 0 if !mi(n_mwiv)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)
gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)
gen poskpolin_avail = (posk_avail == 1) | (polin_avail == 1) ///
	if !mi(posk_avail) | !mi(polin_avail)

* Disease outbreaks

gen outbreak_diar = r709a_k2 == 1 if !mi(r709a_k2)
gen outbreak_deng = r709b_k2 == 1 if !mi(r709b_k2)
gen outbreak_meas = r709c_k2 == 1 if !mi(r709c_k2)
gen outbreak_resp = r709d_k2 == 1 if !mi(r709d_k2)
gen outbreak_mala = r709e_k2 == 1 if !mi(r709e_k2)
gen outbreak_avia = r709f_k2 == 1 if !mi(r709f_k2)
gen outbreak_tubr = r709g_k2 == 1 if !mi(r709g_k2)
gen outbreak_othr = r709h_k2 == 1 if !mi(r709h_k2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_resp ///
	"Upper respiratory tract infection outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_tubr "Tuberculosis outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r709a_k2 == 2
replace deaths_diar = r709a_k4 if r709a_k2 == 1

gen deaths_deng = 0 if r709b_k2 == 2
replace deaths_deng = r709b_k4 if r709b_k2 == 1

gen deaths_meas = 0 if r709c_k2 == 2
replace deaths_meas = r709c_k4 if r709c_k2 == 1

gen deaths_resp = 0 if r709d_k2 == 2
replace deaths_resp = r709d_k4 if r709d_k2 == 1

gen deaths_mala = 0 if r709e_k2 == 2
replace deaths_mala = r709e_k4 if r709e_k2 == 1

gen deaths_avia = 0 if r709f_k2 == 2
replace deaths_avia = r709f_k4 if r709f_k2 == 1

gen deaths_tubr = 0 if r709g_k2 == 2
replace deaths_tubr = r709g_k4 if r709g_k2 == 1

gen deaths_othr = 0 if r709h_k2 == 2
replace deaths_othr = r709h_k4 if r709h_k2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r710
la var victims_malnutr "Number of malnutrition victims during the past 3 years"

* Proxies for number of poor people

gen n_jamkesmas = r711a
gen n_sktm = r711b 
gen n_jkn = r711c

la var n_jamkesmas ///
	"Number of residents receiving JAMKESMAS/JAMKESDA cards in 2013"
la var n_sktm "Number of poverty letters/SKTM issued by village in 2013"	
la var n_jkn "Number of residents who are participants in BPJS Health/JKN"

* Schools 

gen n_schl_kind_pub  = r701a_k2 
gen n_schl_prm_pub   = r701b_k2	
gen n_schl_jrsec_pub = r701c_k2
gen n_schl_srsec_pub = r701d_k2
gen n_schl_voc_pub 	 = r701e_k2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub
gen n_schl_srsecvoc_pub   = n_schl_srsec_pub + n_schl_voc_pub

gen n_schl_kind_prv  = r701a_k3 
gen n_schl_prm_prv   = r701b_k3	
gen n_schl_jrsec_prv = r701c_k3
gen n_schl_srsec_prv = r701d_k3
gen n_schl_voc_prv 	 = r701e_k3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv
gen n_schl_srsecvoc_prv   = n_schl_srsec_prv + n_schl_voc_prv

foreach x in kind prm jrsec srsec sec srsecvoc {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm prm_pub jrsec jrsec_pub srsec srsec_pub ///
			 sec sec_pub srsecvoc srsecvoc_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = r702c == 5 if !mi(r702c)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r702f == 3 if !mi(r702f)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

local x b
local type hosp_mat
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

gen dist_puskesmas = min(r704c_k4,r704d_k4,r704e_k4) ///
	if !mi(r704c_k4) | !mi(r704d_k4) | !mi(r704e_k4)
gen easy_puskesmas = max( inlist(r704c_k5,1,2), inlist(r704d_k5,1,2), ///
						  inlist(r704e_k5,1,2) ) ///
	if !mi(r704c_k5) | !mi(r704d_k5) | !mi(r704e_k5)

local x f
local type poliklinik
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)
						  
local x g
local type dr_off
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

local x h
local type mwiv_off
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

local x i
local type poskesdes
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

local x j
local type polindes
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

local x l
local type pharm
gen dist_`type' = r704`x'_k4
gen easy_`type' = inlist(r704`x'_k5,1,2) if !mi(r704`x'_k5)

local x a
local type kind
gen dist_schl_`type'_pub = r701`x'_k4

local x b
local type prm
gen dist_schl_`type'_pub = r701`x'_k4

local x c
local type jrsec
gen dist_schl_`type'_pub = r701`x'_k4

local x d
local type srsec
gen dist_schl_`type'_pub = r701`x'_k4

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)

gen easy_poskpolin = (easy_poskesdes == 1) | (easy_polindes == 1) ///
	if !mi(easy_poskesdes) | !mi(easy_polindes)

* Roads

gen rd_asph = r1001b1 == 1 if !mi(r1001b1) //& r1001b1 != 0
gen rd_grvl = r1001b1 == 2 if !mi(r1001b1) //& r1001b1 != 0
gen rd_dirt = r1001b1 == 3 if !mi(r1001b1) //& r1001b1 != 0
gen rd_othr = r1001b1 == 4 if !mi(r1001b1) //& r1001b1 != 0

gen rd_pass = r1001b2 == 1 if !mi(r1001b2) //& r1001b2 != 0

local var r404b2
gen rd_connect_asph = `var' == 1 if !mi(`var') //& `var' != 0
gen rd_connect_grvl = `var' == 2 if !mi(`var') //& `var' != 0
gen rd_connect_dirt = `var' == 3 if !mi(`var') //& `var' != 0
gen rd_connect_othr = `var' == 4 if !mi(`var') //& `var' != 0
	/*
	Road surface type from production center / agricultural land to the village 
	main road 
	*/
	
* Public transportation

gen pub_trans = inlist(r1001c1,1,2) if !mi(r1001c1)
	la var pub_trans "Existence of public transportation"	
	
gen pub_trans_daily = r1001c2 == 1 if !mi(r1001c2)
	la var pub_trans_daily "Public transportation operates every day"
	
gen pub_trans_daynight = r1001c3 == 1 if !mi(r1001c3)
	la var pub_trans_daynight "Public transportation operates day and night"
	
* Main source of income

local var r404a
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_trans	 = `var' == 5 if !mi(`var')
gen main_income_services = `var' == 6 if !mi(`var')
gen main_income_other	 = `var' == 7 if !mi(`var')

* Small manufacturing establishments

gen n_estab_sm_leather 	= r1201a if !inlist(r1201a,998,999)
gen n_estab_sm_wood 	= r1201b if !inlist(r1201b,998,999)
gen n_estab_sm_metal 	= r1201c if !inlist(r1201c,998,999)
gen n_estab_sm_woven 	= r1201d if !inlist(r1201d,998,999)
gen n_estab_sm_pottery 	= r1201e if !inlist(r1201e,998,999)
gen n_estab_sm_fabric 	= r1201f if !inlist(r1201f,998,999)
gen n_estab_sm_foodbev 	= r1201g if !inlist(r1201g,998,999)
gen n_estab_sm_other 	= r1201h if !inlist(r1201h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"
		
* Cooperatives

gen n_coop_kud 	  = r1212a if !inlist(r1212a,98,99)
gen n_coop_smmanu = r1212b if !inlist(r1212b,98,99)
gen n_coop_save   = r1212c if !inlist(r1212c,98,99)
gen n_coop_othr   = r1212d if !inlist(r1212d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"	

* Agricultural production stalls

gen agprod_stall_kud_avail 	  = r1213a == 1 if !mi(r1213a)
gen agprod_stall_nonkud_avail = r1213b == 3 if !mi(r1213b)
gen agprod_stall_avail = agprod_stall_kud_avail | agprod_stall_nonkud_avail ///
	if !mi(agprod_stall_kud_avail,agprod_stall_nonkud_avail)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_nonkud_avail ///
	"Non-KUD-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Markets

gen shop_cntr_avail = r1202a == 1 if !mi(r1202a)
gen kero_station_avail = r1203a == 1 if !mi(r1203a)
gen LPG_station_avail  = r1203b == 3 if !mi(r1203b)

gen n_mkt_perm = r1204a + r1204b ///
	if !inlist(r1204a,98,99) & !inlist(r1204b,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r1205 if !inlist(r1205,98,99)
gen mkt_temp_avail = n_mkt_temp > 0 if !mi(n_mkt_temp)

la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"
la var mkt_temp_avail "Temporary market exists"
la var kero_station_avail "Kerosene station/agent exists"
la var LPG_station_avail ///
	"LPG station/agent/seller exists (incl. stall, shops, supermarkets...)"

* Service establishments

gen n_minimkt = r1206
gen n_cornerstore = r1207 if !inlist(r1207,998,999)
gen n_foodstall = r1208 if !inlist(r1208,998,999)
gen n_restaur = r1209 if !inlist(r1209,98,99)
gen n_hotel = r1210 if !inlist(r1210,98,99)
gen n_motel = r1211 if !inlist(r1211,98,99)

foreach x in restaur foodstall hotel motel {
	gen `x'_avail = n_`x' > 0 if !mi(n_`x')
}

gen restaurfoodstall_avail = (restaur_avail == 1) | (foodstall_avail == 1) ///
	if !mi(restaur_avail) | !mi(foodstall_avail)
	
gen hotelmotel_avail = (hotel_avail == 1) | (motel_avail == 1) ///
	if !mi(hotel_avail) | !mi(motel_avail)	

la var n_minimkt "Number of minimarkets"
la var n_cornerstore "Number of corner stores"
la var n_foodstall "Number of food and beverage stalls"
la var n_restaur "Number of restaurants/eating houses"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Banks

gen n_bank_com_gov = 0
replace n_bank_com_gov = r1215a_k3 if r1215a_k2 == 1
replace n_bank_com_gov = . if inlist(r1215a_k3,98,99)

gen n_bank_com_prv = 0
replace n_bank_com_prv = r1215b_k3 if r1215b_k2 == 1
replace n_bank_com_prv = . if inlist(r1215b_k3,98,99)

gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = 0
replace n_bank_rur = r1215c_k3 if r1215c_k2 == 1
replace n_bank_rur = . if inlist(r1215c_k3,98,99)

gen bank_avail = (n_bank_com > 0 & !mi(n_bank_com)) | ///
				 (n_bank_rur > 0 & !mi(n_bank_rur))

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"
la var bank_avail "Bank exists"

* Microfinance

gen microfin_avail = r1214a == 1 | r1214b == 3 | r1214c == 5 
la var microfin_avail "Formal microfinance programs exist"
		
* Main village road has electric lighting

gen rd_light = r502a == 1 & inlist(r502b,1,2) if !mi(r502a) //& r1001b1 != 0

* Main village road has lighting provided by govt./non-govt.

gen rd_light_gov = r502a == 1 & r502b == 1 if !mi(r502a) //& r1001b1 != 0
gen rd_light_nongov = r502a == 1 & r502b == 2 if !mi(r502a) //& r1001b1 != 0

* Household electricity access

ren r501a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r501b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)		
	
* Waste disposal

gen garbage_collect = r505a == 1 if !mi(r505a)
	la var garbage_collect "Gabage disposed using bins that are transported"
	
gen toilet = inrange(r504,1,3) if !mi(r504)
	la var toilet "Most families defecate in a toilet (private, shared, public)"	
	
gen absorp_pit = r506 == 1 if !mi(r506)	
	la var absorp_pit "Most families dispose of wastewater in absorption pit"

* Safe water

gen safe_drink_water = inrange(r507a,1,3) if !mi(r507a) 
	la var safe_drink_water "Access to safe drinking water"

gen safe_bath_water = inrange(r507b,1,2) if !mi(r507b) 
	la var safe_bath_water "Access to safe bathing water"
	
* River

gen river = r508a_k2 == 1 if !mi(r508a_k2)
	la var river "Existence of a river"	
	
* Irrigation canal
	
gen irrigation = r508a_k3 == 1 if !mi(r508a_k3)
	la var irrigation "Existence of an irrigation canal"	
	
* Diversity

gen multi_ethnic = r804a1 == 1 if !mi(r804a1)
	la var multi_ethnic "Multiple ethnic groups in village"

gen multi_lang = r804b1 == 1 if !mi(r804b1)
	la var multi_lang "Multiple languages spoke in village"
	
* Entertainment

gen cinema = r902a1 == 1 if !mi(r902a1)
	la var cinema "Existence of functioning cinema"

gen pub = r902b1 == 1 if !mi(r902b1)
	la var pub "Existence of functioning pub/discotheque/karaoke venue"
	
local x	r903a_k2
gen soccer_facility = `x' == 1 if !mi(`x')
	
local x	r903b_k2
gen volleyball_facility = `x' == 1 if !mi(`x')
	
local x	r903c_k2
gen badminton_facility = `x' == 1 if !mi(`x')
	
local x	r903d_k2
gen basketball_facility = `x' == 1 if !mi(`x')
	
local x	r903e_k2
gen tennis_facility = `x' == 1 if !mi(`x')
	
local x	r903f_k2
gen tabtennis_facility = `x' == 1 if !mi(`x')
	
local x	r903g_k2
gen futsal_facility = `x' == 1 if !mi(`x')

local x	r903h_k2
gen swim_facility = `x' == 1 if !mi(`x')

local x	r903i_k2
gen martialarts_facility = `x' == 1 if !mi(`x')

local x	r903j_k2
gen billiards_facility = `x' == 1 if !mi(`x')

local x	r904
gen fitness_center = `x' == 1 if !mi(`x')
	
	
// Mass fighting
// r1301a 
// ETC	

* Phone, internet, TV

gen n_hh_phn = 0
replace n_hh_phn = r1003b if r1003a == 1

gen pubphn   = r1004a == 1 | r1004b == 3 if !mi(r1004a) | !mi(r1004b)
gen phnstall = r1006 == 1 if !mi(r1006)   
gen internet = r1007b == 3 if !mi(r1007a)   
gen internet_head = r1007a == 1 if !mi(r1007a)    
	// internet facility in office of village head
gen TVRI 	 = r1009a_k2 == 1 if !mi(r1009a_k2) 
gen locTV 	 = r1009b_k2 == 1 if !mi(r1009b_k2) 
gen natcomTV = r1009c_k2 == 1 if !mi(r1009c_k2) 
gen forTV 	 = r1009d_k2 == 1 if !mi(r1009d_k2) 
gen mblphn   = inlist(r1005b,1,2) if !mi(r1005b) 
gen mblphn_strng = r1005b == 2 if !mi(r1005b)    

/*
no data on total number of families -> cannot create hh_phn
*/	

* Fight against govt

gen fight_sec = 0
replace fight_sec = r1301b3_k2 if r1301a == 1 

gen fight_state = 0
replace fight_state = r1301b4_k2 if r1301a == 1 

* Police

local x	r1306a
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"

** Existence of community empowerment programs/activities, last 3 years **
	* "program" = "community empowerment program"
	* Broad categories: infrastructure, economic capacity, social capacity
	
local row_infr_trans  "a1"
local name_infr_trans "Comm. empower. program: infrastructure - transportation"
	
local row_infr_edu  "a2"
local name_infr_edu "Comm. empower. program: infrastructure - education"

local row_infr_heal  "a3"
local name_infr_heal "Comm. empower. program: infrastructure - health"

local row_infr_econ  "a4"
local name_infr_econ "Comm. empower. program: infrastructure - economy"

local row_econ_loanag  "b1"
local name_econ_loanag "Comm. empower. program: Econ. Capacity - agricultural loans"

local row_econ_loannonag  "b2"
local name_econ_loannonag "Comm. empower. program: Econ. Capacity - non-agri loans"

local row_econ_grantbiz  "b3"
local name_econ_grantbiz "Comm. empower. program: Econ. Capacity - grants to business"

local row_soc_prodskill  "c1"
local name_soc_prodskill "Comm. empower. program: Social Capacity - productive skills"

local row_soc_markskill  "c2"
local name_soc_markskill "Comm. empower. program: Social Capacity - marketing skills"

local row_soc_instit  "c3"
local name_soc_instit "Comm. empower. program: Social Capacity - marketing skills"
	
foreach stub in infr_trans infr_edu infr_heal infr_econ ///
				econ_loanag econ_loannonag econ_grantbiz ///
				soc_prodskill soc_markskill soc_instit {
					
	local x r1401`row_`stub''_k
	gen prog_`stub' = `x'2 == 1 if !mi(`x'2)
		la var prog_`stub' "`name_`stub''"
	gen prog_`stub'_pnpm = inlist(`x'3,1,3) if !mi(`x'2) // !mi(`x'3) & `x'2 == 1
		la var prog_`stub'_pnpm "`name_`stub'' (funded by PNPM)"
					
}

egen prog_infr_any_pnpm = rowmax(prog_infr_*_pnpm)
egen prog_econ_any_pnpm = rowmax(prog_econ_*_pnpm)
egen prog_soc_any_pnpm =  rowmax(prog_soc_*_pnpm)
egen prog_any_pnpm = rowmax(prog_*_any_pnpm)

la var prog_infr_any_pnpm "Any infrastructure program funded by PNPM, 2011-13"	
la var prog_econ_any_pnpm "Any economic program funded by PNPM, 2011-13"	
la var prog_soc_any_pnpm  "Any social program funded by PNPM, 2011-13"	
la var prog_any_pnpm "Any program funded by PNPM, 2011-13"	

* Distance, travel time, travel cost: subdistrict office and district capital

local x r1002a_k2
gen dist_subdi_off = `x' if `x' < 998
	la var dist_subdi_off "Distance to subdistrict office (km)"
	
local x r1002a_k3
gen trvltime_subdi_off = `x' if `x' < 98
	la var trvltime_subdi_off "Travel time to subdistrict office (hours)"	

local x r1002a_k7
gen trvlcost_subdi_off = `x' if `x' < 98999
	la var trvlcost_subdi_off "Cost of travel to subdistrict office (000 IDR)"	

local x r1002b_k2
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"

local x r1002b_k3
gen trvltime_distr_cap = `x' if `x' < 98
	la var trvltime_distr_cap "Travel time to district capital (hours)"	
	
local x r1002b_k7
gen trvlcost_distr_cap = `x' if `x' < 98999
	la var trvlcost_distr_cap "Cost of travel to district office (000 IDR)"	

* Distance to nearest district capital	
	
local x r1002d_k2	
gen dist_nearest_distr_cap = `x' ///
	if `x' < 998 & !inlist(`x',98,98.8,98.9,99) & !inrange(`x',99.79,99.91)
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"	
	
* Time/cost per km of travel: subdistrict office and district capital
		 
gen timeperkm_subdi_off = trvltime_subdi_off/dist_subdi_off 
gen costperkm_subdi_off = trvlcost_subdi_off/dist_subdi_off 

la var timeperkm_subdi_off "Hours of travel per km: subdistrict office"	
la var costperkm_subdi_off "Cost of travel per km: subdistrict office (000 IDR)"

gen timeperkm_distr_cap = trvltime_distr_cap/dist_distr_cap 
gen costperkm_distr_cap = trvlcost_distr_cap/dist_distr_cap
	
la var timeperkm_distr_cap "Hours of travel per km: district capital"	
la var costperkm_distr_cap "Cost of travel per km: district capital (000 IDR)"
	
** Village public finance **	
	* All data missing for kelurahan
	
* Own-source revenue

local x pad	
	
ren r1501a_k2 rev_`x'_form
	la var rev_`x'_form "Form of own-source revenue"
	
ren r1501a_k3 rev_`x'	
	la var rev_`x' "Own-Source Revenue (Pendapatan Asli Desa) (IDR millions)"
	
* Village allocation fund (Alokasi Dana Desa, ADD)

local x add	
	
ren r1501b_k2 rev_`x'_form
	la var rev_`x'_form "Form of village allocation fund"
	
ren r1501b_k3 rev_`x'
	la var rev_`x' "Village allocation fund (Alokasi Dana Desa) (IDR millions)"

* Grant revenue from district	
	
local x kab

ren r1501c1_k2 rev_`x'_form
	la var rev_`x'_form "Form of grant revenue from district"
	
ren r1501c1_k3 rev_`x'
	la var rev_`x' "Grant revenue from district (IDR millions)"
	
* Grant revenue from province	
	
local x prov

ren r1501c2_k2 rev_`x'_form
	la var rev_`x'_form "Form of grant revenue from province"
	
ren r1501c2_k3 rev_`x'
	la var rev_`x' "Grant revenue from province (IDR millions)"	
	
* Grant revenue from central govt	
	
local x cent

ren r1501c3_k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from central govt"
	
ren r1501c3_k3 rev_`x'
	la var rev_`x' "Grant revenue from central govt (IDR millions)"	
	
* Grant revenue from foreign country ("overseas")

local x for

ren r1501c4_k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from overseas"
	
ren r1501c4_k3 rev_`x'
	la var rev_`x' "Grant revenue from overseas (IDR millions)"
	
* Grant revenue from private sources

local x priv

ren r1501c5_k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from private sources"
	
ren r1501c5_k3 rev_`x'
	la var rev_`x' "Grant revenue from private sources (IDR millions)"	

* Grant revenue from other sources

local x othr

ren r1501c6_k2 rev_`x'_form
	la var rev_`x'_form "Form of shared revenue from other sources"
	
ren r1501c6_k3 rev_`x'
	la var rev_`x' "Grant revenue from other sources (IDR millions)"	
	
* Label values 

foreach x in pad add kab prov cent for priv othr {
	la def rev_`x'_form 1 "Money" 2 "Goods and Services" ///
						3 "Money, Goods and Services" 4 "No revenue"
	la val rev_`x'_form rev_`x'_form
}	
	
* Replace missing value with zero when form is "no revenue"
	
foreach x in pad add kab prov cent for priv othr {
	replace rev_`x' = 0 if mi(rev_`x') & rev_`x'_form == 4
}	

* Total revenue

egen rev_tot = rowtotal(rev_pad rev_add rev_kab rev_prov rev_cent rev_for ///
						rev_priv rev_othr), missing
	la var rev_tot "Total Revenue (IDR millions)"

* Personnel expenditure 
	* (wages, salary, etc.)

ren r1502a exp_staf
	la var exp_staf "Personnel Expenditure (IDR millions)"
	
* Capital expenditure 
	* (land, buildings, roads, bridges, computers, etc.)	

ren r1502b exp_cap
	la var exp_cap "Capital Expenditure (IDR millions)"

* Other expenditure 
	* (social assistance, unexpected expenditure, meeting consumption, etc.)	

ren r1502c exp_othr
	la var exp_othr "Other Expenditure (IDR millions)"	
	
* Total expenditure

gen exp_tot = exp_staf + exp_cap + exp_othr
	la var exp_tot "Total Expenditure (IDR millions)"

* Set (small number of) apparently top-coded budget values to missing

foreach v in rev_pad rev_add rev_kab rev_prov rev_cent rev_for rev_priv rev_othr {
	replace rev_tot = . if inlist(`v',9999,9998,9980)
	replace `v' = . if inlist(`v',9999,9998,9980)
}
		   
foreach v in exp_staf exp_cap exp_othr {
	replace exp_tot = . if inlist(`v',9999,9998,9980)
	replace `v' = . if inlist(`v',9999,9998,9980)
}

** Characteristics of village officials **
	* Village head
	* Village secretary	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1601`row'_k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1601`row'_k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1601`row'_k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1601`row'_k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}

* Village secretariat (kaur/kasi, etc.)
	* Civil servants funded by DD/ADD that report directly to village head

local x r1601c_k2
gen vlgsecretariat_exists = `x' == 1 if !mi(`x')
	la var vlgsecretariat_exists "Village secretariat (kaur/kasi, etc.) exists"
	
** Village administration **

local x r1601d_k2
gen regadmin_exist = `x' == 1 if !mi(`x')
	la var regadmin_exist "Existence of regional administrators"

ren r1602 n_vlg_officials
	la var n_vlg_officials "Number of village officials"

* For crosswalk

gen nm2014   = desa

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

**# grib
foreach v in id2014 /*id2013_1*/ {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

gen bps_2014 = string(prov_id) + regstr
destring bps_2014, replace

drop regstr kecstr desastr

* Tidying

format %10.0f id?*

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa type rev* exp* prog_* vlg_consult vlghead* vlgsec* ///
	  n_* any_hh* *_avail dist_* easy_* rd_* pub_trans* garbage* toilet absorp* ///
	  safe* irrig* police multi_ethnic multi_lang cinema pub *facility fitness* ///
	  regadmin_exist main_income* pubphn phnstall internet ///
	  internet_head TVRI locTV natcomTV forTV mblphn mblphn_strng fight_sec ///
	  fight_state outbreak* deaths* vic* topog forest dist_*_cap ///
	  trvltime* trvlcost* timeperkm* costperkm* coastal river 
	  
drop r302-r1601d_k2 	  

foreach v of varlist rev* exp* {
	ren `v' `v'_2013
}

drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	cap ren `v' `v'_2014
}

foreach v of varlist type vlg_consult-river prog_* {
	ren `v' `v'_2014
}

save "$work/podes2014.dta", replace

********************************************************************************
**# 2018
* 2018
********************************************************************************

** Merging raw data **

forval n = 1/4 {
	tempfile d`n'
	import dbase "$podes_raw/PODES 2018/podes2018_desa_part`n'_revisi", ///
		clear case(lower)
	save `d`n''
}

use `d1'
merge 1:1 r101 r102 r103 r104 using `d2', nogenerate
merge 1:1 r101 r102 r103 r104 using `d3', nogenerate
merge 1:1 r101 r102 r103 r104 using `d4', nogenerate

foreach v of varlist * {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren r101  prov_id
ren r101n province
ren r102  region_id
ren r102n region
ren r103  kec_id
ren r103n kec
ren r104  desa_id
ren r104n desa

* Raw PODES code (unique)
gen double id_podes2018 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2018
isid id_podes2018
la var id_podes2018 "PODES 2018 code (raw file)"
gen nm_podes2018 = desa
la var nm_podes2018 "PODES 2018 name (raw file)"

ren r301 type
	recode type (3 = 6) (4 = 3)
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type
	
gen vlg_consult = r302a == 1 if !mi(r302a)
	la var vlg_consult "Presence of a Village Consultative Body"
	
ren r302b vlg_consult_num
	la var vlg_consult_num "Number of members of the Village Consultative Body"

ren r305a1 n_islands
	la var n_islands "Number of islands spanned by village"
	
ren r305b topog
	la var topog "Topography"
	la def topog 1 "Slope/peak" 2 "Valley" 3 "Plain"
	la val topog topog	
	
gen coastal = r308a == 1 if !mi(r308a)
	la var coastal "Village is adjacent to sea"	
	
ren r309a forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest	
	
foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"
	
** Generating social and infrastructure variables **

* Doctors, midwives, health facilities

gen n_dr = r706a1 + r706a2
gen n_dent = r706b
gen n_mwiv_all = r706c
gen n_hosp = r704ak2
gen n_hosp_mat = r704bk2
gen n_puskesmas = r704ck2 + r704dk2 + r704ek2 
gen n_poliklinik = r704fk2
gen n_dr_off = r704gk2
gen n_mwiv_off = r704ik2
gen n_poskesdes = r704jk2
gen n_polindes = r704kk2
gen n_posyandu = r705a + r705b
gen n_pharm = r704lk2

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen mwiv_BDD_avail = r707 == 1 if !mi(r707)

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)
gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Disease outbreaks

gen outbreak_diar = r709ak2 == 1 if !mi(r709ak2)
gen outbreak_deng = r709bk2 == 1 if !mi(r709bk2)
gen outbreak_meas = r709ck2 == 1 if !mi(r709ck2)
gen outbreak_mala = r709dk2 == 1 if !mi(r709dk2)
gen outbreak_avia = r709ek2 == 1 if !mi(r709ek2)
gen outbreak_hepe = r709fk2 == 1 if !mi(r709fk2)
gen outbreak_diph = r709gk2 == 1 if !mi(r709gk2)
gen outbreak_othr = r709hk2 == 1 if !mi(r709hk2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_hepe "Hepatitis E outbreak during the past year"
la var outbreak_diph "Diphtheria outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r709ak2 == 2
replace deaths_diar = r709ak4 if r709ak2 == 1

gen deaths_deng = 0 if r709bk2 == 2
replace deaths_deng = r709bk4 if r709bk2 == 1

gen deaths_meas = 0 if r709ck2 == 2
replace deaths_meas = r709ck4 if r709ck2 == 1

gen deaths_mala = 0 if r709dk2 == 2
replace deaths_mala = r709dk4 if r709dk2 == 1

gen deaths_avia = 0 if r709ek2 == 2
replace deaths_avia = r709ek4 if r709ek2 == 1

gen deaths_hepe = 0 if r709fk2 == 2
replace deaths_hepe = r709fk4 if r709fk2 == 1

gen deaths_diph = 0 if r709gk2 == 2
replace deaths_diph = r709gk4 if r709gk2 == 1

gen deaths_othr = 0 if r709hk2 == 2
replace deaths_othr = r709hk4 if r709hk2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r710
la var victims_malnutr "Number of malnutrition victims in 2017"

* Proxies for number of poor people

gen n_jamkesmas = r711a
gen n_sktm = r711b 

la var n_jamkesmas ///
	"Number of BPJS Kesehatan citizens receiving Contribution Assistance (PBI) and JAMKESDA in 2017"
	// Note: PBI is the direct institutional successor of JAMKESMAS
la var n_sktm "Number of poverty letters/SKTM issued by village in 2017"	

* Schools 

gen n_schl_pre_pub	 = r701ak2
gen n_schl_kind_pub  = r701bk2
gen n_schl_prm_pub   = r701ck2	
gen n_schl_jrsec_pub = r701dk2
gen n_schl_srsec_pub = r701ek2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_pre_prv	 = r701ak3
gen n_schl_kind_prv  = r701bk3 
gen n_schl_prm_prv   = r701ck3	
gen n_schl_jrsec_prv = r701dk3
gen n_schl_srsec_prv = r701ek3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in pre kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = n_schl_pre > 0 if !mi(n_schl_pre)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r702f == 3 if !mi(r702f)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x b
local type hosp_mat
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

gen dist_puskesmas = min(r704ck3,r704dk3,r704ek3) ///
	if !mi(r704ck3) | !mi(r704dk3) | !mi(r704ek3)
gen easy_puskesmas = max( inlist(r704ck4,1,2), inlist(r704dk4,1,2), ///
						  inlist(r704ek4,1,2) ) ///
	if !mi(r704ck4) | !mi(r704dk4) | !mi(r704ek4)			  

local x f
local type poliklinik
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)
						  
local x g
local type dr_off
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x i
local type mwiv_off
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x j
local type poskesdes
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x k
local type polindes
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x l
local type pharm
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x b
local type kind
gen dist_schl_`type'_pub = r701`x'k4
gen easy_schl_`type'_pub = inlist(r701`x'k5,1,2) if !mi(r701`x'k5)

local x c
local type prm
gen dist_schl_`type'_pub = r701`x'k4
gen easy_schl_`type'_pub = inlist(r701`x'k5,1,2) if !mi(r701`x'k5)

local x d
local type jrsec
gen dist_schl_`type'_pub = r701`x'k4
gen easy_schl_`type'_pub = inlist(r701`x'k5,1,2) if !mi(r701`x'k5)

local x e
local type srsec
gen dist_schl_`type'_pub = r701`x'k4
gen easy_schl_`type'_pub = inlist(r701`x'k5,1,2) if !mi(r701`x'k5)

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)
gen easy_schl_sec_pub = max(easy_schl_jrsec_pub,easy_schl_srsec_pub)

* Roads

gen rd_asph = r1001b1 == 1 if !mi(r1001b1)
gen rd_grvl = r1001b1 == 2 if !mi(r1001b1)
gen rd_dirt = r1001b1 == 3 if !mi(r1001b1)
gen rd_othr = r1001b1 == 4 if !mi(r1001b1)

gen rd_pass = r1001b2 == 1 if !mi(r1001b2)

local var r403c1
gen rd_connect_asph = `var' == 1 if !mi(`var')
gen rd_connect_grvl = `var' == 2 if !mi(`var')
gen rd_connect_dirt = `var' == 3 if !mi(`var')
gen rd_connect_othr = inrange(`var',4,5) if !mi(`var')
	/*
	Road surface type from production center / agricultural land to the village 
	main road 
	*/
	
* Public transportation
	
gen pub_trans = inlist(r1001c1,1,2) if !mi(r1001c1)
	la var pub_trans "Existence of public transportation"	

* Main source of income

local var r403a
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')
gen main_income_whretail = `var' == 4 if !mi(`var')
gen main_income_trans	 = `var' == 5 if !mi(`var')
gen main_income_services = `var' == 6 if !mi(`var')
gen main_income_other	 = `var' == 7 if !mi(`var')

* Small manufacturing establishments

gen n_estab_sm_leather 	= r1201a if !inlist(r1201a,998,999)
gen n_estab_sm_wood 	= r1201b if !inlist(r1201b,998,999)
gen n_estab_sm_metal 	= r1201c if !inlist(r1201c,998,999)
gen n_estab_sm_fabric 	= r1201d if !inlist(r1201d,998,999)
gen n_estab_sm_pottery 	= r1201e if !inlist(r1201e,998,999)
gen n_estab_sm_woven 	= r1201f if !inlist(r1201f,998,999)
gen n_estab_sm_foodbev 	= r1201g if !inlist(r1201g,998,999)
gen n_estab_sm_other 	= r1201h if !inlist(r1201h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"

* Cooperatives

gen n_coop_kud 	  = r1204a  if !inlist(r1204a,98,99)
gen n_coop_smmanu = r1205a1 if !inlist(r1205a1,98,99)
gen n_coop_save   = r1205a2 if !inlist(r1205a2,98,99)
gen n_coop_othr   = r1205a3 if !inlist(r1205a3,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Agricultural production stalls

gen agprod_stall_kud_avail = r1205b1 == 1 if !mi(r1205b1)
gen agprod_stall_bum_avail = r1205b2 == 3 if !mi(r1205b2)
gen agprod_stall_non_avail = r1205b3 == 5 if !mi(r1205b3)

gen agprod_stall_avail = ///
	agprod_stall_kud_avail | agprod_stall_bum_avail | agprod_stall_non_avail ///
  if !mi(agprod_stall_kud_avail,agprod_stall_bum_avail,agprod_stall_non_avail)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_bum_avail "BUM-owned agricultural production stalls exists"
la var agprod_stall_non_avail ///
	"Non-KUD/BUM-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Industrial areas

gen ind_center = r1202a > 0 if !mi(r1202a)	
la var ind_center "Industrial center in village"
	
gen small_ind_area = r1202b > 0 | r1202c > 0 if !mi(r1202b,r1202c)
la var small_ind_area "Small industrial area in village"

* Markets

gen n_shop_cntr = r1206ak2 if !inlist(r1206ak2,98,99)
gen shop_cntr_avail = n_shop_cntr > 0 if !mi(n_shop_cntr)

gen n_mkt_perm = r1206bk2 + r1206ck2 ///
	if !inlist(r1206bk2,98,99) & !inlist(r1206ck2,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r1206dk2 if !inlist(r1206dk2,98,99)

la var n_shop_cntr "Number of shopping centers"
la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1206ek2
gen n_cornerstore = r1206f1k2 if !inlist(r1206f1k2,998,999) 
gen n_restaur = r1206gk2 if !inlist(r1206gk2,98,99)
gen n_foodstall = r1206hk2 if !inlist(r1206hk2,998,999)
gen n_hotel = r1206ik2 if !inlist(r1206ik2,98,99)
gen n_motel = r1206jk2 if !inlist(r1206jk2,98,99)

la var n_minimkt "Number of minimarkets"
la var n_cornerstore "Number of corner stores"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"

* Banks

gen n_bank_com_gov = r1208ak2 if !inlist(r1208ak2,98,99)
gen n_bank_com_prv = r1208bk2 if !inlist(r1208bk2,98,99)
gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = r1208ck2 if !inlist(r1208ck2,98,99)

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r1207a == 1 | r1207b == 3 | r1207c == 5 | r1207d == 7
la var microfin_avail "Formal microfinance programs exist"

* Main village road has electric lighting

gen rd_light = inlist(r502a,1,2) & inlist(r502b,1,2) ///
	if !mi(r502a) //& r1001b1 != 0

* Main village road has lighting provided by govt. electricity

gen rd_light_gov = inlist(r502a,1,2) & r502b == 1 ///
	if !mi(r502a) //& r1001b1 != 0
gen rd_light_nongov = inlist(r502a,1,2) & r502b == 2 ///
	if !mi(r502a) //& r1001b1 != 0

* Household electricity access

ren r501a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r501b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)

* Waste disposal

gen garbage_collect = r504b == 1 if !mi(r504b)
	la var garbage_collect "Gabage disposed using bins that are transported"
	
gen toilet = inrange(r505a,1,3) if !mi(r505a)
	la var toilet "Most families defecate in a toilet (private, shared, public)"

gen absorp_pit = r506 == 1 if !mi(r506)	
	la var absorp_pit "Most families dispose of wastewater in absorption pit"

* Safe water

gen safe_drink_water = inrange(r507a,1,4) if !mi(r507a) 
	la var safe_drink_water "Access to safe drinking water"

gen safe_bath_water = inrange(r507b,1,2) if !mi(r507b) 
	la var safe_bath_water "Access to safe bathing water"
	
* River

gen river = r509ak2 == 1 if !mi(r509ak2)
	la var river "Existence of a river"
	
* Irrigation canal

gen irrigation = r509ak3 == 1 if !mi(r509ak3)
	la var irrigation "Existence of an irrigation canal"
	
* Reservoir	

gen reservoir = r509ak5 == 1 if !mi(r509ak5)
	la var reservoir "Existence of a reservoir"	
	
* Diversity

gen multi_ethnic = r804a1 == 1 if !mi(r804a1)
	la var multi_ethnic "Multiple ethnic groups in village"

gen eth_code_majority   = r804a2a
	la var eth_code_majority "Code of majority ethnicity"
gen eth_code_2ndbiggest = r804a2b
	la var eth_code_2ndbiggest "Code of 2nd biggest ethnicity"
gen eth_code_3rdbiggest = r804a2c
	la var eth_code_3rdbiggest "Code of 3rd biggest ethnicity"
	replace eth_code_3rdbiggest = "" if eth_code_3rdbiggest == "*"
	destring eth_code_3rdbiggest, replace
	
gen multi_lang = r804b1 == 1 if !mi(r804b1)
	la var multi_lang "Multiple languages spoke in village"

gen lang_code_majority = r804b2
	la var lang_code_majority "Code of majority language"
	
* Entertainment

gen pub = r902a == 1 if !mi(r902a)
	la var pub "Existence of functioning pub/discotheque/karaoke venue"

* Phone, internet, TV

gen n_hh_phn = r1003a

gen internet = r1004 == 1 if !mi(r1004)   
gen internet_head = inlist(r1006b,1,2) if !mi(r1006b)    
	// internet facility in office of village head
gen TVRI 	 = r1008ak2 == 1 if !mi(r1008ak2) 
gen locTV 	 = r1008bk2 == 1 if !mi(r1008bk2) 
gen natcomTV = r1008ck2 == 1 if !mi(r1008ck2) 
gen forTV 	 = r1008dk2 == 1 if !mi(r1008dk2) 
gen mblphn   = inlist(r1005c,1,2,3) if !mi(r1005c) 
gen mblphn_strng = inlist(r1005c,1,2) if !mi(r1005c)

* Fight against govt

gen fight_sec = 0
replace fight_sec = r1301b3k2 if r1301a == 1 

gen fight_state = 0
replace fight_state = r1301b4k2 if r1301a == 1 

* Corruption

gen corruption = r1303a11k3 == 1 if !mi(r1303a11k3)
	la var corruption "Corruption event occurred in village in last year"

* Police

local x	r1306a
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"
	
* Distance to district capital

local x r1002bk5
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"
	
local x r1002dk5
gen dist_nearest_distr_cap = `x' if `x' < 998
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"

** Characteristics of village officials **
	* Village head
	* Village secretary	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1701`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1701`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1701`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1701`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}

** Village administration **

gen n_vlg_officials = r1702a + r1702b + r1702c //+ r1702d
	la var n_vlg_officials "Number of village officials"
	
gen n_regul_vlg = r1405c	
gen n_regul_vlghead = r1405d

la var n_regul_vlg "Number of village regulations in previous year"
la var n_regul_vlghead "Number of village head regulations in previous year"

* For crosswalk

gen nm2018 = desa

qui do "$aux/standardize_nm2018"

gen nm2018_1 = desa

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2018 id2018_1 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

gen bps_2018 = string(prov_id) + regstr
destring bps_2018, replace

drop regstr kecstr desastr

* Tweak village names to facilitate merge
	* Will merge on names in cases where crosswalk is incomplete
	
replace nm2018_1 = "ALUE BU/ALUE LHOK" ///
	if nm2018_1 == "ALUE BU ALUE LHOK" & id2018_1 == 1105111006
replace nm2018_1 = "SEUMALY" ///
	if nm2018_1 == "SEUMALI" & id2018_1 == 1105120012
replace nm2018_1 = "SNB DALAM" ///
	if nm2018_1 == "SEUNEUBOK DALAM" & id2018_1 == 1105120019
replace nm2018_1 = "BUKET RUMIYA" ///
	if nm2018_1 == "BUKET RUMIA" & id2018_1 == 1105140009
replace nm2018_1 = "KEUDE IDI CUT" ///
	if nm2018_1 == "PEUKAN IDI CUT" & id2018_1 == 1105140038
replace nm2018_1 = "PINEUNG SIRI BEE" ///
	if nm2018_1 == "PINEUNG SIRIBEE" & id2018_1 == 1110010073
replace nm2018_1 = "CURE TUNONG" ///
	if nm2018_1 == "CUREE TUNONG" & id2018_1 == 1110011032
replace nm2018_1 = "LAIWO JAYA" ///
	if nm2018_1 == "LAYWO JAYA" & id2018_1 == 7412020006
replace nm2018_1 = "BARUTA ANALAKI" ///
	if nm2018_1 == "BARUTA ANALALAKI" & id2018_1 == 7414070006
replace nm2018_1 = "BONE MARAMBE" ///
	if nm2018_1 == "BONEMARAMBE" & id2018_1 == 7414040003	
replace nm2018_1 = "JAYABAKTI" ///
	if nm2018_1 == "JAYA BAKTI" & id2018_1 == 7415030009

* Tidying

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa type vlg_consult* vlghead* vlgsec* n_* any_hh* *_avail ///
	  dist_* easy_* rd_* pub_trans garbage* toilet absorp* safe* ///
	  irrig* reservoir police safe* multi_ethnic eth_code* multi_lang lang_code* ///
	  pub main_income* internet internet_head TVRI locTV natcomTV forTV mblphn ///
	  mblphn_strng fight_sec fight_state corrupt* outbreak* deaths* vic* ///
	  ind_center small_ind_area topog forest coastal dist_*_cap river 
	  
drop r302a-r1702d
drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	ren `v' `v'_2018
}

foreach v of varlist type-river {
	ren `v' `v'_2018
}

format %10.0f id2018*  

save "$work/podes2018.dta", replace

********************************************************************************
**# 2019
* 2019
********************************************************************************

** Merging raw data **

import dbase "$podes_raw/PODES 2019/podes_2019_b1b8", clear case(lower)
tempfile d1
save `d1'

import dbase "$podes_raw/PODES 2019/podes_2019_b9b13", clear case(lower)
tempfile d2
save `d2'

use `d1'
merge 1:1 r101 r102 r103 r104 using `d2', nogenerate

foreach v of varlist * {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren r101  prov_id
ren r101n province
ren r102  region_id
ren r102n region
ren r103  kec_id
ren r103n kec
ren r104  desa_id
ren r104n desa

* Raw PODES code (unique)
gen double id_podes2019 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2019
isid id_podes2019
la var id_podes2019 "PODES 2019 code (raw file)"
gen nm_podes2019 = desa
la var nm_podes2019 "PODES 2019 name (raw file)"

ren r107 type
	recode type (3 = 6) (4 = 3)
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"
	
** Generating social and infrastructure variables **

* Doctors, midwives, health facilities
	* Missing personnel

gen n_hosp = r502ak2
gen n_hosp_mat = r502bk2
gen n_puskesmas = r502ck2 + r502dk2 + r502ek2 
gen n_poliklinik = r502fk2
gen n_dr_off = r502gk2
gen n_mwiv_off = r502ik2
gen n_poskesdes = r502jk2
gen n_polindes = r502kk2
gen n_pharm = r502lk2
gen n_posyandu = r502n

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)	

* Disease outbreaks

gen outbreak_diar = r1206ak2 == 1 if !mi(r1206ak2)
gen outbreak_deng = r1206bk2 == 1 if !mi(r1206bk2)
gen outbreak_meas = r1206ck2 == 1 if !mi(r1206ck2)
gen outbreak_mala = r1206dk2 == 1 if !mi(r1206dk2)
gen outbreak_avia = r1206ek2 == 1 if !mi(r1206ek2)
gen outbreak_hepe = r1206fk2 == 1 if !mi(r1206fk2)
gen outbreak_diph = r1206gk2 == 1 if !mi(r1206gk2)
gen outbreak_othr = r1206hk2 == 1 if !mi(r1206hk2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_hepe "Hepatitis E outbreak during the past year"
la var outbreak_diph "Diphtheria outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r1206ak2 == 2
replace deaths_diar = r1206ak4 if r1206ak2 == 1

gen deaths_deng = 0 if r1206bk2 == 2
replace deaths_deng = r1206bk4 if r1206bk2 == 1

gen deaths_meas = 0 if r1206ck2 == 2
replace deaths_meas = r1206ck4 if r1206ck2 == 1

gen deaths_mala = 0 if r1206dk2 == 2
replace deaths_mala = r1206dk4 if r1206dk2 == 1

gen deaths_avia = 0 if r1206ek2 == 2
replace deaths_avia = r1206ek4 if r1206ek2 == 1

gen deaths_hepe = 0 if r1206fk2 == 2
replace deaths_hepe = r1206fk4 if r1206fk2 == 1

gen deaths_diph = 0 if r1206gk2 == 2
replace deaths_diph = r1206gk4 if r1206gk2 == 1

gen deaths_othr = 0 if r1206hk2 == 2
replace deaths_othr = r1206hk4 if r1206hk2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r1207
la var victims_malnutr "Number of malnutrition victims in 2018"

* Schools 

gen n_schl_kind_pub  = r501ak2 + r501bk2
gen n_schl_prm_pub   = r501ck2 + r501dk2
gen n_schl_jrsec_pub = r501ek2 + r501fk2
gen n_schl_srsec_pub = r501gk2 + r501hk2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r501ak3 + r501bk3
gen n_schl_prm_prv   = r501ck3 + r501dk3
gen n_schl_jrsec_prv = r501ek3 + r501fk3
gen n_schl_srsec_prv = r501gk3 + r501hk3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

gen n_schl_pre = r1205 if !mi(r1205)

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = n_schl_pre > 0 if !mi(n_schl_pre)
la var schl_pre_avail "Preschool in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

local x b
local type hosp_mat
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

gen dist_puskesmas = min(r502ck3,r502dk3,r502ek3) ///
	if !mi(r502ck3) | !mi(r502dk3) | !mi(r502ek3)
gen easy_puskesmas = max( inlist(r502ck4,1,2), inlist(r502dk4,1,2), ///
						  inlist(r502ek4,1,2) ) ///
	if !mi(r502ck4) | !mi(r502dk4) | !mi(r502ek4)			  

local x f
local type poliklinik
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)
						  
local x g
local type dr_off
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

local x i
local type mwiv_off
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

local x j
local type poskesdes
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

local x k
local type polindes
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

local x l
local type pharm
gen dist_`type' = r502`x'k3
gen easy_`type' = inlist(r502`x'k4,1,2) if !mi(r502`x'k4)

local type kind
gen dist_schl_`type'_pub = min(r501ak4,r501bk4)
gen easy_schl_`type'_pub = inlist(r501ak5,1,2) | inlist(r501bk5,1,2) ///
	if !mi(r501ak5) | !mi(r501bk5)

local type prm
gen dist_schl_`type'_pub = min(r501ck4,r501dk4)
gen easy_schl_`type'_pub = inlist(r501ck5,1,2) | inlist(r501dk5,1,2) ///
	if !mi(r501ck5) | !mi(r501dk5)
	
local type jrsec
gen dist_schl_`type'_pub = min(r501ek4,r501fk4)
gen easy_schl_`type'_pub = inlist(r501ek5,1,2) | inlist(r501fk5,1,2) ///
	if !mi(r501ek5) | !mi(r501fk5)	
	
local type srsec
gen dist_schl_`type'_pub = min(r501gk4,r501hk4)
gen easy_schl_`type'_pub = inlist(r501gk5,1,2) | inlist(r501hk5,1,2) ///
	if !mi(r501gk5) | !mi(r501hk5)	

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)
gen easy_schl_sec_pub = max(easy_schl_jrsec_pub,easy_schl_srsec_pub)

* Roads

gen rd_asph = r701b1 == 1 if !mi(r701b1) & r701b1 != 0
gen rd_grvl = r701b1 == 2 if !mi(r701b1) & r701b1 != 0
gen rd_dirt = r701b1 == 3 if !mi(r701b1) & r701b1 != 0
gen rd_othr = r701b1 == 4 if !mi(r701b1) & r701b1 != 0

gen rd_pass = r701b2 == 1 if !mi(r701b2) & r701b2 != 0

* Public transportation

gen pub_trans = inlist(r701c1,1,2) if !mi(r701c1)
	la var pub_trans "Existence of public transportation"

* Main village road has electric lighting

gen rd_light = inlist(r402a,1,2) & inlist(r402b,1,2) ///
	if !mi(r402a) //& r701b1 != 0

* Main village road has lighting provided by govt. electricity

gen rd_light_gov = inlist(r402a,1,2) & r402b == 1 ///
	if !mi(r402a) //& r701b1 != 0
gen rd_light_nongov = inlist(r402a,1,2) & r402b == 2 ///
	if !mi(r402a) //& r701b1 != 0
	
* Cooperatives

gen n_coop_kud 	  = r803a if !inlist(r803a,98,99)
gen n_coop_smmanu = r803b if !inlist(r803b,98,99)
gen n_coop_save   = r803c if !inlist(r803c,98,99)
gen n_coop_othr   = r803d if !inlist(r803d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"	

* Markets

gen n_shop_cntr = r801ak2 if !inlist(r801ak2,98,99)
gen shop_cntr_avail = n_shop_cntr > 0 if !mi(n_shop_cntr)

gen n_mkt_perm = r801bk2 + r801ck2 ///
	if !inlist(r801bk2,98,99) & !inlist(r801ck2,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r801dk2 if !inlist(r801dk2,98,99)

la var n_shop_cntr "Number of shopping centers"
la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r801ek2
gen n_restaur = r801fk2 if !inlist(r801fk2,98,99)
gen n_foodstall = r801gk2 if !inlist(r801gk2,998,999)
gen n_hotel = r801hk2 if !inlist(r801hk2,98,99)
gen n_motel = r801ik2 if !inlist(r801ik2,98,99)
gen n_cornerstore = r801jk2 if !inlist(r801jk2,998,999)

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"
la var n_cornerstore "Number of corner stores"

* Banks

gen n_bank_com_gov = r802a if !inlist(r802a,98,99)
gen n_bank_com_prv = r802b if !inlist(r802b,98,99)
gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = r802c if !inlist(r802c,98,99)

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Household electricity access

ren r401a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r401a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r401b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)

* Waste disposal

gen toilet = inrange(r405a,1,3) if !mi(r405a)
	la var toilet "Most families defecate in a toilet (private, shared, public)"	
	
* Safe water

gen safe_drink_water = inrange(r404,1,4) if !mi(r404) 
	la var safe_drink_water "Access to safe drinking water"

gen safe_bath_water = inrange(r1301,1,2) if !mi(r1301) 
	la var safe_bath_water "Access to safe bathing water"

* River

gen river = r407 == 1 if !mi(r407)
	la var river "Existence of a river"
	
* Reservoir	

gen reservoir = r1202 == 1 if !mi(r1202)
	la var reservoir "Existence of a reservoir"	
	
* Entertainment

gen pub = r602 == 1 if !mi(r602)
	la var pub "Existence of functioning pub/discotheque/karaoke venue"	
	
* Phone, internet, TV

gen n_hh_phn = r703a
gen internet = r704 == 1 if !mi(r704)
gen internet_head = inlist(r706,1,2) if !mi(r706)
gen mblphn   	 = inlist(r705c,1,2,3) if !mi(r705c) 
gen mblphn_strng = inlist(r705c,1,2) if !mi(r705c)

* Corruption

gen corruption = r110304k3 == 1 if !mi(r110304k3)
	la var corruption "Corruption event occurred in village in last year"

** Characteristics of village officials **
	* Village head
	* Village secretary	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r901`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r901`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r901`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r901`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}

** Village administration **

gen n_vlg_officials = r1303a + r1303b + r1303c
	la var n_vlg_officials "Number of village officials"
	
** Village public finance **

ren r1305 rev_pad
	format %12.0fc rev_pad
	la var rev_pad "Own-Source Revenue (Pendapatan Asli Desa) (IDR millions)"

* For crosswalk

gen nm2019 = desa

qui do "$aux/standardize_nm2019"

gen nm2019_1 = nm2019

tostring prov_id, gen(provstr)
tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2019 id2019_1 {
	gen `v' = provstr + regstr + kecstr + desastr
	destring `v', replace
}

gen bps_2019 = provstr + regstr
destring bps_2019, replace

drop provstr regstr kecstr desastr

* Tidying

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa rev* type vlghead* vlgsec* n_* any_hh* *_avail dist_* easy_* ///
	  rd_* pub_trans toilet safe* reservoir pub internet internet_head mblphn ///
	  mblphn_strng corrupt* outbreak* deaths* vic* river 

drop r402a-r1304c 	  
drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	ren `v' `v'_2019
}

foreach v of varlist type-river {
	ren `v' `v'_2019
}

ren rev_pad rev_pad_2018

format %10.0f id2019*

save "$work/podes2019.dta", replace

********************************************************************************
**# 2020
* 2020
********************************************************************************

** Merging raw data **

import dbase "$podes_raw/PODES 2020/podes2020_b1b7", clear case(lower)
tempfile d1
save `d1'

import dbase "$podes_raw/PODES 2020/podes2020_b8b13", clear case(lower)
tempfile d2
save `d2'

use `d1'
merge 1:1 r101 r102 r103 r104 using `d2', nogenerate

foreach v of varlist * {
	cap destring `v', replace
}

** Renaming geographic names/IDs **

ren r101  prov_id
ren r101n province
ren r102  region_id
ren r102n region
ren r103  kec_id
ren r103n kec
ren r104  desa_id
ren r104n desa

* Raw PODES code (unique)
gen double id_podes2020 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2020
isid id_podes2020
la var id_podes2020 "PODES 2020 code (raw file)"
gen nm_podes2020 = desa
la var nm_podes2020 "PODES 2020 name (raw file)"

ren r301 type
	recode type (3 = 6) (4 = 3)
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}

** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"
	
** Generating social and infrastructure variables **

* Doctors, midwives, health facilities
	* Missing personnel	

gen n_hosp = r603ak2
gen n_hosp_mat = r603bk2
gen n_puskesmas = r603ck2 + r603dk2 + r603ek2 
gen n_poliklinik = r603fk2
gen n_dr_off = r603gk2
gen n_mwiv_off = r603ik2
gen n_poskesdes = r603jk2
gen n_polindes = r603kk2
gen n_pharm = r603lk2
gen n_posyandu = r603nk2

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)	

* Disease outbreaks

gen outbreak_diar = r605ak2 == 1 if !mi(r605ak2)
gen outbreak_deng = r605bk2 == 1 if !mi(r605bk2)
gen outbreak_meas = r605ck2 == 1 if !mi(r605ck2)
gen outbreak_mala = r605dk2 == 1 if !mi(r605dk2)
gen outbreak_avia = r605ek2 == 1 if !mi(r605ek2)
gen outbreak_hepe = r605fk2 == 1 if !mi(r605fk2)
gen outbreak_diph = r605gk2 == 1 if !mi(r605gk2)
gen outbreak_covd = r605hk2 == 1 if !mi(r605hk2)
gen outbreak_othr = r605ik2 == 1 if !mi(r605ik2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_hepe "Hepatitis E outbreak during the past year"
la var outbreak_diph "Diphtheria outbreak during the past year"
la var outbreak_covd "COVID-19 outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r605ak2 == 2
replace deaths_diar = r605ak4 if r605ak2 == 1

gen deaths_deng = 0 if r605bk2 == 2
replace deaths_deng = r605bk4 if r605bk2 == 1

gen deaths_meas = 0 if r605ck2 == 2
replace deaths_meas = r605ck4 if r605ck2 == 1

gen deaths_mala = 0 if r605dk2 == 2
replace deaths_mala = r605dk4 if r605dk2 == 1

gen deaths_avia = 0 if r605ek2 == 2
replace deaths_avia = r605ek4 if r605ek2 == 1

gen deaths_hepe = 0 if r605fk2 == 2
replace deaths_hepe = r605fk4 if r605fk2 == 1

gen deaths_diph = 0 if r605gk2 == 2
replace deaths_diph = r605gk4 if r605gk2 == 1

gen deaths_covd = 0 if r605hk2 == 2
replace deaths_covd = r605hk4 if r605hk2 == 1

gen deaths_othr = 0 if r605ik2 == 2
replace deaths_othr = r605ik4 if r605ik2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r604
la var victims_malnutr "Number of malnutrition victims in 2019"

* Schools

gen n_schl_pre_pub   = r601ak2
gen n_schl_kind_pub  = r601bk2 + r601ck2
gen n_schl_prm_pub   = r601dk2 + r601ek2
gen n_schl_jrsec_pub = r601fk2 + r601gk2
gen n_schl_srsec_pub = r601hk2 + r601ik2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_pre_prv   = r601ak3
gen n_schl_kind_prv  = r601bk3 + r601ck3
gen n_schl_prm_prv   = r601dk3 + r601ek3
gen n_schl_jrsec_prv = r601fk3 + r601gk3
gen n_schl_srsec_prv = r601hk3 + r601ik3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in pre kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = n_schl_pre > 0 if !mi(n_schl_pre)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r602 == 1 if !mi(r602)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x b
local type hosp_mat
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

gen dist_puskesmas = min(r603ck3,r603dk3,r603ek3) ///
	if !mi(r603ck3) | !mi(r603dk3) | !mi(r603ek3)
gen easy_puskesmas = max( inlist(r603ck4,1,2), inlist(r603dk4,1,2), ///
						  inlist(r603ek4,1,2) ) ///
	if !mi(r603ck4) | !mi(r603dk4) | !mi(r603ek4)			  

local x f
local type poliklinik
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)
						  
local x g
local type dr_off
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x i
local type mwiv_off
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x j
local type poskesdes
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x k
local type polindes
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local x l
local type pharm
gen dist_`type' = r603`x'k3
gen easy_`type' = inlist(r603`x'k4,1,2) if !mi(r603`x'k4)

local type kind
gen dist_schl_`type'_pub = min(r601bk4,r601ck4)
gen easy_schl_`type'_pub = inlist(r601bk5,1,2) | inlist(r601ck5,1,2) ///
	if !mi(r601bk5) | !mi(r601ck5)

local type prm
gen dist_schl_`type'_pub = min(r601dk4,r601ek4)
gen easy_schl_`type'_pub = inlist(r601dk5,1,2) | inlist(r601ek5,1,2) ///
	if !mi(r601dk5) | !mi(r601ek5)
	
local type jrsec
gen dist_schl_`type'_pub = min(r601fk4,r601gk4)
gen easy_schl_`type'_pub = inlist(r601fk5,1,2) | inlist(r601gk5,1,2) ///
	if !mi(r601fk5) | !mi(r601gk5)	
	
local type srsec
gen dist_schl_`type'_pub = min(r601hk4,r601ik4)
gen easy_schl_`type'_pub = inlist(r601hk5,1,2) | inlist(r601ik5,1,2) ///
	if !mi(r601hk5) | !mi(r601ik5)	

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)
gen easy_schl_sec_pub = max(easy_schl_jrsec_pub,easy_schl_srsec_pub)

* Roads

gen rd_asph = r801b1 == 1 if !mi(r801b1) & r801b1 != 0
gen rd_grvl = r801b1 == 2 if !mi(r801b1) & r801b1 != 0
gen rd_dirt = r801b1 == 3 if !mi(r801b1) & r801b1 != 0
gen rd_othr = r801b1 == 4 if !mi(r801b1) & r801b1 != 0

gen rd_pass = r801b2 == 1 if !mi(r801b2)  & r801b2 != 0

* Small manufacturing establishments

gen n_estab_sm_leather 	= r901a if !inlist(r901a,998,999)
gen n_estab_sm_wood 	= r901b if !inlist(r901b,998,999)
gen n_estab_sm_metal 	= r901c if !inlist(r901c,998,999)
gen n_estab_sm_fabric 	= r901d if !inlist(r901d,998,999)
gen n_estab_sm_pottery 	= r901e if !inlist(r901e,998,999)
gen n_estab_sm_woven 	= r901f if !inlist(r901f,998,999)
gen n_estab_sm_foodbev 	= r901g if !inlist(r901g,998,999)
gen n_estab_sm_other 	= r901h if !inlist(r901h,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"

* Cooperatives

gen n_coop_kud 	  = r904a if !inlist(r904a,98,99)
gen n_coop_smmanu = r904b if !inlist(r904b,98,99)
gen n_coop_save   = r904c if !inlist(r904c,98,99)
gen n_coop_othr   = r904d if !inlist(r904d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Markets

gen n_shop_cntr = r906ak2 if !inlist(r906ak2,98,99)
gen shop_cntr_avail = n_shop_cntr > 0 if !mi(n_shop_cntr)

gen n_mkt_perm = r906bk2 + r906ck2 ///
	if !inlist(r906bk2,98,99) & !inlist(r906ck2,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r906dk2 if !inlist(r906dk2,98,99)

la var n_shop_cntr "Number of shopping centers"
la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r906ek2
gen n_restaur = r906fk2 if !inlist(r906fk2,98,99)
gen n_foodstall = r906gk2 if !inlist(r906gk2,998,999)
gen n_hotel = r906hk2 if !inlist(r906hk2,98,99)
gen n_motel = r906ik2 if !inlist(r906ik2,98,99)
gen n_cornerstore = r906jk2 if !inlist(r906jk2,998,999)

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"
la var n_cornerstore "Number of corner stores"

* Banks

gen n_bank_com_gov = r903ak2 if !inlist(r903ak2,98,99)
gen n_bank_com_prv = r903bk2 if !inlist(r903bk2,98,99)
gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = r903ck2 if !inlist(r903ck2,98,99)

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Public transportation

gen pub_trans = inlist(r801c1,1,2) if !mi(r801c1)
	la var pub_trans "Existence of public transportation"

* Main village road has electric lighting

gen rd_light = inlist(r502a,1,2) & inlist(r502b,1,2) ///
	if !mi(r502a) //& r801b1 != 0

* Main village road has lighting provided by govt. electricity

gen rd_light_gov = inlist(r502a,1,2) & r502b == 1 ///
	if !mi(r502a) //& r801b1 != 0
gen rd_light_nongov = inlist(r502a,1,2) & r502b == 2 ///
	if !mi(r502a) //& r801b1 != 0

* Household electricity access

ren r501a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r501b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)
	
* Waste disposal

gen garbage_collect = r504b == 1 if !mi(r504b)
	la var garbage_collect "Gabage disposed using bins that are transported"	
	
gen toilet = inrange(r507a,1,3) if !mi(r507a)
	la var toilet "Most families defecate in a toilet (private, shared, public)"

* Safe water

gen safe_drink_water = inrange(r508,1,4) if !mi(r508) 
	la var safe_drink_water "Access to safe drinking water"	
	
gen safe_bath_water = inrange(r509,1,2) if !mi(r509) 
	la var safe_bath_water "Access to safe bathing water"
	
* Reservoir	

gen reservoir = r511 == 1 if !mi(r511)
	la var reservoir "Existence of a reservoir"	
	
* Entertainment

gen pub = r702 == 1 if !mi(r702)
	la var pub "Existence of functioning pub/discotheque/karaoke venue"	
	
* River

gen river = r510 == 1 if !mi(r510)
	la var river "Existence of a river"

* Phone, internet, TV

gen n_hh_phn = r803a
gen internet = r804 == 1 if !mi(r804)
gen internet_head = inlist(r806b,1,2) if !mi(r806b)
gen mblphn   	 = inlist(r805c,1,2,3) if !mi(r805c) 
gen mblphn_strng = inlist(r805c,1,2) if !mi(r805c)	

* Corruption

gen corruption = r100404k3 == 1 if !mi(r100404k3)
	la var corruption "Corruption event occurred in village in last year"

** Characteristics of village officials **
	* Village head
	* Village secretary	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1301`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1301`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1301`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1301`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}	

** Village administration **
	// fewer types of govt officials listed -- not comparable to 2019 & earlier

//gen n_vlg_officials = r1302a + r1302b 
//	la var n_vlg_officials "Number of village officials"

* For crosswalk

gen nm2020 = desa
gen nm2020_1 = desa
gen nm2020_2 = desa

tostring prov_id, gen(provstr)
tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2020 id2020_1 id2020_2 {
	gen `v' = provstr + regstr + kecstr + desastr
	destring `v', replace
}

gen bps_2020 = provstr + regstr
destring bps_2020, replace

drop provstr regstr kecstr desastr

* Tidying

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa type vlghead* vlgsec* n_* any_hh* *_avail dist_* easy_* rd_* ///
	  pub_trans garbage* toilet safe* reservoir pub internet internet_head ///
	  mblphn mblphn_strng corrupt* outbreak* deaths* vic* river 

drop r107a-r1302b	  
drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	ren `v' `v'_2020
}

foreach v of varlist type-river {
	ren `v' `v'_2020
}

format %10.0f id2020*

save "$work/podes2020.dta", replace
	
********************************************************************************
**# 2021
* 2021
********************************************************************************

** Merging raw data **

forval n = 1/4 {
	tempfile d`n'
	import dbase "$podes_raw/PODES 2021/podes2021_desa_`n'", ///
		clear case(lower)
	save `d`n''
}

use `d1'
merge 1:1 r101 r102 r103 r104 using `d2', nogenerate
merge 1:1 r101 r102 r103 r104 using `d3', nogenerate
merge 1:1 r101 r102 r103 r104 using `d4', nogenerate

foreach v of varlist * {
	cap destring `v', replace
}
	
** Renaming geographic names/IDs **

ren r101  prov_id
ren r101n province
ren r102  region_id
ren r102n region
ren r103  kec_id
ren r103n kec
ren r104  desa_id
ren r104n desa

* Raw PODES code (unique)
gen double id_podes2021 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2021
isid id_podes2021
la var id_podes2021 "PODES 2021 code (raw file)"
gen nm_podes2021 = desa
la var nm_podes2021 "PODES 2021 name (raw file)"

ren r105 status
	la var status "Urban/Rural Status"
	la def status 1 "Urban" 2 "Rural"
	la val status status

ren r301 type
	recode type (3 = 6) (4 = 3)
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type
	
gen vlg_consult = r1603a == 1 if !mi(r1603a)
	la var vlg_consult "Presence of a Village Consultative Body"
	
ren r305a topog
	la var topog "Topography"
	la def topog 1 "Peak/Cliff" 2 "Slope" 3 "Plain" 4 "Valley"
	la val topog topog	

gen coastal = r308a == 1 if !mi(r308a)
	la var coastal "Village is adjacent to sea"	
	
ren r309a forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest	
	
foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}	

** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"

** Generating social and infrastructure variables **

* Doctors, midwives, health facilities

gen n_dr = r706a1 + r706a2
gen n_dent = r706b
gen n_mwiv_all = r706c
gen n_hosp = r704ak2
gen n_hosp_mat = r704bk2
gen n_puskesmas = r704ck2 + r704dk2 + r704ek2 
gen n_poliklinik = r704fk2
gen n_dr_off = r704gk2
gen n_mwiv_off = r704ik2
gen n_poskesdes = r704jk2
gen n_polindes = r704kk2
gen n_posyandu = r705b + r705c
gen n_pharm = r704lk2

gen n_heal_cntr  = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen mwiv_BDD_avail = r707 == 1 if !mi(r707)

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)
gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Disease outbreaks

gen outbreak_diar = r709ak2 == 1 if !mi(r709ak2)
gen outbreak_deng = r709bk2 == 1 if !mi(r709bk2)
gen outbreak_meas = r709ck2 == 1 if !mi(r709ck2)
gen outbreak_mala = r709dk2 == 1 if !mi(r709dk2)
gen outbreak_avia = r709ek2 == 1 if !mi(r709ek2)
gen outbreak_hepe = r709fk2 == 1 if !mi(r709fk2)
gen outbreak_diph = r709gk2 == 1 if !mi(r709gk2)
gen outbreak_covd = r709hk2 == 1 if !mi(r709hk2)
gen outbreak_othr = r709ik2 == 1 if !mi(r709ik2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_hepe "Hepatitis E outbreak during the past year"
la var outbreak_diph "Diphtheria outbreak during the past year"
la var outbreak_covd "COVID-19 outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r709ak2 == 2
replace deaths_diar = r709ak4 if r709ak2 == 1

gen deaths_deng = 0 if r709bk2 == 2
replace deaths_deng = r709bk4 if r709bk2 == 1

gen deaths_meas = 0 if r709ck2 == 2
replace deaths_meas = r709ck4 if r709ck2 == 1

gen deaths_mala = 0 if r709dk2 == 2
replace deaths_mala = r709dk4 if r709dk2 == 1

gen deaths_avia = 0 if r709ek2 == 2
replace deaths_avia = r709ek4 if r709ek2 == 1

gen deaths_hepe = 0 if r709fk2 == 2
replace deaths_hepe = r709fk4 if r709fk2 == 1

gen deaths_diph = 0 if r709gk2 == 2
replace deaths_diph = r709gk4 if r709gk2 == 1

gen deaths_covd = 0 if r709hk2 == 2
replace deaths_covd = r709hk4 if r709hk2 == 1

gen deaths_othr = 0 if r709ik2 == 2
replace deaths_othr = r709ik4 if r709ik2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r710
la var victims_malnutr "Number of malnutrition victims in 2020"

* Proxies for number of poor people

gen n_sktm = r711
la var n_sktm "Number of poverty letters/SKTM issued by village in 2020"	

* Food insecurity

gen any_foodinsec = r709jk2 == 1 if !mi(r709jk2)

gen n_foodinsec = 0 if r709jk2 == 2
replace n_foodinsec = r709jk3 if r709jk2 == 1

gen deaths_foodinsec = 0 if r709jk2 == 2
replace deaths_foodinsec = r709jk4 if r709jk2 == 1

la var any_foodinsec "Any villagers faced food insecurity during the past year"
la var n_foodinsec ///
	"Number of villagers who faced food insecurity during the past year"
la var deaths_foodinsec "Deaths food insecurity during the past year"	

* Schools 

gen n_schl_pre_pub   = r701ak2
gen n_schl_kind_pub  = r701bk2 + r701ck2
gen n_schl_prm_pub   = r701dk2 + r701ek2
gen n_schl_jrsec_pub = r701fk2 + r701gk2
gen n_schl_srsec_pub = r701hk2 + r701ik2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_pre_prv   = r701ak3
gen n_schl_kind_prv  = r701bk3 + r701ck3
gen n_schl_prm_prv   = r701dk3 + r701ek3
gen n_schl_jrsec_prv = r701fk3 + r701gk3
gen n_schl_srsec_prv = r701hk3 + r701ik3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in pre kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = n_schl_pre > 0 if !mi(n_schl_pre)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r702c == 5 if !mi(r702c)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

local x b
local type hosp_mat
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

gen dist_puskesmas = min(r704ck3,r704dk3,r704ek3) ///
	if !mi(r704ck3) | !mi(r704dk3) | !mi(r704ek3)
gen easy_puskesmas = max( inlist(r704ck7,1,2), inlist(r704dk7,1,2), ///
						  inlist(r704ek7,1,2) ) ///
	if !mi(r704ck7) | !mi(r704dk7) | !mi(r704ek7)			  

local x f
local type poliklinik
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)
						  
local x g
local type dr_off
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

local x i
local type mwiv_off
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

local x j
local type poskesdes
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

local x k
local type polindes
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

local x l
local type pharm
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k7,1,2) if !mi(r704`x'k7)

local type kind
gen dist_schl_`type'_pub = min(r701bk4,r701ck4)
gen easy_schl_`type'_pub = inlist(r701bk8,1,2) | inlist(r701ck8,1,2) ///
	if !mi(r701bk8) | !mi(r701ck8)

local type prm
gen dist_schl_`type'_pub = min(r701dk4,r701ek4)
gen easy_schl_`type'_pub = inlist(r701dk8,1,2) | inlist(r701ek8,1,2) ///
	if !mi(r701dk8) | !mi(r701ek8)
	
local type jrsec
gen dist_schl_`type'_pub = min(r701fk4,r701gk4)
gen easy_schl_`type'_pub = inlist(r701fk8,1,2) | inlist(r701gk8,1,2) ///
	if !mi(r701fk8) | !mi(r701gk8)	
	
local type srsec
gen dist_schl_`type'_pub = min(r701hk4,r701ik4)
gen easy_schl_`type'_pub = inlist(r701hk8,1,2) | inlist(r701ik8,1,2) ///
	if !mi(r701hk8) | !mi(r701ik8)	

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)
gen easy_schl_sec_pub = max(easy_schl_jrsec_pub,easy_schl_srsec_pub)

* Roads

gen rd_asph = r1001b1 == 1 if !mi(r1001b1)
gen rd_grvl = r1001b1 == 2 if !mi(r1001b1)
gen rd_dirt = r1001b1 == 3 if !mi(r1001b1)
gen rd_othr = r1001b1 == 4 if !mi(r1001b1)

gen rd_pass = r1001b2 == 1 if !mi(r1001b2)

local var r403c1
gen rd_connect_asph = `var' == 1 if !mi(`var')
gen rd_connect_grvl = `var' == 2 if !mi(`var')
gen rd_connect_dirt = `var' == 3 if !mi(`var')
gen rd_connect_othr = inrange(`var',4,5) if !mi(`var')
	/*
	Road surface type from production center / agricultural land to the village 
	main road 
	*/
	
* Public transportation

gen pub_trans = inlist(r1001c1,1,2) if !mi(r1001c1)
	la var pub_trans "Existence of public transportation"

* Main source of income

local var r403a
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')

* Small manufacturing establishments

gen n_estab_sm_leather 	= r1201a if !inlist(r1201a,998,999)
gen n_estab_sm_wood 	= r1201b if !inlist(r1201b,998,999)
gen n_estab_sm_metal 	= r1201c if !inlist(r1201c,998,999)
gen n_estab_sm_textile 	= r1201d if !inlist(r1201d,998,999)
gen n_estab_sm_cloth 	= r1201e if !inlist(r1201e,998,999)
gen n_estab_sm_pottery 	= r1201f if !inlist(r1201f,998,999)
gen n_estab_sm_woven 	= r1201g if !inlist(r1201g,998,999)
gen n_estab_sm_food 	= r1201h if !inlist(r1201h,998,999)
gen n_estab_sm_bev	 	= r1201i if !inlist(r1201i,998,999)
gen n_estab_sm_tobacc 	= r1201j if !inlist(r1201j,998,999)
gen n_estab_sm_paper 	= r1201k if !inlist(r1201k,998,999)
gen n_estab_sm_print 	= r1201l if !inlist(r1201l,998,999)
gen n_estab_sm_trans 	= r1201m if !inlist(r1201m,998,999)
gen n_estab_sm_craft 	= r1201n if !inlist(r1201n,998,999)
gen n_estab_sm_repair 	= r1201o if !inlist(r1201o,998,999)
gen n_estab_sm_other 	= r1201p if !inlist(r1201p,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"

* Cooperatives

gen n_coop_kud 	  = r1206a1 if !inlist(r1206a1,98,99)
gen n_coop_smmanu = r1206a2 if !inlist(r1206a2,98,99)
gen n_coop_save   = r1206a3 if !inlist(r1206a3,98,99)
gen n_coop_othr   = r1206a4 if !inlist(r1206a4,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Agricultural production stalls

gen agprod_stall_kud_avail = r1206b1 == 1 if !mi(r1206b1)
gen agprod_stall_bum_avail = r1206b2 == 3 if !mi(r1206b2)
gen agprod_stall_non_avail = r1206b3 == 5 if !mi(r1206b3)

gen agprod_stall_avail = ///
	agprod_stall_kud_avail | agprod_stall_bum_avail | agprod_stall_non_avail ///
  if !mi(agprod_stall_kud_avail,agprod_stall_bum_avail,agprod_stall_non_avail)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_bum_avail "BUM-owned agricultural production stalls exists"
la var agprod_stall_non_avail ///
	"Non-KUD/BUM-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Industrial areas

gen ind_center = r1202a > 0 if !mi(r1202a)	
la var ind_center "Industrial center in village"
	
gen small_ind_area = r1202b > 0 | r1202c > 0 if !mi(r1202b,r1202c)
la var small_ind_area "Small industrial area in village"	
	
* Markets

gen n_shop_cntr = r1207ak2 if !inlist(r1207ak2,98,99)
gen shop_cntr_avail = n_shop_cntr > 0 if !mi(n_shop_cntr)

gen n_mkt_perm = r1207bk2 + r1207ck2 ///
	if !inlist(r1207bk2,98,99) & !inlist(r1207ck2,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r1207dk2 if !inlist(r1207dk2,98,99)

la var n_shop_cntr "Number of shopping centers"
la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1207ek2
gen n_restaur = r1207fk2 if !inlist(r1207fk2,98,99)
gen n_foodstall = r1207gk2 if !inlist(r1207gk2,998,999)
gen n_hotel = r1207hk2 if !inlist(r1207hk2,98,99)
gen n_motel = r1207ik2 if !inlist(r1207ik2,98,99)
gen n_cornerstore = r1207jk2 if !inlist(r1207jk2,998,999)

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"
la var n_cornerstore "Number of corner stores"

* Banks

gen n_bank_com_gov = r1205a1 if !inlist(r1205a1,98,99)
gen n_bank_com_prv = r1205a2 if !inlist(r1205a2,98,99)
gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = r1205a3 if !inlist(r1205a3,98,99)

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r1208a == 1 | r1208b == 3 | r1208c == 5 | r1208d == 7
la var microfin_avail "Formal microfinance programs exist"

* Main village road has electric lighting

gen rd_light = inlist(r502b,1,2) & inlist(r502c,1,2) ///
	if !mi(r502b) //& r1001b1 != 0

* Main village road has lighting provided by govt. electricity

gen rd_light_gov = inlist(r502b,1,2) & r502c == 1 ///
	if !mi(r502b) //& r1001b1 != 0
gen rd_light_nongov = inlist(r502b,1,2) & r502c == 2 ///
	if !mi(r502b) //& r1001b1 != 0

* Household electricity access

ren r501a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r501b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)

* Waste disposal

gen garbage_collect = r504b == 1 if !mi(r504b)
	la var garbage_collect "Gabage disposed using bins that are transported"
	
gen toilet = inrange(r505a,1,3) if !mi(r505a)
	la var toilet "Most families defecate in a toilet (private, shared, public)"
	
gen sewage = r505b == 2 if !mi(r505b)
	la var sewage "Most families dispose of feces in wastewater treatment plant"

gen absorp_pit = r506 == 1 if !mi(r506)	
	la var absorp_pit "Most families dispose of wastewater in absorption pit"

* Safe water

gen safe_drink_water = inrange(r507a,1,4) if !mi(r507a) 
	la var safe_drink_water "Access to safe drinking water"

gen safe_bath_water = inrange(r507b,1,2) if !mi(r507b) 
	la var safe_bath_water "Access to safe bathing water"

* River

gen river = r509ak2 == 1 if !mi(r509ak2)
	la var river "Existence of a river"
	
* Irrigation canal

gen irrigation = r509ak3 == 1 if !mi(r509ak3)
	la var irrigation "Existence of an irrigation canal"
	
* Reservoir	

gen reservoir = r509ak5 == 1 if !mi(r509ak5)
	la var reservoir "Existence of a reservoir"
	
* Diversity

gen multi_ethnic = r804a1 == 1 if !mi(r804a1)
	la var multi_ethnic "Multiple ethnic groups in village"

gen eth_code_majority   = r804a2a
	la var eth_code_majority "Code of majority ethnicity"
gen eth_code_2ndbiggest = r804a2b
	la var eth_code_2ndbiggest "Code of 2nd biggest ethnicity"
gen eth_code_3rdbiggest = r804a2c
	la var eth_code_3rdbiggest "Code of 3rd biggest ethnicity"
	
gen multi_lang = r804b1 == 1 if !mi(r804b1)
	la var multi_lang "Multiple languages spoke in village"

gen lang_code_majority = r804b2_2
	la var lang_code_majority "Code of majority language"	
	
* Entertainment

gen pub = r902a == 1 if !mi(r902a)
	la var pub "Existence of functioning pub/discotheque/karaoke venue"

* Phone, internet, TV

gen n_hh_phn = r1003a

gen internet = r1004 == 1 if !mi(r1004)   
gen internet_head = inlist(r1006b,1,2) if !mi(r1006b)    
	// internet facility in office of village head
gen TVRI 	 = r1008ak2 == 1 if !mi(r1008ak2) 
gen locTV 	 = r1008bk2 == 1 if !mi(r1008bk2) 
gen natcomTV = r1008ck2 == 1 if !mi(r1008ck2) 
gen forTV 	 = r1008dk2 == 1 if !mi(r1008dk2) 
gen mblphn   = inlist(r1005c,1,2,3) if !mi(r1005c) 
gen mblphn_strng = inlist(r1005c,1,2) if !mi(r1005c)

* Fight against govt

gen fight_sec = 0
replace fight_sec = r1301b3k2 if r1301a == 1 

gen fight_state = 0
replace fight_state = r1301b4k2 if r1301a == 1 

* Corruption

gen corruption = r1303a11k3 == 1 if !mi(r1303a11k3)
	la var corruption "Corruption event occurred in village in last year"

* Police

local x	r1306a
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"	

* Distance to district capital

local x r1002bk5
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"
	
local x r1002dk5
gen dist_nearest_distr_cap = `x' if `x' < 998
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"

** Characteristics of village officials **
	* Village head
	* Village secretary	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1601`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1601`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1601`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
	
	local x r1601`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}		
	
** Village administration **

gen n_vlg_officials = r1602a + r1602b + r1602c //+ r1602d
	la var n_vlg_officials "Number of village officials"
	
gen n_regul_vlg = r1403c
gen n_regul_vlghead = r1403d

la var n_regul_vlg "Number of village regulations in previous year"
la var n_regul_vlghead "Number of village head regulations in previous year"	
	
* For crosswalk

gen nm2021 = desa
gen nm2021_1 = desa
gen nm2021_2 = desa

tostring region_id, gen(regstr)
tostring kec_id, gen(kecstr)
tostring desa_id, gen(desastr)

replace regstr = "0" + regstr if strlen(regstr) == 1

foreach v in kecstr desastr {
	replace `v' = "00" + `v' if strlen(`v') == 1
	replace `v' = "0"  + `v' if strlen(`v') == 2
}

foreach v in id2021 id2021_1 id2021_2 {
	gen `v' = string(prov_id) + regstr + kecstr + desastr
	destring `v', replace
}

gen bps_2021 = string(prov_id) + regstr
destring bps_2021, replace

drop regstr kecstr desastr

* Tweak village names to facilitate merge
	* Will merge on names in cases where crosswalk is incomplete	
	
/*
replace nm2021_1 = "" ///
	if nm2021_1 == "" & id2021_1 == 
*/	

* Tidying

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa type status vlg_consult* vlghead* vlgsec* n_* any_hh* *_avail ///
	  dist_* easy_* rd_* pub_trans garbage* toilet sewage absorp* safe* ///
	  irrig* reservoir police multi_ethnic eth_code* multi_lang lang_code* ///
	  pub main_income* internet internet_head TVRI locTV natcomTV forTV mblphn ///
	  mblphn_strng fight_sec fight_state corrupt* outbreak* deaths* vic* ///
	  any_foodinsec ind_center small_ind_area topog forest coastal dist_*_cap ///
	  river
	
drop r106b-r1603c	
drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	ren `v' `v'_2021
}

foreach v of varlist type-river {
	ren `v' `v'_2021
}

format %10.0f id2021*  

save "$work/podes2021.dta", replace

********************************************************************************
**# 2024
* 2024
********************************************************************************

** Merging raw data **

forval n = 1/4 {
	tempfile d`n'
	import dbase "$podes_raw/PODES 2024/podes2024_desa_0`n'", ///
		clear case(lower)
	save `d`n''
}

use `d1'
merge 1:1 iddesa using `d2', nogenerate
merge 1:1 iddesa using `d3', nogenerate
merge 1:1 iddesa using `d4', nogenerate

foreach v of varlist * {
	cap destring `v', replace
}

format %10.0f iddesa
	
** Renaming geographic names/IDs **

ren iddesa id2024
ren r106b  id2024_moha
gen double id2024_1 = id2024

ren r101 prov_id
ren r102 region_id
ren r103 kec_id
ren r104 desa_id

ren nama_prov province
ren nama_kab  region
ren nama_kec  kec
ren nama_desa desa

* Raw PODES code (unique)
gen double id_podes2024 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2024
isid id_podes2024
la var id_podes2024 "PODES 2024 code (raw file)"
gen nm_podes2024 = desa
la var nm_podes2024 "PODES 2024 name (raw file)"

** Clean names **

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}	

** Fix MoHA village code **
	/*
	Villages established by MoHA decree (vast majority) record MoHA village ID
	*/

replace id2024_moha = subinstr(id2024_moha,".","",.)
destring id2024_moha, replace
format %10.0f id2024_moha

** Geography **

ren r105 status
	la var status "Urban/Rural Status"
	la def status 1 "Urban" 2 "Rural"
	la val status status

ren r301 type
	recode type (3 = 6) (4 = 3)
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type
	
gen vlg_consult = r1603a == 1 if !mi(r1603a)
	la var vlg_consult "Presence of a Village Consultative Body"	

ren r305a topog
	la var topog "Topography"
	la def topog 1 "Peak/Cliff" 2 "Slope" 3 "Plain" 4 "Valley"
	la val topog topog	
	
gen coastal = r308a == 1 if !mi(r308a)
	la var coastal "Village is adjacent to sea"	
	
ren r309a forest
	la var forest "Location relative to forest"
	la def forest 1 "In the forest" 2 "At edge of the forest" 3 "Outside forest"
	la val forest forest		
	
** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"	

** Generating social and infrastructure variables **

* Doctors, midwives, health facilities

gen n_dr = r706a1 + r706a2
gen n_dent = r706b
gen n_mwiv_all = r706c
gen n_hosp = r704ak2
gen n_hosp_mat = r704bk2
gen n_puskesmas = r704ck2 + r704dk2 + r704ek2 
gen n_poliklinik = r704fk2
gen n_dr_off = r704gk2
gen n_mwiv_off = r704ik2
gen n_poskesdes = r704jk2
gen n_polindes = r704kk2
gen n_posyandu = r705b + r705c
gen n_pharm = r704lk2

gen n_heal_cntr = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen mwiv_BDD_avail = r707 == 1 if !mi(r707)

gen dr_avail = n_dr > 0 if !mi(n_dr)
gen dent_avail = n_dent > 0 if !mi(n_dent)
gen mwiv_all_avail = n_mwiv_all > 0 if !mi(n_mwiv_all)
gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen hosp_mat_avail = n_hosp_mat > 0 if !mi(n_hosp_mat)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Disease outbreaks

gen outbreak_diar = r711ak2 == 1 if !mi(r711ak2)
gen outbreak_deng = r711bk2 == 1 if !mi(r711bk2)
gen outbreak_meas = r711ck2 == 1 if !mi(r711ck2)
gen outbreak_mala = r711dk2 == 1 if !mi(r711dk2)
gen outbreak_avia = r711ek2 == 1 if !mi(r711ek2)
gen outbreak_hepe = r711fk2 == 1 if !mi(r711fk2)
gen outbreak_diph = r711gk2 == 1 if !mi(r711gk2)
gen outbreak_covd = r711hk2 == 1 if !mi(r711hk2)
gen outbreak_othr = r711ik2 == 1 if !mi(r711ik2)

egen outbreak_any = rowmax(outbreak_*)

la var outbreak_diar "Diarrhea outbreak during the past year"
la var outbreak_deng "Dengue fever outbreak during the past year"
la var outbreak_meas "Measles outbreak during the past year"
la var outbreak_mala "Malaria outbreak during the past year"
la var outbreak_avia "Avian flu outbreak during the past year"
la var outbreak_hepe "Hepatitis E outbreak during the past year"
la var outbreak_diph "Diphtheria outbreak during the past year"
la var outbreak_covd "COVID-19 outbreak during the past year"
la var outbreak_othr "Other type of outbreak during the past year"

la var outbreak_any "Any disease outbreak during the past year"

gen deaths_diar = 0 if r711ak2 == 2
replace deaths_diar = r711ak4 if r711ak2 == 1

gen deaths_deng = 0 if r711bk2 == 2
replace deaths_deng = r711bk4 if r711bk2 == 1

gen deaths_meas = 0 if r711ck2 == 2
replace deaths_meas = r711ck4 if r711ck2 == 1

gen deaths_mala = 0 if r711dk2 == 2
replace deaths_mala = r711dk4 if r711dk2 == 1

gen deaths_avia = 0 if r711ek2 == 2
replace deaths_avia = r711ek4 if r711ek2 == 1

gen deaths_hepe = 0 if r711fk2 == 2
replace deaths_hepe = r711fk4 if r711fk2 == 1

gen deaths_diph = 0 if r711gk2 == 2
replace deaths_diph = r711gk4 if r711gk2 == 1

gen deaths_covd = 0 if r711hk2 == 2
replace deaths_covd = r711hk4 if r711hk2 == 1

gen deaths_othr = 0 if r711ik2 == 2
replace deaths_othr = r711ik4 if r711ik2 == 1

egen deaths_outbreak = rowtotal(deaths_*), missing
la var deaths_outbreak "Deaths from disease outbreak during the past year"

* Malnutrition

gen victims_malnutr = r709
la var victims_malnutr "Number of malnutrition victims in 2023"

* Proxies for number of poor people

gen n_sktm = r710
la var n_sktm "Number of poverty letters/SKTM issued by village in 2023"	

* Food insecurity

gen any_foodinsec = r711jk2 == 1 if !mi(r711jk2)

gen n_foodinsec = 0 if r711jk2 == 2
replace n_foodinsec = r711jk3 if r711jk2 == 1

gen deaths_foodinsec = 0 if r711jk2 == 2
replace deaths_foodinsec = r711jk4 if r711jk2 == 1

la var any_foodinsec "Any villagers faced food insecurity during the past year"
la var n_foodinsec ///
	"Number of villagers who faced food insecurity during the past year"
la var deaths_foodinsec "Deaths food insecurity during the past year"	

* Schools 

gen n_schl_pre_pub   = r701ak2
gen n_schl_kind_pub  = r701bk2 + r701ck2
gen n_schl_prm_pub   = r701dk2 + r701ek2
gen n_schl_jrsec_pub = r701fk2 + r701gk2
gen n_schl_srsec_pub = r701hk2 + r701ik2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_pre_prv   = r701ak3
gen n_schl_kind_prv  = r701bk3 + r701ck3
gen n_schl_prm_prv   = r701dk3 + r701ek3
gen n_schl_jrsec_prv = r701fk3 + r701gk3
gen n_schl_srsec_prv = r701hk3 + r701ik3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in pre kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

gen schl_pre_avail = n_schl_pre > 0 if !mi(n_schl_pre)
la var schl_pre_avail "Preschool in village"

gen lib_avail = r702c == 1 if !mi(r702c)
la var lib_avail "Library in village"

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x b
local type hosp_mat
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

gen dist_puskesmas = min(r704ck3,r704dk3,r704ek3) ///
	if !mi(r704ck3) | !mi(r704dk3) | !mi(r704ek3)
gen easy_puskesmas = max( inlist(r704ck4,1,2), inlist(r704dk4,1,2), ///
						  inlist(r704ek4,1,2) ) ///
	if !mi(r704ck4) | !mi(r704dk4) | !mi(r704ek4)			  

local x f
local type poliklinik
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)
						  
local x g
local type dr_off
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x i
local type mwiv_off
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x j
local type poskesdes
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x k
local type polindes
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local x l
local type pharm
gen dist_`type' = r704`x'k3
gen easy_`type' = inlist(r704`x'k4,1,2) if !mi(r704`x'k4)

local type kind
gen dist_schl_`type'_pub = min(r701bk4,r701ck4)
gen easy_schl_`type'_pub = inlist(r701bk5,1,2) | inlist(r701ck5,1,2) ///
	if !mi(r701bk5) | !mi(r701ck5)

local type prm
gen dist_schl_`type'_pub = min(r701dk4,r701ek4)
gen easy_schl_`type'_pub = inlist(r701dk5,1,2) | inlist(r701ek5,1,2) ///
	if !mi(r701dk5) | !mi(r701ek5)
	
local type jrsec
gen dist_schl_`type'_pub = min(r701fk4,r701gk4)
gen easy_schl_`type'_pub = inlist(r701fk5,1,2) | inlist(r701gk5,1,2) ///
	if !mi(r701fk5) | !mi(r701gk5)	
	
local type srsec
gen dist_schl_`type'_pub = min(r701hk4,r701ik4)
gen easy_schl_`type'_pub = inlist(r701hk5,1,2) | inlist(r701ik5,1,2) ///
	if !mi(r701hk5) | !mi(r701ik5)	

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)
gen easy_schl_sec_pub = max(easy_schl_jrsec_pub,easy_schl_srsec_pub)

* Roads

gen rd_asph = r1001b1 == 1 if !mi(r1001b1)
gen rd_grvl = r1001b1 == 2 if !mi(r1001b1)
gen rd_dirt = r1001b1 == 3 if !mi(r1001b1)
gen rd_othr = r1001b1 == 4 if !mi(r1001b1)

gen rd_pass = r1001b2 == 1 if !mi(r1001b2)

local var r403c1
gen rd_connect_asph = `var' == 1 if !mi(`var')
gen rd_connect_grvl = `var' == 2 if !mi(`var')
gen rd_connect_dirt = `var' == 3 if !mi(`var')
gen rd_connect_othr = inrange(`var',4,5) if !mi(`var')

* Public transportation

gen pub_trans = inlist(r1001c1,1,2) if !mi(r1001c1)
	la var pub_trans "Existence of public transportation"
	
* Main source of income

local var r403a
gen main_income_agri	 = `var' == 1 if !mi(`var')
gen main_income_mining	 = `var' == 2 if !mi(`var')
gen main_income_industr  = `var' == 3 if !mi(`var')

* Small manufacturing establishments

gen n_estab_sm_leather 	= r1201a1 if !inlist(r1201a1,998,999)
gen n_estab_sm_wood 	= r1201a2 if !inlist(r1201a2,998,999)
gen n_estab_sm_metal 	= r1201a3 if !inlist(r1201a3,998,999)
gen n_estab_sm_textile 	= r1201a4 if !inlist(r1201a4,998,999)
gen n_estab_sm_cloth 	= r1201a5 if !inlist(r1201a5,998,999)
gen n_estab_sm_pottery 	= r1201a6 if !inlist(r1201a6,998,999)
gen n_estab_sm_woven 	= r1201a7 if !inlist(r1201a7,998,999)
gen n_estab_sm_food 	= r1201a8 if !inlist(r1201a8,998,999)
gen n_estab_sm_bev	 	= r1201a9 if !inlist(r1201a9,998,999)
gen n_estab_sm_tobacc 	= r1201a10 if !inlist(r1201a10,998,999)
gen n_estab_sm_paper 	= r1201a11 if !inlist(r1201a11,998,999)
gen n_estab_sm_print 	= r1201a12 if !inlist(r1201a12,998,999)
gen n_estab_sm_trans 	= r1201a13 if !inlist(r1201a13,998,999)
gen n_estab_sm_craft 	= r1201a14 if !inlist(r1201a14,998,999)
gen n_estab_sm_repair 	= r1201a15 if !inlist(r1201a15,998,999)
gen n_estab_sm_other 	= r1201a16 if !inlist(r1201a16,998,999)

egen n_estab_sm = rowtotal(n_estab_sm_*), missing

foreach v of varlist n_estab_sm_* {
	replace n_estab_sm = . if mi(`v')
}

la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"

* Cooperatives

gen n_coop_kud 	  = r1206a1 if !inlist(r1206a1,98,99)
gen n_coop_smmanu = r1206a2 if !inlist(r1206a2,98,99)
gen n_coop_save   = r1206a3 if !inlist(r1206a3,98,99)
gen n_coop_othr   = r1206a4 if !inlist(r1206a4,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"

* Agricultural production stalls

gen agprod_stall_kud_avail = r1206b1 == 1 if !mi(r1206b1)
gen agprod_stall_bum_avail = r1206b2 == 1 if !mi(r1206b2)
gen agprod_stall_non_avail = r1206b3 == 1 if !mi(r1206b3)

gen agprod_stall_avail = ///
	agprod_stall_kud_avail | agprod_stall_bum_avail | agprod_stall_non_avail ///
  if !mi(agprod_stall_kud_avail,agprod_stall_bum_avail,agprod_stall_non_avail)

la var agprod_stall_kud_avail "KUD-owned agricultural production stalls exists"
la var agprod_stall_bum_avail "BUM-owned agricultural production stalls exists"
la var agprod_stall_non_avail ///
	"Non-KUD/BUM-owned agricultural production stalls exists"
la var agprod_stall_avail "Agricultural production stalls exists"

* Industrial areas

gen ind_center = r1202a1 > 0 if !mi(r1202a1)	
la var ind_center "Industrial center in village"
	
gen small_ind_area = r1202b > 0 | r1202c > 0 if !mi(r1202b,r1202c)
la var small_ind_area "Small industrial area in village"

* Markets

gen n_shop_cntr = r1209ak2 if !inlist(r1209ak2,98,99)
gen shop_cntr_avail = n_shop_cntr > 0 if !mi(n_shop_cntr)

gen n_mkt_perm = r1209bk2 + r1209ck2 ///
	if !inlist(r1209bk2,98,99) & !inlist(r1209ck2,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r1209dk2 if !inlist(r1209dk2,98,99)

la var n_shop_cntr "Number of shopping centers"
la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r1209ek2
gen n_restaur = r1209fk2 if !inlist(r1209fk2,98,99)
gen n_foodstall = r1209gk2 if !inlist(r1209gk2,998,999)
gen n_hotel = r1209hk2 if !inlist(r1209hk2,98,99)
gen n_motel = r1209ik2 if !inlist(r1209ik2,98,99)
gen n_cornerstore = r1209jk2 if !inlist(r1209jk2,998,999)

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"
la var n_cornerstore "Number of corner stores"

* Banks

gen n_bank_com_gov = r1205a1 if !inlist(r1205a1,98,99)
gen n_bank_com_prv = r1205a2 if !inlist(r1205a2,98,99)
gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = r1205a3 if !inlist(r1205a3,98,99)

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r1207a == 1 | r1207b == 1 | r1207c == 1 | r1207d == 1
la var microfin_avail "Formal microfinance programs exist"

* Main village road has electric lighting

gen rd_light = inlist(r502b,1,2) & inlist(r502c,1,2) ///
	if !mi(r502b) //& r1001b1 != 0

* Main village road has lighting provided by govt. electricity

gen rd_light_gov = inlist(r502b,1,2) & r502c == 1 ///
	if !mi(r502b) //& r1001b1 != 0
gen rd_light_nongov = inlist(r502b,1,2) & r502c == 2 ///
	if !mi(r502b) //& r1001b1 != 0
	
* Household electricity access

ren r501a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r501b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)
	
* Waste disposal

gen garbage_collect = r504b == 1 if !mi(r504b)
	la var garbage_collect "Gabage disposed using bins that are transported"
	
gen toilet = inrange(r506a,1,3) if !mi(r506a)
	la var toilet "Most families defecate in a toilet (private, shared, public)"	
	
gen sewage = r506b == 2 if !mi(r506b)
	la var sewage "Most families dispose of feces in wastewater treatment plant"
	
gen absorp_pit = r507 == 1 if !mi(r507)	
	la var absorp_pit "Most families dispose of wastewater in absorption pit"
	
* Safe water

gen safe_drink_water = inrange(r508a,1,4) if !mi(r508a) 
	la var safe_drink_water "Access to safe drinking water"

gen safe_bath_water = inrange(r508b,1,2) if !mi(r508b) 
	la var safe_bath_water "Access to safe bathing water"	
	
* River

gen river = r510ak2 == 1 if !mi(r510ak2)
	la var river "Existence of a river"
	
* Irrigation canal

gen irrigation = r510ak3 == 1 if !mi(r510ak3)
	la var irrigation "Existence of an irrigation canal"
	
* Reservoir	

gen reservoir = r510ak5 == 1 if !mi(r510ak5)
	la var reservoir "Existence of a reservoir"	
	
* Diversity

gen multi_ethnic = r804a1 == 1 if !mi(r804a1)
	la var multi_ethnic "Multiple ethnic groups in village"

gen eth_code_majority   = r804a2a
	la var eth_code_majority "Code of majority ethnicity"
gen eth_code_2ndbiggest = r804a2b
	la var eth_code_2ndbiggest "Code of 2nd biggest ethnicity"
gen eth_code_3rdbiggest = r804a2c
	la var eth_code_3rdbiggest "Code of 3rd biggest ethnicity"
	
gen multi_lang = r804b1 == 1 if !mi(r804b1)
	la var multi_lang "Multiple languages spoke in village"

gen lang_code_majority = r804b2
	la var lang_code_majority "Code of majority language"	
	
* Entertainment

gen pub = r902a == 1 if !mi(r902a)
	la var pub "Existence of functioning pub/discotheque/karaoke venue"

* Phone, internet, TV

gen n_hh_phn = r1003a

gen internet = r1004 == 1 if !mi(r1004)   
gen internet_head = inlist(r1006b,1,2) if !mi(r1006b)    
	// internet facility in office of village head	
gen TVRI 	 = r1008ak2 == 1 if !mi(r1008ak2) 
gen locTV 	 = r1008bk2 == 1 if !mi(r1008bk2) 
gen natcomTV = r1008ck2 == 1 if !mi(r1008ck2) 
gen forTV 	 = r1008dk2 == 1 if !mi(r1008dk2) 
gen mblphn   = inlist(r1005c,1,2,3) if !mi(r1005c) 
gen mblphn_strng = inlist(r1005c,1,2) if !mi(r1005c)	
	
* Fight against govt

gen fight_sec = 0
replace fight_sec = r1301b3k2 if r1301a == 1 

gen fight_state = 0
replace fight_state = r1301b4k2 if r1301a == 1 	

* Corruption

gen corruption = r1303a11k3 == 1 if !mi(r1303a11k3)
	la var corruption "Corruption event occurred in village in last year"

* Police

local x	r1306a
gen police = `x' == 1 if !mi(`x')
	la var police "Existence of police station"	

* Distance to district capital

local x r1002bk5
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"
	
local x r1002dk5
gen dist_nearest_distr_cap = `x' if `x' < 998
	la var dist_nearest_distr_cap "Distance to nearest district capital (km)"	

** Characteristics of village officials **
	* Village head
	* Village secretary	
	/*
	Education coding (follows Martinez-Bravo 2017 (see appendix)):
		no schooling = 0 years of schooling; 
		not completed primary school = 2 years; (these two are combined in 2005)
		primary school = 6 years; 
		junior high school = 9 years; 
		senior high school = 12 years; 
		academy = 14 years;
		college = 16 years.
	I then coded masters = 17 yrs, PhD = 20 yrs	
	*/
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1601`row'_k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1601`row'_k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1601`row'_k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1601`row'_k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
	local x r1601`row'_k6
	gen `stub'_start = `x'	
		la var `stub'_start "`name' year of taking office"
	
}	

** Village administration **

gen n_vlg_officials = r1602a + r1602b + r1602c //+ r1602d
	la var n_vlg_officials "Number of village officials"
	
gen n_regul_vlg = r1404c
gen n_regul_vlghead = r1404d

la var n_regul_vlg "Number of village regulations in previous year"
la var n_regul_vlghead "Number of village head regulations in previous year"	

** Village head elections **

gen simul_election = r1604a == 1 if !mi(r1604a)
gen yr_last_election = r1604b if simul_election == 1
gen n_cand_vlghead = r1604c if simul_election == 1
gen votes_winner_vlghead = r1604d if simul_election == 1

la var simul_election ///
	"Village has already held simultaneous village head elections"
la var yr_last_election "Year of most recent village head election"
la var n_cand_vlghead "Number of village head election candidates"
la var votes_winner_vlghead ///
	"Percentage of votes obtained by village head election winner"

* For crosswalk

gen nm2024 = desa
gen nm2024_1 = desa
gen nm2024_2 = desa

gen bps_2024 = floor(id2024/(10^6))

* Tidying

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa type status vlg_consult* vlghead* vlgsec* *election* ///
	  *_vlghead n_* any_hh* *_avail dist_* easy_* rd_* pub_trans garbage* toilet ///
	  sewage absorp* safe* irrig* reservoir police ///
	  multi_ethnic eth_code* multi_lang lang_code* ///
	  pub main_income* internet internet_head TVRI locTV natcomTV forTV mblphn ///
	  mblphn_strng fight_sec fight_state corrupt* outbreak* deaths* vic* ///
	  any_foodinsec ind_center small_ind_area ///
	  topog forest coastal dist_*_cap river 

drop r107a-r1604d	  
drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	ren `v' `v'_2024
}

foreach v of varlist type-river {
	ren `v' `v'_2024
}

format %10.0f id2024*  

save "$work/podes2024.dta", replace

********************************************************************************
**# 2025
* 2025
********************************************************************************

** Merging raw data **

forval n = 1/2 {
	tempfile d`n'
	import dbase "$podes_raw/PODES 2025/podes2025-desa_part`n'", ///
		clear case(lower)
	save `d`n''
}

use `d1'
merge 1:1 iddesa using `d2', nogenerate

foreach v of varlist * {
	cap destring `v', replace
}

format %10.0f iddesa

** Renaming geographic names/IDs **

ren iddesa id2025

ren r101 prov_id
ren r102 region_id
ren r103 kec_id
ren r104 desa_id

ren nama_prov province
ren nama_kab  region
ren nama_kec  kec
ren nama_desa desa

* Raw PODES code (unique)
gen double id_podes2025 = prov_id*1e8 + region_id*1e6 + kec_id*1e3 + desa_id
format %10.0f id_podes2025
isid id_podes2025
la var id_podes2025 "PODES 2025 code (raw file)"
gen nm_podes2025 = desa
la var nm_podes2025 "PODES 2025 name (raw file)"

** Clean names **

foreach v in province region kec desa {
	replace `v' = strupper(`v')
	replace `v' = subinstr(`v',"  "," ",.)	
	replace `v' = subinstr(`v',"   "," ",.)	
	replace `v' = subinstr(`v',"    "," ",.)
}	

* Line breaks, invalid UTF-8 bytes, and double quotes used as apostrophes
foreach v in province region kec desa {
	replace `v' = subinstr(`v', char(10), " ", .)
	replace `v' = subinstr(`v', char(13), " ", .)
	replace `v' = ustrfix(`v', "'")
	replace `v' = strtrim(stritrim(`v'))
}

** Geography **

ren r105 status
	la var status "Urban/Rural Status"
	la def status 1 "Urban" 2 "Rural"
	la val status status

ren r301 type
	recode type (3 = 6) (4 = 3)
	la var type "Village Organizational Type"
	la def type 1 "Desa" 2 "Kelurahan" 3 "Nagari" 4 "Other" 6 "UPT/SPT"
	la val type type
	
gen vlg_consult = r1203a == 1 if !mi(r1203a)
	la var vlg_consult "Presence of a Village Consultative Body"	
	
** Assigning region type **

gen region_type = "Kab."
replace region_type = "Kota" if region_id > 70

** Cleaning region names **

qui do "$aux/standardize_region"

** Generating social and infrastructure variables **

* Doctors, midwives, health facilities

gen n_hosp = r702ak2
gen n_puskesmas = r702dk2 + r702ek2 + r702fk2
gen n_poliklinik = r702bk2 + r702ck2 + r702gk2
gen n_dr_off = r702hk2
gen n_mwiv_off = r702ik2
gen n_poskesdes = r702jk2
gen n_polindes = r702kk2
gen n_posyandu = r703b + r703c
gen n_pharm = r702lk2

gen n_heal_cntr = n_puskesmas + n_poliklinik
gen n_polinposk = n_polindes + n_poskesdes

gen dr_off_avail = n_dr_off > 0 if !mi(n_dr_off)
gen mwiv_off_avail = n_mwiv_off > 0 if !mi(n_mwiv_off)
gen pharm_avail = n_pharm > 0 if !mi(n_pharm)
gen poly_avail = n_poliklinik > 0 if !mi(n_poliklinik)
gen pusk_avail = n_puskesmas > 0 if !mi(n_puskesmas)
gen polin_avail = n_polindes > 0 if !mi(n_polindes)
gen posy_avail = n_posyandu > 0 if !mi(n_posyandu)
gen posk_avail = n_poskesdes > 0 if !mi(n_poskesdes)
gen hosp_avail = n_hosp > 0 if !mi(n_hosp)
gen heal_cntr_avail = pusk_avail | poly_avail if !mi(pusk_avail,poly_avail)

* Schools 

gen n_schl_kind_pub  = r701ak2 + r701bk2
gen n_schl_prm_pub   = r701ck2 + r701dk2
gen n_schl_jrsec_pub = r701ek2 + r701fk2
gen n_schl_srsec_pub = r701gk2 + r701hk2
gen n_schl_sec_pub   = n_schl_jrsec_pub + n_schl_srsec_pub

gen n_schl_kind_prv  = r701ak3 + r701bk3
gen n_schl_prm_prv   = r701ck3 + r701dk3
gen n_schl_jrsec_prv = r701ek3 + r701fk3
gen n_schl_srsec_prv = r701gk3 + r701hk3
gen n_schl_sec_prv   = n_schl_jrsec_prv + n_schl_srsec_prv
gen n_schl_prv       = n_schl_prm_prv + n_schl_sec_prv

foreach x in kind prm jrsec srsec sec {
	gen n_schl_`x' = n_schl_`x'_pub + n_schl_`x'_prv
}

foreach x in kind kind_pub prm_pub jrsec_pub srsec_pub sec_pub { 
	gen schl_`x'_avail = n_schl_`x' > 0 if !mi(n_schl_`x')
}

* Distance/ease of access: health and schools

local x a
local type hosp
gen dist_`type' = r702`x'k3
gen easy_`type' = inlist(r702`x'k4,1,2) if !mi(r702`x'k4)

local type puskesmas
gen dist_`type' = min(r702dk3,r702ek3,r702fk3) ///
	if !mi(r702dk3) | !mi(r702ek3) | !mi(r702fk3)
gen easy_`type' = max( inlist(r702dk4,1,2), inlist(r702ek4,1,2), ///
						  inlist(r702fk4,1,2) ) ///
	if !mi(r702dk4) | !mi(r702ek4) | !mi(r702fk4)
	
local type poliklinik
gen dist_`type' = min(r702bk3,r702ck3,r702gk3) ///
	if !mi(r702bk3) | !mi(r702ck3) | !mi(r702gk3)
gen easy_`type' = max( inlist(r702bk4,1,2), inlist(r702ck4,1,2), ///
						  inlist(r702gk4,1,2) ) ///
	if !mi(r702bk4) | !mi(r702ck4) | !mi(r702gk4)

local x h
local type dr_off
gen dist_`type' = r702`x'k3
gen easy_`type' = inlist(r702`x'k4,1,2) if !mi(r702`x'k4)

local x i
local type mwiv_off
gen dist_`type' = r702`x'k3
gen easy_`type' = inlist(r702`x'k4,1,2) if !mi(r702`x'k4)

local x j
local type poskesdes
gen dist_`type' = r702`x'k3
gen easy_`type' = inlist(r702`x'k4,1,2) if !mi(r702`x'k4)

local x k
local type polindes
gen dist_`type' = r702`x'k3
gen easy_`type' = inlist(r702`x'k4,1,2) if !mi(r702`x'k4)

local x l
local type pharm
gen dist_`type' = r702`x'k3
gen easy_`type' = inlist(r702`x'k4,1,2) if !mi(r702`x'k4)

local type kind
gen dist_schl_`type'_pub = min(r701ak4,r701bk4)
gen easy_schl_`type'_pub = inlist(r701ak5,1,2) | inlist(r701bk5,1,2) ///
	if !mi(r701ak5) | !mi(r701bk5)

local type prm
gen dist_schl_`type'_pub = min(r701ck4,r701dk4)
gen easy_schl_`type'_pub = inlist(r701ck5,1,2) | inlist(r701dk5,1,2) ///
	if !mi(r701ck5) | !mi(r701dk5)
	
local type jrsec
gen dist_schl_`type'_pub = min(r701ek4,r701fk4)
gen easy_schl_`type'_pub = inlist(r701ek5,1,2) | inlist(r701fk5,1,2) ///
	if !mi(r701ek5) | !mi(r701fk5)	
	
local type srsec
gen dist_schl_`type'_pub = min(r701gk4,r701hk4)
gen easy_schl_`type'_pub = inlist(r701gk5,1,2) | inlist(r701hk5,1,2) ///
	if !mi(r701gk5) | !mi(r701hk5)	

gen dist_schl_sec_pub = min(dist_schl_jrsec_pub,dist_schl_srsec_pub)
gen easy_schl_sec_pub = max(easy_schl_jrsec_pub,easy_schl_srsec_pub)

* Roads

gen rd_asph = r801b1 == 1 if !mi(r801b1)
gen rd_grvl = r801b1 == 2 if !mi(r801b1)
gen rd_dirt = r801b1 == 3 if !mi(r801b1)
gen rd_othr = r801b1 == 4 if !mi(r801b1)

gen rd_pass = r801b2 == 1 if !mi(r801b2)

* Public transportation

gen pub_trans = inlist(r801c1,"A","B","AB") if !mi(r801c1)
	la var pub_trans "Existence of public transportation"
	
* Small manufacturing establishments
	
gen n_estab_sm = r907a
la var n_estab_sm "Number of small manufacturing establishments (< 20 employees)"
	
* Cooperatives

gen n_coop_kud 	  = r903a if !inlist(r903a,98,99)
gen n_coop_smmanu = r903b if !inlist(r903b,98,99)
gen n_coop_save   = r903c if !inlist(r903c,98,99)
gen n_coop_othr   = r903d if !inlist(r903d,98,99)

egen n_coop = rowtotal(n_coop_*), missing

foreach v of varlist n_coop_* {
	replace n_coop = . if mi(`v')
}

la var n_coop_kud "Number of Village Unit Cooperatives (KUD)"
la var n_coop_smmanu "Number of small manufacturing cooperatives (Kopinkra)"
la var n_coop_save "Number of savings and loan cooperatives (Kospin)"
la var n_coop_othr "Number of other cooperatives"
la var n_coop "Number of cooperatives"
	  
* Industrial areas

gen ind_center = r907b > 0 if !mi(r907b)	
la var ind_center "Industrial center in village"

* Markets

gen n_shop_cntr = r905ak2 if !inlist(r905ak2,98,99)
gen shop_cntr_avail = n_shop_cntr > 0 if !mi(n_shop_cntr)

gen n_mkt_perm = r905bk2 + r905ck2 ///
	if !inlist(r905bk2,98,99) & !inlist(r905ck2,98,99)
gen mkt_perm_avail = n_mkt_perm > 0 if !mi(n_mkt_perm)

gen n_mkt_temp = r905dk2 if !inlist(r905dk2,98,99)

la var n_shop_cntr "Number of shopping centers"
la var shop_cntr_avail "Shopping center exists"
la var n_mkt_perm "Number of markets with permanent/semi-permanent buildings"
la var mkt_perm_avail "Market with permanent/semi-permanent buildings exists"
la var n_mkt_temp "Number of temporary markets"

* Service establishments

gen n_minimkt = r905ek2
gen n_restaur = r905fk2 if !inlist(r905fk2,98,99)
gen n_foodstall = r905gk2 if !inlist(r905gk2,998,999)
gen n_hotel = r905hk2 if !inlist(r905hk2,98,99)
gen n_motel = r905ik2 if !inlist(r905ik2,98,99)
gen n_cornerstore = r905jk2 if !inlist(r905jk2,998,999)

la var n_minimkt "Number of minimarkets"
la var n_restaur "Number of restaurants/eating houses"
la var n_foodstall "Number of food and beverage stalls"
la var n_hotel "Number of hotels"
la var n_motel "Number of motels/hostels/inns/guesthouses"
la var n_cornerstore "Number of corner stores"

* Banks

gen n_bank_com_gov = r902a1 if !inlist(r902a1,98,99)
gen n_bank_com_prv = r902a2 if !inlist(r902a2,98,99)
gen n_bank_com = n_bank_com_gov + n_bank_com_prv

gen n_bank_rur = r902a3 if !inlist(r902a3,98,99)

la var n_bank_com "Number of commercial banks"
la var n_bank_rur "Number of rural banks"

* Microfinance

gen microfin_avail = r904a == 1 | r904b == 1 | r904c == 1 | r904d == 1
la var microfin_avail "Formal microfinance programs exist"

* Main village road has electric lighting

gen rd_light = inlist(r502a,1,2) & inlist(r502b,1,2) ///
	if !mi(r502a)

* Main village road has lighting provided by govt. electricity

gen rd_light_gov = inlist(r502a,1,2) & r502b == 1 ///
	if !mi(r502a) 
gen rd_light_nongov = inlist(r502a,1,2) & r502b == 2 ///
	if !mi(r502a) 

* Household electricity access

ren r501a1 n_hh_elec_pln
	la var n_hh_elec_pln "# Households using PLN electricity"

ren r501a2 n_hh_elec_nonpln
	la var n_hh_elec_nonpln "# Households using non-PLN electricity"	
	
ren r501b n_hh_noelec
	la var n_hh_noelec "# Households without electricity"
	
gen any_hh_elec = n_hh_elec_pln > 0 | n_hh_elec_nonpln > 0 ///
	if !mi(n_hh_elec_pln,n_hh_elec_nonpln)	

* Phone, internet, TV

gen n_hh_phn = r803a
gen mblphn   = inlist(r804c,1,2,3) if !mi(r804c) 
gen mblphn_strng = inlist(r804c,1,2) if !mi(r804c)	
	
* Distance to district capital

local x r802bk5
gen dist_distr_cap = `x' if `x' < 998
	la var dist_distr_cap "Distance to district capital (km)"
	
** Characteristics of village officials **
	* Village head
	* Village secretary
	
foreach stub in vlghead vlgsec {
	
	if "`stub'" == "vlghead" {
		local row  "a"
		local name "Village head"
	}
	else if "`stub'" == "vlgsec" {
		local row  "b"
		local name "Village secretary"
	}
	
	local x r1201`row'k2
	gen `stub'_exists = `x' == 1 if !mi(`x')
		la var `stub'_exists "`name' exists"

	ren r1201`row'k3 `stub'_age
		recode `stub'_age (0 = .) if `stub'_exists == 0
		assert `stub'_age != 0
		la var `stub'_age "`name' age"

	local x r1201`row'k4	
	gen `stub'_male = `x' == 1 if !mi(`x')	
		replace `stub'_male = . if `stub'_exists == 0
		la var `stub'_male "`name' is male"
		
	local x r1201`row'k5	
	gen `stub'_educ = .	
		replace `stub'_educ = 0  if `x' == 1
		replace `stub'_educ = 2  if `x' == 2
		replace `stub'_educ = 6  if `x' == 3
		replace `stub'_educ = 9  if `x' == 4
		replace `stub'_educ = 12 if `x' == 5
		replace `stub'_educ = 14 if `x' == 6
		replace `stub'_educ = 16 if `x' == 7
		replace `stub'_educ = 17 if `x' == 8
		replace `stub'_educ = 20 if `x' == 9
		la var `stub'_educ "`name' years of education"

	gen `stub'_highschl = inrange(`x',5,9) if !mi(`x') & `stub'_exists == 1	
	gen `stub'_college  = inrange(`x',7,9) if !mi(`x') & `stub'_exists == 1
	gen `stub'_gradschl = inrange(`x',8,9) if !mi(`x') & `stub'_exists == 1

	la var `stub'_highschl "`name' completed high school"
	la var `stub'_college  "`name' completed college"
	la var `stub'_gradschl "`name' completed graduate school"
	
}

** Village administration **

gen n_vlg_officials = r1202a + r1202b + r1202c //+ r1202d
	la var n_vlg_officials "Number of village officials"
	
gen n_regul_vlg = r1103
	la var n_regul_vlg "Number of village regulations in previous year"

* For crosswalk

gen double id2025_1 = id2025

gen nm2025 = desa
gen nm2025_1 = desa

gen bps_2025 = floor(id2025/(10^6))	

* Tidying

order id* bps_* nm* prov_id province region_id region region_type kec_id kec ///
	  desa_id desa type status vlg_consult* vlghead* vlgsec* ///
	  n_* any_hh* *_avail dist_* easy_* rd_* pub_trans mblphn mblphn_strng ///
	  ind_center dist_*_cap 
	  
drop r107a-r1203c  
drop prov_id region_id kec_id desa_id

foreach v in province region region_type kec desa {
	ren `v' `v'_2025
}

foreach v of varlist type-ind_center {
	ren `v' `v'_2025
}

format %10.0f id2025*

drop if mi(id2025)

* Tidying

order id* nm*

save "$work/podes2025.dta", replace
