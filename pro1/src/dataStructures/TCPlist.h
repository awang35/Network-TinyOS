//Author: UCM ANDES Lab
#ifndef TCPLIST_H
#define TCPLIST_H

#include "TCPpackets.h"
typedef tpack dataType2;
#define ARRAYSIZE 30
#define MAXNUMVALS ARRAYSIZE

typedef struct tcplist
{	
	dataType2 values[ARRAYSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}tcplist;

void tcpListInit(tcplist *cur){
	cur->numValues = 0;	
}

bool tcpListPushBack(tcplist* cur, dataType2 newVal){
	if(cur->numValues != MAXNUMVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool tcpListPushFront(tcplist* cur, dataType2 newVal){
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

dataType2 tpop_back(tcplist* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

dataType2 tpop_front(tcplist* cur){
	dataType2 returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

dataType2 tfront(tcplist* cur)
{
	return cur->values[0];
}

dataType2 tback(tcplist * cur)
{
	return cur->values[cur->numValues-1];	
}

bool tcpListIsEmpty(tcplist* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t tcpListSize(tcplist* cur){	return cur->numValues;}

void tcpListClear(tcplist* cur){	cur->numValues = 0;}

dataType2 tcpListGet(tcplist* cur, nx_uint8_t i){	return cur->values[i];}

bool tcpListContains(tcplist* list, uint8_t iSrc, uint8_t iSeq){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		//if(iSeq == list->values[i].seq && iSrc == list->values[i].src) return TRUE;
	}
	return FALSE;
}

#endif 
