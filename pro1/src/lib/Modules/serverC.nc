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

module serverC{
	uses{
		interface TCPSocket<TCPSocketAL>;
		interface Timer<TMilli> as ServerTimer;
		interface Timer<TMilli> as WorkerTimer;
		interface Random;
		interface TCPManager<TCPSocketAL,pack>;
	}
	provides{
		interface server<TCPSocketAL>;
		interface serverWorker<serverWorkerAL, TCPSocketAL>;
	}
}
implementation{
	//Local Variables Variables
	serverAL mServer;	
	serverWorkerList workers;

	command void server.init(TCPSocketAL *socket){
		mServer.socket = socket;
		mServer.numofWorkers=0;	
			dbg("Project3", "Server. Current State: %d\n", mServer.socket->currentState);
		call ServerTimer.startPeriodic(SERVER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
		call WorkerTimer.startPeriodic(WORKER_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
	}
	
	event void ServerTimer.fired(){
		if(! call TCPSocket.isClosed(mServer.socket->srcPort) ){
			TCPSocketAL connectedSock;
			TCPSocketAL *test;
			uint8_t newPort;
			dbg("serverAL", "serverAL - Trying to accept.\n");
			//Attempt to Establish a Connection
			
			newPort = call Random.rand16()%255;
			if(call TCPSocket.accept(mServer.socket->srcPort, newPort) == TCP_ERRMSG_SUCCESS){
				serverWorkerAL newWorker;
				test = call TCPManager.getSocket(newPort);
				connectedSock = *test;
				dbg("Project3", "ConnectedSock Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",connectedSock.uniqueID,connectedSock.srcID,connectedSock.destID,connectedSock.srcPort,connectedSock.destPort, connectedSock.currentState);
				dbg("serverAL", "serverAL - Connection Accepted.\n");
				dbg("serverAL", "serverAL - New worker. ID: %d.\n",mServer.numofWorkers);				
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
		
		call TCPSocket.copy(inputSocket, worker->socket);
		
		//worker->socket->addr, worker->socket->destAddr);		
		dbg("serverAL", "serverAL - Worker Intilized\n");
	}
	command void server.Buffer(uint8_t port, uint8_t data){
		uint16_t i;
		serverWorkerAL *currentWorker;
		dbg("serverAL","Size of worker: %d. Port %d, Data: %lu\n",serverWorkerListSize(&workers),port, data);
		for(i=0; i<serverWorkerListSize(&workers); i++){
			currentWorker = serverWorkerListGet(&workers, i);
			dbg("serverAL", "currentWorker port %d, workerID: %d, bufferSize: \n", currentWorker->socket->srcPort,currentWorker->socket->workerID);
			if(currentWorker->socket->srcPort == port)
				currentWorker->amountToRead++;
		}
		
	}
	command void serverWorker.execute(serverWorkerAL *worker){
		if(!call TCPSocket.isClosed( (worker->socket->srcPort) ) ){
			uint16_t bufferIndex, length, count;
			
			bufferIndex = (worker->position) % SERVER_WORKER_BUFFER_SIZE + (worker->position/ SERVER_WORKER_BUFFER_SIZE) + 1;
			
			length = SERVER_WORKER_BUFFER_SIZE - bufferIndex;			//Amount left on the worker buffer
			dbg("serverAL", "Trying to read\n");
			count = call TCPSocket.read( (worker->socket->srcPort), worker->buffer, worker->position% SERVER_WORKER_BUFFER_SIZE, length);
			
			if(count == -1){
				// Socket unable to read, release socket
				dbg("serverAL", "serverAL - Releasing socket\n");
				dbg("serverAL", "Position: %lu\n", worker->position);
				call TCPSocket.release( (worker->socket->srcPort) );
				
				serverWorkerListRemoveValue(&workers, *worker);
				return;
			}
			
			if(count > 0 ){
				uint16_t i;
				for(i=0; i<count; i++){
					if( worker->buffer[ (i+worker->position)%SERVER_WORKER_BUFFER_SIZE] != (0x00FF&(i+bufferIndex))){ // Makes a 16 bit into a byte.(8 bits);
						dbg("serverAL", "Releasing socket\n");
						dbg("serverAL", "Buffer Index: %lu Position: %lu\n", i+bufferIndex, worker->position);
						call TCPSocket.release( (worker->socket->srcPort) );
						serverWorkerListRemoveValue(&workers, *worker);
						
						return;
					}
				}
				
				worker->position+= count;
				return;
			}
		}else{
			uint32_t closeTime;
			closeTime = call ServerTimer.getNow();
				
			dbg("serverAL", "Connection Closed:\n");
			dbg("serverAL", "Data Read: %d\n", worker->position);
			dbg("serverAL", "Close Time: %d\n", closeTime);
			call TCPManager.freeSocket(worker->socket);
			serverWorkerListRemoveValue(&workers, *worker); return;
		}
	}
}
