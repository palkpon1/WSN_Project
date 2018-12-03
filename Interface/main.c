#include "main.h"

#include "serialsource.h"

int main(int argc, char **argv){
    //Instantiation
    char const *portname = "/dev/ttyUSB2";
    char baudrate[] = "57600";

    serial_source src;

    src = open_serial_source(portname, platform_baud_rate(baudrate), 0, 0);

    if (!src)
    {
      fprintf(stderr, "Couldn't open serial port at %s:%s\n",
	      argv[1], argv[2]);
      exit(1);
    }

    for (;;){
        int len, i;
        char *packet = (char *) read_serial_packet(src, &len);

        if (!packet)
	  exit(0);
        
	printf("%s", packet + 8);

        free((void *)packet);
    }
}