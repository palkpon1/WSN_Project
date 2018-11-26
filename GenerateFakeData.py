import random
import sys
import time

numSensors = int(sys.argv[1])
sensors = [i for i in range(0, numSensors)]

while(1):
    for i in sensors:
        if random.randint(0, 1):
            value = format(random.randint(0, 255), '03')
            outString = f'{i} {value}\n'
            sys.stdout.write(outString)
    time.sleep(5)
    
    
