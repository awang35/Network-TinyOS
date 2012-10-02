#ifndef ROUTINGTABLE_H
#define ROUTINGTABLE_H
#define MAX_ROUTES 20 /* maximum size of routing table */
#define MAX_TTL 120 /* time (in seconds) until route expires */
typedef struct routingEntry{
	uint16_t Destination;   /* address of destination */
	uint16_t NextHop;                                               /* address of next hop */
	int Cost;                                       /* distance metric */
	uint8_t TTL; /* time to live */
} Route;

typedef struct routingTable{
	int numRoutes ;
	uint8_t keys[MAX_ROUTES];
	Route table[MAX_ROUTES];
	
}routingTable;

void tableInit(routingTable *input){
	uint16_t i;
	for(i=0; i<MAX_ROUTES; i++){
		input->table[i].Cost=0; 		
	}
	input->numRoutes=0;
}
#endif /* ROUTINGTABLE_H */
