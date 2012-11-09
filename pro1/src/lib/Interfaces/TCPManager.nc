interface TCPManager<val_t, val2_t>{
	command bool checkPort(uint8_t);
	command void init();
	command val_t *socket();
	command void freeSocket(val_t *);
	command void handlePacket(void *);
	command void forcePortState(uint8_t);
}
