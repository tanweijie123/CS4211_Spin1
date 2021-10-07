byte numShuttle = 1; 
chan s1alert = [3] of { byte }; //first for source, second for dest, third for capacity
chan s1conf = [1] of { bit };
chan order1 = [2] of { byte }; //to change number according to number of shuttle; 0 is failure

proctype shuttle(byte station; byte capacity; byte charge)
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
			atomic { order1!1; order1!toCharge }; s1conf?inOrder; 	
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
		:: else -> atomic { order1!1; order1!0 };	s1conf?inOrder; 
		fi;	
	:: (inOrder == true) ->
		if
		:: (capacity == 0 && destination == station) -> inOrder = false; 
		:: else -> 
			if
			:: (clockwise == true && station == 1) -> ch12!1; ch12e?1; 
			:: (clockwise == true && station == 2) -> ch23!1; ch23e?1; 
			:: (clockwise == true && station == 3) -> ch34!1; ch34e?1; 
			:: (clockwise == true && station == 4) -> ch41!1; ch41e?1; 
			:: (clockwise  == false && station == 1) -> ch14!1; ch14e?1; 
			:: (clockwise  == false && station == 2) -> ch21!1; ch21e?1; 
			:: (clockwise  == false && station == 3) -> ch32!1; ch32e?1; 
			:: (clockwise  == false && station == 4) -> ch43!1; ch43e?1; 
			fi; 
		fi; 
	od; 

}

init {
	run shuttle1(1, 10);
}
