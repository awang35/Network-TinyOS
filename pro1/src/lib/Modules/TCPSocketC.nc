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

	inCon incomingConnections[5];
	uint8_t max = 1, inital = 0,fairCount = 0;
	async command void TCPSocket.init(TCPSocketAL *input){
		int i = 0;
		input->currentState = CLOSED;
		input->destPort = -1;
		input->destID= -1;
		input->srcPort= -1;
		input-> srcID= TOS_NODE_ID;
		input->packetID= -1;
		input->highestSeqSeen= -1;
		input->highestSeqSent= -1;
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
		//For servers, associates a socket with a port and address. For clients, associates a socket with a specific source address.
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
	
	async command uint8_t TCPSocket.listen(uint8_t port, uint8_t backlog){
		//(Server only.) Waits for incoming connection with a client.
		TCPSocketAL *input;
		max = backlog;
		dbg("Project3", "Changing port %d to listen.\n",port);
		input = call tcpLayer.getSocket(port);
		dbg("Project3", "SocketInfo: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",input->uniqueID,input->srcID,input->destID,input->srcPort,input->destPort, input->currentState);
		//call tcpLayer.forcePortState(5, 1);
		input->currentState = LISTEN;
		dbg("Project3", "Listen. Current State: %d\n", input->currentState);
		//call tcpLayer.checkPort(input->srcPort);
		return 0;
	
	}
	/*
	 * 
	 * 	async command uint8_t TCPSocket.listen(TCPSocketAL *input, uint8_t backlog){
	//(Server only.) Waits for incoming connection with a client.
	max = backlog;
	input = call tcpLayer.getSocket(input->srcPort);
	//call tcpLayer.forcePortState(5, 1);
	input->currentState = LISTEN;
	dbg("Project3", "Listen. Current State: %d\n", input->currentState);
	call tcpLayer.checkPort(input->srcPort);
	return 0;
	
	}
	 */
	
	async command uint8_t TCPSocket.accept(uint8_t srcPort, uint8_t newPort){
		//(Server only.) Accepts incoming connection with a client.
		pack temp = removeFromQueue();
		transport *pckt;
		transport send;
		TCPSocketAL *input, *output;
		if(temp.protocol != 255){
			dbg("Project3", "Grabing socket at port %d",srcPort);
			input = call tcpLayer.getSocket(srcPort);
			output = call tcpLayer.socket();
			call TCPSocket.copy(input,output);
			pckt = (transport*)temp.payload;
			output->currentState = ESTABLISHED;
			output->destID = temp.src;
			output->destPort = pckt->srcPort;
			output->srcPort = newPort;
			dbg("Project3", "Accepted a connection. Socket State: %d\n",output->currentState);
			dbg("Project3", "After: Output Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",output->uniqueID,output->srcID,output->destID,output->srcPort,output->destPort, output->currentState);
			call tcpLayer.AddSocket(output,output->srcPort);
			call tcpLayer.checkPort(output->srcPort);
			
			createTransport(&send,output->srcPort,output->destPort,TRANSPORT_ACK,output->highestSeqSent++,0,NULL,0);	
			call Node.tcpPack(&send,output);
			return 0;
		}
		return -1;
	}

	async command uint8_t TCPSocket.connect(uint16_t destAddr, uint8_t destPort,uint8_t port){
		//(Client only.) Establishes a network connection on a socket.
		TCPSocketAL *input;
		transport pckt;
		dbg("Project3", "Atempting to connect from port %d to destID %d on port %d.\n",port,destAddr,destPort);
		input = call tcpLayer.getSocket(port);
		if(destPort < 0 || destPort > TRANSPORT_MAX_PORT)
			return -1;
		dbg("Project3", "Called connect. Socket State: %d\n",input->currentState);
		//input->currentState = CLOSED;
		if(input->currentState == CLOSED){
			//send a syn packet
			input->destID = destAddr;
			input->destPort = destPort;
			input->currentState = SYN_SENT;
			dbg("Project3", "SocketInfo: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",input->uniqueID,input->srcID,input->destID,input->srcPort,input->destPort, input->currentState);
			createTransport(&pckt,input->srcPort,destPort,TRANSPORT_SYN,input->highestSeqSent++,0,NULL,0);	
			call Node.tcpPack(&pckt,input);
			return 0;
		}
		return -1;
	}

	async command uint8_t TCPSocket.close(TCPSocketAL *input){
		//Terminates a network connection.
		transport pckt;
		createTransport(&pckt,input->srcPort,input->destPort,TRANSPORT_FIN,input->highestSeqSent++,0,NULL,0);	
		call Node.tcpPack(&pckt,input);
	
		return 0;
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

	async command bool TCPSocket.isListening(uint8_t port){
		TCPSocketAL *input;
		input = call tcpLayer.getSocket(port);
		if(input->currentState == 1)
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isConnected(uint8_t port){
		TCPSocketAL *input;
		input = call tcpLayer.getSocket(port);
		if(input->currentState == 3)
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isClosing(uint8_t port){
		TCPSocketAL *input;
		input = call tcpLayer.getSocket(port);
		if (input->currentState == 5 )
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isClosed(uint8_t port){
		TCPSocketAL *input;
		input = call tcpLayer.getSocket(port);
		if(input->currentState == 0)
			return TRUE;
		return FALSE;
	}

	async command bool TCPSocket.isConnectPending(uint8_t port){
		TCPSocketAL *input;
		input = call tcpLayer.getSocket(port);
		if(input->currentState == 2)
			return TRUE;
		return FALSE;	
	
	}
	
	async command void TCPSocket.copy(TCPSocketAL *input, TCPSocketAL *output){
		//dbg("Project3", "Copying input to output");
		//dbg("Project3", "Input Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",input->uniqueID,input->srcID,input->destID,input->srcPort,input->destPort, input->currentState);
		//dbg("Project3", "Before Output Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",output->uniqueID,output->srcID,output->destID,output->srcPort,output->destPort, output->currentState);
		output-> currentState = input-> currentState;
		output-> destPort = input-> destPort;
		output-> destID = input-> destID;
		output-> srcPort = input-> srcPort;
		output-> srcID = input-> srcID;
		dbg("Project3", "After: Output Info: ID: %d,srcID: %d, destID: %d, srcPort: %d, destPort: %d, state: %d\n",output->uniqueID,output->srcID,output->destID,output->srcPort,output->destPort, output->currentState);
	
	}


}
