#include <Timer.h>
#include "PARKING.h"

configuration PARKINGAppC {
}

implementation {
    components MainC;
    components LedsC;
    components PARKINGC as App;
    components new TimerMilliC() as Timer0;
    components ActiveMessageC as Radio, SerialActiveMessageC as Serial;
    components LocalTimeMilliC as localTimer;

    App.Boot -> MainC.Boot;
    App.Leds -> LedsC.Leds;
    App.Timer0 -> Timer0;

    App.RadioPacket -> Radio;
    App.RadioAMPacket -> Radio;
    App.RadioSend -> Radio;
    //App.RadioReceive -> Radio.Receive;
    //App.RadioSnoop -> Radio.Snoop;
    App.RadioControl -> Radio;

    App.LocalTime -> localTimer;

    App.UartSend -> Serial;
    App.UartReceive -> Serial.Receive;
    App.UartPacket -> Serial;
    App.UartAMPacket -> Serial;
    App.SerialControl -> Serial;
}
