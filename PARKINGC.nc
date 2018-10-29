#include <Timer.h>
#include "PARKING.h"
#include "AM.h"
#include "Serial.h"
#include <stdio.h>

module PARKINGC {
    uses interface Boot;
    
    uses interface Leds;
    
    uses interface Timer<TMilli> as Timer0;
    uses interface LocalTime<TMilli>;
    
    uses interface SplitControl as RadioControl;
    uses interface Packet as RadioPacket;       //to create a packet
    uses interface AMPacket as RadioAMPacket;   //To extract information out of packets
    uses interface AMSend as RadioSend;
    uses interface Receive as RadioReceive;
    
    uses interface AMSend as UartSend[am_id_t id];
    uses interface Receive as UartReceive[am_id_t id];
    uses interface Packet as UartPacket;
    uses interface AMPacket as UartAMPacket;
}

implementation {
    uint16_t counter = 0;
    bool busy = FALSE;
    message_t pkt;

    uint64_t num_messages = 0;
    uint64_t total_delay = 0;
    uint64_t delay;
    uint8_t my_parent = 255;

    /*to handle message buffer */
    enum {
        RADIO_QUEUE_LEN = 12,
        UART_QUEUE_LEN = 12,
    };

    message_t  radioQueueBufs[RADIO_QUEUE_LEN];
    message_t  * ONE_NOK radioQueue[RADIO_QUEUE_LEN];
    uint8_t    radioIn, radioOut;
    bool       radioBusy, radioFull;
    
    message_t  uartQueueBufs[UART_QUEUE_LEN];
    message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN];
    uint8_t    uartIn, uartOut;
    bool       uartBusy, uartFull;

    //****************************************************************************
    //Prototypes
    //****************************************************************************
    task void RadioSendTask();
    task void uartSendTask();

    //****************************************************************************
    //internal functions
    //****************************************************************************

    void DropBlink(char * str) {
        call Leds.led2Toggle();
        dbg("LED", "DropBlink: %s \n", str);
    }

    void FailBlink() {
        call Leds.led1Toggle();
        dbg("LED", "FailBlink\n");
    }
    void SendBlink(am_addr_t dest) {
        call Leds.led0Toggle();
        dbg("LED", "SendBlink to: %u\n",dest);
    }

    message_t* QueueIt(message_t *msg, void *payload, uint8_t len)
    {
        message_t *ret = msg;

        atomic
        {
            if (!radioFull)
            {
                ret = radioQueue[radioIn];
                radioQueue[radioIn] = msg;

                radioIn = (radioIn + 1) % RADIO_QUEUE_LEN;

                if (radioIn == radioOut)
                    radioFull = TRUE;

                if (!radioBusy)
                {
                    post RadioSendTask();
                    radioBusy = TRUE;
                }
            }
            else
                DropBlink("From Queue Function");
        }
        return ret;
    }

    //************************************************************************************
    //Events
    //************************************************************************************

    //**********
    //Booted
    //*********

    event void Boot.booted() {

        uint8_t i;  //index to initialize queues

        dbg ("BOOT", "Application booted (%d).\n", TOS_NODE_ID);

        for (i = 0; i < RADIO_QUEUE_LEN; i++)
            radioQueue[i] = &radioQueueBufs[i];

        radioIn = radioOut = 0;
        radioBusy = FALSE;
        radioFull = TRUE;

        //call RadioControl.start();
    	if (call SerialControl.start() == EALREADY)
      	    uartFull = FALSE;

    }
    //**********
    //Radio Start Done
    //*********

    event void RadioControl.startDone(error_t err)
    {
        if (err == SUCCESS)
        {
            dbg ("DBG", "Radio Started.\n");
            radioFull = FALSE;
        }
        else
        {
            call RadioControl.start();
        }
    }
    //**********
    //Radio Stop Done
    //*********

    event void RadioControl.stopDone(error_t err)
    {}
    
    event void SerialControl.startDone(error_t error) {
      if (error == SUCCESS) {
        uartFull = FALSE;
      }
    }

    //**********
    //Time Fired
    //*********

    event void Timer0.fired() {
        message_t* msg;
        hw3_msg * btrpkt;
        counter ++;
        //call Leds.set(counter);

        if (TOS_NODE_ID != BASESTATION_ID)
        {
            atomic
            if (!radioFull)
            {
                msg = radioQueue[radioIn];
                btrpkt = (hw3_msg*) (call RadioPacket.getPayload(msg, sizeof (hw3_msg)));
                if (btrpkt == NULL)
                {
                    dbg ("ERR", "payload is smaller than length!\n");
                    exit(-1);
                }
                btrpkt->nodeid = TOS_NODE_ID;
                btrpkt->counter = counter;
                btrpkt->destid = my_parent;
                btrpkt->time = call LocalTime.get();
                //Set packet header data. These info will be adjusted in each hop
                call RadioPacket.setPayloadLength(msg, sizeof (hw3_msg));
                call RadioAMPacket.setDestination(msg, my_parent);
                call RadioAMPacket.setSource(msg, TOS_NODE_ID);
                dbg("PKG", "Generated Packet. source: %d, destination: %d, timestamp: %d\n", btrpkt->nodeid, btrpkt->destid, btrpkt->time);

                ++radioIn;
                if(radioIn >=RADIO_QUEUE_LEN)
                    radioIn=0;
                if(radioIn == radioOut)
                    radioFull = TRUE;
                if (!radioBusy)
                {
                    post RadioSendTask();
                    radioBusy = TRUE;
                }
            }
            else
            {
                DropBlink("Timer Fired Function");
            }
        }
        else
        {
            if (num_messages > 0)
            {
                dbg_clear("BASE","\n");
                dbg("BASE", "=========Base Station Statistics============\n");
                dbg("BASE", "Total Received Packages:%d\n", num_messages);
                dbg("BASE", "Avgerage Delivery Delay:%.2f\n", (float)total_delay/(float)num_messages);
                dbg("BASE", "============================================\n\n");
            }
        }
    }

  message_t* receive(message_t *msg, void *payload, uint8_t len) {
    message_t *ret = msg;

    atomic {
      if (!uartFull)
	{
	  ret = uartQueue[uartIn];
	  uartQueue[uartIn] = msg;

	  uartIn = (uartIn + 1) % UART_QUEUE_LEN;
	
	  if (uartIn == uartOut)
	    uartFull = TRUE;

	  if (!uartBusy)
	    {
	      post uartSendTask();
	      uartBusy = TRUE;
	    }
	}
      else
	dropBlink();
    }
    
    return ret;
  }

  uint8_t tmpLen;
  
  task void uartSendTask() {
    uint8_t len;
    am_id_t id;
    am_addr_t addr, src;
    message_t* msg;
    am_group_t grp;
    atomic
      if (uartIn == uartOut && !uartFull)
	{
	  uartBusy = FALSE;
	  return;
	}

    msg = uartQueue[uartOut];
    tmpLen = len = call RadioPacket.payloadLength(msg);
    id = call RadioAMPacket.type(msg);
    addr = call RadioAMPacket.destination(msg);
    src = call RadioAMPacket.source(msg);
    grp = call RadioAMPacket.group(msg);
    call UartPacket.clear(msg);
    call UartAMPacket.setSource(msg, src);
    call UartAMPacket.setGroup(msg, grp);

    if (call UartSend.send[id](addr, uartQueue[uartOut], len) == SUCCESS)
      call Leds.led1Toggle();
    else
      {
	failBlink();
	post uartSendTask();
      }
  }

  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      failBlink();
    else
      atomic
	if (msg == uartQueue[uartOut])
	  {
	    if (++uartOut >= UART_QUEUE_LEN)
	      uartOut = 0;
	    if (uartFull)
	      uartFull = FALSE;
	  }
    post uartSendTask();
  }

  event message_t *UartReceive.receive[am_id_t id](message_t *msg,
						   void *payload,
						   uint8_t len) {
    message_t *ret = msg;
    bool reflectToken = FALSE;

    atomic
      if (!radioFull)
	{
	  reflectToken = TRUE;
	  ret = radioQueue[radioIn];
	  radioQueue[radioIn] = msg;
	  if (++radioIn >= RADIO_QUEUE_LEN)
	    radioIn = 0;
	  if (radioIn == radioOut)
	    radioFull = TRUE;

	  if (!radioBusy)
	    {
	      post radioSendTask();
	      radioBusy = TRUE;
	    }
	}
      else
	dropBlink();

    if (reflectToken) {
      //call UartTokenReceive.ReflectToken(Token);
    }
    
    return ret;
  }
    //**********
    //Radio Receive
    //*********
    event message_t* RadioReceive.receive(message_t* msg, void* payload, uint8_t len)
    {
        uint32_t localTime;
        if (len == sizeof(hw3_msg))
        {
            hw3_msg* btrpkt = (hw3_msg*)payload;
            am_addr_t dest = call RadioAMPacket.destination(msg);

            dbg("DBG", "Received a packet. Origin:%d, counter:%d, next hop:%d, timestamp:%d:\n", btrpkt->nodeid, btrpkt->counter, btrpkt->destid, btrpkt->time);

            if (TOS_NODE_ID ==  dest)
            {
                if (TOS_NODE_ID == BASESTATION_ID)
                {
                    num_messages++;
                    localTime = call LocalTime.get();
                    delay = localTime - btrpkt->time;
                    total_delay += delay;

                    dbg("DBG", "Received a packet. LocalTime: %d, Timestamp of packet: %d, delay:%d\n", localTime, btrpkt->time, delay);
                    dbg("DBG", "BS received a packet, statistics==> num_messages: %d, total_delay:%d, total_delay: %d\n",num_messages, total_delay, total_delay);
                }
                else
                {
                    if (qos_attack == 1 && active)
                    {
                        //Insert it into buffer to be relayed forward
                        dbg("FWD", "QUEUE it to be relayed to %d\n",my_parent);
                        //Adjust source and destination of the packet for next hop
                        call RadioAMPacket.setDestination(msg, my_parent);
                        call RadioAMPacket.setSource(msg, TOS_NODE_ID);
                        //Whenever it is active disable it
                        active = FALSE;
                    }
                    else
                    {
                        //Insert it into buffer to be relayed forward
                        dbg("FWD", "QUEUE it to be relayed to %d\n",my_parent);
                        //Adjust source and destination of the packet for next hop
                        call RadioAMPacket.setDestination(msg, my_parent);
                        call RadioAMPacket.setSource(msg, TOS_NODE_ID);
                        msg = QueueIt(msg, payload, len);
                        active = TRUE;
                    }
                }
            }
            else   //not destined for me, drop it!
            {
                dbg("DROP", "Droped the packet__%d, %d, %d\n", btrpkt->nodeid, btrpkt->destid, btrpkt->time);
            }
        }
        else
        {
            dbg("DROP", "wrong lenght! %d instead of %d\n", len, sizeof(hw3_msg));
        }
        return msg;
    }
    //**********
    //Send Done
    //*********

    event void RadioSend.sendDone(message_t* msg, error_t error) {
        if (error != SUCCESS)
            FailBlink();
        else
            atomic
            if (msg == radioQueue[radioOut])
            {
                if (++radioOut >= RADIO_QUEUE_LEN)
                    radioOut = 0;
                if (radioFull)
                    radioFull = FALSE;
            }
            post RadioSendTask();
    }

    //*********************************************************************
    //Tasks
    //********************************************************************
    task void RadioSendTask() {
        uint8_t len;
        am_addr_t addr;
        message_t* msg;
        hw3_msg *btrpkt;

        atomic
        if (radioIn == radioOut && !radioFull)
        {
            radioBusy = FALSE;
            return;
        }

        msg = radioQueue[radioOut];

        btrpkt = (hw3_msg*) (call RadioPacket.getPayload(radioQueue[radioOut], sizeof (hw3_msg)));
        dbg ("DBG", "nodeid:%d, parent:%d, counter:%d\n",btrpkt->nodeid, btrpkt->destid, btrpkt->counter);
        len = call RadioPacket.payloadLength(msg);
        addr = call RadioAMPacket.destination(msg);

        dbg("DBG", "len:%d, addr:%d\n",len,addr);

        if (call RadioSend.send(addr, msg, len) == SUCCESS)
        {
            SendBlink(addr);
        }
        else
        {
            FailBlink();
            post RadioSendTask();
        }
    }
}