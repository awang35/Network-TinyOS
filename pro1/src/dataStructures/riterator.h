

/*
 * Author: UCM ANDES Lab
 * Description: A simple method of converting the hashmap class I created into an iterator.
 */
#ifndef RITERATOR_H
#define RITERATOR_H

#include "routeHashmap.h"

typedef struct riterator{
	hashType2 values[rHASH_MAX_SIZE];
	uint16_t size;
	uint16_t position;
}riterator;

/*
 * iteratorInit - copies values from the hashmap to the iterator struct.
 * @param
 * 			iterator *it = iterator that is to be made.
 * 			hashmap *input = hashmap from which the values are made from.
 */
void riteratorInit(riterator *it, rhashmap *input){
	uint16_t i;
	it->position = 0;
	it->size = 0;
		
	for(i=0; i<input->numofVals; i++){
		it->values[i] = rhashmapGet(input, input->keys[i]);
		it->size++;
	}
}

/*
 * iteratorNext - returns the next value.
 * @param
 * 			iterator *it = iterator that the value is getting from.
 */
hashType2 riteratorNext(riterator *it){
	if(it->position < it->size){
		hashType2 temp=it->values[it->position];
		it->position++;
		return temp;
	}
	it->position++;
	dbg("iterator", "Error: iterator has overflown.");
	return it->values[0];
}

void riteratorResetPos(riterator *it){
	it->position=0;	
}

/*
 * routeIteratorNext - returns a bool if the iterator has a next value.
 * @param
 * 			iterator *it = iterator that the value is getting from.
 * @return
 * 			bool = returns TRUE if there is another value else returns FALSE.
 */
bool riteratorHasNext(riterator *it){
	dbg("iterator", "it Position: %hhu \nit Size: %hhu\n", it->position, it->size);
	if(it->position < it->size) return TRUE;
	return FALSE;
}
#endif /* ITERATOR_H */