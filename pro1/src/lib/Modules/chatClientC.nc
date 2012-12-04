/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author Adrian Wang
 * @date   December 1 2012
 * 
 */ 

#include "TCPSocketAL.h"
#include "clientAL.h"
#include "../packet.h"



module chatClientC{
	uses{
		interface TCPSocket<TCPSocketAL>;
	
		interface Timer<TMilli> as ClientTimer;
		interface Random;
		interface TCPManager<TCPSocketAL,pack>;
	}
	provides{
		interface chatClient<TCPSocketAL>;
	}
}
implementation{
	clientAL mClient;
	char *msg;
	pack buffer;
	bool firstTime;
	//int amountToSend = 0;	
	command void chatClient.init(TCPSocketAL *socket, void* name){
		char * pch;
		int i =0;
		uint8_t charBuffer;
		pack* myMsg=(pack*) name;
		buffer = *myMsg;
		mClient.socket = socket;
		mClient.startTime = 0;
		mClient.position = 0;
		mClient.amount= 0;
		firstTime = TRUE;
		mClient.payload = *myMsg;
		//mClient.payload.payload;
		//dbg("Project4","UserName on setup mClient: %s. size of load %d\n",mClient.payload.payload,sizeof(mClient.payload.payload));
		pch = strtok (buffer.payload," ");
							i=0;
							while (pch!= NULL){
								//dbg("Project3", "%s\n",pch);
								if(i == 2){
									//dbg("Project4", "Welcome user %s.\nConnecting you to server now.\n",pch);
									mClient.name = pch;
									//srcPort = atoi(pch);
									}
								pch = strtok (NULL, " ");
								i++;
							}
	pch = strtok (mClient.payload.payload," ");
	msg =	strtok (NULL, "");
	
	i = 0;
	charBuffer = msg[i];
	//dbg("Project4","%d\n",charBuffer);
	while(charBuffer!= 0){
		//dbg("Project4","%s\n",charBuffer);
		
		mClient.amount++;
		i++;
		charBuffer = msg[i];
		
	}
	//dbg("Project4","msg to send: %s, size: %d", msg, mClient.amount);
		call ClientTimer.startPeriodic(CLIENT_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	
	void clearBuffer(){
		memset (mClient.buffer,0,CLIENTAL_BUFFER_SIZE);
	}
	command void chatClient.msgCommand(uint8_t* _msg){
		uint8_t charBuffer;
		int i =0;
		
		dbg("Project4","what am i going to send %s\n",_msg);
		//strncpy(temp, (_msg),strlen(_msg));
		charBuffer = _msg[i];
		
		while(charBuffer!= 0){
		//dbg("Project4","%s\n",charBuffer);
			mClient.buffer[i] = charBuffer;
			mClient.amount++;
			i++;
			charBuffer = _msg[i];
		}
		dbg("Project4","new amount: %d\n",mClient.amount);
		call ClientTimer.startPeriodic(CLIENT_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	event void ClientTimer.fired(){
		TCPSocketAL connectedSock;
		TCPSocketAL *test;
		bool testa;
		uint8_t newPort;
		//dbg("Project3", "ClientSocket Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",mClient.socket->uniqueID,mClient.socket->srcID,mClient.socket->destID,mClient.socket->srcPort,mClient.socket->destPort, mClient.socket->currentState);
		//dbg("Project4","UserName on setup mClient: %s\n",mClient.name);
		if(call TCPSocket.isConnectPending( (mClient.socket->srcPort) )){
			dbg("clientAL", "clientAL - Connection Pending...\n");
		}else if(call TCPSocket.isConnected( (mClient.socket->srcPort) )){
			uint16_t bufferIndex, len, count, k;
	
			if(mClient.startTime == 0){ // First Iteration
				mClient.startTime = call ClientTimer.getNow();
				dbg_clear("clientAL", "clientAL - Connection established at time: %lu\n", mClient.startTime);
				dbg_clear("Project4","******************************************************************************\n");
				dbg_clear("Project4", "**\tWelcome user %s.\n**\tConnecting you to server now.\n",mClient.name);
				dbg_clear("Project4","******************************************************************************\n");
				for(k = 0;k<mClient.amount;k++){
					//dbg_clear("Project4", "storing %c in buffer\n",msgHello[k]);
					mClient.buffer[k] = msg[k];			
				}
				bufferIndex = mClient.amount;
			}
	
			if(mClient.amount == 0){
				//Finish sending all the bytes.
				uint32_t closeTime;
				closeTime = call ClientTimer.getNow();
				clearBuffer();
				mClient.position = 0;
				dbg("clientAL", "clientAL - Sending Completed at time: %lu\n",closeTime);
				dbg("clientAL", "Waiting for input...\n");
				call ClientTimer.stop(); 
					//call TCPSocket.close( (mClient.socket->srcPort) );
				return;
			}
	
			bufferIndex = mClient.position % CLIENTAL_BUFFER_SIZE;
	
			//if(bufferIndex == 0&&!firstTime){ // Out of data, time to create more.
				//uint16_t i, offset;
	
				//dbg("clientAL", "clientAL - Creating additional data.\n");
				
				
//				offset = mClient.position/255 + 1; //Offset to remove any 0s from the data.
//				for(i=0; i< CLIENTAL_BUFFER_SIZE; i++){
//					mClient.buffer[i] = (uint8_t)((mClient.position + i + offset)&0x00FF); //Clears first 8 bits in the 16bit int.
//	
//					//dbg("clientAL", "clientAL - POS: %lu, Data: %hhu \n", i, mClient.buffer[i]);
//				}
	//		}
		//	firstTime = FALSE;
			//Which is the min, the number of bytes in the buffer or the total number of bytes to be sent.
			if(CLIENTAL_BUFFER_SIZE - bufferIndex < mClient.amount){
				len = CLIENTAL_BUFFER_SIZE - bufferIndex;
				//len = CLIENTAL_BUFFER_SIZE;
				//dbg("clientAL", "buffer-index was least\n");
			}else{
				//dbg("clientAL", "amount was least\n");
				len = mClient.amount;
			}
	
			count = call TCPSocket.write((mClient.socket->srcPort), mClient.buffer, bufferIndex, len);
	
			if(count == -1){
				//Error, release socket immediately.
				uint32_t endTime;
	
				endTime = call ClientTimer.getNow();
				dbg("clientAL", "clientAL - Sending aborted at time %lu\n Position: %lu\n", endTime, mClient.position);
				call TCPSocket.release( (mClient.socket) );
	
				call ClientTimer.stop();
				return;
			}
	
			mClient.amount -= count;
			mClient.position += count;
		}else if(call TCPSocket.isClosing(mClient.socket->srcPort)){
			//Debugging statements
			//dbg("clientAL", "clientAL ----- CLOSING!\n");
		}else if(call TCPSocket.isClosed( (mClient.socket->srcPort) )){
			uint32_t endTime = call ClientTimer.getNow();
	
			dbg("clientAL", "clientAL - Conection Closed at time: %lu \n Bytes sent: %lu\n Time Elapsed: %lu\n Bytes per Second %lu\n",
					endTime, mClient.position, (endTime - mClient.startTime), (mClient.position * 1000 / (endTime - mClient.startTime)) );
		
			call TCPSocket.release(mClient.socket);
			call ClientTimer.stop();

			return;
		}
	}	
}
