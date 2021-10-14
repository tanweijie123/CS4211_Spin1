mtype = { IDLE, PRE_INIT, INIT, POST_INIT, PRE_UPDATING, UPDATING, POST_UPDATING, POST_REVERTING }; 
mtype:connStatus = { NO, IP, YES }; // IP = in progress
mtype:job = { FAILED, SUCCESS, CONNECTED, DISCONNECTED, GET_WEATHER, USE_WEATHER, USE_OLD };

bool WCP_enabled = true; 
int WCP_current_weather = 0; 

chan cm_request = [1] of { byte }; 
chan wcp_update = [1] of { byte };

byte numClients = 3; 

// 1-based indexing, so num = num+1; 
chan client_in[4] = [1] of { mtype:job }; //used for communication INTO the client (ie. Manager -> Client) 
chan client_out[4] = [1] of { mtype:job }; // used for communication OUT of client (ie. Client -> Manager) 

mtype status[4] = { IDLE, IDLE, IDLE, IDLE}; // 0-th array is CM, 1-st onwards is clients 
mtype:connStatus isConnected[4] = { NO, NO, NO, NO }; // for clients to check their connection status
int clientWeather[4] = { 0, 0, 0, 0 }; //for client weather

active proctype CommManager() {
	int pending_weather = 0; 
		
	//var declaration
	byte newRequestFrom = 0; 
	byte newWeatherUpdate = 0; 
	int i;
	bool allSuccess = true; 

	do
	:: (status[0] == IDLE) -> 
		do
		:: cm_request?newRequestFrom -> 
		
			WCP_enabled = false; 
			status[0] = PRE_INIT;
			status[newRequestFrom] = PRE_INIT; 
			client_in[newRequestFrom]!CONNECTED; 
			break; 
		:: wcp_update?newWeatherUpdate -> 
			WCP_enabled = false; 
			status[0] = PRE_UPDATING; 

			// loop through all connected (update status to pre-updating) 
 
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> status[i] = PRE_UPDATING; 
				:: else -> ;
				fi; 
			}
			break; 
		od; 
	:: (status[0] == PRE_INIT) -> 
		client_in[newRequestFrom]!GET_WEATHER;
		status[0] = INIT;
		status[newRequestFrom] = INIT; 

	:: (status[0] == INIT) -> 
		mtype:job retrieve_success = false;
		client_out[newRequestFrom]?retrieve_success; 

		if 
		:: (retrieve_success == SUCCESS) -> 
			client_in[newRequestFrom]!USE_WEATHER; 
			status[0] = POST_INIT; 
			status[newRequestFrom] = POST_INIT; 
		:: else -> 
			client_in[newRequestFrom]!DISCONNECTED; 
			status[0] = IDLE; 
			status[newRequestFrom] = IDLE;  
			WCP_enabled = true; 
		fi; 
	:: (status[0] == POST_INIT) -> 
		mtype:job use_success = false;
		client_out[newRequestFrom]?use_success; 

		if 
		:: (use_success == FAILED) -> 
			client_in[newRequestFrom]!DISCONNECTED; 
		:: else -> ; 
		fi; 
		
		status[0] = IDLE; 
		status[newRequestFrom] = IDLE;  
		WCP_enabled = true; 
	:: (status[0] != IDLE) -> 
		byte rejectRequestFrom = 0; 
		do 
		:: cm_request?rejectRequestFrom -> client_in[rejectRequestFrom]!FAILED; 
		:: empty(cm_request) -> break;
		//:: true -> break;
		od; 
		 
	:: (status[0] == PRE_UPDATING) -> 
		// loop through all connected (update status to pre-updating)  
		for (i: 1 .. numClients) {
			if
			:: (isConnected[i] == YES) -> 
				client_in[i]!GET_WEATHER;
				status[i] = UPDATING; 
			:: else -> ;
			fi; 
		}
		
		status[0] = UPDATING; 
	:: (status[0] == UPDATING) -> 
		allSuccess = true; 

		// loop through all connected (and get all update status) 
		for (i: 1 .. numClients) {
			if
			:: (isConnected[i] == YES) -> 
				mtype:job isSuccessful = SUCCESS; 
				client_out[i]?isSuccessful; 
				allSuccess = (allSuccess && (isSuccessful == SUCCESS) ); 
			:: else -> ;
			fi; 
		}

		if
		:: (allSuccess) -> 
			// loop through all connected (and update all to POST_UPDATING) 
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> 
					client_in[i]!USE_WEATHER; 
					status[i] = POST_UPDATING;  
				:: else -> ;
				fi; 
			}
			
			status[0] = POST_UPDATING;
			
		:: else -> 
			//someone failed; 
			// loop through all connected (and update all to POST_REVERTING) 
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> 
					client_in[i]!USE_OLD; 
					status[i] = POST_REVERTING;  
				:: else -> ;
				fi; 
			}

			status[0] = POST_REVERTING;
		fi; 
	:: (status[0] == POST_UPDATING) -> ;
		allSuccess = true; 

		// loop through all connected (and get all update status) 
		for (i: 1 .. numClients) {
			if
			:: (isConnected[i] == YES) -> 
				mtype:job isSuccessful = SUCCESS; 
				client_out[i]?isSuccessful; 
				allSuccess = (allSuccess && (isSuccessful == SUCCESS) ); 
			:: else -> ;
			fi; 
		}

		if
		:: (allSuccess) -> 
			// loop through all connected (and update all to IDLE)  
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> 
					status[i] = IDLE;   
				:: else -> ;
				fi; 
			}
			
			status[0] = IDLE; 
			WCP_enabled = true; 
			
		:: else -> 
			//someone failed; 
			// loop through all connected (and disconnect all) 
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> 
					isConnected[i] = NO; 
					//status[i] = IDLE;   to check if client reset to IDLE
				:: else -> ;
				fi; 
			}

			status[0] = IDLE; 
			WCP_enabled = true; 
		fi; 
	:: (status[0] == POST_REVERTING) -> ;
		allSuccess = true; 

		// loop through all connected (and get all update status) 
		for (i: 1 .. numClients) {
			if
			:: (isConnected[i] == YES) -> 
				mtype:job isSuccessful = SUCCESS; 
				client_out[i]?isSuccessful; 
				allSuccess = (allSuccess && (isSuccessful == SUCCESS) ); 
			:: else -> ;
			fi; 
		}

		if
		:: (allSuccess) -> 
			// loop through all connected (and update all to IDLE)  
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> 
					status[i] = IDLE;   
				:: else -> ;
				fi; 
			}
			
			status[0] = IDLE; 
			WCP_enabled = true; 
			
		:: else -> 
			//someone failed; 
			// loop through all connected (and disconnect all) 
			for (i: 1 .. numClients) {
				if
				:: (isConnected[i] == YES) -> 
					isConnected[i] = NO; 
					//status[i] = IDLE;   to check if client reset to IDLE
				:: else -> ;
				fi; 
			}

			status[0] = IDLE; 
			WCP_enabled = true; 
		fi; 
	od; 

}

