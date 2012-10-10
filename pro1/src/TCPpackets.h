//Author: UCM ANDES Lab
//Date: 2/15/2012

#ifndef TCPPACKET_H
#define TCPPACKET_H

#ifndef TOSH_DATA_LENGTH
#define TOSH_DATA_LENGTH 20
#endif
# include "packet.h"
# include "protocol.h"

enum{
		TCP_HEADER_LENGTH = 8,
	TCP_MAX_PAYLOAD_SIZE = TOSH_DATA_LENGTH - TCP_HEADER_LENGTH,
	PORT_LIMIT = 225	
};
/**
 * TCP Data Structure
 *
 *        dstLink                the destination link address.
 *        dstPort                the destination port.
 *        srcLink                the source link address.
 *        srcPort                the source port.
 *        contents               the contents of the packet.
 *        syn                    the flag for SYN packet
 *        ack                    the flag for ACK packet
 *        stp                    the flag for STP packet
 *        fin                    the flag for FIN packet
 *        packetID               the id of the packet
 */
typedef nx_struct tpack{
	nx_uint8_t dstLink;
	nx_uint8_t dstPort;
	nx_uint8_t srcLink;
	nx_uint8_t srcPort;
	nx_uint8_t contents[TCP_MAX_PAYLOAD_SIZE];	
	bool syn;
	bool ack;
	bool stp;
	bool fin;
	nx_uint8_t packetID;
}tpack;
 
void setPack(nx_uint8_t _dstLink,nx_uint8_t _dstPort, nx_uint8_t _srcLink, nx_uint8_t _srcPort, nx_uint8_t _contents[], bool _syn, bool _ack, bool _stp, bool _fin,nx_uint8_t _packetID,uint8_t *newContents){
	tpack temp;
	temp.dstPort = _dstPort;
	temp.srcPort =  _srcPort;
	temp.syn = _syn;
	temp.ack = _ack;
	temp.fin = _fin;
	temp.stp = _stp;
	temp.packetID = _packetID;
	temp.contents = _contents;
	
	newContents[0] = _dstPort;
	newContents[1] = _dstLink;newContents[5] = 1;
	newContents[2] = _srcPort;
	newContents[3] = _srcLink;
	newContents[4] = _packetID;
	//newContents[5] = ;
	if((_syn == TRUE) && (_ack == FALSE) && (_stp == FALSE) && (_fin == FALSE))
		newContents[3] = 1;
	//ack
	if((_syn == FALSE) && (_ack == TRUE) && (_stp == FALSE) && (_fin == FALSE))
		newContents[3] = 2;
	//_stp
	if((_syn == FALSE) && (_ack == FALSE) && (_stp == TRUE) && (_fin == FALSE))
		newContents[3] = 4;
	//fin
	if((_syn == FALSE) && (_ack == FALSE) && (_stp == FALSE) && (_fin == TRUE))
		newContents[3] = 8;
	//finack
	if((_syn == FALSE) && (_ack == TRUE) && (_stp == FALSE) && (_fin == TRUE))
		newContents[3] = 10;
	//synack
	if((_syn == TRUE) && (_ack == TRUE) && (_stp == FALSE) && (_fin == FALSE))
		newContents[3] = 3;
 

}
/*
 * logPack
 * 	Sends packet information to the "genDebug" channel.
 * @param:
 * 		pack *input = pack to be printed.
 */
void logTCP(pack *input){
	dbg("genDebug", "Src: %hhu Dest: %hhu Seq: %hhu TTL: %hhu Protocol:%hhu  Payload: %s\n",
			input->src, input->dest, input->seq, input->TTL, input->protocol, input->payload);
}


#endif
