#include "serverWorkerList.h"
interface server<val_t>{
	command void init(val_t *);
	command uint16_t Buffer(uint8_t port, uint8_t data,uint8_t requestedAction);
	command serverWorkerAL *GrabWorker(uint8_t port);
}