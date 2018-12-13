#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <time.h>



void PrintDatabase(int8_t* db, int size, int t){
    char timeStr[20];
    if(t){
        time_t timer;
        struct tm* tm_info;
        time(&timer);
        tm_info = localtime(&timer);
        strftime(timeStr, 20, "%H:%M:%S", tm_info);
    }
    for(int i = 0; i < size; i++){
        if(db[i] == 1){
            if(t){
                printf("%s\t", timeStr);
            }
            printf("%3d true\n", i);
        }else if(db[i] == 0){
            if(t){
                printf("%s\t", timeStr);
            }
            printf("%3d false\n", i);
        }
    }
}

int indexOf(char c, char* str){
    for(int i = 0; i < strlen(str); i++){
        if (str[i] == c){
            //printf("%d %c %c %s\n", i, c, str[i], str);
            return i;
        }
    }
    return -1;
}

int strSplit(char c, char* half1, char* half2, char* in){
    int idx = indexOf(c, in);
    if(idx != -1){
        //printf("idx: %d\n", idx);
        for(int i = 0; i < idx; i++){
            half1[i] = in[i];
        }   
        half1[idx] = '\0';
        for(int i = idx + 1; i < strlen(in); i++){
            half2[i - idx - 1] = in[i];
        }
        half2[strlen(in) - idx - 1] = '\0';
    }else{
        return -1;
    };
}

int ParseString(int8_t* db, char* input, int threshold){
    char half1[20];
    char half2[20];
    int spot = 0;
    int lightValue = 0;
    if(strSplit(':', half1, half2, input) != -1){
        half2[strlen(half2) - 2] = '\0';
        spot = atoi(half1);
        lightValue = atoi(half2);
        //printf("%d\t%03x\n", spot, lightValue);
        if(lightValue > threshold){
            db[spot] = 0;
        }else{
            db[spot] = 1;
        }
        return 1;
    }else{
        return -1;
    }
}
        

/*int ParseString(int8_t* spotDatabase, char* input, int threshold){
    char half1[200];
    char half2[200];
    char half1_1[20];
    char half1_2[20];
    int spot = 0;
    int lightValue = 0; 
    do{ 
        if(strSplit('\n', half1, half2, input) == -1){
            strcpy(half1, input);
            strcpy(half2, "");
        }
        printf("%s %s\n", half1, half2);
        if(strSplit(':', half1_1, half1_2, half1) == -1){
            return -1;
        }
        spot = atoi(half1_1);
        lightValue = atoi(half1_2); 
        if(lightValue > threshold){
            spotDatabase[spot] = 0;
        }else{
            spotDatabase[spot] = 1;
        }
        strcpy(input, half2);
    }while(half2 != "");
    return 1;
}*/
    
/*int main(int argc, char** argv){

    char test[40] = "10:233\n24:9\n22:140\n";
    char test2[40] = "9:233\n23:9\n21:140";
    char half1[200];
    char half2[200];
    strSplit('\n', half1, half2, test);
    printf("half1: %s\thalf2: %s\n", half1, half2);
    
    int8_t spotDatabase[200]; 
    for(int i = 0; i < 200; i++){
        spotDatabase[i] = -1;
    }
    ParseString(spotDatabase, test, 100);
    PrintDatabase(spotDatabase, 200);
    ParseString(spotDatabase, test2, 100);
    PrintDatabase(spotDatabase, 200);
}*/
