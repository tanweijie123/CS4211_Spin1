chan s1alert = [3] of { byte }; //first for source, second for dest, third for capacity
chan s1conf = [1] of { bit }; // to reply to shuttle 1
chan order1ch = [2] of { byte }; //to change number according to number of shuttle; 0 is failure

proctype order1(byte sourceStn; byte destStn; byte numPeople) {
	// ping all shuttles
	s1alert!sourceStn;
	s1alert!destStn;
	s1alert!numPeople;

	//get order price
	int lowestPrice = 1000000; 
	int lowestShuttle = 0; 
	int thisPrice = lowestPrice; 
	int thisShuttle = lowestShuttle; 

	// loop through all shuttles
	order1ch?thisShuttle;
	order1ch?thisPrice; 
	if 
	::(thisPrice < lowestPrice) -> lowestPrice = thisPrice; lowestShuttle = thisShuttle;
	::else ->; 
	fi;
	
	// feedback 1 to lowestShuttle
	s1conf!(lowestShuttle == 1);	
}

init {
	run order1(1, 3, 4); 
}
