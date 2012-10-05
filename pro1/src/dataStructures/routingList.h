//Author: UCM ANDES Lab
#ifndef ROUTINGLIST_H
#define ROUTINGLIST_H

#include "routingtable.h"
typedef Route dataType1;
#define routeAYSIZE 30
#define MAXNUMVALS routeAYSIZE

typedef struct routelist
{	
	dataType1 values[routeAYSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the routeay
}routelist;

void routeListInit(routelist *cur){
	cur->numValues = 0;	
}

bool routeListPushBack(routelist* cur, dataType1 newVal){
	if(cur->numValues != MAXNUMVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool routeListPushFront(routelist* cur, dataType1 newVal){
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

dataType1 rpop_back(routelist* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

dataType1 rpop_front(routelist* cur){
	dataType1 returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

dataType1 rfront(routelist* cur)
{
	return cur->values[0];
}

dataType1 rback(routelist * cur)
{
	return cur->values[cur->numValues-1];	
}

bool routeListIsEmpty(routelist* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t routeListSize(routelist* cur){	return cur->numValues;}

void routeListClear(routelist* cur){	cur->numValues = 0;}

dataType1 routeListGet(routelist* cur, nx_uint8_t i){	return cur->values[i];}

bool routeListContains(routelist* list, uint8_t iSrc, uint8_t iSeq){
	uint8_t i=0;
	//for(i; i<list->numValues; i++){
//if(iSeq == list->values[i].seq && iSrc == list->values[i].src) return TRUE;
	//}
	return FALSE;
}

#endif /* LIST_H */
