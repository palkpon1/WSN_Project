//java class to parse strings and update central database
//takes string in the format:
//<index>:<light value>\n
//<index>:<light value>\n
//<index>:<light value>\n
//...
//
//thought was to queue incoming serial communication and then periodically
//update the database using this class
//
//Also has relatively neat function to print current database
import java.util.Random;

public class SerialDatabase {

    public static String generateRandomData(int maxLength, int databaseSize){
        Random rand = new Random();
        int lines = rand.nextInt(maxLength) + 1;
        String str = "";
        for(int i = 0; i < lines; i++){
            int index = rand.nextInt(databaseSize);
            int value = rand.nextInt(100);
            str += Integer.toString(index) + ":" + Integer.toString(value) + "\n";
        }
        return str;
    }

    public static int[] updateDatabase(int[] database, String serialData, int t){
        String splitData[] = serialData.split("\n");
        for (int i = 0; i < splitData.length; i++){
            String dataStrings[] = splitData[i].split(":");
            int index = Integer.parseInt(dataStrings[0]);    
            int light = Integer.parseInt(dataStrings[1]);
            if(light > t){
                database[index] = 0;
            }else{
                database[index] = 1;
            }
        }
        return database;
    }

    public static int[] initDatabase(int size){
        int d[] = new int[size];
        for (int i = 0; i < size; i++){
            d[i] = -1;
        }
        return d;
    }

    public static int printDatabase(int[] database, int columns){
        int j = 0;
        String buffer = "";
        for(int i = 0; i < database.length; i++){
           while(j < columns && i < database.length){
                if(database[i] != -1){
                    buffer += "Node: " + Integer.toString(i) + " Value: " + Integer.toString(database[i]) + "\t";
                }
                j++;
                i++;
           }
           i--;
           j = 0;
           buffer += "\n";
        }
        System.out.print(buffer);
        return buffer.length();
    }
    
    public static void main(String args[]) throws InterruptedException{ 
        int db[] = initDatabase(20);
        int bufferLen = 0;
        for(int i = 0; i < 100; i++){
            //System.out.print(generateRandomData(10, 100));
            db = updateDatabase(db, generateRandomData(10, 20), 20);
            //for(int j = 0; j < 100; j++){
            //    System.out.print(Integer.toString(j) + ":" + Integer.toString(db[j]) + " ");
            //}
            //System.out.println();
        }
        printDatabase(db, 4);
    }
}
        
