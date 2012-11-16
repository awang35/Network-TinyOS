/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   Apr 28 2012
 * 
 */ 
#include <Timer.h>
#include "command.h"
#include "packet.h"
#include "dataStructures/list.h"
#include "dataStructures/pair.h"
#include "packBuffer.h"
#include "dataStructures/hashmap.h"
#include "message.h"
#include "string.h"
//Ping Includes
#include "dataStructures/pingList.h"
#include "ping.h"
#include "dataStructures/routingtable.h"
#include "lib/TCPSocketAL.h"
#include "transport.h"
#include <stdlib.h>

module Node{
	provides interface node;
	uses{
		interface Boot;
		interface Timer<TMilli> as pingTimeoutTimer;
		interface Timer<TMilli> as neighborDiscovey;
		interface Timer<TMilli> as neighborMap;
		interface Random as Random;
		interface Timer<TMilli> as sendDelay;
		interface Packet;
		interface AMPacket;
		interface AMSend;
		interface SplitControl as AMControl;
		interface Receive;
		interface TCPManager<TCPSocketAL,pack> as tcpLayer;
		interface TCPSocket<TCPSocketAL> as tcpSocket;
		interface client<TCPSocketAL> as ALClient;
		interface server<TCPSocketAL> as ALServer;
	}
	//provides interface Node;
}

