/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#ifndef CLIENT_H
#define CLIENT_H
#include "TCPSocketAL.h"
#include "../packet.h"

enum{
	CLIENT_TIMER_PERIOD=500, //500 ms
	CLIENTAL_BUFFER_SIZE=64	//64 bytes
};


typedef struct clientAL{
	TCPSocketAL *socket;
	uint32_t startTime;
	uint16_t amount; //Amount of bytes to be sent.
	uint8_t *name;
	pack payload;
	uint16_t position;
	uint8_t buffer[CLIENTAL_BUFFER_SIZE];
	uint8_t readBuffer[CLIENTAL_BUFFER_SIZE];
	uint16_t readPosition;
	uint16_t amountToRead;
	bool needRead;
}clientAL;

#endif /* CLIENT_H */
