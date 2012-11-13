#include "./TCPSocketAL.h"
#include "socketList.h"
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
	TCPSocketAL activeSockets[TRANSPORT_MAX_PORT];
	//TCPSocketAL activePorts[TRANSPORT_MAX_PORT];
	TCPSocketAL newSocket[6];
	//bool ports[TRANSPORT_MAX_PORT];
	uint8_t uniqueID = 1,index =0;
	command void TCPManager.init(){
		//int i = 0;
		//for(i;i<20;i++){
		//call TCPSocket.init(&activePorts[i]);
		//ports[i]= FALSE;
		//}
		//shashmapInit(&activeSockets);
	
	}
	
	command TCPSocketAL *TCPManager.socket(){
		//returns a socket
		//activePorts[0];
	
		newSocket[index].uniqueID = uniqueID;
		call TCPSocket.init(&newSocket[index]);
		uniqueID++;
		//dbg("Project3","Asked for a new socket. Sending SocketID of : %d. Indexed at: %d\n",newSocket[index].uniqueID,index);
		//shashmapInsert(&activeSockets,);
		index++;
		return &newSocket[index-1];
	
	}
	command void TCPManager.AddSocket(TCPSocketAL *sckt, uint8_t port){
		//activePorts[port] = *sckt;
		//index++;
		activeSockets[port] = *sckt;
		//sarrListPushFront(&activeSockets, *sckt);
		//dbg("Project3","State: %d",sckt->currentState);//activePorts[port].currentState);
	}
	command void TCPManager.setUpServer(uint8_t srcPort){
		TCPSocketAL *mSocket;

		mSocket = call TCPManager.socket();
		//id = mSocket;
		//dbg("Project3","Retrieve a new socket. ID: %d,State: %d\n",mSocket->uniqueID,mSocket->currentState);
		//dbg("Project3", "SocketInfo: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",mSocket->uniqueID,mSocket->srcID,mSocket->destID,mSocket->srcPort,mSocket->destPort, mSocket->currentState);
		call TCPSocket.bind(mSocket, srcPort, TOS_NODE_ID);
		call TCPSocket.listen(srcPort, 5);
		call ALServer.init(&activeSockets[srcPort]);
	}
	command void TCPManager.setUpClient(uint8_t srcPort, uint8_t destPort, uint8_t destID){
		TCPSocketAL *mSocket;

		mSocket = call TCPManager.socket();
		//id = mSocket;
		//dbg("Project3","Retrieve a new socket. ID: %d,State: %d\n",mSocket->uniqueID,mSocket->currentState);
		call TCPSocket.bind(mSocket, srcPort, TOS_NODE_ID);
		call TCPSocket.connect(destID,destPort,srcPort);
		call ALClient.init(&activeSockets[srcPort]);
	}
	
	command void TCPManager.handlePacket(void *msg){
		//insert switch cases depending on flags here.
		pack* myMsg=(pack*) msg;
		transport *pckt = &myMsg->payload;
		transport responsePckt;
		uint8_t i = 0;
		TCPSocketAL sckt;
		//dbg("Project3","Checking TCP packet. srcID: %d, destID: %d,srcPort: %d, destPort: %d\n",myMsg->src, myMsg->dest, pckt->srcPort,pckt->destPort);
		//dbg("Project3","Recieved a TCP packet\n");
		//printTransport(pckt);

		sckt = activeSockets[pckt->destPort];
		switch(pckt->type){
			case TRANSPORT_SYN:
			//dbg("Project3", "SYN RECIEVED. What is the status of port %d: %d\n",pckt->destPort,activePorts[pckt->destPort].currentState);
			if(sckt.currentState == LISTEN){
				dbg("Project3", "SYN. CONNECTION ADDED TO QUEUE \n");
				//activeSockets[pckt->destPort].highestSeqSeen = pckt->seq;
				call TCPSocket.addToQueue(msg);
				//createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_ACK, 0, 0, NULL, 0);
				//call Node.tcpPack(&responsePckt,&sckt);
				//call TCPSocket.bind(&activePorts[pckt->destPort],pckt->destPort,2);	
				//sckt.currentState = ESTABLISHED;
			}
			break;
			case TRANSPORT_ACK:
			if(sckt.currentState == SYN_SENT){
				dbg("Project3", "ACK recieved on port %d\n",pckt->destPort);
				//sckt.highestSeqSeen = pckt->seq;
				activeSockets[pckt->destPort].destPort = pckt->srcPort;
				sckt.destPort =pckt->srcPort;
				//createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_ACK, 0, 0, NULL, 0);
				//call TCPSocket.bind(&activePorts[pckt->destPort],pckt->destPort,2);	
				sckt.currentState = ESTABLISHED;
				call TCPManager.forcePortState(pckt->destPort, ESTABLISHED);
				call TCPManager.checkPort(3);
			}
			if(sckt.currentState == ESTABLISHED){
				dbg("Project3", "ACK for data recieved on port %d\n",pckt->destPort);
			}
			break;
			case TRANSPORT_FIN:
			if(sckt.currentState == ESTABLISHED){
				dbg("Project3", "FIN: SOCKET IS NOW CLOSED\n");
				//sckt.highestSeqSeen = pckt->seq;
				createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				//call TCPSocket.bind(&activePorts[pckt->destPort],pckt->destPort,2);	
				activeSockets[pckt->destPort].currentState = CLOSED;
			}
			break;
			case TRANSPORT_DATA:
	
			if(sckt.highestSeqSeen == 0){
				sckt.highestSeqSeen = pckt->seq;
				activeSockets[pckt->destPort].highestSeqSeen = pckt->seq;
			}
			if((activeSockets[pckt->destPort].highestSeqSeen+1)==pckt->seq){
				dbg("Project3", "Data recieved in order.\n");
				activeSockets[pckt->destPort].highestSeqSeen++;
	
				//dbg("Project3", "DATA RECIEVED. HIGHEST SEQ SEEN: %d. THIS PCKT SEQ IS: %d, DATA: %d \n",sckt.highestSeqSeen,pckt->seq, pckt->payload[0]);
				call ALServer.Buffer(pckt->destPort,pckt->payload[0]);
				if(sckt.currentState == ESTABLISHED){
					createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_ACK, 0, 0, NULL, 0);
					//call Node.tcpPack(&responsePckt,&sckt);
				}
			}
			break;
			default:
			dbg("Project3", "UNKNOWN");
		}
	
	
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){			
	}


	command void TCPManager.checkPort(uint8_t port){
		//if(activePorts[port].currentState == CLOSED){
		//	dbg("Project3", "Free to use port.\n");
		//	return TRUE;
		//}
		//dbg("Project3", "Port was not in state closed.\n");
		//return FALSE;
		dbg("Project3", "Port %d is in state: %d.\n",port,activeSockets[port].currentState);
	}

	command void TCPManager.forcePortState(uint8_t port, uint8_t state){
		// TODO Auto-generated method stub
		activeSockets[port].currentState = state;
	}
	command nx_uint16_t TCPManager.increaseSEQ(uint8_t port){
		activeSockets[port].highestSeqSent++;
		return activeSockets[port].highestSeqSent-1;
	}

	command TCPSocketAL * TCPManager.getSocket(uint8_t port){
		int i =0;
		/*for(i;i <TRANSPORT_MAX_PORT;i++){
		if(activePorts[i].currentState == CLOSED)
		return &activePorts[i];
		}*/

	
		return &activeSockets[port];
	}
}
