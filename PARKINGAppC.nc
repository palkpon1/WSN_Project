#include <Timer.h>
#include "PARKING.h"

configuration PARKINGAppC {
}

implementation {
    components MainC;
    components LedsC;
    components PARKINGC as App;
    components new TimerMilliC() as Timer0;
    //components ActiveMessageC as Radio, SerialActiveMessageC as Serial;
    components CollectionC as Collector;
    components new CollectionSenderC(0xee);
    components PrintfC;

    App.Boot -> MainC.Boot;
    App.Leds -> LedsC.Leds;
    App.Timer0 -> Timer0;

    /*App.RadioPacket -> Radio;
    App.RadioAMPacket -> Radio;
    App.RadioReceive -> Radio.Receive;
    App.RadioSnoop -> Radio.Snoop;
    App.RadioControl -> Radio;

    App.UartSend -> Serial;
    App.UartReceive -> Serial.Receive;
    App.UartPacket -> Serial;
    App.UartAMPacket -> Serial;
    App.SerialControl -> Serial;*/

    App.RootControl -> Collector;
    App.RoutingControl -> Collector;
    App.Receive -> Collector.Receive[0xee];
    App.Send -> CollectionSenderC;
}
