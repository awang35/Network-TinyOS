/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#ifndef TCP_SOCKET_AL_H
#define TCP_SOCKET_AL_H
#include "transport.h"
enum TCPSOCKET_ERR_MSG{
 
	TCP_ERRMSG_SUCCESS 
 
}; 
enum TCPSOCKET_STATE{
	CLOSED=0,
	LISTEN=1,
	SYN_SENT=2,
	ESTABLISHED=3,
	SHUTDOWN=4,
	CLOSING=5
};

typedef struct TCPSocketAL{
	/*Insert Variables Here */
	uint8_t uniqueID;
	uint8_t currentState;
	uint8_t destPort;
	uint8_t destID;
	uint8_t srcPort;
	uint8_t srcID;
	uint8_t packetID;
	uint8_t highestSeqSeen;
	uint8_t highestSeqSent;
}TCPSocketAL;
typedef struct incomingConnect{
	TCPSocketAL socket;
	pack packet;
	bool free;
} inCon;
#endif /* TCP_SOCKET_AL_H */
