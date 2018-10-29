#ifndef PARKING_H
#define PARKING_H

enum {
    AM_CHAN = 6,
    TIMER_PERIOD_MILLI = 250,
    BASESTATION_ID = 0,
    GROUPID = 230,
    MAX_SIZE = 32
};

typedef nx_struct node_msg {
    nx_uint16_t command;
    nx_uint16_t nodeid;
    nx_uint16_t destid;
    nx_uint16_t groupid;
    nx_uint16_t size;
    nx_uint16_t node_id[MAX_SIZE];
    nx_uint16_t node_data[MAX_SIZE];
} node_msg;

#endif /* PARKING_H */
