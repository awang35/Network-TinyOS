#ifndef LSP_H
#define LSP_H
#define MAX_ROUTES 20 /* maximum size of routing table */
#define MAX_TTL 120 /* time (in seconds) until route expires */

typedef struct lspList{                           
	uint8_t Cost;                                       /* distance metric */
}lspList;
typedef struct nodeID{                           
	uint8_t nodeid;                                       /* distance metric */
}nodeID;
typedef struct lspAlgorithm{                           
	uint8_t Cost;
	uint8_t NodeID;                                       /* distance metric */
}lspAlgorithm;
typedef struct recieveLspList{
	uint8_t Cost;
	lspList container[MAX_ROUTES][MAX_ROUTES];
}rLspList;


#endif /* LSP_H */