proctype Client(byte clientId) {
	int pending_weather = 0; 
	int finalised_weather = 0; 
	
	//var declaration
	mtype:job resp; 
	bool retrieve_success = true; 
	bool use_success = true; 

	do
	:: (isConnected[clientId] == NO) -> 
		cm_request!clientId; 
		client_in[clientId]?resp; 

		if 
		:: (resp == CONNECTED) -> isConnected[clientId] = IP; 
		:: (resp == FAILED) -> isConnected[clientId] = NO; 
		:: else -> ;
		fi; 
	:: client_in[clientId]?resp -> //listen for commands  
		if
		:: (isConnected[clientId] == IP && resp == GET_WEATHER) -> 
			pending_weather = WCP_current_weather; 
			retrieve_success = (pending_weather == WCP_current_weather);  
			if
			:: (retrieve_success) -> client_out[clientId]!SUCCESS;
			:: else -> 
				client_out[clientId]!FAILED; 
				client_in[clientId]?DISCONNECTED; 
				isConnected[clientId] = NO; 
			fi; 			
		:: (isConnected[clientId] == IP && resp == USE_WEATHER) -> 
			finalised_weather = pending_weather; 
			use_success = (finalised_weather == pending_weather); 
			if
			:: (use_success) -> 
				client_out[clientId]!SUCCESS; 
				isConnected[clientId] = YES; 
				clientWeather[clientId] = finalised_weather; 
			:: else -> 
				client_out[clientId]!FAILED; 
				client_in[clientId]?DISCONNECTED; 
				isConnected[clientId] = NO;
			fi;
		:: (isConnected[clientId] == YES && resp == GET_WEATHER) -> 
			
			pending_weather = WCP_current_weather; 
			retrieve_success = (pending_weather == WCP_current_weather);  

			if
			:: (retrieve_success) -> client_out[clientId]!SUCCESS;
			:: else -> client_out[clientId]!FAILED; 
			// :: true -> client_out[clientId]!FAILED; // FOR NON-DETERMINISTIC PURPOSE
			fi; 

		:: (isConnected[clientId] == YES && resp == USE_WEATHER) -> 
			finalised_weather = pending_weather; 
			use_success = (finalised_weather == pending_weather); 
			
			if
			:: (retrieve_success) -> 
				client_out[clientId]!SUCCESS; 
				clientWeather[clientId] = finalised_weather;
			:: else -> client_out[clientId]!FAILED; 
			fi; 

		:: (isConnected[clientId] == YES && resp == USE_OLD) -> 
			pending_weather = clientWeather[clientId]; 
			use_success = (clientWeather[clientId] == pending_weather); 

			if
			:: (retrieve_success) -> 
				client_out[clientId]!SUCCESS; 
				finalised_weather = clientWeather[clientId]; 
			:: else -> client_out[clientId]!FAILED; 
			fi; 

		:: else -> ; 
		fi;  	
	od; 

}

active proctype User() {
	byte expectedUpdate = 5; 
	byte numUpdate = 0; 

	// non deterministic update and exit 
	do 
	:: (WCP_enabled) -> 
		numUpdate = numUpdate + 1; 
		wcp_update!numUpdate; 
		WCP_current_weather = numUpdate; 
	:: (true) -> skip; 
	:: (numUpdate > expectedUpdate) -> break; 
	od; 
}

init {
	// Client (byte clientId)
	run Client(1); 
	run Client(2); 
	run Client(3); 
}

//eventually clients will have the lastest weather update

#define updatedWeather (clientWeather[1] == WCP_current_weather) && (clientWeather[2] == WCP_current_weather) && (clientWeather[3] == WCP_current_weather)

ltl v1 { []<> (updatedWeather) }
