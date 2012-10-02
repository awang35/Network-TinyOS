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




module Node{
	uses interface Boot;
	uses interface Timer<TMilli> as pingTimeoutTimer;
	uses interface Timer<TMilli> as neighborDiscovey;
	uses interface Timer<TMilli> as neighborMap;
	uses interface Random as Random;
	
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface SplitControl as AMControl;
	uses interface Receive;
	
}

implementation{
	//need to create a data structure to create a seen list
	//hashmap receivedList;
	
	uint16_t sequenceNum = 0;

	bool busy = FALSE;
	
	message_t pkt;
	pack sendPackage;
	uint8_t broadcastMessage[PACKET_MAX_PAYLOAD_SIZE] = {"broadc@st"};
	//broadcastMessage = {"test"};
	sendBuffer packBuffer;	
	arrlist Received;
	hashmap Neighbors;

	bool isActive = TRUE;

	//Ping/PingReply Variables	
	pingList pings;
	
	error_t send(uint16_t src, uint16_t dest, pack *message);
	void makePack(pack *Package, uint16_t src, uint16_t dest, uint16_t TTL, uint16_t Protocol, uint16_t seq, uint8_t *payload, uint8_t length);
	task void sendBufferTask();
	
	
	event void Boot.booted(){
		call AMControl.start();
		arrListInit(&Received);
		hashmapInit(&Neighbors);
		//dbg("genDebug", "Booted\n");
	}
	event void pingTimeoutTimer.fired(){
		checkTimes(&pings, call pingTimeoutTimer.getNow());
	}

	event void AMControl.startDone(error_t err){
		if(err == SUCCESS){
			call pingTimeoutTimer.startPeriodic(PING_TIMER_PERIOD + (uint16_t) ((call Random.rand16())%200));
			call neighborDiscovey.startPeriodic(30000 + (uint16_t) ((call Random.rand16())%200));
			call neighborMap.startPeriodic(60000 + (uint16_t) ((call Random.rand16())%200));
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
	event void neighborMap.fired(){
		//Generating neighbor map
		pack lsp;
		dbg("Project2", "Sending out LSP\n");
		makePack(&lsp,TOS_NODE_ID,AM_BROADCAST_ADDR, MAX_TTL, PROTOCOL_LINKEDSTATE, sequenceNum++,NULL,0);
		sendBufferPushBack(&packBuffer, lsp, lsp.src, AM_BROADCAST_ADDR);
		post sendBufferTask();
	
	}
	event void neighborDiscovey.fired(){
		// TODO Auto-generated method stub
		dbg("Project1N","Looking up neighbors\n");
		checkNeighbors(&Neighbors);
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
						dbg("Project1N", "I have been discovered, sending reply.\n");
						makePack(&sendPackage, TOS_NODE_ID,myMsg->src, 1, PROTOCOL_PINGREPLY, sequenceNum++, (uint8_t *) broadcastMessage, sizeof(broadcastMessage));
						//sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, sendPackage.dest);
						sendBufferPushBack(&packBuffer, sendPackage, sendPackage.src, myMsg->src);
						post sendBufferTask();
						break;
						case PROTOCOL_LINKEDSTATE:
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
					if(!strcmp(myMsg->payload,broadcastMessage)){
						hashmapInsert(&Neighbors,hash3(myMsg->src,1),myMsg->src);
						printNeighbors(&Neighbors);
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
					case(PROTOCOL_LINKEDSTATE ):
					break;
					default:
					break;
				}
			}
			//dbg("Project1F", "A Packet has been dropped.\n");
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
	 *
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



