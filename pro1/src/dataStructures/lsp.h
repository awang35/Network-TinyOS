#ifndef LSP_H
#define LSP_H
#define MAX_ROUTES 20 /* maximum size of routing table */
#define MAX_TTL 120 /* time (in seconds) until route expires */

typedef struct lspList{                           
	uint8_t Cost;                                       /* distance metric */
}lspList;

typedef struct lspRecord{
	lspList container[MAX_ROUTES][MAX_ROUTES];
}lspRecord;

#endif /* LSP_H */