implementation{
	//uint16_t NUMNODES = 5;
	uint16_t sequenceNum = 0;
	bool busy = FALSE;
	message_t pkt;
	pack sendPackage;
	sendBuffer packBuffer;	
	arrlist Received;
	bool isActive = TRUE;
	//Ping/PingReply Variables	
	pingList pings;
	/**
	 * Adrian's Variable
	 */
	transport transportPckt;
	uint8_t neighborCount;
	uint8_t helloCount;
	hashmap Neighbors;
	uint8_t broadcastMessage[PACKET_MAX_PAYLOAD_SIZE] = {"broadc@st"};
	uint8_t helloMessage[PACKET_MAX_PAYLOAD_SIZE] = {"he!!o"};
	uint8_t trans[5] = {"abc"};
	char tcp = 'a';
	lspList sendLsp[NUMNODES];
	lspList recieveLsp[NUMNODES][NUMNODES];
	int8_t recieveSeq[NUMNODES];
	Route confirmList[NUMNODES], tentList[NUMNODES];
	/**
	 * End
	 */ 
 
 
	error_t send(uint16_t src, uint16_t dest, pack *message);
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	task void sendBufferTask();
	/**
	 * Initialize LSP payload. Set all cost to inf (in this case 21 is infinity)
	 * When it is infinity that means the node is not connected
	 */

	void intializeList(){
		uint8_t i=0, j = 0;
		uint8_t inf = 21;
		lspList nothing;
		for(i; i<NUMNODES;i++){
			sendLsp[i].Cost = inf;
			recieveSeq[i] = -1;
			for(j=0; j<NUMNODES; j++)
				recieveLsp[i][j].Cost = inf;
		}	
	}

	event void Boot.booted(){
		call AMControl.start();
		arrListInit(&Received);
		neighborCount = 0;
		hashmapInit(&Neighbors);
		intializeList();
	
		//dbg("genDebug", "Booted\n");
	}
	event void pingTimeoutTimer.fired(){
		checkTimes(&pings, call pingTimeoutTimer.getNow());
	}

	event void AMControl.startDone(error_t err){
		if(err == SUCCESS){
			call pingTimeoutTimer.startPeriodic(PING_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
			call neighborDiscovey.startOneShot(30000 + (uint16_t) ((call Random.rand16())%200));
			//call neighborDiscovey.startPeriodic(30000 + (uint16_t) ((call Random.rand16())%200));
			//call helloProtocol.startPeriodic(45000 + (uint16_t) ((call Random.rand16())%200));
			call neighborMap.startOneShot(60000 + (uint16_t) ((call Random.rand16())%200));
			//call neighborMap.startPeriodic(60000 + (uint16_t) ((call Random.rand16())%200));
			call sendDelay.startOneShot( call Random.rand16() % 200);
		}else{
			//Retry until successful
			call AMControl.start();
		}
	}
	
	event void AMControl.stopDone(error_t err){}


	event void AMSend.sendDone(message_t* msg, error_t error){
		//Clear Flag, we can send again.
		if(&pkt == msg){
			dbg("Project1F", "Packet Sent\n");
			busy = FALSE;
			post sendBufferTask();
		}
	}

	void delaySendTask(){
		call sendDelay.startOneShot( call Random.rand16() % 200);
	}
	void intializeNeighbors(hashmap *neighbors){
		pack sendNeighbor;
		dbg("Project1N", "Intializing Neighbors.\n");
		hashmapInit(&Neighbors);
		makePack(&sendNeighbor,TOS_NODE_ID,AM_BROADCAST_ADDR, 1, PROTOCOL_PING, sequenceNum++,NULL,0);
		sendBufferPushBack(&packBuffer, sendNeighbor, sendNeighbor.src, AM_BROADCAST_ADDR);
		post sendBufferTask();
	}
	void printNeighbors(hashmap *neighbors){
		iterator it;
		iteratorInit(&it,neighbors);
		dbg("Project1N", "--------------------------------------\n");
		dbg("Project1N", "Printing Neighbor List:\n");
		while(iteratorHasNext(&it)){
 
			dbg("Project1N", "Node: %d\n", iteratorNext(&it));
		}
		dbg("Project1N", "Printing Done.\n");
		dbg("Project1N", "--------------------------------------\n");
	}
	void checkNeighbors(hashmap *neighbors){
		intializeNeighbors(neighbors);
	}
	void makeLSP(){
		pack lsp;
		makePack(&lsp,TOS_NODE_ID,AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKEDSTATE, sequenceNum++,&sendLsp,sizeof(sendLsp));
		sendBufferPushBack(&packBuffer, lsp, lsp.src, AM_BROADCAST_ADDR);
		//post sendBufferTask();
		delaySendTask();
	}

	event void neighborMap.fired(){
		//Generating neighbor map
		iterator it;
		iteratorInit(&it,&Neighbors);
		while(iteratorHasNext(&it)){
			int8_t buffer = iteratorNext(&it);
			sendLsp[buffer-1].Cost = 1;
		}
		makeLSP();
		call neighborMap.startPeriodic(332422 + (uint16_t) ((call Random.rand16())%200));	
	}
	event void neighborDiscovey.fired(){
		// TODO Auto-generated method stub
		call neighborDiscovey.startPeriodic(233333 + (uint16_t) ((call Random.rand16())%200));
		dbg("Project1N","Looking up neighbors\n");
		checkNeighbors(&Neighbors);
	}

	lspAlgorithm selectLSP(uint8_t key){
		uint8_t i = 0;
		lspAlgorithm entry;
		entry.nodeid = (uint8_t)(key+1);
		for(i=0;i<NUMNODES;i++){
			entry.neighborid[i] = (uint8_t)(i+1);
			entry.cost[i] =recieveLsp[key][i].Cost ;	
		}
		//	lsparrlistPushBack(&recieveLspList,entry);
		return entry;
	}

	void printTable(int8_t type){
		uint8_t i =0;
		Route temp[NUMNODES];
		if(type == 0){
			for(i = 0; i< NUMNODES;i++){
	
				temp[i] = confirmList[i];
			}
			dbg("Project3","Printing ConfirmList\n");
		}
		else{
				for(i = 0; i< NUMNODES;i++){
				temp[i] = tentList[i];
			}
			dbg("Project3","Printing tentList\n");	
		}
		for(i = 0; i< NUMNODES;i++){
			dbg("Project3","Entry %d: Dest: %d, Cost: %d, NextHop: %d, isValid: %d\n",i+1, temp[i].Dest,temp[i].Cost,temp[i].NextHop,temp[i].isValid);
	
		}
	}
	uint8_t countValid(){
		uint8_t i = 0, countForValid=0;
		for(i =0;i<NUMNODES;i++){
			if(tentList[i].isValid)
				countForValid++;
		}
		if(countForValid ==0){
			dbg("disAlg","Nothing was Valid\n");
			return 0;}
		else if (countForValid == NUMNODES){
			dbg("disAlg","All was valid\n");
			return 1;}
		else
			dbg("disAlg","Some was valid. Num valid: %d\n",countForValid);
		return 2;
	}
	
	uint8_t getLowCost(){
		uint8_t i = 0, low = 21, node1;
		for(i = 0; i< NUMNODES; i++){
			//dbg("Project2","Checking if tentList[%d] with cost %d is the lowest compared to %d\n",i,tentList[i].Cost,low );
			if(tentList[i].Cost< low && tentList[i].isValid){
				low = tentList[i].Cost;
				node1 = i; 
			}
		}
		//dbg("Project2","Lowest was Node %d", node);
		return node1;
	}
	void printRecieveLsp(){
		uint8_t i=0,j=0;
		dbg("Project2p","------------------------------------\n");
		dbg("Project2p","Printing Recieved LSP List for Node %d\n",TOS_NODE_ID);
		while(i<NUMNODES){
			dbg("Project2p","Node %d LSP list: ",i+1);
			for(j=0;j<NUMNODES;j++){
				dbg("Project2p","%d",recieveLsp[i][j].Cost);
			}
			dbg("Project2p","\n");
			i++;
		}
	
		dbg("Project2p","------------------------------------\n");
	
	}
	void dijkstra(){
	
		Route confirmEntry, tentativeEntry;
		//Route confirmList[NUMNODES], tentList[NUMNODES];
		uint8_t i = 0, j=0, infinity = 21, nextNode, counter=0, errorCount=0, path, traceList[NUMNODES];
		lspAlgorithm currentLsp;
		//printRecieveLsp();
		for(i = 0;i<NUMNODES;i++){
			confirmList[i].Cost = 21;
			confirmList[i].isValid = FALSE;
			tentList[i].isValid = FALSE;
			tentList[i].Cost = 21;
		}
		nextNode = TOS_NODE_ID - 1;
		confirmEntry.Cost = 0;
		confirmEntry.NextHop = TOS_NODE_ID;
		confirmEntry.Dest = TOS_NODE_ID;
		confirmEntry.isValid = TRUE;
		confirmList[nextNode] = confirmEntry;
	
		dbg("disAlg","Doing Dijkstra Algorithm for node %d\n", nextNode+1); 
		do{
			dbg("disAlg","^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^\n");
			counter++;						
			/**
			 * Select the LSP Packet relating to this node 
			 */
			dbg("disAlg","Node %d was just added to confirmed List.\n", nextNode+1); 
			//printTable(0);
			currentLsp = selectLSP(nextNode);
			for(i = 0; i < NUMNODES;i++){
				if(currentLsp.cost[i]<infinity){
					dbg("disAlg","Checking Cost for neighbors.\n"); 
					tentativeEntry.Cost = currentLsp.cost[i]+ confirmEntry.Cost;
					dbg("disAlg","To reach Node %d, it cost %d.\n", i+1,tentativeEntry.Cost); 
					dbg("disAlg","Checking if its not neither list\n"); 
					if(confirmEntry.Dest!= TOS_NODE_ID)
						path = confirmEntry.NextHop;
					else
						path = i+1;
					if((confirmList[i].isValid == FALSE) && (tentList[i].isValid == FALSE)){
	
						dbg("disAlg","It was not in the list, adding entry to tentative with (%d,%d,%d)\n", i+1,tentativeEntry.Cost,path);
						tentativeEntry.Dest = i+1;
						tentativeEntry.NextHop = path;
						tentativeEntry.isValid = TRUE;
						tentList[i]= tentativeEntry;
					}
					if( tentList[i].isValid == TRUE && tentativeEntry.Cost < tentList[i].Cost ){
						dbg("disAlg","A better entry was found, updating table with entry (%d,%d,%d)\n",currentLsp.neighborid[i],tentativeEntry.Cost,path);
						tentativeEntry.Dest = i+1;
						tentativeEntry.NextHop = path;
						tentativeEntry.isValid = TRUE;
						tentList[i]= tentativeEntry;
					}
				}
			}
			//printTable(1);
			if(countValid()==0)
				break;
			nextNode = getLowCost();
			dbg("disAlg","It was Node %d with cost %d\n",nextNode+1,tentList[nextNode].Cost);
			confirmEntry.Cost = tentList[nextNode].Cost;
			confirmEntry.NextHop = tentList[nextNode].NextHop;
			confirmEntry.Dest = tentList[nextNode].Dest;
			confirmEntry.isValid = TRUE;
			confirmList[nextNode] = confirmEntry;
			tentList[nextNode].isValid = FALSE;
			//printTable(1);
		}while(TRUE);//counter<4);
	}
	void storePayload(lspList *payload, uint16_t src ){
		uint8_t i=0;
		//uint8_t inf = 21;
		//dbg("Project2"," Going to store in slot %d\n",src);
		for(i; i<NUMNODES;i++){
			recieveLsp[src][i].Cost= payload[i].Cost;
		}
		//printRecieveLsp();
	}
	void printPayload(lspList *payload,uint16_t src){
		uint8_t i=0;
		uint8_t inf = 21;
		dbg("Project2","*************************************\n");
		dbg("Project2","Printing PAYLOAD from Node %d\n",src+1);
		dbg("Project2","\tNode\tCost\n");
		for(i; i<NUMNODES;i++)
			if(payload[i].Cost<21)
			dbg("Project2","\t%d\t%d\n",i+1,payload[i].Cost);
		dbg("Project2","*************************************\n");
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if(!isActive){
			dbg("genDebug", "The Node is inactive, packet will not be read.");
			return msg;	
		}
		if(len==sizeof(pack)){
			pack* myMsg=(pack*) payload;
			pair receivedPacket = {myMsg->src,myMsg->seq};
			uint8_t i = 0;
			iterator it;
			TCPSocketAL *mSocket;
			//logPack(payload);
			if( arrListContains(&Received,myMsg->src,myMsg->seq)){
				dbg("Project1F", "Packet has been seen before, dropping it.\n");
				return msg;
			}
			else//store it in the seen list
			if(arrListPushBack(&Received,receivedPacket));
			else{
					dbg("Project1F", "filled list\n");
				//only keep track of recent packets
				pop_front(&Received);
				arrListPushBack(&Received,receivedPacket);
			}
			//if(myMsg->protocol==PROTOCOL_CMD)
			//	dbg("cmdDebug", "CMD packet has arrive\n");
			if(TOS_NODE_ID!=myMsg->dest){
				//dbg("Project1F", "Broadcasting to Neighbors\n");
				//if(myMsg->protocol==PROTOCOL_CMD)
				//	dbg("cmdDebug", "Not meant for me\n");
				if(myMsg->dest==AM_BROADCAST_ADDR){//should be a broadcast packet
	
					switch(myMsg->protocol){
						case PROTOCOL_PING:
						if(!strcmp(myMsg->payload,helloMessage)){
							dbg("Project2", "Node %d said hello, sending reply.\n",myMsg->src);
							makePack(&sendPackage, TOS_NODE_ID,myMsg->src, 1, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) helloMessage, sizeof(helloMessage));
							sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, myMsg->src);
							//post sendBufferTask();
							delaySendTask();
						}
						else{
								dbg("Project1N", "I have been discovered, sending reply.\n");
							makePack(&sendPackage, TOS_NODE_ID,myMsg->src, 1, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) broadcastMessage, sizeof(broadcastMessage));
							//sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
							sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, myMsg->src);
							//post sendBufferTask();
							delaySendTask();
						}
						break;
						case PROTOCOL_LINKEDSTATE:
						//dbg("Project2", "I have recieved the list from Node %d, checking if its old.\n", myMsg->src);
						//logPack(myMsg);
						//printPayload(myMsg->payload,myMsg->src-1);
						//dbg("Project2", "Compare Seq. Old %d from New %d\n",recieveSeq[myMsg->src-1] ,myMsg->seq);
	
						if(recieveSeq[myMsg->src-1]< myMsg->seq){
							storePayload(myMsg->payload,myMsg->src-1);
							recieveSeq[myMsg->src-1]= myMsg->seq;
						}
						else{
								return msg;
						}
						makePack(&sendPackage, myMsg->src,myMsg->dest, myMsg->TTL--, myMsg->protocol, myMsg->seq, myMsg->payload, sizeof(myMsg->payload));
						sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);
						delaySendTask();
						break;
						default:
						break;
					}
	
				}
				else{
						dbg("Project1F", "Packet is not meant for me, broadcasting it.\n");
					dijkstra();
					printRecieveLsp();
					//printTable(0);
					dbg("Project2", "Packet is meant for Node %d. Looking up table. Will be routed to Node %d\n", myMsg->dest, confirmList[myMsg->dest-1].NextHop);
	
					makePack(&sendPackage, myMsg->src,myMsg->dest, myMsg->TTL, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));					
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, confirmList[myMsg->dest-1].NextHop);
					//post sendBufferTask();
					delaySendTask();
				}
			}
			if(TOS_NODE_ID==myMsg->src&& myMsg->protocol != 99){
				dbg("Project1F", "Source is this node: %s\n", myMsg->payload);
				return msg;
			}
			if(TOS_NODE_ID==myMsg->dest){
				dbg("Project1F", "Packet from %d has arrived! Msg: %s\n", myMsg->src, myMsg->payload);
				switch(myMsg->protocol){
					uint8_t createMsg[PACKET_MAX_PAYLOAD_SIZE];
					uint8_t zero = 1;
					uint16_t dest,srcPort,destPort;
					case PROTOCOL_PING:
					dijkstra();
					printRecieveLsp();
					//printTable(0);
					dbg("Project2", "PingReply Packeted is enroute to Node %d, will be routed to Node %d\n",myMsg->src, confirmList[myMsg->src-1].NextHop);
					//dest =AM_BROADCAST_ADDR;
					dbg("Project1F", "Sending Ping Reply to %d! \n", myMsg->src);
					makePack(&sendPackage, TOS_NODE_ID,myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, confirmList[myMsg->src-1].NextHop);
					//post sendBufferTask();
					delaySendTask();
					break;

					case PROTOCOL_PINGREPLY:
					dbg("Project1F", "Received a Ping Reply from %d with message: %s!\n", myMsg->src, myMsg->payload);
					dbg("Project2", "Received a Ping Reply from %d with message: %s!\n", myMsg->src, myMsg->payload);
					//should add the node to the map
					if(!strcmp(myMsg->payload,helloMessage)){
						helloCount++;
						dbg("Project2","Timer for neighbor check intiated.\n");
						//call waitTimer.startOneShot(30);
					}
					if(!strcmp(myMsg->payload,broadcastMessage)){
						neighborCount++;
						hashmapInsert(&Neighbors,hash3(myMsg->src,1),myMsg->src);
						printNeighbors(&Neighbors);
						//sendLsp[myMsg->src-1].Cost = 1;
						//dbg("Project2", "Updating List. Setting %d cost to 1.\n",myMsg->src);
						//printLsp();
	
					}
					//dbg("genDebug", "WENT PAST");
					break;
	
					case PROTOCOL_CMD:	
					//dbg("Project3", "WENT TO CMD");
					switch(getCMD((uint8_t *) &myMsg->payload, sizeof(myMsg->payload))){
						uint32_t temp=0, i = 0;
						char * pch;
						case CMD_PING:
						memcpy(&createMsg, (myMsg->payload) + PING_CMD_LENGTH, sizeof(myMsg->payload) - PING_CMD_LENGTH);
						memcpy(&dest, (myMsg->payload)+ PING_CMD_LENGTH-2, sizeof(uint8_t));
						makePack(&sendPackage, TOS_NODE_ID, (dest-48)&(0x00FF), MAX_TTL, PROTOCOL_PING, sequenceNum++, (uint8_t *)createMsg,
								sizeof(createMsg));	
	
						//Place in Send Buffer
						sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
						//post sendBufferTask();
						delaySendTask();
	
						break;
						case CMD_TEST_CLIENT:
						dbg("Project3", "Client is now being set up\n");
						pch = strtok (myMsg->payload," ");
						i=0;
						while (pch != NULL){
							//dbg("Project3", "%s\n",pch);
							if(i == 2)
								srcPort = atoi(pch);
							else if (i ==3)
								destPort = atoi(pch);
							else if (i == 4)
								dest= atoi(pch);
							pch = strtok (NULL, " ");
							i++;
						}
	
						//dbg("Project3", "DEST: %d, srcPort: %d, destPort: %d\n", dest,srcPort,destPort);
						call tcpLayer.init();
						call  tcpLayer.setUpClient(srcPort,destPort,dest);
						//mSocket = call tcpLayer.socket();	
						//call tcpLayer.forcePortState(99);
						//call tcpSocket.bind(mSocket, srcPort, TOS_NODE_ID);
						//call tcpSocket.connect(mSocket, srcPort, destPort);
						//call ALClient.init(mSocket);
						break;
						case CMD_TEST_SERVER:
						dbg("Project3", "Server is now being set up\n");
						pch = strtok (myMsg->payload," ");
						i=0;
						while (pch != NULL){
							//dbg("Project3", "%s\n",pch);
							if(i == 2)
								srcPort = atoi(pch);
							pch = strtok (NULL, " ");
							i++;
						}
						call tcpLayer.init();
						call  tcpLayer.setUpServer( srcPort);
						//mSocket = call tcpLayer.socket();
						//dbg("Project3","Retrieve a new socket. ID: %d,State: %d\n",mSocket->uniqueID,mSocket->currentState);
						//call tcpSocket.bind(mSocket, srcPort, TOS_NODE_ID);
						////call tcpSocket.listen(mSocket, 5);
						//call ALServer.init(mSocket);
						break;
	
						case CMD_KILL:
						isActive = FALSE;
						break;
	
						case CMD_ERROR:
						break;
						default:
						break;
					}
					break;
					case PROTOCOL_TCP:
	
					//createTransport(&transportPckt,0,0,0,0,0, &trans, sizeof(trans));
					//dbg("Project3", "TCP Packet has arrived.\n");
					//printTransport(&transportPckt);
					//call tcpLayer.handlePacket(&transportPckt);
					call tcpLayer.handlePacket(payload);
					break;
					default:
					break;
				}
			}
			//dbg("Project2", "A Packet has been dropped.\n");
			return msg;
		}

		dbg("genDebug", "Unknown Packet Type\n");
		return msg;
	}
	
	task void sendBufferTask(){
		if(packBuffer.size !=0 && !busy){
			sendInfo info;
			info = sendBufferPopFront(&packBuffer);
			send(info.src,info.dest, &(info.packet));
		}
	
		if(packBuffer.size !=0 && !busy){
			//post sendBufferTask();
			delaySendTask();
		}
	}

	/*
	 * Send a packet
	 *
	 *@param
	 *	src - source address
	 *	dest - destination address
	 *	msg - payload to be sent
	 *neighborMap
	 *@return
	 *	error_t - Returns SUCCESS, EBUSY when the system is too busy using the radio, or FAIL.
	 */
	error_t send(uint16_t src, uint16_t dest, pack *message){
		if(!busy && isActive){
			pack* msg = (pack *)(call Packet.getPayload(&pkt, sizeof(pack) ));			
			*msg = *message;
			//TTL Check
			if(msg->TTL >0)msg->TTL--;
			else return FAIL;
	
			if(call AMSend.send(dest, &pkt, sizeof(pack)) ==SUCCESS){
				dbg("Project1F", "Successful sent\n");
				busy = TRUE;
				return SUCCESS;
			}else if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(pack)) ==SUCCESS){
				busy = TRUE;
				return SUCCESS;
			}else{
				dbg("genDebug","The radio is busy, or something\n");
				return FAIL;
			}
		}else{
			return EBUSY;
		}
		dbg("genDebug", "FAILED!?");
		return FAIL;
	}	

	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t protocol, uint16_t seq, uint8_t* payload, uint8_t length){
		Package->src = src;
		Package->dest = dest;
		Package->TTL = TTL;
		Package->seq = seq;
		Package->protocol = protocol;
		memcpy(Package->payload, payload, length);
	}

	

	event void sendDelay.fired(){
		// TODO Auto-generated method stub
		post sendBufferTask();
	}

	command void node.tcpPack(transport payload, TCPSocketAL sckt){
		dijkstra();
		//printTable(0);
		//dbg("Project3", "transport preparing to be sent.DestID: %d, DestPort: %d, Type: %d. Next Hop: %d. Data: %d, payload size: %d, Seq Num: %d\n", sckt.destID, sckt.destPort,payload.type, confirmList[(sckt.destID)-1].NextHop,payload.payload[0],sizeof(payload),sequenceNum+1);
		makePack(&sendPackage,TOS_NODE_ID,sckt.destID, MAX_TTL, 4, sequenceNum++, &payload, sizeof(payload));
		//makePack(&sendPackage, sckt->srcID,sckt->destID, MAX_TTL, 4, sequenceNum++, payload, sizeof(payload));
		
		
		sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, confirmList[(sckt.destID)-1].NextHop);
		delaySendTask();
	
	}
}



