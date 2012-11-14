#ANDES Lab - University of California, Merced
#Author: UCM ANDES Lab --Edited by Adrian Wang
#Last Update: 08-31-2012
#! /usr/bin/python
from TOSSIM import *
from packet import *
import sys
import random

t = Tossim([])
r = t.radio()
print "Creating virtual motes and creating noise trace."
#noise = open("no_noise.txt", "r")
#Number of nodes that will be in the network
numNodes = 5
for i in range(1, numNodes+1):
    for j in range (100):
        t.getNode(i).addNoiseTraceReading(-98)
#for line in noise:
 # str1 = line.strip()
  #if str1:
  #  val = int(str1)
  #  for i in range(1, 3):
   #    t.getNode(i).addNoiseTraceReading(val)
      
print "Creating 'connections' between nodes"
f = open("topo.txt", "r")
for line in f:
  s = line.split()
  if s:
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))
    #r.connected(int(s[0]),int(s[1]))
print "--------------------------------------"

# Channels used for debuging
print "Setting Debug Channels"
#t.addChannel("genDebug", sys.stdout)
t.addChannel("cmdDebug", sys.stdout);
#t.addChannel("Project1F", sys.stdout);
#t.addChannel("Project1N", sys.stdout);
#t.addChannel("Project2", sys.stdout);
#t.addChannel("disAlg", sys.stdout);
t.addChannel("Project3", sys.stdout);
t.addChannel("transport", sys.stdout);
t.addChannel("clientAL", sys.stdout);
t.addChannel("serverAL", sys.stdout);

print "Setting noise model"
for i in range(1, numNodes+1):
    t.getNode(i).createNoiseModel()
print "Booting up the virtual motes."
for i in range(1, numNodes+1):
    t.getNode(i).bootAtTime(random.choice(range(1, 250, 1)))
    


def package(string):
    ints = []
    for c in string:
        ints.append(ord(c))
    return ints

def run(ticks):
    for i in range(ticks):
        t.runNextEvent()

def runTime(amount):
    time = t.time()
    while time + amount*10000000000 > t.time():
        t.runNextEvent() 

#Create a Command Packet
msg = pack()
msg.set_seq(0)
msg.set_TTL(15)
msg.set_protocol(99)

pkt = t.newPacket()
pkt.setData(msg.data)
pkt.setType(msg.get_amType())

def sendCMD(string):
    args = string.split(' ');
    msg.set_src(int(args[0]));
    msg.set_dest(int(args[1]));
    payload=args[2];
    for i in range(3, len(args)):
        payload= payload + ' '+ args[i]
    
    msg.setString_payload(payload)
    
    pkt.setData(msg.data)
    pkt.setDestination(int(args[1]))
    
    #print "Delivering!"
    pkt.deliver(int(args[1]), t.time()+5)
    runTime(2);
#Flood Control On(1) Off(0)
flooding = 1;
if(flooding == 1):
    runTime(200)
    #sendCMD("1 1 cmd ping 2 hi")
   
    sendCMD("1 1 cmd client 3 5 2")
    #runTime(200)
    #sendCMD("3 3 cmd client 3 5 2")
    sendCMD("2 2 cmd server 5")
    #sendCMD("5 1 Hi again!")
    #sendCMD("1 5 hi")
    runTime(200)
   # sendCMD("5 2 Flooding!")
    #sendCMD("1 65535 Flooding!")
else:
    runTime(2000)
    sendCMD("1 2 Hello World!")
    
