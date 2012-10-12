#include "TCPSocketAL.h"
#include "transport.h"
module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
}
implementation{	
	async command void TCPSocket.init(TCPSocketAL *input){
		input->currentState = CLOSED;
		
	}
	
	async command uint8_t TCPSocket.bind(TCPSocketAL *input, uint8_t localPort, uint16_t address){
	//For servers, associates a socket with a port and address. For clients, associates a socket with a specific source address.
	input->srcPort = localPort;
	input->srcID = address;
	
	return input;
	}
	
	async command uint8_t TCPSocket.listen(TCPSocketAL *input, uint8_t backlog){
	//(Server only.) Waits for incoming connection with a client.
	
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
		if(input->currentState == CLOSED){
			//send a syn packet
			//createTransport(&pckt,0,destPort,TRANSPORT_SYN,0,0,NULL,0);	
			
			return input;
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
