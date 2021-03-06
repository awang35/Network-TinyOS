#include "TCPSocketAL.h"
interface TCPManager<val_t, val2_t>{
	command void checkPort(uint8_t);
	command void init();
	command val_t *socket();
	command void freeSocket(val_t *);
	command void handlePacket(void *);
	command void forcePortState(uint8_t,uint8_t);
	command void AddSocket(val_t *,uint8_t);
	command TCPSocketAL *getSocket(uint8_t);
	command void setUpServer(uint8_t srcPort);
	command void setUpClient(uint8_t srcPort, uint8_t destPort, uint8_t destID);
	command void setUpChatClient(uint8_t srcPort, uint8_t destPort, uint8_t destID, void *);
	command nx_uint16_t increaseSEQ(uint8_t port);
	command nx_uint16_t window(uint8_t port, uint8_t type);
	command TCPSocketAL getCopySocket(uint8_t port); 
	command void turnOffTimer();
}
