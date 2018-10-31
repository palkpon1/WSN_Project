#include <Timer.h>
#include <printf.h>

module Collection2SerialC {
  uses interface Boot;
  uses interface SplitControl as RadioControl;
  uses interface StdControl as RoutingControl;
  uses interface Send;
  uses interface Leds;
  uses interface Timer<TMilli>;
  uses interface RootControl;
  uses interface Receive;
}
implementation {
  message_t packet;
  bool sendBusy = FALSE;

  typedef nx_struct TestMsg {
    nx_uint16_t data;
    nx_uint16_t id;
  } TestMsg;

  event void Boot.booted() {
    call RadioControl.start();
  }
  
  event void RadioControl.startDone(error_t err) {
    if (err != SUCCESS)
      call RadioControl.start();
    else {
      call RoutingControl.start();
      if (TOS_NODE_ID == 1) 
    call RootControl.setRoot();
      else
    call Timer.startPeriodic(2000);
    }
  }

  event void RadioControl.stopDone(error_t err) {}

  void sendMessage() {
    TestMsg* msg =
      (TestMsg*)call Send.getPayload(&packet, sizeof(TestMsg));
    msg->data = 0xBEEF;
    msg->id = TOS_NODE_ID;
    
    if (call Send.send(&packet, sizeof(TestMsg)) != SUCCESS) 
      call Leds.led0On();
    else 
      sendBusy = TRUE;
  }
  event void Timer.fired() {
    call Leds.led2Toggle();
    if (!sendBusy)
      sendMessage();
  }
  
  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) 
      call Leds.led0On();
    sendBusy = FALSE;
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    call Leds.led1Toggle();    
    printf("%x: %x!\n", ((TestMsg*)payload)->id, ((TestMsg*)payload)->data);
    printfflush();
    return msg;
  }
}

