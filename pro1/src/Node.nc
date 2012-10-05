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
//#include "routingtable.h"
//Ping Includes
#include "dataStructures/pingList.h"
#include "ping.h"
//adds the lsp payload
#include "dataStructures/lsp.h"



module Node{
	uses interface Boot;
	uses interface Timer<TMilli> as pingTimeoutTimer;
	uses interface Timer<TMilli> as neighborDiscovey;
	uses interface Timer<TMilli> as neighborMap;
	uses interface Timer<TMilli> as waitTimer;
	uses interface Random as Random;
	uses interface Timer<TMilli> as helloProtocol; 
	
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	
}

implementation{
	uint16_t numNodes;
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
	 uint8_t neighborCount;
	 uint8_t helloCount;
	 hashmap Neighbors;
	 uint8_t broadcastMessage[PACKET_MAX_PAYLOAD_SIZE] = {"broadc@st"};
	 uint8_t helloMessage[PACKET_MAX_PAYLOAD_SIZE] = {"he!!o"};
	 lspList sendLsp[20];
	 lspList recieveLsp[20][20];
	 int8_t recieveSeq[20];
	 rLspList test;
	 uint8_t lspSeq = 0;
	 pack lspCache;
	/**
	 * End
	 */ 
	 
	 
	error_t send(uint16_t src, uint16_t dest, pack *message);
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	
	
	task void sendBufferTask();

	void printLsp(){
	 uint8_t p = 0;
	//	dbg("Project2", "------------------------------------\n");
	//	dbg("Project2","------------------------------------\n");
	//	dbg("Project2","Printing LSP Payload that is going to be sent\n");
		
		for( p = 0; p<numNodes;p++)
			dbg("Project2", "Node %d have cost %d.\n",p+1,sendLsp[p].Cost);
	}
	/**
	 * Initialize LSP payload. Set all cost to inf (in this case 21 is infinity)
	 * When it is infinity that means the node is not connected
	 */
	void printTest(){
		 uint8_t o=0,i=0, j = 0;
		dbg("Project2","------------------------------------\n");
		dbg("Project2","Intial Print\n");
		
		dbg("Project2","LSP packet\n");
		for(o=0; o<numNodes;o++){
			dbg("Project2", "Node %d have cost %d.\n",o+1,sendLsp[o].Cost);
			}
		dbg("Project2","Recieve List\n");
		for(i=0; i<numNodes;i++){
			for(j=0;j<numNodes;j++){
				dbg("Project2", "Node %d have cost %d.\n",i+1,sendLsp[i].Cost);
				}
			}
		dbg("Project2","------------------------------------\n");
	}
	void intializeList(){
		uint8_t i=0, j = 0;
		uint8_t inf = 21;
		lspList nothing;
		for(i; i<numNodes;i++){
			sendLsp[i].Cost = inf;
			recieveSeq[i] = -1;
			for(j=0; j<numNodes; j++)
				recieveLsp[i][j].Cost = inf;
			}
			//printTest();
	}
	
	void dijkstra(){
		
	}
	event void Boot.booted(){
		call AMControl.start();
		numNodes = 5;
		arrListInit(&Received);
		neighborCount = 0;
		hashmapInit(&Neighbors);
		//lsplist = sendLsp;
		intializeList();
		
		//lspPointer = sendLsp
		
		//dbg("genDebug", "Booted\n");
	}
	event void pingTimeoutTimer.fired(){
		checkTimes(&pings, call pingTimeoutTimer.getNow());
	}
	event void waitTimer.fired(){
		//checkTimes(&pings, call pingTimeoutTimer.getNow());
		dbg("Project2","Wait is over! Checking if Neighbor is the same. Current Neighbors: %d. Past Neighbors: %d.\n",helloCount, neighborCount);
		if(helloCount == neighborCount)
			dbg("Project2","Same neighbors, nothing to do.\n");
		else{
			dbg("Project2","Different neighbors! Time to update everyone.\n");
		}
	}
	event void AMControl.startDone(error_t err){
		if(err == SUCCESS){
			call pingTimeoutTimer.startPeriodic(PING_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
			call neighborDiscovey.startOneShot(30000 + (uint16_t) ((call Random.rand16())%200));
			//call neighborDiscovey.startPeriodic(30000 + (uint16_t) ((call Random.rand16())%200));
			//call helloProtocol.startPeriodic(45000 + (uint16_t) ((call Random.rand16())%200));
			call neighborMap.startOneShot(35632 + (uint16_t) ((call Random.rand16())%200));
			//call neighborMap.startPeriodic(60000 + (uint16_t) ((call Random.rand16())%200));
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

	void isOnline(hashmap *neighbors){
		uint8_t i=0;
		pair temp;
		for(i; i<(neighbors->numofVals); i++){
			dbg("Project1N", "Node Lost!\n Msg: %s", temp.src);
			hashmapRemove(neighbors, i);
		}
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
		//dbg("Project1F", "is hashmap empty?: %d\n",hashmapIsEmpty(neighbors));
		//if (hashmapIsEmpty(neighbors)){
		intializeNeighbors(neighbors);
	
	}
	void makeLSP(){
		pack lsp;
		dbg("Project2", "Sending out LSP\n");
		//dbg("Project2", "Size of list is %d\n",sizeof(sendLsp));
		makePack(&lsp,TOS_NODE_ID,AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKEDSTATE, lspSeq++,&sendLsp,sizeof(sendLsp));
		sendBufferPushBack(&packBuffer, lsp, lsp.src, AM_BROADCAST_ADDR);
		post sendBufferTask();
	}
	event void helloProtocol.fired(){
		
		pack helloPacket;
		helloCount = 0;
		if(call neighborDiscovey.isRunning());
		else{
			dbg("Project2","NEIGHBOR DISCOVERY TIMER STARTED\n");
			call neighborDiscovey.startPeriodic(90000 + (uint16_t) ((call Random.rand16())%200));}
		makePack(&helloPacket,TOS_NODE_ID,AM_BROADCAST_ADDR, 1, PROTOCOL_PING, sequenceNum++,(uint8_t *) helloMessage,sizeof(helloMessage));
		sendBufferPushBack(&packBuffer, helloPacket, helloPacket.src, AM_BROADCAST_ADDR);
		post sendBufferTask();
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
		call neighborMap.startPeriodic(600000 + (uint16_t) ((call Random.rand16())%200));
		
	}
	event void neighborDiscovey.fired(){
		// TODO Auto-generated method stub
		call neighborDiscovey.startPeriodic(300000 + (uint16_t) ((call Random.rand16())%200));
		dbg("Project1N","Looking up neighbors\n");
		checkNeighbors(&Neighbors);
	}
	void printRecieveLsp(){
		uint8_t i=0,j=0;
		dbg("Project2","------------------------------------\n");
		dbg("Project2","Printing Recieved LSP List for Node %d\n",TOS_NODE_ID);
		while(i<numNodes){
			dbg("Project2","Node %d LSP list: ",i+1);
			for(j=0;j<numNodes;j++){
				dbg("Project2","%d",recieveLsp[i][j].Cost);
				}
				dbg("Project2","\n");
				i++;
			}
		
		dbg("Project2","------------------------------------\n");
		
	}
	void storePayload(lspList *payload, uint16_t src ){
		uint8_t i=0;
		uint8_t inf = 21;
		dbg("Project2"," Going to store in slot %d\n",src);
		for(i; i<numNodes;i++){
			recieveLsp[src][i].Cost= payload[i].Cost;
			}
		printRecieveLsp();
	}
	void printPayload(lspList *payload,uint16_t src){
		uint8_t i=0;
		uint8_t inf = 21;
		dbg("Project2","*************************************\n");
		dbg("Project2","Printing PAYLOAD from Node %d\n",src+1);
		dbg("Project2","\tNode\tCost\n");
		for(i; i<numNodes;i++)
			if(payload[i].Cost<21)
				dbg("Project2","\t%d\t%d\n",i+1,payload[i].Cost);
		dbg("Project2","*************************************\n");
	}
	
	//event void checkNeighbors(){}
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		if(!isActive){
			dbg("genDebug", "The Node is inactive, packet will not be read.");
			return msg;	
		}
	
		if(len==sizeof(pack)){
			pack* myMsg=(pack*) payload;
			pair receivedPacket = {myMsg->src,myMsg->seq};
			iterator it;
			//dbg("Project1F", "Recieved a message with the following info:\n");
			//dbg("Project1F", "*IP Header* Src: %d, Dest: %d Seq:%d TTL: %d\n", myMsg->src, myMsg->dest, myMsg->seq, myMsg->TTL);
			/*
			 * Check if this node have seen this packet
			 */
			if( arrListContains(&Received,myMsg->src,myMsg->seq)){
				dbg("Project1F", "Packet has been seen before, dropping it.\n");
				return msg;
			}
			else//store it in the seen list
			if(arrListPushBack(&Received,receivedPacket)){
				//dbg("Project1F", "added to seen list.\n");
			}//do nothing for now
			else{
					dbg("Project1F", "filled list\n");
				//only keep track of recent packets
				pop_front(&Received);
				arrListPushBack(&Received,receivedPacket);
	
			}
			/*
			 * Checking if this packet was intended for this node
			 */
	
			if(TOS_NODE_ID!=myMsg->dest){
				//dbg("Project1F", "Broadcasting to Neighbors\n");
	
				if(myMsg->dest==AM_BROADCAST_ADDR){//should be a broadcast packet
					switch(myMsg->protocol){
						case PROTOCOL_PING:
						if(!strcmp(myMsg->payload,helloMessage)){
							dbg("Project2", "Node %d said hello, sending reply.\n",myMsg->src);
							makePack(&sendPackage, TOS_NODE_ID,myMsg->src, 1, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) helloMessage, sizeof(helloMessage));
							//sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
							sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, myMsg->src);
							post sendBufferTask();
						}
						else{
							dbg("Project1N", "I have been discovered, sending reply.\n");
							makePack(&sendPackage, TOS_NODE_ID,myMsg->src, 1, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) broadcastMessage, sizeof(broadcastMessage));
							//sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
							sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, myMsg->src);
							post sendBufferTask();
						}
						break;
						case PROTOCOL_LINKEDSTATE:
						dbg("Project2", "I have recieved the list from Node %d, updating table and fowarding.\n", myMsg->src);
						//logPack(myMsg);
						printPayload(myMsg->payload,myMsg->src-1);
						dbg("Project2", "Compare Seq. Old %d from New %d\n",recieveSeq[myMsg->src-1] ,myMsg->seq);
						
						if(recieveSeq[myMsg->src-1]> myMsg->seq){
							storePayload(myMsg->payload,myMsg->src-1);
							recieveSeq[myMsg->src-1]= myMsg->seq;
						}
						makePack(&sendPackage, myMsg->dest,myMsg->src, myMsg->TTL, myMsg->protocol, myMsg->seq, myMsg->payload, sizeof(myMsg->payload));
						iteratorInit(&it,&Neighbors);
						while(iteratorHasNext(&it)){
							int8_t buffer = iteratorNext(&it);
							if(buffer != myMsg->src){
								dbg("Project2", "LSP fowarded to %d\n", buffer);
								sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, buffer);
								}
							//dbg("Project1N", "Node: %d\n", iteratorNext(&it));
						}
						post sendBufferTask();
						break;
						default:
						break;
					}
	
				}
				else{
						dbg("Project1F", "Packet is not meant for me, broadcasting it.\n");
					makePack(&sendPackage, myMsg->src,myMsg->dest, myMsg->TTL, myMsg->protocol, myMsg->seq, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));					
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);
					post sendBufferTask();
				}
			}
			if(TOS_NODE_ID==myMsg->src){
				dbg("Project1F", "Source is this node: %s\n", myMsg->payload);
				return msg;
			}
			if(TOS_NODE_ID==myMsg->dest){
				dbg("Project1F", "Packet from %d has arrived! Msg: %s\n", myMsg->src, myMsg->payload);
				switch(myMsg->protocol){
					uint8_t createMsg[PACKET_MAX_PAYLOAD_SIZE];
					uint8_t zero = 1;
					uint16_t dest;
					case PROTOCOL_PING:
					//if())
					dest =AM_BROADCAST_ADDR;
					//else dest = myMsg->src;
					dbg("Project1F", "Sending Ping Reply to %d! \n", myMsg->src);
					makePack(&sendPackage, TOS_NODE_ID,myMsg->src, MAX_TTL, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) myMsg->payload, sizeof(myMsg->payload));
					//sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
					sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, AM_BROADCAST_ADDR);
					post sendBufferTask();
					break;

					case PROTOCOL_PINGREPLY:
					dbg("Project1F", "Received a Ping Reply from %d with message: %s!\n", myMsg->src, myMsg->payload);
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
					switch(getCMD((uint8_t *) &myMsg->payload, sizeof(myMsg->payload))){
						uint32_t temp=0;
						case CMD_PING:
						dbg("genDebug", "Ping packet received: %lu\n", temp);
						memcpy(&createMsg, (myMsg->payload) + PING_CMD_LENGTH, sizeof(myMsg->payload) - PING_CMD_LENGTH);
						memcpy(&dest, (myMsg->payload)+ PING_CMD_LENGTH-2, sizeof(uint8_t));
						makePack(&sendPackage, TOS_NODE_ID, (dest-48)&(0x00FF), MAX_TTL, PROTOCOL_PING, sequenceNum++, (uint8_t *)createMsg,
								sizeof(createMsg));	
	
						//Place in Send Buffer
						sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
						post sendBufferTask();
	
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
					case PROTOCOL_LINKEDSTATE:
					dbg("Project2", "I have recieved the list from Node %d, updating table and fowarding.\n", myMsg->src);
						
					printPayload(myMsg->payload,myMsg->src-1);
					dbg("Project2", "Compare Seq. Old %d from New %d\n",recieveSeq[myMsg->src-1] ,myMsg->seq);
						
					if(recieveSeq[myMsg->src-1]> myMsg->seq){
						storePayload(myMsg->payload,myMsg->src-1);
						recieveSeq[myMsg->src-1]= myMsg->seq;
					}
					makePack(&sendPackage, myMsg->dest,myMsg->src, myMsg->TTL, myMsg->protocol, myMsg->seq, myMsg->payload, sizeof(myMsg->payload));
					iteratorInit(&it,&Neighbors);
					while(iteratorHasNext(&it)){
						int8_t buffer = iteratorNext(&it);
						if(buffer != myMsg->src){
							dbg("Project2", "LSP fowarded to %d\n", buffer);
							sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, buffer);
							}
						//dbg("Project1N", "Node: %d\n", iteratorNext(&it));
					}
					post sendBufferTask();
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
			post sendBufferTask();
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

	
}



