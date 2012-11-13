#include "lib/TCPSocketAL.h"
#include "transport.h"
interface node{
	command void tcpPack(transport payload, TCPSocketAL *sckt);
}