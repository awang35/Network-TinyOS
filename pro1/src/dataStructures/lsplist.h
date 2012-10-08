//Author: UCM ANDES Lab
#ifndef LSPLIST_H
#define LSPLIST_H

#include "lsp.h"
#include "routingtable.h"
typedef lspEntry datatype2;
#define ARRAYSIZE 30
#define MAXNUMVALS ARRAYSIZE

typedef struct lsparrlist
{	
	datatype2 values[ARRAYSIZE]; //list of values
	uint8_t numValues;			//number of objects currently in the array
}lsparrlist;

void lsparrlistInit(lsparrlist *cur){
	cur->numValues = 0;	
}

bool lsparrlistPushBack(lsparrlist* cur, datatype2 newVal){
	if(cur->numValues != MAXNUMVALS){
		cur->values[cur->numValues] = newVal;
		++cur->numValues;
		return TRUE;	
	}else return FALSE;
}

bool lsparrlistPushFront(lsparrlist* cur, datatype2 newVal){
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

datatype2 lsppop_back(lsparrlist* cur){
	--cur->numValues;
	return cur->values[cur->numValues];
}

datatype2 lsppop_front(lsparrlist* cur){
	datatype2 returnVal;
	nx_uint8_t i;	
	returnVal = cur->values[0];
	for(i = 1; i < cur->numValues; ++i)
	{
		cur->values[i-1] = cur->values[i];
	}
	--cur->numValues;
	return returnVal;			
}

datatype2 lspfront(lsparrlist* cur)
{
	return cur->values[0];
}

datatype2 lspback(lsparrlist * cur)
{
	return cur->values[cur->numValues-1];	
}

bool lsparrlistIsEmpty(lsparrlist* cur)
{
	if(cur->numValues == 0)
		return TRUE;
	else
		return FALSE;
}

uint8_t lsparrlistSize(lsparrlist* cur){	return cur->numValues;}

void lsparrlistClear(lsparrlist* cur){	cur->numValues = 0;}

datatype2 lsparrlistGet(lsparrlist* cur, nx_uint8_t i){	return cur->values[i];}

bool lsparrlistContains(lsparrlist* list, uint8_t iSrc){
	uint8_t i=0;
	for(i; i<list->numValues; i++){
		if(iSrc == list->values[i].node) return TRUE;
	}
	return FALSE;
}

#endif /* LIST_H */
