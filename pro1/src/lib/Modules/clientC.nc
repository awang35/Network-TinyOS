/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#include "TCPSocketAL.h"
#include "clientAL.h"
#include "../packet.h"

enum{
		BYTES_TO_SEND = 100
};

module clientC{
	uses{
		interface TCPSocket<TCPSocketAL>;
	
		interface Timer<TMilli> as ClientTimer;
		interface Random;
		interface TCPManager<TCPSocketAL,pack>;
	}
	provides{
		interface client<TCPSocketAL>;
	}
}
implementation{
	clientAL mClient;
	command void client.init(TCPSocketAL *socket){
		mClient.socket = socket;
		mClient.startTime = 0;
		mClient.position = 0;
		mClient.amount=BYTES_TO_SEND;
	
		call ClientTimer.startPeriodic(CLIENT_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	event void ClientTimer.fired(){
		TCPSocketAL connectedSock;
		TCPSocketAL *test;
		bool testa;
		uint8_t newPort;
		//dbg("Project3", "ClientSocket Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",mClient.socket->uniqueID,mClient.socket->srcID,mClient.socket->destID,mClient.socket->srcPort,mClient.socket->destPort, mClient.socket->currentState);

		if(call TCPSocket.isConnectPending( (mClient.socket->srcPort) )){
			dbg("clientAL", "clientAL - Connection Pending...\n");
		}else if(call TCPSocket.isConnected( (mClient.socket->srcPort) )){
			uint16_t bufferIndex, len, count;
	
			if(mClient.startTime == 0){ // First Iteration
				mClient.startTime = call ClientTimer.getNow();
				dbg("clientAL", "clientAL - Connection established at time: %lu\n Bytes to be send: %lu\n", mClient.startTime, mClient.amount);
			}
	
			if(mClient.amount == 0){
				//Finish sending all the bytes.
				uint32_t closeTime;
				closeTime = call ClientTimer.getNow();
	
				dbg("clientAL", "clientAL - Sending Completed at time: %lu\n",closeTime);
				dbg("clientAL", "Connection Closing...\n");
	
				call TCPSocket.close( (mClient.socket->srcPort) );
				return;
			}
	
			bufferIndex = mClient.position % CLIENTAL_BUFFER_SIZE;
	
			if(bufferIndex == 0){ // Out of data, time to create more.
				uint16_t i, offset;
	
				dbg("clientAL", "clientAL - Creating additional data.\n");
	
				offset = mClient.position/255 + 1; //Offset to remove any 0s from the data.
				for(i=0; i< CLIENTAL_BUFFER_SIZE; i++){
					mClient.buffer[i] = (uint8_t)((mClient.position + i + offset)&0x00FF); //Clears first 8 bits in the 16bit int.
	
					//dbg("clientAL", "clientAL - POS: %lu, Data: %hhu \n", i, mClient.buffer[i]);
				}
			}
	
			//Which is the min, the number of bytes in the buffer or the total number of bytes to be sent.
			if(CLIENTAL_BUFFER_SIZE - bufferIndex < mClient.amount){
				len = CLIENTAL_BUFFER_SIZE - bufferIndex;
				//len = CLIENTAL_BUFFER_SIZE;
				dbg("clientAL", "buffer-index was least\n");
			}else{
				dbg("clientAL", "amount was least\n");
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
