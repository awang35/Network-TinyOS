#include "TCPSocketAL.h"
#include "transport.h"
#include "packBuffer.h"
module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
	uses{
		interface TCPManager<TCPSocketAL, pack> as tcpLayer;
		interface node as Node;
	
	}
}
implementation{	
	uint8_t trans[5] = {"abc"};
	inCon incomingConnections[5];
	uint8_t max = 1, inital = 0,fairCount = 0;
	async command void TCPSocket.init(TCPSocketAL *input){
		input->currentState = CLOSED;
		input->destPort = 0;
		input->destID= 0;
		input->srcPort= 0;
		input-> srcID= TOS_NODE_ID;
		input->packetID= 0;
		input->highestSeqSeen= 0;
		input->highestSeqSent= 0;
		for(i =0;i< 5;i++)
			incomingConnections[i].free = TRUE;
	}
	pack removeFromQueue(){
		//transport temp;
		pack temp;
		int count = 0;
		while(count<4){
			if (fairCount > 4)
				fairCount = 0;
			//dbg("Project3", "Current FairCount: %d. Is it free?: %s\n",fairCount,(incomingConnections[fairCount].free)?"true":"false"); 
			if(incomingConnections[fairCount].free ==FALSE)	{
				dbg("Project3", "Found a waiting connection.\n");
				temp = incomingConnections[fairCount].packet;
				incomingConnections[fairCount].free = TRUE;
				return temp;
			}
			fairCount++;
			count++;
		}
		dbg("Project3", "No waiting connection.\n");
		temp.protocol = 255;
		return temp;

	}


	async command void TCPSocket.addToQueue(pack *pckt){
		uint8_t counter = 0,j;
		pack* myMsg=(pack*) pckt;
		//dbg("Project3", "Added to Queue. srcID: %d, destID: %d\n", pckt->src,pckt->dest);

		while(counter< max){
			if(incomingConnections[counter].free){
				dbg("Project3", "Added to Queue. srcID: %d, destID: %d on count %d\n", pckt->src,pckt->dest,counter);
				incomingConnections[counter].packet = *pckt;
				incomingConnections[counter].free = FALSE;
				return;
			}

			counter++;
		}

	}
	async command uint8_t TCPSocket.bind(TCPSocketAL *input, uint8_t localPort, uint16_t address){
		input->srcPort = localPort;
		input->srcID = address;
		dbg("Project3", "Binding socket ID %d. Current State: %d. Socket binded to port: %d\n",input->uniqueID, input->currentState, localPort);
		dbg("Project3", "SocketInfo: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",input->uniqueID,input->srcID,input->destID,input->srcPort,input->destPort, input->currentState);
		
		//input->currentState = 0;
		//input = call tcpLayer.getSocket(localPort);

		call tcpLayer.AddSocket(input,localPort);
		//call tcpLayer.checkPort(localPort);
		return 0;
	}
	
	async command uint8_t TCPSocket.listen(TCPSocketAL *input, uint8_t backlog){
		//(Server only.) Waits for incoming connection with a client.
		max = backlog;
		dbg("Project3", "Changing port %d to listen.\n",port);
		return input;
	
	}
	
	async command uint8_t TCPSocket.accept(TCPSocketAL *input, TCPSocketAL *output){
		//(Server only.) Accepts incoming connection with a client.
		input->currentState = LISTEN;
	
		return input;
	}
	
	async command uint8_t TCPSocket.connect(TCPSocketAL *input, uint16_t destAddr, uint8_t destPort){
		//(Client only.) Establishes a network connection on a socket.
		transport pckt;
		if(destPort < 0 || destPort > TRANSPORT_MAX_PORT)
			return -1;
		dbg("Project3", "Called connect. Socket State: %d\n",input->currentState);
		if(input->currentState == CLOSED){
			//send a syn packet
			createTransport(&pckt,input->srcPort,destPort,TRANSPORT_SYN,input->highestSeqSent++,0,NULL,0);	
			call Node.tcpPack(&pckt,&input);
			input->currentState = SYN_SENT;
			return 1;
		}
		return -1;
	}

	async command uint8_t TCPSocket.close(TCPSocketAL *input){
		//Terminates a network connection.
	
		return input;
	}

	async command uint8_t TCPSocket.release(TCPSocketAL *input){
		return input;
	}

	async command int16_t TCPSocket.read(TCPSocketAL *input, uint8_t *readBuffer, uint16_t pos, uint16_t len){
	
	
		return input;
	}

	async command int16_t TCPSocket.write(TCPSocketAL *input, uint8_t *writeBuffer, uint16_t pos, uint16_t len){
		return input;
	}

	async command bool TCPSocket.isListening(TCPSocketAL *input){
		if(input->currentState == 1)
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isConnected(TCPSocketAL *input){
		if(input->currentState == 3)
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isClosing(TCPSocketAL *input){
		if (input->currentState == 5 )
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isClosed(TCPSocketAL *input){
		if(input->currentState == 0)
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isConnectPending(TCPSocketAL *input){
		if(input->currentState == 2)
			return TRUE;
		return FALSE;	
	
	}
	
	async command void TCPSocket.copy(TCPSocketAL *input, TCPSocketAL *output){
	}

}
