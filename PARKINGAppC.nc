#include <Timer.h>
#include "PARKING.h"

configuration PARKINGAppC {
}

implementation {
    components MainC;
    components LedsC;
    components PARKINGC as App;
    components new TimerMilliC() as Timer0;
    components ActiveMessageC;
    components new AMSenderC(AM_CHAN);
    components new AMReceiverC(AM_CHAN);
    components LocalTimeMilliC as localTimer;

    App.Boot -> MainC.Boot;
    App.Leds -> LedsC.Leds;
    App.Timer0 -> Timer0;
    App.RadioPacket -> AMSenderC.Packet;
    App.RadioAMPacket -> AMSenderC.AMPacket;
    App.RadioSend -> AMSenderC.AMSend;
    App.RadioReceive -> AMReceiverC;
    App.RadioControl -> ActiveMessageC;
    App.LocalTime -> localTimer;

}
