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
	uint8_t trans;
	inCon incomingConnections[5];
	uint8_t max = 1, inital = 0,fairCount = 0;
	async command void TCPSocket.init(TCPSocketAL *input){
		int i = 0;
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

	async command uint8_t TCPSocket.close(uint8_t port){
		//Terminates a network connection.
		TCPSocketAL *input;
		transport pckt;
		createTransport(&pckt,input->srcPort,input->destPort,TRANSPORT_FIN,input->highestSeqSent++,0,NULL,0);	
		call Node.tcpPack(&pckt,input);
		input -> currentState = CLOSED;
		call tcpLayer.forcePortState(port, CLOSED);
		call tcpLayer.checkPort(input->srcPort);
		return 0;
	}

	async command uint8_t TCPSocket.release(uint8_t port){
		TCPSocketAL *input;
		//transport pckt;
		//createTransport(&pckt,input->srcPort,input->destPort,TRANSPORT_FIN,input->highestSeqSent++,0,NULL,0);	
	
		return input;
	}

	async command int16_t TCPSocket.read(uint8_t port, uint8_t *readBuffer, uint16_t pos, uint16_t len){
		TCPSocketAL *input;
		uint16_t i = 0, read = 0;
		input = call tcpLayer.getSocket(port);
		
		if(input->currentState == ESTABLISHED){
			for(i = pos;i<len;i++ ){
				dbg("Project3", "Data being Read: %d\n",readBuffer[i]);
				read++;
			}
		}
		return read;
	}

	async command int16_t TCPSocket.write(uint8_t port, uint8_t *writeBuffer, uint16_t pos, uint16_t len){
		TCPSocketAL *input;
		transport pckt;
		//uint8_t trans;
		uint16_t i = 0, wrote = 0;
		input = call tcpLayer.getSocket(port);
		if(input->currentState == ESTABLISHED){
			for(i = pos;i<len;i++ ){
				dbg("Project3", "Data being sent: %d\n",writeBuffer[i]);
				trans = writeBuffer[i];
				createTransport(&pckt,input->srcPort,input->destPort,TRANSPORT_DATA,input->adwin,input->highestSeqSent++,&trans,sizeof(trans));	
				//dbg("Project3", "Data being sent: %d\n",writeBuffer[i]);
				call Node.tcpPack(&pckt,input);
				wrote++;
			}
		}
		return wrote;
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
