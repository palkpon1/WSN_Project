#include <Timer.h>
#include "PARKING.h"
#include "AM.h"
#include "Serial.h"
#include "printf.h"
#include <stdio.h>

module PARKINGC {
    uses interface Boot;
    
    uses interface Leds;
    
    uses interface Timer<TMilli> as Timer0;
    
    uses interface SplitControl as RadioControl;
    //uses interface SplitControl as SerialControl;
    uses interface StdControl as RoutingControl;
    
    uses interface Packet;       //to create a packet
    //uses interface AMPacket as RadioAMPacket;   //To extract information out of packets
    uses interface Send;
    uses interface Receive;
    
    /*uses interface AMSend as UartSend[am_id_t id];
    uses interface Receive as UartReceive[am_id_t id];
    uses interface Packet as UartPacket;
    uses interface AMPacket as UartAMPacket;*/

    uses interface RootControl;
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
    
    /*message_t  uartQueueBufs[UART_QUEUE_LEN];
    message_t  * ONE_NOK uartQueue[UART_QUEUE_LEN];
    uint8_t    uartIn, uartOut;
    bool       uartBusy, uartFull;*/

    //****************************************************************************
    //Prototypes
    //****************************************************************************
    task void RadioSendTask();
    //task void uartSendTask();

    //****************************************************************************
    //internal functions
    //****************************************************************************

    void DropBlink(char * str) {
        call Leds.led2Toggle();
        dbg("LED", "DropBlink: %s \n", str);
    }

    void FailBlink() {
        call Leds.led2Toggle();
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

        /*for (i = 0; i < UART_QUEUE_LEN; i++)
            uartQueue[i] = &uartQueueBufs[i];
        uartIn = uartOut = 0;
        uartBusy = FALSE;
        uartFull = TRUE;*/
    
        for (i = 0; i < RADIO_QUEUE_LEN; i++)
            radioQueue[i] = &radioQueueBufs[i];

        radioIn = radioOut = 0;
        radioBusy = FALSE;
        radioFull = TRUE;

        if (call RadioControl.start() == EALREADY)
            radioFull = FALSE;
    	//if (call SerialControl.start() == EALREADY)
      	    //uartFull = FALSE;

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
            call RoutingControl.start();
            if (TOS_NODE_ID == 0)
            	call RootControl.setRoot();
	    else
	        call Timer0.startPeriodic(2000);    	
        }
        else
        {
            call RadioControl.start();
        }
    }
    //**********
    //Radio Stop Done
    //*********

    event void RadioControl.stopDone(error_t err) {}
    //event void SerialControl.stopDone(error_t error) {}
    
    /*event void SerialControl.startDone(error_t error) {
      if (error == SUCCESS) {
        uartFull = FALSE;
      }
    }*/

    //**********
    //Time Fired
    //*********

    event void Timer0.fired() {
    	call Leds.led1Toggle();
        post RadioSendTask();
    }

  /*message_t* receive(message_t *msg, void *payload, uint8_t len) {
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
	FailBlink();
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
	//FailBlink();
	post uartSendTask();
      }
  }

  event void UartSend.sendDone[am_id_t id](message_t* msg, error_t error) {
    if (error != SUCCESS)
      FailBlink();
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
    if(*((nx_uint16_t *) payload) == 3) call Leds.led0Toggle();

    atomic
      if (!radioFull)
	{
	  ret = radioQueue[radioIn];
	  radioQueue[radioIn] = msg;
	  if (++radioIn >= RADIO_QUEUE_LEN)
	    radioIn = 0;
	  if (radioIn == radioOut)
	    radioFull = TRUE;

	  if (!radioBusy)
	    {
	      //post radioSendTask();
	      radioBusy = TRUE;
	    }
	    
	}
      else
	FailBlink();
    
    return ret;
  }*/
    //**********
    //Radio Receive
    //*********
    event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len)
    {
        if (len == sizeof(node_msg))
        {
            node_msg* btrpkt = (node_msg*)payload;
            
            printf("Here is an id: %u and a random %u\n", btrpkt->node_id, btrpkt->random);
        }
        else
        {
            dbg("DROP", "wrong lenght! %d instead of %d\n", len, sizeof(node_msg));
        }
        return msg;
    }
    //**********
    //Send Done
    //*********

    event void Send.sendDone(message_t* msg, error_t error) {
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
    }

    //*********************************************************************
    //Tasks
    //********************************************************************
    task void RadioSendTask() {
        uint8_t len;
        message_t* msg;
        node_msg *btrpkt;

        atomic
        if (radioIn == radioOut && !radioFull)
        {
            radioBusy = FALSE;
            return;
        }

        msg = radioQueue[radioOut];

        btrpkt = (node_msg*) (call RadioPacket.getPayload(msg, sizeof (node_msg)));
        dbg ("DBG", "nodeid:%d, parent:%d, counter:%d\n",btrpkt->nodeid, btrpkt->destid, btrpkt->counter);
        
        btrpkt->node_id = TOS_NODE_ID;
        btrpkt->random = 105;
        
        len = call RadioPacket.payloadLength(msg);

        if (call Send.send(msg, len) == SUCCESS)
        {
            FailBlink();
        }
        else
        {
            FailBlink();
            post RadioSendTask();
        }
    }
}
