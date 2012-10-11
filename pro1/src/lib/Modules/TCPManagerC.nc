#include "./TCPSocketAL.h"
#include "../packet.h"

module TCPManagerC{
	provides interface TCPManager<TCPSocketAL, pack>;
	uses interface TCPSocket<TCPSocketAL>;	
}
implementation{
	command void TCPManager.init(){
	}
	
	command TCPSocketAL *TCPManager.socket(){
	}

	command void TCPManager.handlePacket(void *payload){
	//insert switch cases depending on flags here.
	dbg("Project3","Recieved a TCP packet\n");	
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){			
	}
}
