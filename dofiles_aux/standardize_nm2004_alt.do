foreach v in nm2004_alt {

	replace `v' = subinstr(`v',"SEI ","SUNGAI ",1) ///
		if substr(`v',1,4) == "SEI "
		
	replace `v' = subinstr(`v',"SEI. ","SUNGAI ",1) ///
		if substr(`v',1,5) == "SEI. "
		
	replace `v' = subinstr(`v',"PERK ","PERKEBUNAN ",1) ///
		if substr(`v',1,5) == "PERK "
		
	replace `v' = subinstr(`v',"PERK. ","PERKEBUNAN ",1) ///
		if substr(`v',1,6) == "PERK. "	
	
}	
	
