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

chan orderMgmtIn = [4] of { byte };  //first = ordernum, second for source, 3rd for dest, 4th for capacity
chan shuttleMgmtIn = [8] of { byte }; // { first = shuttle#, second = price (0 for fail); } * numShuttle

chan s1alert = [5] of { byte }; //first = ordernum, second for source, 3rd for dest, 4th for capacity, extra space for {0} feeder
chan s1conf = [1] of { bit };
chan s2alert = [5] of { byte }; 
chan s2conf = [1] of { bit };
chan s3alert = [5] of { byte }; 
chan s3conf = [1] of { bit };
chan s4alert = [5] of { byte }; 
chan s4conf = [1] of { bit };

active proctype Management() {
	
	// order mgmt
	byte reqOrderNumber;
	byte reqSourceStation; 
	byte reqDestStation; 
	byte reqCapacity; 
	do 
	:: (true) -> 
		orderMgmtIn?reqOrderNumber;
		orderMgmtIn?reqSourceStation;
		orderMgmtIn?reqDestStation;
		orderMgmtIn?reqCapacity;

		// pump info to all shuttles 
		atomic {
		s1alert!reqOrderNumber; 
		s1alert!reqSourceStation;
		s1alert!reqDestStation;
		s1alert!reqCapacity;
		}
		atomic {
		s2alert!reqOrderNumber; 
		s2alert!reqSourceStation;
		s2alert!reqDestStation;
		s2alert!reqCapacity;
		}
		atomic {
		s3alert!reqOrderNumber; 
		s3alert!reqSourceStation;
		s3alert!reqDestStation;
		s3alert!reqCapacity;
		}
		atomic {
		s4alert!reqOrderNumber; 
		s4alert!reqSourceStation;
		s4alert!reqDestStation;
		s4alert!reqCapacity;
		}

		// receive reply & get assign to lowest
		int lowestPrice = 1000000; 
		int lowestShuttle = 0; 
		int thisPrice = lowestPrice; 
		int thisShuttle = lowestShuttle; 

		// loop through all shuttles
		shuttleMgmtIn?thisShuttle;
		shuttleMgmtIn?thisPrice; 
		if 
		::(thisPrice == 0) -> ;
		::(thisPrice > 0 && thisPrice < lowestPrice) -> lowestPrice = thisPrice; lowestShuttle = thisShuttle;
		::else ->; 
		fi;

		shuttleMgmtIn?thisShuttle;
		shuttleMgmtIn?thisPrice; 
		if 
		::(thisPrice == 0) -> ;
		::(thisPrice > 0 && thisPrice < lowestPrice) -> lowestPrice = thisPrice; lowestShuttle = thisShuttle;
		::else ->; 
		fi;

		shuttleMgmtIn?thisShuttle;
		shuttleMgmtIn?thisPrice; 
		if 
		::(thisPrice == 0) -> ;
		::(thisPrice > 0 && thisPrice < lowestPrice) -> lowestPrice = thisPrice; lowestShuttle = thisShuttle;
		::else ->; 
		fi;

		shuttleMgmtIn?thisShuttle;
		shuttleMgmtIn?thisPrice; 
		if 
		::(thisPrice == 0) -> ;
		::(thisPrice > 0 && thisPrice < lowestPrice) -> lowestPrice = thisPrice; lowestShuttle = thisShuttle;
		::else ->; 
		fi;
	
		// feedback 1 to lowestShuttle
		s1conf!(lowestShuttle == 1);	
		s2conf!(lowestShuttle == 2);	
		s3conf!(lowestShuttle == 3);	
		s4conf!(lowestShuttle == 4);		
	od; 
	
}


