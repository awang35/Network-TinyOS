#include "./TCPSocketAL.h"
#include "socketList.h"
#include "../packet.h"
#include "../transport.h"
#include "../dataStructures/socketHash.h"
module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, pack>;
	uses{ 
		interface TCPSocket<TCPSocketAL>;	
		//interface client<TCPSocketAL> as ALClient;
		//interface server<TCPSocketAL> as ALServer;
		interface chatClient<TCPSocketAL> as ALClient;
		interface chatServer<TCPSocketAL> as ALServer;
		interface node as Node;
		interface Timer<TMilli> as closing;
		interface Timer<TMilli> as pckResend;
	}
}
implementation{
	TCPSocketAL activeSockets[TRANSPORT_MAX_PORT];
	TCPSocketAL newSocket[30];
	uint8_t connectSeen;
	bool three = TRUE, ten = TRUE;
	transport resendMe;
	transport bufferTrans[128];
	uint8_t uniqueID = 1,index =0, socketClosed, resendPort;
	command void TCPManager.init(){}
	
	command TCPSocketAL *TCPManager.socket(){
		newSocket[index].uniqueID = uniqueID;
		call TCPSocket.init(&newSocket[index]);
		uniqueID++;
		index++;
		return &newSocket[index-1];
	
	}
	command void TCPManager.AddSocket(TCPSocketAL *sckt, uint8_t port){
		activeSockets[port] = *sckt;
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
				if(connectSeen!=myMsg->src){
					dbg_clear("Project3", "SYN. CONNECTION ADDED TO QUEUE \n");
					call TCPSocket.addToQueue(msg);
					connectSeen = myMsg->src;
				}
				else
					dbg("Project3", "Dropping syn packet.\n");
			}
			else{
				dbg("Project3", "Port is closed.\n");
				
				sckt.destID = myMsg->src;
				sckt.srcID = myMsg->dest;
				resendMe = responsePckt;
				resendPort = sckt.srcPort;
				createTransport(&responsePckt, pckt->destPort, pckt->srcPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				call Node.tcpPack(responsePckt,sckt);
				//call pckResend.startPeriodic(200);
			}
			break;
			case TRANSPORT_ACK:
			if(sckt.currentState == SYN_SENT){
				dbg("Project3", "ACK recieved on port %d\nCONNECTION ESTABISHED! WINDOW SIZE: %d\n",pckt->destPort,pckt->window);
				activeSockets[pckt->destPort].adwin = pckt->window;
				call TCPSocket.TimerStop(2);
				//sckt.highestSeqSeen = pckt->seq;
				activeSockets[pckt->destPort].destPort = pckt->srcPort;
				call TCPManager.forcePortState(pckt->destPort, ESTABLISHED);
			}
			else if(sckt.currentState == ESTABLISHED){
				// TODO WINDOW AND RELIABLE ACK
				//dbg("Project3", "ACK for data recieved on port %d\n",pckt->destPort);
				//dbg("Project3", "Comparing Seq. Expected Seq: %d, Received: %d\n",(activeSockets[pckt->destPort].highestSeqSeen+1),pckt->seq);
				//dbg("Project3", "Comparing Seq. Highest Seq Sent: %d, Seen: %d\n",(activeSockets[pckt->destPort].highestSeqSent),activeSockets[pckt->destPort].highestSeqSeen);
				if(activeSockets[pckt->destPort].highestSeqSent == pckt->seq){
					//dbg("Project3", "I recieved an ack that satisfied all the ack before me.!\n");
					dbg("Project3", "Increasing CDWIN\n");
					activeSockets[pckt->destPort].cdwin+=2;
					call TCPSocket.resetBuffer();
					if(activeSockets[pckt->destPort].cdwin> activeSockets[pckt->destPort].adwin)
						activeSockets[pckt->destPort].cdwin = activeSockets[pckt->destPort].adwin;
					activeSockets[pckt->destPort].adwin= pckt->window;
					activeSockets[pckt->destPort].highestSeqSeen++;
				}
				else if((activeSockets[pckt->destPort].highestSeqSeen+1)==pckt->seq)
				{
					if(activeSockets[pckt->destPort].highestSeqSent == pckt->seq){
					}
					//dbg("Project3", "Correct ack received.\n");
					activeSockets[pckt->destPort].adwin= pckt->window;
					activeSockets[pckt->destPort].highestSeqSeen++;
				}
				else{	
						activeSockets[pckt->destPort].cdwin/=2;
					dbg("Project3", "Incorrect Ack. Sending Data Again.\n");
					call TCPSocket.startBufferTimmer(activeSockets[pckt->destPort].highestSeqSeen);
				}
			}
			else{
					createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				call Node.tcpPack(responsePckt,sckt);
			}
			break;
			case TRANSPORT_FIN:
			if(sckt.currentState == ESTABLISHED){
				call pckResend.stop();
				dbg("Project3", "FIN: SOCKET WILL BE CLOSED SOON\n");
				//sckt.highestSeqSeen = pckt->seq;
				call closing.startOneShot(2500);
				socketClosed = pckt->destPort;
				createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_FIN, 0, 0, NULL, 0);
				resendMe = responsePckt;
				resendPort = sckt.srcPort;
				call Node.tcpPack(responsePckt,sckt);
				call pckResend.startPeriodic(600);
			}
			if(sckt.currentState == CLOSING){
				call TCPSocket.TimerStop(2);
				activeSockets[pckt->destPort].currentState = CLOSED;
				//call closing.startOneShot(1200);
			}
			if(sckt.currentState == SYN_SENT){
				call TCPSocket.TimerStop(2);
				dbg("Project3", "Did you send to the right port?\n");
				activeSockets[pckt->destPort].currentState = CLOSED;
				//call closing.startOneShot(1200//
			}
			break;
			case TRANSPORT_DATA:
	
			if(sckt.highestSeqSeen == 0){
				//++sckt.highestSeqSeen = pckt->seq;
				dbg("Project3","Packet Seq Receive: %d\n",pckt->seq);
				activeSockets[pckt->destPort].highestSeqSeen = pckt->seq-1;
				call TCPSocket.TimerStop(2);
			}
			if((activeSockets[pckt->destPort].highestSeqSeen+1)==pckt->seq){
				call pckResend.stop();
				//dbg("Project3", "Data recieved in order.\n");
				activeSockets[pckt->destPort].highestSeqSeen++;
				//dbg("Project3", "DATA RECIEVED. HIGHEST SEQ SEEN: %d. THIS PCKT SEQ IS: %d, DATA: %d \n",sckt.highestSeqSeen,pckt->seq, pckt->payload[0]);
				call ALServer.Buffer(pckt->destPort,pckt->payload[0],0);
				if(sckt.currentState == ESTABLISHED){
					activeSockets[pckt->destPort].adwin--;
					createTransport(&responsePckt, sckt.srcPort, sckt.destPort, TRANSPORT_ACK, sckt.adwin, (pckt->seq)+1, NULL, 0);
					resendMe = responsePckt;
					resendPort = sckt.srcPort;
					call Node.tcpPack(responsePckt,sckt);
					call pckResend.startPeriodic(1033);
				}
			}
			else{
					dbg("Project3", "Data received OUT OF ORDER. Expected Seq: %d, Recieved: %d\n",(activeSockets[pckt->destPort].highestSeqSeen+1),pckt->seq);
			}
			break;
			default:
			dbg("Project3", "UNKNOWN");
		}
	
	
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){			
	}


	command void TCPManager.checkPort(uint8_t port){
		dbg("Project3", "Port %d is in state: %d.\n",port,activeSockets[port].currentState);
	}

	command void TCPManager.forcePortState(uint8_t port, uint8_t state){
		activeSockets[port].currentState = state;
	}
	command nx_uint16_t TCPManager.increaseSEQ(uint8_t port){
		activeSockets[port].highestSeqSent++;
		return activeSockets[port].highestSeqSent-1;
	}

	command TCPSocketAL * TCPManager.getSocket(uint8_t port){
		return &activeSockets[port];
	}
	command TCPSocketAL TCPManager.getCopySocket(uint8_t port){
		return activeSockets[port];
	}
	command nx_uint16_t TCPManager.window(uint8_t port, uint8_t type){
		if(type==0)
			activeSockets[port].adwin++;
		if(type == 1)
			activeSockets[port].adwin--;
		if(type == 2)
			activeSockets[port].cdwin++;
		if(type == 3)
			activeSockets[port].cdwin--;
		if(type== 4)
			activeSockets[port].adwin = SERVER_WORKER_BUFFER_SIZE;
		return 0;	
	}
	event void closing.fired(){
		call pckResend.stop();
		dbg("Project3", "Port %d is now closed.",socketClosed);
		activeSockets[socketClosed].currentState = CLOSED;
	}

	event void pckResend.fired(){
		// TODO Auto-generated method stub
		dbg("Project3", "TCPManager -- Seems like a packet was lost. Resending.\n");
		dbg_clear("Project3", "Packet that was lost:\n");
		printTransport(&resendMe);
		call Node.tcpPack(resendMe ,activeSockets[resendPort]);
	}
}
