
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
	}
	
	command void TCPManager.freeSocket(TCPSocketAL *input){			
	}
}
