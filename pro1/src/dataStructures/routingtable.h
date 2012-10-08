#ifndef ROUTINGTABLE_H
#define ROUTINGTABLE_H
#define MAX_ROUTES 20 /* maximum size of routing table */
#define MAX_TTL 120 /* time (in seconds) until route expires */
typedef struct routingEntry{
	bool isValid;
	uint16_t Dest;   /* address of destination */
	uint16_t NextHop;                                               /* address of next hop */
	int Cost;                                       /* distance metric */
} Route2;
typedef struct lspEntry{
	uint8_t node;                                     /* distance metric */
	uint8_t cost[20]; /* time to live */
} lspEntry;
typedef struct routingTable{
	int numRoutes ;
	uint8_t keys[MAX_ROUTES];
	Route2 table[MAX_ROUTES];
	
}routingTable2;

#endif /* ROUTINGTABLE_H */
