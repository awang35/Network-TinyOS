#ifndef ROUTINGTABLE_H
#define ROUTINGTABLE_H
#define MAX_ROUTES 20 /* maximum size of routing table */
#define MAX_TTL 120 /* time (in seconds) until route expires */

enum{
	NUMNODES = 5
};

typedef struct routingEntry2{
	//uint16_t nodeid;
	uint16_t Dest;   /* address of destination */
	uint16_t NextHop;                                               /* address of next hop */
	int Cost; 
	bool isValid;                                      /* distance metric */
	uint8_t TTL; /* time to live */
} Route;

typedef struct lspList{                           
	uint8_t Cost;                                       /* distance metric */
}lspList;

typedef struct lspAlgorithm{                           
	uint8_t cost[20];
	uint8_t nodeid;
	uint8_t neighborid[20];                              /* distance metric */
}lspAlgorithm;

typedef struct lspEntry{
	uint8_t node;                                     /* distance metric */
	uint8_t cost[20]; /* time to live */
} lspEntry;

void bubbleSort(int numbers[], int array_size){
	int i, j, temp;
	for (i = (array_size - 1); i > 0; i--){
    	for (j = 1; j <= i; j++){
      		if (numbers[j-1] > numbers[j]){
        		temp = numbers[j-1];
        		numbers[j-1] = numbers[j];
        		numbers[j] = temp;
      		}
    	}
  	}
}
	
void printLsp(lspList * list){
	 uint8_t p = 0;
	//	dbg("Project2", "------------------------------------\n");
	//	dbg("Project2","------------------------------------\n");
	//	dbg("Project2","Printing LSP Payload that is going to be sent\n");
		
		for( p = 0; p<NUMNODES;p++)
			dbg("Project2", "Node %d have cost %d.\n",p+1,list[p].Cost);
}



#endif /* ROUTINGTABLE_H */
