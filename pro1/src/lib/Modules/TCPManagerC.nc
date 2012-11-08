#include "./TCPSocketAL.h"
#include "../packet.h"
#include "../transport.h"
#include "../dataStructures/socketHash.h"
module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, pack>;
	uses interface TCPSocket<TCPSocketAL>;	
}
implementation{
	socketmap freeList;
	//a pair of sockets will uniquely id a connection
	//socketmap activePorts[TRANSPORT_MAX_PORT];
	
	command void TCPManager.init(){
	
		
	}
	
	command TCPSocketAL *TCPManager.socket(){
	//returns a socket
		
	
	}
	void keySocket(transport pckt){
	uint16_t key;
		key = pckt.destPort + pckt.srcPort ;
	}
	
	command void TCPManager.handlePacket(void *payload){
	//insert switch cases depending on flags here.
	transport *pckt = (transport*)payload;
	transport responsePckt;
	uint8_t i = 0;
	TCPSocketAL sckt;
	dbg("Project3","Recieved a TCP packet\n");
	printTransport(pckt);
	//check connection info if there is a socket relating to it
	//if(shashmapContains(&activePorts[pckt->srcPort],pckt->destPort)){
		
	//} 
	switch(pckt->type){
		case TRANSPORT_SYN:
			dbg("Project3", "SYN ");
			//createTransport(&responsePckt, uint8_t srcPort, uint8_t destPort, uint8_t type, uint16_t window, int16_t seq, uint8_t *payload, uint8_t packetLength);
				
			
			break;
		case TRANSPORT_ACK:
			dbg("Project3", "ACK ");
			break;
		case TRANSPORT_FIN:
			dbg("Project3", "FIN ");
			break;
		case TRANSPORT_DATA:
			dbg("Project3", "DATA ");
			break;
		default:
			dbg("Project3", "UNKNOWN");
	}
	
	
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){			
	}
}
