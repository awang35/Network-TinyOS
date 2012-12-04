interface chatClient<val_t>{
	command void init(val_t *, void*);
	command void msgCommand(uint8_t*);
}