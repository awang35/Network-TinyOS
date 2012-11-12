#include "transport.h"
interface TCPSocket<val_t>{
	async command void init(val_t *input);

	async command uint8_t bind(val_t *input, uint8_t localPort, uint16_t address);
	
	//async command uint8_t listen(val_t *input, uint8_t backlog);
	async command uint8_t listen(uint8_t port, uint8_t backlog);
	async command uint8_t accept(uint8_t srcPort,uint8_t newPort);
	
	async command uint8_t connect(uint16_t destAddr, uint8_t destPort,uint8_t port);
	
	async command uint8_t close(uint8_t port);
	
	async command uint8_t release(uint8_t port);
	
	async command int16_t read(uint8_t port, uint8_t *readBuffer, uint16_t pos, uint16_t len);
	
	async command int16_t write(uint8_t port, uint8_t *writeBuffer, uint16_t pos, uint16_t len);
	
	//Checks
	async command bool isConnectPending(uint8_t port);
	async command bool isConnected(uint8_t port);
	async command bool isListening(uint8_t port);
	async command bool isClosed(uint8_t port);
	async command bool isClosing(uint8_t port);
	async command void addToQueue(pack *pckt);
	async command void copy(val_t *input, val_t *output);
}
