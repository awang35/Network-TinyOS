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
}TCPSocketAL;

#endif /* TCP_SOCKET_AL_H */
