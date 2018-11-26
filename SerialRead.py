import sys
import os
import time

def printDatabase(database):
    os.system('clear')
    for i in range(0, len(database)):
        if database[i] != -1:
            print(f'{i}\t\t{database[i]}')

threshhold = int(sys.argv[1])
database = [-1 for i in range(100)]
print(threshhold)

while(1):
    line = sys.stdin.read(5)
    line = line.strip()
    linesplit = line.split()
    index = int(linesplit[0])
    data = (int(linesplit[1]) > threshhold)
    database[index] = data
    printDatabase(database)




