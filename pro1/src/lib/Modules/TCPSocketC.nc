#include "TCPSocketAL.h"

module TCPSocketC{
	provides{
		interface TCPSocket<TCPSocketAL>;
	}
}
implementation{	
	async command void TCPSocket.init(TCPSocketAL *input){
	}
	
	async command uint8_t TCPSocket.bind(TCPSocketAL *input, uint8_t localPort, uint16_t address){
	}
	
	async command uint8_t TCPSocket.listen(TCPSocketAL *input, uint8_t backlog){
	}
	
	async command uint8_t TCPSocket.accept(TCPSocketAL *input, TCPSocketAL *output){
	}

	async command uint8_t TCPSocket.connect(TCPSocketAL *input, uint16_t destAddr, uint8_t destPort){
	}

	async command uint8_t TCPSocket.close(TCPSocketAL *input){
	}

	async command uint8_t TCPSocket.release(TCPSocketAL *input){
	}

	async command int16_t TCPSocket.read(TCPSocketAL *input, uint8_t *readBuffer, uint16_t pos, uint16_t len){
	}

	async command int16_t TCPSocket.write(TCPSocketAL *input, uint8_t *writeBuffer, uint16_t pos, uint16_t len){
	}

	async command bool TCPSocket.isListening(TCPSocketAL *input){
	}

	async command bool TCPSocket.isConnected(TCPSocketAL *input){
	}

	async command bool TCPSocket.isClosing(TCPSocketAL *input){
	}

	async command bool TCPSocket.isClosed(TCPSocketAL *input){
	}

	async command bool TCPSocket.isConnectPending(TCPSocketAL *input){
	}
	
	async command void TCPSocket.copy(TCPSocketAL *input, TCPSocketAL *output);
}
