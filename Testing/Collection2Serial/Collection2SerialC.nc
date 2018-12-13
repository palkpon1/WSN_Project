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
  uses interface Read<uint16_t>;
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
    call Timer.startPeriodic(2000);
    }
  }

  event void RadioControl.stopDone(error_t err) {}

  void sendMessage(uint16_t data) {
    TestMsg* msg =
      (TestMsg*)call Send.getPayload(&packet, sizeof(TestMsg));
    msg->data = data;
    msg->id = TOS_NODE_ID;
    
    if (call Send.send(&packet, sizeof(TestMsg)) != SUCCESS) 
      call Leds.led0On();
    else 
      sendBusy = TRUE;
  }
  event void Timer.fired() {
    call Leds.led2Toggle();
    if (!sendBusy)
      call Read.read();
  }
  
  event void Send.sendDone(message_t* m, error_t err) {
    if (err != SUCCESS) 
      call Leds.led0On();
    sendBusy = FALSE;
  }
  
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len) {
    call Leds.led1Toggle();    
    printf("%02i:%03d\n", ((TestMsg*)payload)->id, ((TestMsg*)payload)->data);
    printfflush();
    return msg;
  }

  event void Read.readDone(error_t result, uint16_t data) 
  {
    if (result == SUCCESS){
      sendMessage(data);
    }
  }
}

