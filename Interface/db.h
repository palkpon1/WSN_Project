#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

void PrintDatabase(int8_t* db, int size, int t);
int indexOf(char c, char* str);
int strSplit(char c, char* half1, char* half2, char* in);
int ParseString(int8_t* spotDatabase, int8_t* timeOutDB, char* input, int len, int threshold, int8_t timeOut);