proctype shuttle1(byte station; byte capacity; byte charge)
{
	bool fetch = false; 
	bool inOrder = false; 
	bool clockwise = true; 
	byte sourceStation = station; 

	// order mgmt
	byte reqOrderNumber;
	byte reqSourceStation; 
	byte reqDestStation; 
	byte reqCapacity; 
	
	byte passengers[5]; // 1 -> stn1, 2 -> stn2, 3 -> stn3, etc. 
	
	do
	:: (inOrder == false) -> 
		s1alert?reqOrderNumber;
		s1alert?reqSourceStation;
		s1alert?reqDestStation;
		s1alert?reqCapacity;
		if
		:: (reqCapacity <= capacity) -> 
			int toCharge = reqCapacity * charge; 
			atomic { shuttleMgmtIn!1; shuttleMgmtIn!toCharge }; s1conf?inOrder;				 	
			if 
			:: (inOrder == true) -> 
				sourceStation = reqSourceStation;
				passengers[reqDestStation] = reqCapacity; 
				if
				// directly opposite / current station can just use clockwise
				:: ( (station == 1 && sourceStation == 4) || (station - sourceStation == 1)) -> 
					clockwise = false; 
				:: else -> clockwise = true;  
				fi; 
				s1alert!0; //delimiter for alerts. 
			:: (inOrder == false) -> ;
			fi; 
		:: else -> atomic { shuttleMgmtIn!1; shuttleMgmtIn!0 };	s1conf?inOrder; 
		fi;	
	:: (inOrder == true) ->
		if
		:: (fetch) -> passengers[station] = 0; 
		:: else -> ;
		fi; 

		s1alert?reqOrderNumber;
		
		if 
		:: (reqOrderNumber > 0) -> 
			s1alert?reqSourceStation;
			s1alert?reqDestStation;
			s1alert?reqCapacity;

			byte currentCapacity = passengers[1] + passengers[2] + passengers[3] + passengers[4]; 
			toCharge = reqCapacity * charge; 

			bool canAccept = ((currentCapacity + reqCapacity) <= capacity) && 
				( (clockwise && (station - 1) != reqSourceStation) || 
				   (!clockwise && (station + 1) != reqSourceStation) ); 

			bool newOrder = false; 

			if 
			:: (canAccept) -> atomic { shuttleMgmtIn!1; shuttleMgmtIn!toCharge }; s1conf?newOrder;
			:: (!canAccept) -> atomic { shuttleMgmtIn!1; shuttleMgmtIn!0 };	s1conf?newOrder; 
			fi;

			if
			::(newOrder) -> 
				passengers[reqDestStation] = reqCapacity; 
			:: else -> ; 
			fi;
			
		:: else -> s1alert!0; //no orders received
		fi;
		
		if
		:: (fetch == false && sourceStation == station) -> fetch = true; 
		:: (fetch == true && (passengers[1] + passengers[2] + passengers[3] + passengers[4]) == 0) -> 
			inOrder = false; fetch = false; s1alert?0; // remove last 0;
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

proctype shuttle2(byte station; byte capacity; byte charge)
{
	bool fetch = false; 
	bool inOrder = false; 
	bool clockwise = true; 
	byte sourceStation = station; 

	// order mgmt
	byte reqOrderNumber;
	byte reqSourceStation; 
	byte reqDestStation; 
	byte reqCapacity; 
	
	byte passengers[5]; // 1 -> stn1, 2 -> stn2, 3 -> stn3, etc. 
	
	do
	:: (inOrder == false) -> 
		s2alert?reqOrderNumber;
		s2alert?reqSourceStation;
		s2alert?reqDestStation;
		s2alert?reqCapacity;
		if
		:: (reqCapacity <= capacity) -> 
			int toCharge = reqCapacity * charge; 
				atomic { shuttleMgmtIn!2; shuttleMgmtIn!toCharge }; s2conf?inOrder;				 	
			if 
			:: (inOrder == true) -> 
				sourceStation = reqSourceStation;
				passengers[reqDestStation] = reqCapacity; 
				if
				// directly opposite / current station can just use clockwise
				:: ( (station == 1 && sourceStation == 4) || (station - sourceStation == 1)) -> 
					clockwise = false; 
				:: else -> clockwise = true;  
				fi; 
				s2alert!0; //delimiter for alerts. 
			:: (inOrder == false) -> ;
			fi; 
		:: else -> atomic { shuttleMgmtIn!2; shuttleMgmtIn!0 };	s2conf?inOrder; 
		fi;	
	:: (inOrder == true) ->
		if
		:: (fetch) -> passengers[station] = 0; 
		:: else -> ;
		fi; 

		s2alert?reqOrderNumber;
		
		if 
		:: (reqOrderNumber > 0) -> 
			s2alert?reqSourceStation;
			s2alert?reqDestStation;
			s2alert?reqCapacity;

			byte currentCapacity = passengers[1] + passengers[2] + passengers[3] + passengers[4]; 
			toCharge = reqCapacity * charge; 

			bool canAccept = ((currentCapacity + reqCapacity) <= capacity) && 
				( (clockwise && (station - 1) != reqSourceStation) || 
				   (!clockwise && (station + 1) != reqSourceStation) ); 

			bool newOrder = false; 

			if 
			:: (canAccept) -> atomic { shuttleMgmtIn!2; shuttleMgmtIn!toCharge }; s2conf?newOrder;
			:: (!canAccept) -> atomic { shuttleMgmtIn!2; shuttleMgmtIn!0 };	s2conf?newOrder; 
			fi;

			if
			::(newOrder) -> 
				passengers[reqDestStation] = reqCapacity; 
			:: else -> ; 
			fi;
			
		:: else -> s2alert!0; //no orders received
		fi;
		
		if
		:: (fetch == false && sourceStation == station) -> fetch = true; 
		:: (fetch == true && (passengers[1] + passengers[2] + passengers[3] + passengers[4]) == 0) -> 
			inOrder = false; fetch = false; s2alert?0; // remove last 0;
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

proctype shuttle3(byte station; byte capacity; byte charge)
{
	bool fetch = false; 
	bool inOrder = false; 
	bool clockwise = true; 
	byte sourceStation = station; 

	// order mgmt
	byte reqOrderNumber;
	byte reqSourceStation; 
	byte reqDestStation; 
	byte reqCapacity; 
	
	byte passengers[5]; // 1 -> stn1, 2 -> stn2, 3 -> stn3, etc. 
	
	do
	:: (inOrder == false) -> 
		s3alert?reqOrderNumber;
		s3alert?reqSourceStation;
		s3alert?reqDestStation;
		s3alert?reqCapacity;
		if
		:: (reqCapacity <= capacity) -> 
			int toCharge = reqCapacity * charge; 
			atomic { shuttleMgmtIn!3; shuttleMgmtIn!toCharge }; s3conf?inOrder;
							 	
			if 
			:: (inOrder == true) -> 
				sourceStation = reqSourceStation;
				passengers[reqDestStation] = reqCapacity; 
				if
				// directly opposite / current station can just use clockwise
				:: ( (station == 1 && sourceStation == 4) || (station - sourceStation == 1)) -> 
					clockwise = false; 
				:: else -> clockwise = true;  
				fi; 
				s3alert!0; //delimiter for alerts. 
			:: (inOrder == false) -> ;
			fi; 
		:: else -> atomic { shuttleMgmtIn!3; shuttleMgmtIn!0 };	s3conf?inOrder; 
		fi;	
	:: (inOrder == true) ->
		if
		:: (fetch) -> passengers[station] = 0; 
		:: else -> ;
		fi; 

		s3alert?reqOrderNumber;
		
		if 
		:: (reqOrderNumber > 0) -> 
			s3alert?reqSourceStation;
			s3alert?reqDestStation;
			s3alert?reqCapacity;

			byte currentCapacity = passengers[1] + passengers[2] + passengers[3] + passengers[4]; 
			toCharge = reqCapacity * charge; 

			bool canAccept = ((currentCapacity + reqCapacity) <= capacity) && 
				( (clockwise && (station - 1) != reqSourceStation) || 
				   (!clockwise && (station + 1) != reqSourceStation) ); 

			bool newOrder = false; 

			if 
			:: (canAccept) -> atomic { shuttleMgmtIn!3; shuttleMgmtIn!toCharge }; s3conf?newOrder;
			:: (!canAccept) -> atomic { shuttleMgmtIn!3; shuttleMgmtIn!0 };	s3conf?newOrder; 
			fi;

			if
			::(newOrder) -> 
				passengers[reqDestStation] = reqCapacity; 
			:: else -> ; 
			fi;
			
		:: else -> s3alert!0; //no orders received
		fi;
		
		if
		:: (fetch == false && sourceStation == station) -> fetch = true; 
		:: (fetch == true && (passengers[1] + passengers[2] + passengers[3] + passengers[4]) == 0) -> 
			inOrder = false; fetch = false; s3alert?0; // remove last 0;
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

proctype shuttle4(byte station; byte capacity; byte charge)
{
	bool fetch = false; 
	bool inOrder = false; 
	bool clockwise = true; 
	byte sourceStation = station; 

	// order mgmt
	byte reqOrderNumber;
	byte reqSourceStation; 
	byte reqDestStation; 
	byte reqCapacity; 
	
	byte passengers[5]; // 1 -> stn1, 2 -> stn2, 3 -> stn3, etc. 
	
	do
	:: (inOrder == false) -> 
		s4alert?reqOrderNumber;
		s4alert?reqSourceStation;
		s4alert?reqDestStation;
		s4alert?reqCapacity;
		if
		:: (reqCapacity <= capacity) -> 
			int toCharge = reqCapacity * charge; 
			atomic { shuttleMgmtIn!4; shuttleMgmtIn!toCharge }; s4conf?inOrder;
				 	
			if 
			:: (inOrder == true) -> 
				sourceStation = reqSourceStation;
				passengers[reqDestStation] = reqCapacity; 
				if
				// directly opposite / current station can just use clockwise
				:: ( (station == 1 && sourceStation == 4) || (station - sourceStation == 1)) -> 
					clockwise = false; 
				:: else -> clockwise = true;  
				fi; 
				s3alert!0; //delimiter for alerts. 
			:: (inOrder == false) -> ;
			fi; 
		:: else -> atomic { shuttleMgmtIn!4; shuttleMgmtIn!0 };	s4conf?inOrder; 
		fi;	

	:: (inOrder == true) ->
		if
		:: (fetch) -> passengers[station] = 0; 
		:: else -> ;
		fi; 

		s4alert?reqOrderNumber;
		
		if 
		:: (reqOrderNumber > 0) -> 
			s4alert?reqSourceStation;
			s4alert?reqDestStation;
			s4alert?reqCapacity;

			byte currentCapacity = passengers[1] + passengers[2] + passengers[3] + passengers[4]; 
			toCharge = reqCapacity * charge; 

			bool canAccept = ((currentCapacity + reqCapacity) <= capacity) && 
				( (clockwise && (station - 1) != reqSourceStation) || 
				   (!clockwise && (station + 1) != reqSourceStation) ); 

			bool newOrder = false; 

			if 
			:: (canAccept) -> atomic { shuttleMgmtIn!4; shuttleMgmtIn!toCharge }; s4conf?newOrder;
			:: (!canAccept) -> atomic { shuttleMgmtIn!4; shuttleMgmtIn!0 };	s4conf?newOrder; 
			fi;

			if
			::(newOrder) -> 
				passengers[reqDestStation] = reqCapacity; 
			:: else -> ; 
			fi;
			
		:: else -> s4alert!0; //no orders received
		fi;
		
		if
		:: (fetch == false && sourceStation == station) -> fetch = true; 
		:: (fetch == true && (passengers[1] + passengers[2] + passengers[3] + passengers[4]) == 0) -> 
			inOrder = false; fetch = false; s4alert?0; // remove last 0;
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

proctype order(byte orderNumber; byte sourceStn; byte destStn; byte numPeople) {
	atomic {
	orderMgmtIn!orderNumber;
	orderMgmtIn!sourceStn;
	orderMgmtIn!destStn;
	orderMgmtIn!numPeople;
	}
}
init {
	//order -> (byte orderNumber; byte sourceStn; byte destStn; byte numPeople)
	run order(1, 1, 3, 4); 
	run order(2, 2, 3, 2); 

	//shuttle -> (byte station; byte capacity; byte charge)
	run shuttle1(1,4,2); 
	run shuttle2(1,2,4); 
	run shuttle3(2,5,1);
	run shuttle4(3,3,3); 
}
