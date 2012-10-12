//Author: UCM ANDES Lab
//Date: 2/16/2012
//Description: A simple hashtable. Change the HASHMAP_TYPE to change the type being stored.
#ifndef SOCKETHASH_H
#define SOCKETHASH_H
#include "TCPSocketAL.h"

typedef TCPSocketAL sockType;

enum{
	MAX_CONNECTIONS = 20
};

typedef struct socketEntry{
	uint16_t key;
	sockType value;
}socketEntry;

typedef struct socketmap{
	socketEntry map[20];
	uint8_t keys[MAX_CONNECTIONS];
	uint8_t numofVals;
}socketmap;

/*
 * Hash, Hash2
 * @param int k = key
 * @return int - uses a hashing function to create a position.
 */
uint16_t shash(uint16_t k){
	return k%13;
}
uint16_t shash2(uint16_t k){
	return 1+k%11;
}

/*
 * Hash3
 * @param 	uint16_t k = key
 * 			uint16_t i = number of iterations.
 * @return 	uint16_t a function that return as position based on hash and hash2.
 */
uint16_t shash3(uint16_t k, uint16_t i){
 	return (shash(k)+ i*shash2(k))%MAX_CONNECTIONS;
 }

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 */
void shashmapInit(socketmap *input){
	uint16_t i;
	for(i=0; i<MAX_CONNECTIONS; i++){
		input->map[i].key=0; 		
	}
	input->numofVals=0;
}

bool shashmapIsEmpty(socketmap *input){
	if(input->numofVals==0)return TRUE;
	return FALSE;
}

/*
 * hashmapGet - return value with the inputed key.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
sockType shashmapGet(socketmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=shash3(key, i);
		if(input->map[j].key == key){	return input->map[j].value;}
		i++;
	}while(i<MAX_CONNECTIONS);	
	return input->map[input->keys[0]].value;
}

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
bool shashmapContains(socketmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	dbg("hashmap", "Checking to see if values exist");
	do{
		j=shash3(key, i);
		if(input->map[j].key == key){	return TRUE;}
		i++;
	}while(i<MAX_CONNECTIONS);	
	return FALSE;
}


/*
 * hashmapInsert - insert in a free position based on the value. If it exist already, overwrite the value.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 * 			hashType value = the value to be stored
 */
void shashmapInsert(socketmap *input, uint8_t key, sockType value){
	uint16_t i=0;	uint16_t j=0;
	dbg("hashmap", "Attempting to place Entry: %hhu\n", key);
	do{
		j=shash3(key, i);
		if(input->map[j].key==0 || input->map[j].key==key){
			if(input->map[j].key==0){
				input->keys[input->numofVals]=key;
				input->numofVals++;
			}
			input->map[j].value=value;
			input->map[j].key = key;
			dbg("hashmap","------------------Entry: %hhu was placed in %hhu\n", key, j);
			return;
		}
		i++;
	}while(i<MAX_CONNECTIONS);
	
}

/*
 * hashmapRemove - removes value stored in the array, also removes key from known values.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
void shashmapRemove(socketmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=shash3(key, i);
		if(input->map[j].key == key){	input->map[j].key=0; return;}
		i++;
	}while(i<MAX_CONNECTIONS);
	
	for(i=0; i<input->numofVals; i++){
		if(input->keys[i]==key){
			for(j=i; j<input->numofVals-1; j++){
				input->keys[j]=input->keys[j+1];
			}
			input->numofVals--;
			return;
		}
	}
}

#endif /* HASHMAP_H */
