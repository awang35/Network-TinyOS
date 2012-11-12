#include "TCPSocketAL.h"
interface TCPManager<val_t, val2_t>{
	command bool checkPort(uint8_t);
	command void init();
	command val_t *socket();
	command void freeSocket(val_t *);
	command void handlePacket(void *);
	command void AddSocket(val_t *,uint8_t);
	command TCPSocketAL *getSocket(uint8_t);
	command void setUpServer(uint8_t srcPort);
	command void setUpClient(uint8_t srcPort, uint8_t destPort, uint8_t destID);
	command void forcePortState(uint8_t,uint8_t);
}
