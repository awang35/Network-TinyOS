interface server<val_t>{
	command void init(val_t *);
	command void Buffer(uint8_t port, uint8_t data);
}