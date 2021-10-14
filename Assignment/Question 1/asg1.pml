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

int totalTrainOnTracks = 0; // for ltl check

// Track name syntax: Track<From><To>

active proctype Track12() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch12e) -> ch12?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch12e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track23() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch23e) -> ch23?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch23e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track34() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch34e) -> ch34?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch34e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track41() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch41e) -> ch41?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch41e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track14() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch14e) -> ch14?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch14e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track43() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch43e) -> ch43?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch43e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track32() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch32e) -> ch32?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch32e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}
active proctype Track21() 
{
	bool inUse = false; 
	byte shuttle; 
	do 
	:: !inUse && empty(ch21e) -> ch21?shuttle; inUse = true; totalTrainOnTracks = totalTrainOnTracks + 1; 
	:: (inUse) -> ch21e!shuttle; inUse = false; totalTrainOnTracks = totalTrainOnTracks - 1; 
	od;
}

byte numShuttle = 4; 

chan orderMgmtIn = [4] of { byte };  //first = ordernum, second for source, 3rd for dest, 4th for capacity
chan shuttleMgmtIn = [8] of { byte }; // { first = shuttle#, second = price (0 for fail); } * numShuttle
int totalCustomerInSystem = 0; //track all customers for ltl

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
	bool moving = false; 
	chan movingAlert = [0] of {byte};
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
		salert[shuttleNum]?reqSourceStation;
		salert[shuttleNum]?reqDestStation;
		salert[shuttleNum]?reqCapacity;
		if
		:: (reqCapacity <= capacity 
			&& (  (((reqSourceStation + 4 - station) % 4) <= 2 )  // + 4 to prevent negative modulo
			       ||    (((station + 4 - reqSourceStation ) % 4) <= 2 )  ) 
		    )-> 
			int toCharge = reqCapacity * charge; 
			atomic { shuttleMgmtIn!shuttleNum; shuttleMgmtIn!toCharge }; sconfirm[shuttleNum]?inOrder;				 	185				
			if 
			:: (inOrder == true) -> 
 				totalCustomerInSystem =  totalCustomerInSystem + reqCapacity; 
				sourceStation = reqSourceStation;
				passengers[reqDestStation] = reqCapacity; 
				if
				:: ( ((reqSourceStation + 4 - station) % 4) <= 2) -> 
					clockwise = true;   
				:: else -> clockwise = false;
				fi; 
			:: (inOrder == false) -> ;
			fi; 
		:: else -> atomic { shuttleMgmtIn!shuttleNum; shuttleMgmtIn!0 };	sconfirm[shuttleNum]?inOrder; 
		fi;	
	:: (inOrder == true) ->
		// check if received any new orders.. 
		do
		:: salert[shuttleNum]?reqOrderNumber -> 
			salert[shuttleNum]?reqSourceStation;
			salert[shuttleNum]?reqDestStation;
			salert[shuttleNum]?reqCapacity;

			byte currentCapacity = passengers[1] + passengers[2] + passengers[3] + passengers[4]; 
			toCharge = reqCapacity * charge; 

			bool canAccept = (   ((currentCapacity + reqCapacity) <= capacity)  
				&&  ( (clockwise && (reqSourceStation + 4 - station) <= 2)  
				      ||  (!clockwise && (station + 4 - reqSourceStation) <= 2) )
				); 

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
				totalCustomerInSystem =  totalCustomerInSystem + reqCapacity;  
			:: else -> ; 
			fi;
		:: empty(salert[shuttleNum]) -> break; 
		od; 

		if
		:: (moving) -> 
			do
			:: movingAlert?shuttleNum -> moving = false;
			:: empty(movingAlert) -> break; 
			od; 
		:: else -> ;
		fi; 
		
		if
		:: (fetch && !moving) -> 
			totalCustomerInSystem =  totalCustomerInSystem - passengers[station];
			passengers[station] = 0;  
		:: else -> ;
		fi; 
		
		if
		:: (!moving) -> 
			if
			:: (!fetch && sourceStation == station) -> fetch = true; 
			:: (fetch && (passengers[1] + passengers[2] + passengers[3] + passengers[4]) == 0) ->
				inOrder = false; fetch = false;
			:: else -> 
				moving = true; 
				if
			:: (clockwise == true && station == 1) -> ch12!shuttleNum; station = 2; movingAlert = ch12e; 
			:: (clockwise == true && station == 2) -> ch23!shuttleNum; station = 3; movingAlert = ch23e;
			:: (clockwise == true && station == 3) -> ch34!shuttleNum; station = 4; movingAlert = ch34e;
			:: (clockwise == true && station == 4) -> ch41!shuttleNum; station = 1; movingAlert = ch41e;
			:: (clockwise  == false && station == 1) -> ch14!shuttleNum; station = 4; movingAlert = ch14e;
			:: (clockwise  == false && station == 2) -> ch21!shuttleNum; station = 1; movingAlert = ch21e;
			:: (clockwise  == false && station == 3) -> ch32!shuttleNum; station = 2; movingAlert = ch32e;
			:: (clockwise  == false && station == 4) -> ch43!shuttleNum; station = 3; movingAlert =ch43e;
				fi;
			fi; 
		:: (moving) -> ;
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

#define no_passenger (totalCustomerInSystem == 0)
#define no_train_on_track (totalTrainOnTracks == 0)
ltl v1 { []<> (no_passenger && no_train_on_track) } 
