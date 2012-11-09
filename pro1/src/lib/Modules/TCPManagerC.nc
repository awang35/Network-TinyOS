#include "./TCPSocketAL.h"
#include "../packet.h"
#include "../transport.h"
#include "../dataStructures/socketHash.h"
module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, pack>;
	uses{ 
		interface TCPSocket<TCPSocketAL>;	
		interface client<TCPSocketAL> as ALClient;
		interface server<TCPSocketAL> as ALServer;
		interface node as Node;
	}
}
implementation{
	//socketmap freeList;
	//a pair of sockets will uniquely id a connection
	//socketmap activePorts[TRANSPORT_MAX_PORT];
	TCPSocketAL activePorts[TRANSPORT_MAX_PORT];

	command void TCPManager.init(){
		int i = 0;
		for(i;i<TRANSPORT_MAX_PORT;i++){
			call TCPSocket.init(&activePorts[i]);
		}
	
	}
	
	command TCPSocketAL *TCPManager.socket(){
		//returns a socket
		dbg("Project3", "Grab a socket. Socket State: %d\n",activePorts[99].currentState);
		return &activePorts[99];
	
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
	
		//return;
		//} 
		
		sckt = activePorts[pckt->destPort];
		switch(pckt->type){
			case TRANSPORT_SYN:
			//if(activePorts[pckt->destPort].currentState == LISTEN){
				dbg("Project3", "SYN ");
				sckt.highestSeqSeen = pckt->seq;
				createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_ACK, 0, 0, NULL, 0);
				call Node.tcpPack(&responsePckt,&sckt);
				//call TCPSocket.bind(&activePorts[pckt->destPort],pckt->destPort,2);	
				sckt.currentState = ESTABLISHED;
			//}
			break;
			case TRANSPORT_ACK:
			if(activePorts[pckt->destPort].currentState == SYN_SENT){
				dbg("Project3", "ACK ");
				sckt.highestSeqSeen = pckt->seq;
				//createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_ACK, 0, 0, NULL, 0);
				//call TCPSocket.bind(&activePorts[pckt->destPort],pckt->destPort,2);	
				sckt.currentState = ESTABLISHED;
			}
			break;
			case TRANSPORT_FIN:
				if(activePorts[pckt->destPort].currentState == ESTABLISHED){
				dbg("Project3", "FIN ");
				//sckt.highestSeqSeen = pckt->seq;
				createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				//call TCPSocket.bind(&activePorts[pckt->destPort],pckt->destPort,2);	
				sckt.currentState = ESTABLISHED;
			}
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

	

	command bool TCPManager.checkPort(uint8_t port){
		if(activePorts[port].currentState == CLOSED){
			dbg("Project3", "Free to use port.\n");
			return TRUE;
		}
		dbg("Project3", "Port was not in state closed.\n");
		return FALSE;
	}

	command void TCPManager.forcePortState(uint8_t port){
		// TODO Auto-generated method stub
		activePorts[port].currentState = ESTABLISHED;
	}
}
