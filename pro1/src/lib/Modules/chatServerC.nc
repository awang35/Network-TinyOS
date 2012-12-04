/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#include "serverAL.h"
#include "TCPSocketAL.h"
#include "serverWorkerList.h"
#include "../packet.h"
#include <string.h>

module chatServerC{
	uses{
		interface TCPSocket<TCPSocketAL>;
		interface Timer<TMilli> as ServerTimer;
		interface Timer<TMilli> as WorkerTimer;
		interface Random;
		interface TCPManager<TCPSocketAL,pack>;
	}
	provides{
		interface chatServer<TCPSocketAL>;
		interface serverWorker<serverWorkerAL, TCPSocketAL>;
	}
}
implementation{
	//Local Variables Variables
	serverAL mServer;	
	serverWorkerList workers;
	userList list[20];
	//uint8_t sendBuffer[50];
	uint8_t listIndex;
	command void chatServer.init(TCPSocketAL *socket){
		mServer.socket = socket;
		mServer.numofWorkers=0;	
		listIndex = 0;
		//dbg("Project3", "Server. Current State: %d\n", mServer.socket->currentState);
		call ServerTimer.startPeriodic(SERVER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
		call WorkerTimer.startPeriodic(WORKER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	event void ServerTimer.fired(){
		if(! call TCPSocket.isClosed(mServer.socket->srcPort) ){
			TCPSocketAL connectedSock;
			TCPSocketAL *test;
			uint8_t newPort;
			dbg("serverAL", "serverAL - Looking for new connection.\n");
			//Attempt to Establish a Connection
	
			newPort = call Random.rand16()%255;
			if(call TCPSocket.accept(mServer.socket->srcPort, newPort) == TCP_ERRMSG_SUCCESS){
				serverWorkerAL newWorker;
				test = call TCPManager.getSocket(newPort);
				connectedSock = *test;
				//dbg("Project3", "ConnectedSock Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",connectedSock.uniqueID,connectedSock.srcID,connectedSock.destID,connectedSock.srcPort,connectedSock.destPort, connectedSock.currentState);
				dbg("serverAL", "serverAL - Connection Accepted.\n");
				//dbg("serverAL", "serverAL - New worker. ID: %d.\n",mServer.numofWorkers);				
				//create a worker.
				call serverWorker.init(&newWorker, &connectedSock);
				newWorker.id= mServer.numofWorkers;
				mServer.numofWorkers++;
				test->workerID = newWorker.id;
				newWorker.socket->workerID = newWorker.id;
				serverWorkerListPushBack(&workers, newWorker);
			}
		}else{ //Shutdown
			//Socket is closed, shutdown
			dbg("serverAL", "serverAL - Server Shutdown\n" );
	
			call TCPSocket.release( mServer.socket->srcPort );			
			call WorkerTimer.stop();
			call ServerTimer.stop();
		}
	}
	
	event void WorkerTimer.fired(){
		uint16_t i;
		serverWorkerAL *currentWorker;
	
		for(i=0; i<serverWorkerListSize(&workers); i++){
			currentWorker = serverWorkerListGet(&workers, i);
	
			call serverWorker.execute(currentWorker);
		}		
	}
	
	
	//WORKER
	command void serverWorker.init(serverWorkerAL *worker, TCPSocketAL *inputSocket){
		worker->position = 0;
		worker->socket = call TCPManager.socket();
		worker->amountToRead = 0;
		worker->amountToWrite = 0;
		worker->writePosition = 0;
		worker->needWrite = FALSE;
		memset (worker->sendBuffer,0,50);
		memset (worker->buffer,0,SERVER_WORKER_BUFFER_SIZE);
		call TCPSocket.copy(inputSocket, worker->socket);
	
		//worker->socket->addr, worker->socket->destAddr);		
		dbg("serverAL", "serverAL - Worker Intilized\n");
	}
	command serverWorkerAL * chatServer.GrabWorker(uint8_t port){
		uint16_t i;
		serverWorkerAL *currentWorker;
		for(i=0; i<serverWorkerListSize(&workers); i++){
			currentWorker = serverWorkerListGet(&workers, i);
			//dbg("serverAL", "currentWorker port %d, workerID: %d, bufferSize: \n", currentWorker->socket->srcPort,currentWorker->socket->workerID);
			if(currentWorker->socket->srcPort == port){
	
				return currentWorker;
			}
		}
		return currentWorker;
	}
	
	void clearBuffer(serverWorkerAL *worker){
		memset (worker->buffer,0,SERVER_WORKER_BUFFER_SIZE);
		worker->amountToRead = 0;
		worker->position =0;
	
		call TCPManager.turnOffTimer();
	}
	void printUser(){
		int i = 0;
		char *temp;
		dbg_clear("Project4", "-----------------------------------------------------------\n");
		dbg_clear("Project4", "\t\t\tPrinting UserList\n");
		for(i;i<20;i++){
			if(list[i].name[0]!=0)
				dbg_clear("Project4", "%s, size: %d\n",list[i].name,strlen(list[i].name));
		}
	}
	void printBuffer(serverWorkerAL *worker){
		int i = 0;
		char temp;
		temp = worker->buffer[i];
		dbg_clear("Project4", "--------Printing Server Buffer-------\n");
		while(temp!=0){
			dbg_clear("Project4", "%c",temp);
			i++;
			temp = worker->buffer[i];
	
		}
		dbg_clear("Project4", "\n");
	}
	command uint16_t chatServer.Buffer(uint8_t port, uint8_t data, uint8_t requestedAction){
		uint16_t i;
		serverWorkerAL *currentWorker;
	
		for(i=0; i<serverWorkerListSize(&workers); i++){
			currentWorker = serverWorkerListGet(&workers, i);
			//dbg("serverAL","Size of worker: %d. Port %d, Data: %lu, amountToRead: %d\n",serverWorkerListSize(&workers),port, data,currentWorker->amountToRead);
			//dbg("serverAL", "currentWorker port %d, workerID: %d, bufferSize: \n", currentWorker->socket->srcPort,currentWorker->socket->workerID);
			if(currentWorker->socket->srcPort == port){
				if(requestedAction==0){
					currentWorker->amountToRead=currentWorker->amountToRead%SERVER_WORKER_BUFFER_SIZE;
					currentWorker->buffer[currentWorker->amountToRead] = data;
					currentWorker->amountToRead++;
				}
				if(requestedAction==1){
					dbg("serverAL", "Open spots: %d\n",SERVER_WORKER_BUFFER_SIZE-currentWorker->amountToRead);
					return (SERVER_WORKER_BUFFER_SIZE-currentWorker->amountToRead);
				}
	
			}
		}
		return 0;
	}
	command void serverWorker.execute(serverWorkerAL *worker){
		if(!call TCPSocket.isClosed( (worker->socket->srcPort) ) ){
			uint16_t bufferIndex, length, count, writeIndex,len;
	
			bufferIndex = (worker->position) % SERVER_WORKER_BUFFER_SIZE + (worker->position/ SERVER_WORKER_BUFFER_SIZE) + 1;
	
			length = SERVER_WORKER_BUFFER_SIZE - bufferIndex;			//Amount left on the worker buffer
			//dbg("serverAL", "Trying to read\n");
			count = call TCPSocket.read( (worker->socket->srcPort), worker->buffer, worker->position% SERVER_WORKER_BUFFER_SIZE, length);
	
			if(count > 0 ){
				uint16_t i,j;
				char * pch;
				worker->position+= count;
				for (i=0; i<worker->position;i++){
					//	dbg("Project4","I just read in: %d,%c", worker->buffer[ (i)%SERVER_WORKER_BUFFER_SIZE], worker->buffer[ (i)%SERVER_WORKER_BUFFER_SIZE]);
					if( worker->buffer[ (i)%SERVER_WORKER_BUFFER_SIZE] == '\r'){
						if( worker->buffer[ (i)%SERVER_WORKER_BUFFER_SIZE+1] == '\n'){
							dbg("Project4","Recieved a command. I should see what the command was. Position: %d\n",i+1);
							printBuffer(worker);
							if(worker->buffer[0]=='h'&&worker->buffer[1]=='e'&&worker->buffer[2]=='l'&&worker->buffer[3]=='l'&&worker->buffer[4]=='o'){
								dbg("Project4","It is a hello packet\n");
								pch = strtok (worker->buffer," ");
								j=0;
								while (pch!= NULL){
									if(j == 1){
										strncpy(list[listIndex%20].name,pch,strlen(pch));
										strncpy(worker->name, pch,strlen(pch));
										listIndex++;
									}
									pch = strtok (NULL, " ");
									j++;
								}
								printUser();
								clearBuffer(worker);
							}
							if(worker->buffer[0]=='m'&&worker->buffer[1]=='s'&&worker->buffer[2]=='g'){
								uint8_t i = 0;	
								dbg("Project4","It is a msg packet\n");
								pch = strtok (worker->buffer," ");
								pch = strtok (NULL, "");
	
								//intialize the sendBuffer with msg
								worker->sendBuffer[0]= 'm';worker->sendBuffer[1]= 's';worker->sendBuffer[2]= 'g';worker->sendBuffer[3]= ' ';
								//append the username
								memcpy((worker->sendBuffer)+4,worker->name,strlen(worker->name));
								worker->sendBuffer[strlen(worker->sendBuffer)] =' ';
								dbg("Project4", "SendBuffer: %s,size: %d\n", worker->sendBuffer,strlen(worker->sendBuffer));
								dbg("Project4", "User %s have sent a message '%s' to everyone.\n",worker->name,pch);
								memcpy((worker->sendBuffer)+strlen(worker->sendBuffer),pch,strlen(pch));
								dbg("Project4", "SendBuffer: %s,size: %d\n", worker->sendBuffer,strlen(worker->sendBuffer));
								worker->needWrite = TRUE;
								worker->amountToWrite = strlen(worker->sendBuffer);
		
								clearBuffer(worker);
							}
							
						}
					}
				}

			}
			if(worker->needWrite){
				uint32_t closeTime;
				uint16_t counts,l;
				serverWorkerAL *currentWorker;
				closeTime = call WorkerTimer.getNow();
				dbg("Project4", "Need to write\n");
				if(worker->amountToWrite == 0){
					worker->needWrite = FALSE;
					memset (worker->sendBuffer,0,SERVER_WORKER_SEND_SIZE);
					worker->writePosition = 0;
					dbg("serverAL", "serverAL - Sending Completed at time: %lu\n",closeTime);
					return;
				}
				writeIndex = worker->writePosition%SERVER_WORKER_SEND_SIZE;
				if(SERVER_WORKER_SEND_SIZE - writeIndex < worker->amountToWrite){
					len = SERVER_WORKER_SEND_SIZE - bufferIndex;
					//len = CLIENTAL_BUFFER_SIZE;
					dbg("serverAL", "buffer-index was least\n");
				}else{
					//dbg("clientAL", "amount was least\n");
					len = worker->amountToWrite;
				}
				counts = call TCPSocket.write((worker->socket->srcPort), worker->sendBuffer, writeIndex, len);
//				for(l=0; l<serverWorkerListSize(&workers); l++){
//					currentWorker = serverWorkerListGet(&workers, l);
//					dbg("serverAL", "Sending MSG to: %s\n",currentWorker->name);
//					counts = call TCPSocket.write((currentWorker->socket->srcPort), worker->sendBuffer, writeIndex, len);
//				}
				
				worker->amountToWrite -=counts;
				worker->writePosition +=counts;
			}	
	
		}//else{
		//			uint32_t closeTime;
		//			closeTime = call ServerTimer.getNow();
		//	
		//			dbg("serverAL", "Connection Closed:\n");
		//			dbg("serverAL", "Data Read: %d\n", worker->position);
		//			dbg("serverAL", "Close Time: %d\n", closeTime);
		//			call TCPManager.freeSocket(worker->socket);
		//			serverWorkerListRemoveValue(&workers, *worker); return;
		//		}
	}
}
