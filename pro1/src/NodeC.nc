/**
 * ANDES Lab - University of California, Merced
 * This class provides the basic functions of a network node.
 *
 * @author UCM ANDES Lab
 * @date   Apr 28 2012
 * 
 */ 

#include <Timer.h>
#include "packet.h"

configuration NodeC {
}
implementation {
	components MainC;
	components Node;
	components RandomC as Random;
	//components new 
	components new TimerMilliC() as pingTimeoutTimer;
	components new TimerMilliC() as neighborDiscovery;
	components new TimerMilliC() as neighborMap;
	components new TimerMilliC() as helloProtocol;
	components new TimerMilliC() as waitTimer;
	components new TimerMilliC() as sendDelay;
	components ActiveMessageC;
	components new AMSenderC(6);
	components new AMReceiverC(6);
	components TCPManagerC as tcpLayer;
	components TCPSocketC as tcpSocket;
	Node->MainC.Boot;

	//Timers
	Node.sendDelay->sendDelay;
	Node.pingTimeoutTimer->pingTimeoutTimer;
	Node.neighborDiscovey->neighborDiscovery;
	Node.neighborMap-> neighborMap;
	Node.helloProtocol -> helloProtocol;
	Node.waitTimer -> waitTimer;
	//Node.neighborDiscovey -> TimerMilliC;
	Node.Random->Random;
	
	Node.Packet->AMSenderC;
	Node.AMPacket->AMSenderC;
	Node.AMSend->AMSenderC;
	Node.AMControl->ActiveMessageC;
	Node.Receive->AMReceiverC;
	//TCP LAYER
	Node.tcpLayer->tcpLayer;
	Node.tcpSocket-> tcpSocket;
}