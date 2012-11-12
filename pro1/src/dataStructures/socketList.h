#ifndef SOCKET_LIST_H
#define SOCKET_LIST_H
#include "TCPSocketAL.h"

typedef TCPSocketAL dataType5;
#define ARRAYSIZE 100
#define MAXNUMVALS ARRAYSIZE

typedef struct arrlist1
{	
	dataType5 values[ARRAYSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}arrlist1;

void sarrListInit(arrlist1 *cur){
	cur->numValues = 0;	
}

bool sarrListPushBack(arrlist1* cur, dataType5 newVal){
	if(cur->numValues != MAXNUMVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool sarrListPushFront(arrlist1* cur, dataType5 newVal){
	if(cur->numValues!= MAXNUMVALS){
		uint8_t i;
		for( i = cur->numValues-1; i >= 0; --i){
			cur->values[i+1] = cur->values[i];
		}
		cur->values[0] = newVal;
		++cur->numValues;
		return TRUE;	
	}else	return FALSE;
} 

dataType5 spop_back(arrlist1* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

dataType5 spop_front(arrlist1* cur){
	dataType5 returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

dataType5 sfront(arrlist1* cur)
{
	return cur->values[0];
}

dataType5 sback(arrlist1 * cur)
{
	return cur->values[cur->numValues-1];	
}

bool sarrListIsEmpty(arrlist1* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t sarrListSize(arrlist1* cur){	return cur->numValues;}

void sarrListClear(arrlist1* cur){	cur->numValues = 0;}

dataType5 sarrListGet(arrlist1* cur, nx_uint8_t i){	return cur->values[i];}

bool sarrListContains(arrlist1* list, uint8_t iSrc, uint8_t iSeq){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		//if(iSeq == list->values[i].seq && iSrc == list->values[i].src) return TRUE;
	}
	return FALSE;
}



#endif /* SOCKET_LIST_H */
