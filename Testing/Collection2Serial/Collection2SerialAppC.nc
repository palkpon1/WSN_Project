configuration Collection2SerialAppC {}
implementation {
  components Collection2SerialC, MainC, LedsC, ActiveMessageC, PrintfC, SerialStartC;
  components CollectionC as Collector;
  components new CollectionSenderC(0xee);
  components new TimerMilliC();

  Collection2SerialC.Boot -> MainC;
  Collection2SerialC.RadioControl -> ActiveMessageC;
  Collection2SerialC.RoutingControl -> Collector;
  Collection2SerialC.Leds -> LedsC;
  Collection2SerialC.Timer -> TimerMilliC;
  Collection2SerialC.Send -> CollectionSenderC;
  Collection2SerialC.RootControl -> Collector;
  Collection2SerialC.Receive -> Collector.Receive[0xee];
}
