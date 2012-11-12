#include "./TCPSocketAL.h"
#include "../packet.h"
#include "../transport.h"
#include "../dataStructures/socketList.h"

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
	TCPSocketAL activePorts[TRANSPORT_MAX_PORT];
	ports activeSockets;
	uint8_t uniqueID = 1,index =0;
	TCPSocketAL newSock;
	command void TCPManager.init(){
		//int i = 0;
		//for(i;i<TRANSPORT_MAX_PORT;i++){
		//	call TCPSocket.init(&activePorts[i]);
		//}
	
	}
	
	command TCPSocketAL *TCPManager.socket(){
		//returns a socket
		
		call TCPSocket.init(&newSock);
		newSock.uniqueID = uniqueID;
		uniqueID++;
		dbg("Project3","Asked for a new socket. Sending SocketID of : %d. Indexed at: %d\n",newSock.uniqueID);
		//dbg("Project3", "Grab a socket. Socket State: %d\n",activePorts[99].currentState);
		return &newSock;
	
	}
	void keySocket(transport pckt){
		uint16_t key;
		key = pckt.destPort + pckt.srcPort ;
	}
	
	command void TCPManager.handlePacket(void *msg){
	//insert switch cases depending on flags here.
		pack* myMsg=(pack*) msg;
		transport *pckt = &myMsg->payload;
		transport responsePckt;
		uint8_t i = 0;
		TCPSocketAL sckt;
		dbg("Project3","Checking TCP packet. srcID: %d, destID: %d,srcPort: %d, destPort: %d\n",myMsg->src, myMsg->dest, pckt->srcPort,pckt->destPort);
		dbg("Project3","Recieved a TCP packet\n");
		printTransport(pckt);

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

	//command void TCPManager.forcePortState(uint8_t port){
	//	// TODO Auto-generated method stub
	//	activePorts[port].currentState = ESTABLISHED;
	//}
	
		command void TCPManager.setUpServer(uint8_t srcPort){
		TCPSocketAL *mSocket;

		mSocket = call TCPManager.socket();
		//id = mSocket;
		dbg("Project3","Retrieve a new socket. ID: %d,State: %d\n",mSocket->uniqueID,mSocket->currentState);
		//dbg("Project3", "SocketInfo: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",mSocket->uniqueID,mSocket->srcID,mSocket->destID,mSocket->srcPort,mSocket->destPort, mSocket->currentState);
		call TCPSocket.bind(mSocket, srcPort, TOS_NODE_ID);
		call TCPSocket.listen(mSocket, 5);
		//call ALServer.init(&activeSockets[srcPort]);
	}
	command void TCPManager.setUpClient(uint8_t srcPort, uint8_t destPort, uint8_t destID){
		TCPSocketAL *mSocket;

		mSocket = call TCPManager.socket();
		//id = mSocket;
		dbg("Project3","Retrieve a new socket. ID: %d,State: %d\n",mSocket->uniqueID,mSocket->currentState);
	//	call TCPSocket.bind(mSocket, srcPort, TOS_NODE_ID);
	//	call TCPSocket.connect(destID,destPort,srcPort);
	//	call ALClient.init(&activeSockets[srcPort]);
	}
	
	
//
	//command void TCPManager.checkPort(uint8_t port){
		//if(activePorts[port].currentState == CLOSED){
		//	dbg("Project3", "Free to use port.\n");
		//	return TRUE;
		//}
		//dbg("Project3", "Port was not in state closed.\n");
		//return FALSE;
	//	dbg("Project3", "Port %d is in state: %d.\n",port,activeSockets[port].currentState);
	//}

	command void TCPManager.forcePortState(uint8_t port, uint8_t state){
		// TODO Auto-generated method stub
	//	activeSockets[port].currentState = state;
	}

	command TCPSocketAL * TCPManager.getSocket(uint8_t port){
			int i =0;
		/*for(i;i <TRANSPORT_MAX_PORT;i++){
			if(activePorts[i].currentState == CLOSED)
				return &activePorts[i];
		}*/


	//	return &activeSockets[port];
	}
	

	command void TCPManager.AddSocket(TCPSocketAL *input, uint8_t){
		
		sarrListPushBack(&activeSockets, *input);
		//dbg("Project3","State: %d",input->currentState);//activePorts[port].currentState);
	}
}
