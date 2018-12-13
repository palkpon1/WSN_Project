#include "main.h"
#include "serialsource.h"
#include "db.h"
#include <signal.h>

static volatile int keepRunning = 1;

void sigHandler(int dummy){
    keepRunning = 0;
}

int different(int8_t* db1, int8_t* db2, int len){
    for(int i = 0; i < len; i++){
        if(db1[i] != db2[i]){
            return 1;
        }
    }
    return 0;
}

void cpy(int8_t* db1, int8_t* db2, int len){
    for(int i = 0; i < len; i++){
        db1[i] = db2[i];
    }
}

int main(int argc, char **argv){
    //Instantiation
    
    signal(SIGINT, sigHandler);

    char const *portname = "/dev/ttyUSB1";
    char baudrate[] = "57600";

    serial_source src;

    src = open_serial_source(portname, platform_baud_rate(baudrate), 0, 0);

    if (!src)
    {
      fprintf(stderr, "Couldn't open serial port at %s:%s\n",
          argv[1], argv[2]);
      exit(1);
    }

    char buffer[50];
    int8_t db[50];
    int8_t db_prev[50];
    for(int i = 0; i < 50; i++){
        db[i] = -1;
        db_prev[i] = -1;
    }
    while (keepRunning){
        int len, i;
        char *packet = (char *) read_serial_packet(src, &len);

        if (!packet)
            exit(0);
        
        sprintf(buffer, "%s", packet + 8);
        if(ParseString(db, buffer, 0x30) == 1){
            if(different(db, db_prev, 55)){
                system("clear");
                PrintDatabase(db, 50, 0);
            } 
            cpy(db_prev, db, 50);
        }

        free((void *)packet);
    }
}
