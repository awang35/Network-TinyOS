#ifndef SOCKET_LIST_H
#define SOCKET_LIST_H
#include "TCPSocketAL.h"

enum{
	MAX_PORTS = 255
};

typedef struct ports
{	
	TCPSocketAL values[MAX_PORTS]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}ports;

void sarrListInit(ports *cur){
	cur->numValues = 0;	
}

bool sarrListPushBack(ports* cur, TCPSocketAL newVal){
	if(cur->numValues != MAX_PORTS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

TCPSocketAL *spop_back(ports* cur){
	--cur->numValues;
	return &(cur->values[cur->numValues]);
}

TCPSocketAL spop_front(ports* cur){
	TCPSocketAL returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

TCPSocketAL sfront(ports* cur)
{
	return cur->values[0];
}

TCPSocketAL sback(ports * cur)
{
	return cur->values[cur->numValues-1];	
}

bool sarrListIsEmpty(ports* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t sarrListSize(ports* cur){	return cur->numValues;}

uint8_t sarrListContains(ports* list, uint8_t srcPort){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		if(srcPort == list->values[i].srcPort) return i;
	}
	return -1;
}
TCPSocketAL *sarrListGet(ports* cur, uint8_t port){	
int i = 0;
i = sarrListContains(cur,port);

return &(cur->values[i]);}


#endif /* SOCKET_LIST_H */
