chan ch12 = [0] of {byte};
chan ch12e = [0] of {byte};
chan ch23 = [0] of {byte};
chan ch23e = [0] of {byte};
chan ch34 = [0] of {byte};
chan ch34e = [0] of {byte};
chan ch41 = [0] of {byte};
chan ch41e = [0] of {byte};
chan ch14 = [0] of {byte};
chan ch14e = [0] of {byte};
chan ch43 = [0] of {byte};
chan ch43e = [0] of {byte};
chan ch32 = [0] of {byte};
chan ch32e = [0] of {byte};
chan ch21 = [0] of {byte};
chan ch21e = [0] of {byte};
active proctype Track12() 
{
	byte shuttle; 
	do 
	:: ch12?shuttle-> ch12e!shuttle;
	od;
}
active proctype Track23() 
{
	byte shuttle; 
	do 
	:: ch23?shuttle -> ch23e!shuttle;
	od;
}
active proctype Track34() 
{
	byte shuttle; 
	do 
	:: ch34?shuttle -> ch34e!shuttle;
	od;
}
active proctype Track41() 
{
	byte shuttle; 
	do 
	:: ch41?shuttle -> ch41e!shuttle;
	od;
}
active proctype Track14() 
{
	byte shuttle; 
	do 
	:: ch14?shuttle -> ch14e!shuttle;
	od;
}
active proctype Track43() 
{
	byte shuttle; 
	do 
	:: ch43?shuttle -> ch43e!shuttle;
	od;
}
active proctype Track32() 
{
	byte shuttle; 
	do 
	:: ch32?shuttle -> ch32e!shuttle;
	od;
}
active proctype Track21() 
{
	byte shuttle; 
	do 
	:: ch21?shuttle -> ch21e!shuttle;
	od;
}

chan s1alert = [3] of { byte }; //first for source, second for dest, third for capacity
chan s1conf = [1] of { bit };
chan order1ch = [2] of { byte }; //to change number according to number of shuttle; 0 is failure

proctype shuttle1(byte station; byte capacity; byte charge)
{
	bool inOrder = false; 
	bool clockwise = true; 
	byte sourceStation = station; 
	byte destination = station; 
	
	do
	:: (inOrder == false) -> 
		byte reqSourceStation; 
		byte reqDestStation; 
		byte reqCapacity; 
		s1alert?reqSourceStation;
		s1alert?reqDestStation;
		s1alert?reqCapacity;
		if
		:: (reqCapacity <= capacity) -> 
			int toCharge = reqCapacity * charge; 
			atomic { order1ch!1; order1ch!toCharge }; s1conf?inOrder; 	
			if 
			:: (inOrder == true) -> 
				sourceStation = reqSourceStation;
				destination = reqDestStation; 
				capacity = reqCapacity; 
				if
				// directly opposite / current station can just use clockwise
				:: ( (station == 1 && sourceStation == 4) || (station - sourceStation == 1)) -> 
					clockwise = false; 
				:: else -> clockwise = true;  
				fi; 
			:: (inOrder == false) -> ;
			fi; 
		:: else -> atomic { order1ch!1; order1ch!0 };	s1conf?inOrder; 
		fi;	
	:: (inOrder == true) ->
		if
		:: (destination == station) -> inOrder = false; 
		:: else -> 
			if
			:: (clockwise == true && station == 1) -> ch12!1; ch12e?1; station = 2;
			:: (clockwise == true && station == 2) -> ch23!1; ch23e?1; station = 3;
			:: (clockwise == true && station == 3) -> ch34!1; ch34e?1; station = 4;
			:: (clockwise == true && station == 4) -> ch41!1; ch41e?1; station = 1;
			:: (clockwise  == false && station == 1) -> ch14!1; ch14e?1; station = 4;
			:: (clockwise  == false && station == 2) -> ch21!1; ch21e?1; station = 1; 
			:: (clockwise  == false && station == 3) -> ch32!1; ch32e?1; station = 2; 
			:: (clockwise  == false && station == 4) -> ch43!1; ch43e?1; station = 3; 
			fi; 
		fi; 
	od; 
}
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
	run shuttle1(1,4,2); 
}
