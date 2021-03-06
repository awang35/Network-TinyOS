/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   October 1 2012
 * 
 */ 

#ifndef SERVER_AL_H
#define SERVER_AL_H
#include "TCPSocketAL.h"

typedef struct serverAL{
	TCPSocketAL *socket;
	uint8_t numofWorkers;
}serverAL;

enum{
	SERVER_WORKER_BUFFER_SIZE = 128, // 128 bytes
	SERVER_WORKER_SEND_SIZE = 50
};

typedef struct buffer{
	uint8_t buffer[SERVER_WORKER_BUFFER_SIZE];
	uint16_t amountToRead;
	//uint16_t currentPos;
}serverBuffer;

typedef struct serverWorkerAL{
	TCPSocketAL *socket;
	uint16_t position;
	uint8_t buffer[SERVER_WORKER_BUFFER_SIZE];
	uint8_t sendBuffer[SERVER_WORKER_SEND_SIZE];
	uint8_t id;
	uint16_t amountToRead;
	uint16_t amountToWrite;
	uint16_t writePosition;
	uint8_t name[10];
	bool needWrite;
}serverWorkerAL;

typedef struct userList{
	uint8_t name[10];

}userList;

enum{
	SERVER_TIMER_PERIOD=500, //500 ms
	WORKER_TIMER_PERIOD=533 //533 ms
};
#endif /* SERVER_AL_H */
