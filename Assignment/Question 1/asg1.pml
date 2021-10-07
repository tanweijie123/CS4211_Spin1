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

// Track name syntax: Track<From><To>

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

byte numShuttle = 4; 

chan orderMgmtIn = [4] of { byte };  //first = ordernum, second for source, 3rd for dest, 4th for capacity
chan shuttleMgmtIn = [8] of { byte }; // { first = shuttle#, second = price (0 for fail); } * numShuttle

// 1-based indexing for easy management
// salert -> shuttle alert (for new order / check alive status) 
// sconfirm -> shuttle order confirmation status
chan salert[5] = [5] of { byte }; //first = ordernum, second for source, 3rd for dest, 4th for capacity, extra space for {0} feeder
chan sconfirm[5] = [1] of { bit };

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
		
		int i;
		for (i : 1 .. numShuttle) {
			atomic {
			salert[i]!reqOrderNumber; 
			salert[i]!reqSourceStation;
			salert[i]!reqDestStation;
			salert[i]!reqCapacity;
			}
		}
		// receive reply & get assign to lowest
		int lowestPrice = 1000000; 
		int lowestShuttle = 0; 
		int thisPrice = lowestPrice; 
		int thisShuttle = lowestShuttle; 

		int j; 
		for (j : 1 .. numShuttle) {
			shuttleMgmtIn?thisShuttle;
			shuttleMgmtIn?thisPrice; 
			if 
			::(thisPrice == 0) -> ;
			::(thisPrice > 0 && thisPrice < lowestPrice) -> 
				lowestPrice = thisPrice; lowestShuttle = thisShuttle;
			::else ->; 
			fi;
		}

		int k
		for (k : 1 .. numShuttle) {
			sconfirm[k]!(lowestShuttle == k);
		} 
	od; 
	
}

proctype shuttle(byte shuttleNum; byte station; byte capacity; byte charge)
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
		salert[shuttleNum]?reqOrderNumber;

		if
		:: (reqOrderNumber == 0) -> ;
		:: else -> 
			salert[shuttleNum]?reqSourceStation;
			salert[shuttleNum]?reqDestStation;
			salert[shuttleNum]?reqCapacity;
			if
			:: (reqCapacity <= capacity) -> 
				int toCharge = reqCapacity * charge; 
				atomic { shuttleMgmtIn!shuttleNum; shuttleMgmtIn!toCharge }; sconfirm[shuttleNum]?inOrder;				 	
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
					salert[shuttleNum]!0; //delimiter for alerts. 
				:: (inOrder == false) -> ;
				fi; 
			:: else -> atomic { shuttleMgmtIn!shuttleNum; shuttleMgmtIn!0 };	sconfirm[shuttleNum]?inOrder; 
			fi;
		fi;	
	:: (inOrder == true) ->
		if
		:: (fetch) -> passengers[station] = 0; 
		:: else -> ;
		fi; 

		salert[shuttleNum]?reqOrderNumber;
		
		if 
		:: (reqOrderNumber > 0) -> 
			salert[shuttleNum]?reqSourceStation;
			salert[shuttleNum]?reqDestStation;
			salert[shuttleNum]?reqCapacity;

			byte currentCapacity = passengers[1] + passengers[2] + passengers[3] + passengers[4]; 
			toCharge = reqCapacity * charge; 

			bool canAccept = ((currentCapacity + reqCapacity) <= capacity) && 
				( (clockwise && (station - 1) != reqSourceStation) || 
				   (!clockwise && (station + 1) != reqSourceStation) ); 

			bool newOrder = false; 

			if 
			:: (canAccept) -> 
				atomic { shuttleMgmtIn!shuttleNum; shuttleMgmtIn!toCharge }; 
				sconfirm[shuttleNum]?newOrder;
			:: (!canAccept) -> 
				atomic { shuttleMgmtIn!shuttleNum; shuttleMgmtIn!0 };	
				sconfirm[shuttleNum]?newOrder; 
			fi;

			if
			::(newOrder) -> 
				passengers[reqDestStation] = reqCapacity; 
			:: else -> ; 
			fi;
			
		:: else -> salert[shuttleNum]!0; //no orders received
		fi;
		
		if
		:: (fetch == false && sourceStation == station) -> fetch = true; 
		:: (fetch == true && (passengers[1] + passengers[2] + passengers[3] + passengers[4]) == 0) -> 
			inOrder = false; fetch = false;
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
	// TrackXX and Management are active on execution. 

	//order -> (byte orderNumber; byte sourceStn; byte destStn; byte numPeople)
	run order(1, 1, 3, 4); 
	run order(2, 2, 3, 2); 

	//shuttle -> (byte shuttleNum; byte station; byte capacity; byte charge)
	run shuttle(1,1,4,2); 
	run shuttle(2,1,2,4); 
	run shuttle(3,2,5,1);
	run shuttle(4,3,3,3); 
}
