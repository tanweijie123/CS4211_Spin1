mtype = { IDLE, PRE_INIT, INIT, POST_INIT}; 
mtype:job = { FAILED, SUCCESS, CONNECTED, DISCONNECTED, GET_WEATHER, USE_WEATHER };

bool WCP_enabled = true; 
int WCP_current_weather = 1; 

chan cm_request = [1] of { byte }; 

// 1-based indexing, so num = num+1; 
chan client_in[4] = [1] of { mtype:job }; //used for communication INTO the client (ie. Manager -> Client) 
chan client_out[4] = [1] of { mtype:job }; // used for communication OUT of client (ie. Client -> Manager) 

mtype status[4] = { IDLE, IDLE, IDLE, IDLE}; // 0-th array is CM, 1-st onwards is clients 
bool isConnected[4] = { false, false, false, false }; // for clients to check their connection status

active proctype CommManager() {
		
	//var declaration
	byte newRequestFrom = 0; 

	do
	:: (status[0] == IDLE) -> 
		cm_request?newRequestFrom; 
		
		//set both its own status and the conn.client status to pre-init; disable WCP
		status[0] = PRE_INIT;
		status[newRequestFrom] = PRE_INIT; 
		WCP_enabled = false; 
		client_in[newRequestFrom]!CONNECTED; 
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
		od; 
		 
		
	od; 

}

proctype Client(byte clientId) {
	int current_weather = 0; 
	int pending_weather = 0; 
	
	//var declaration
	mtype:job resp; 

	do
	:: (!isConnected[clientId]) -> 
		atomic { cm_request!clientId; } 
		client_in[clientId]?resp; 

		if 
		:: (resp == CONNECTED) -> isConnected[clientId] = true; 
		:: (resp == FAILED) -> isConnected[clientId] = false; 
		:: else -> ;
		fi; 
	:: (isConnected[clientId]) -> 
		client_in[clientId]?resp; //listen for jobs 
		
		if
		:: (resp == GET_WEATHER) -> 
			atomic { pending_weather = WCP_current_weather; } 
			bool retrieve_success = (pending_weather == WCP_current_weather);  
			if
			:: (retrieve_success) -> client_out[clientId]!SUCCESS;
			:: else -> 
				client_out[clientId]!FAILED; 
				client_in[clientId]?DISCONNECTED; 
				isConnected[clientId] = false; 
			fi; 
		:: (resp == USE_WEATHER) -> 
			atomic { current_weather = pending_weather; } 
			bool use_success = (current_weather == pending_weather); 
			if
			:: (use_success) -> client_out[clientId]!SUCCESS;
			:: else -> 
				client_out[clientId]!FAILED; 
				client_in[clientId]?DISCONNECTED; 
				isConnected[clientId] = false; 
			fi; 
		fi; 	
	od; 

}

init {
	// Client (byte clientId)
	run Client(1); 
	run Client(2); 
	run Client(3); 
}
