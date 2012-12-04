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
	bool needRead;
	//int amountToSend = 0;	
	void clearBuffer(){
		memset (mClient.buffer,0,CLIENTAL_BUFFER_SIZE);
	}
	
	void clearReadBuffer(){
		memset (mClient.readBuffer,0,CLIENTAL_BUFFER_SIZE);
	}
	command void chatClient.init(TCPSocketAL *socket, void* name){
		char * pch;
		int i =0;
		uint8_t charBuffer;
		pack* myMsg=(pack*) name;
		buffer = *myMsg;
		mClient.socket = socket;
		mClient.startTime = 0;
		mClient.needRead = FALSE;
		mClient.position = 0;
		mClient.amount= 0;
		mClient.readPosition = 0;
		mClient.amountToRead = 0;
		firstTime = TRUE;
		mClient.payload = *myMsg;
		needRead = FALSE;
		clearBuffer();
		clearReadBuffer();
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
	
	

	async command void chatClient.addData(uint8_t data){
		dbg("Project4","%c was added to read buffer\n",data);
	
		mClient.amountToRead = mClient.amountToRead%CLIENTAL_BUFFER_SIZE;
		mClient.readBuffer[mClient.amountToRead] = data;
		//dbg("Project4","Did it write? %c");
		mClient.amountToRead++;
	}
	command void chatClient.msgCommand(uint8_t* _msg){
		uint8_t charBuffer;
		int i =0;
	
	//	dbg("Project4","what am i going to send %s\n",_msg);
		//strncpy(temp, (_msg),strlen(_msg));
		charBuffer = _msg[i];
	
		while(charBuffer!= 0){
			//dbg("Project4","%s\n",charBuffer);
			mClient.buffer[i] = charBuffer;
			mClient.amount++;
			i++;
			charBuffer = _msg[i];
		}
	//	dbg("Project4","new amount: %d\n",mClient.amount);
		//call ClientTimer.startPeriodic(CLIENT_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	void printBuffer(){
		int i = 0;
		char temp;
		temp = mClient.readBuffer[i];
		dbg_clear("Project4", "--------Printing Client Buffer-------\n");
		while(temp!=0){
			dbg_clear("Project4", "%c",temp);
			i++;
			temp = mClient.readBuffer[i];
	
		}
		dbg_clear("Project4", "\n");
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
				clearBuffer();
				mClient.position = 0;
				//dbg("clientAL", "clientAL - Sending Completed at time: %lu\n",closeTime);
				dbg("clientAL", "Waiting for input...\n");
				//call ClientTimer.stop(); 
				//call TCPSocket.close( (mClient.socket->srcPort) );
	
			}
			else{
					bufferIndex = mClient.position % CLIENTAL_BUFFER_SIZE;
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
				mClient.amount -= count;
				mClient.position += count;
			}
			//printBuffer();
			if(mClient.readBuffer[0]!=0){
				uint16_t readerIndex, readLen, counts;
				dbg("clientAL", "Need to read\n");
				//printBuffer();
				readerIndex = mClient.readPosition%CLIENTAL_BUFFER_SIZE;
				readLen = CLIENTAL_BUFFER_SIZE - readerIndex;
				counts =call TCPSocket.read(mClient.socket->srcPort,mClient.readBuffer,mClient.readPosition%CLIENTAL_BUFFER_SIZE,readLen);
				if(counts>0){
					uint16_t i,j;
					char * pch;
					mClient.readPosition+=counts;
					for(i = 0;i<mClient.readPosition;i++){
						if( mClient.readBuffer[ (i)%CLIENTAL_BUFFER_SIZE] == '\r'){
							if( mClient.readBuffer[ (i)%CLIENTAL_BUFFER_SIZE+1] == '\n'){
								dbg("Project4","Recieved a new message message. I should see what the message was:\n");
								printBuffer();
								clearReadBuffer();
							}
						}
					}
	
				}
	
			}
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
