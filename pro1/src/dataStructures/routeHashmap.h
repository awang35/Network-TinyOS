//Author: UCM ANDES Lab
//Date: 2/16/2012
//Description: A simple hashtable. Change the HASHMAP_TYPE to change the type being stored.
#ifndef ROUTEHASHMAP_H
#define ROUTEHASHMAP_H


	

enum{
	rHASH_MAX_SIZE = 20,
	NUMNODES = 10
};
typedef struct routingEntry2{
	//uint16_t nodeid;
	uint16_t Dest;   /* address of destination */
	uint16_t NextHop;                                               /* address of next hop */
	int Cost; 
	bool isValid;                                      /* distance metric */
	uint8_t TTL; /* time to live */
} Route;
typedef Route hashType2;
typedef struct rhashmapEntry{
	uint16_t key;
	hashType2 value;
}rhashmapEntry;

typedef struct rhashmap{
	rhashmapEntry map[rHASH_MAX_SIZE];
	uint8_t keys[rHASH_MAX_SIZE];
	uint8_t numofVals;
}rhashmap;

/*
 * Hash, Hash2
 * @param int k = key
 * @return int - uses a hashing function to create a position.
 */
uint16_t rhash(uint16_t k){
	return k%13;
}
uint16_t rhash2(uint16_t k){
	return 1+k%11;
}

/*
 * Hash3
 * @param 	uint16_t k = key
 * 			uint16_t i = number of iterations.
 * @return 	uint16_t a function that return as position based on hash and hash2.
 */
uint16_t rhash3(uint16_t k, uint16_t i){
 	return (rhash(k)+ i*rhash2(k))%rHASH_MAX_SIZE;
 }

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 */
void rhashmapInit(rhashmap *input){
	uint16_t i;
	for(i=0; i<rHASH_MAX_SIZE; i++){
		input->map[i].key=0; 		
	}
	input->numofVals=0;
}

bool rhashmapIsEmpty(rhashmap *input){
	if(input->numofVals==0)return TRUE;
	return FALSE;
}

/*
 * hashmapGet - return value with the inputed key.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
hashType2 rhashmapGet(rhashmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=rhash3(key, i);
		if(input->map[j].key == key){	return input->map[j].value;}
		i++;
	}while(i<rHASH_MAX_SIZE);	
	return input->map[input->keys[0]].value;
}

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
bool rhashmapContains(rhashmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	dbg("hashmap", "Checking to see if values exist");
	do{
		j=rhash3(key, i);
		if(input->map[j].key == key){	return TRUE;}
		i++;
	}while(i<rHASH_MAX_SIZE);	
	return FALSE;
}


/*
 * hashmapInsert - insert in a free position based on the value. If it exist already, overwrite the value.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 * 			hashType value = the value to be stored
 */
void rhashmapInsert(rhashmap *input, uint8_t key, hashType2 value){
	uint16_t i=0;	uint16_t j=0;
	dbg("hashmap", "Attempting to place Entry: %hhu\n", key);
	do{
		j=rhash3(key, i);
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
	}while(i<rHASH_MAX_SIZE);
	
}

/*
 * hashmapRemove - removes value stored in the array, also removes key from known values.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
void rhashmapRemove(rhashmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=rhash3(key, i);
		if(input->map[j].key == key){	
		dbg("Project2", "Going to delete key: %d\n", key);
		input->map[j].key=0; return;}
		i++;
	}while(i<rHASH_MAX_SIZE);
	
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
