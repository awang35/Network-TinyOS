//Author: UCM ANDES Lab
//Date: 2/16/2012
//Description: A simple hashtable. Change the HASHMAP_TYPE to change the type being stored.
#ifndef LSPHASHMAP_H
#define LSPHASHMAP_H



enum{
	lHASH_MAX_SIZE = 20
};

typedef struct lspAlgorithm{                           
	uint8_t cost[20];
	uint8_t nodeid;
	uint8_t neighborid[20];                              /* distance metric */
}lspAlgorithm;

typedef lspAlgorithm hashType3;

typedef struct hashmapEntry3{
	uint16_t key;
	hashType3 value;
}lhEntry;

typedef struct hashmap3{
	lhEntry map[lHASH_MAX_SIZE];
	uint8_t keys[lHASH_MAX_SIZE];
	uint8_t numofVals;
}lhashmap;

uint16_t lhash(uint16_t k){
	return k%13;
}
uint16_t lhash2(uint16_t k){
	return 1+k%11;
}

/*
 * Hash3
 * @param 	uint16_t k = key
 * 			uint16_t i = number of iterations.
 * @return 	uint16_t a function that return as position based on hash and hash2.
 */
uint16_t lhash3(uint16_t k, uint16_t i){
 	return (lhash(k)+ i*lhash2(k))%lHASH_MAX_SIZE;
 }
/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 */
void lhashmapInit(lhashmap *input){
	uint16_t i;
		for(i=0; i<lHASH_MAX_SIZE; i++){
		input->map[i].key=0; 		
	}
	input->numofVals=0;
}

bool lhashmapIsEmpty(lhashmap *input){
	if(input->numofVals==0)return TRUE;
	return FALSE;
}

/*
 * hashmapGet - return value with the inputed key.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
hashType3 lhashmapGet(lhashmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=lhash3(key, i);
		if(input->map[j].key == key){	return input->map[j].value;}
		i++;
	}while(i<lHASH_MAX_SIZE);	
	return input->map[input->keys[0]].value;
}

/*
 * hashmapInit - initialize by setting all keys to 0 and the number of values to 0.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
bool lhashmapContains(lhashmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	dbg("lhashmap", "Checking to see if values exist");
	do{
		j=lhash3(key, i);
		if(input->map[j].key == key){	return TRUE;}
		i++;
	}while(i<lHASH_MAX_SIZE);	
	return FALSE;
}


/*
 * hashmapInsert - insert in a free position based on the value. If it exist already, overwrite the value.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 * 			hashType value = the value to be stored
 */
void lhashmapInsert(lhashmap *input, uint8_t key, hashType3 value){
	uint16_t i=0;	uint16_t j=0;
	dbg("hashmap", "Attempting to place Entry: %hhu\n", key);
	do{
		j=lhash3(key, i);
		if(input->map[j].key==0 || input->map[j].key==key){
			if(input->map[j].key==0){
				input->keys[input->numofVals]=key;
				input->numofVals++;
			}
			input->map[j].value=value;
			input->map[j].key = key;
			dbg("lhashmap","------------------Entry: %hhu was placed in %hhu\n", key, j);
			return;
		}
		i++;
	}while(i<lHASH_MAX_SIZE);
	
}

/*
 * hashmapRemove - removes value stored in the array, also removes key from known values.
 * @param	hashmap *input = the value to be initialized
 * 			uint8_t key = location key
 */
void lhashmapRemove(lhashmap *input, uint8_t key){
	uint16_t i=0;	uint16_t j=0;
	do{
		j=lhash3(key, i);
		if(input->map[j].key == key){	input->map[j].key=0; return;}
		i++;
	}while(i<lHASH_MAX_SIZE);
	
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
