#include <SD.h>

#define D0  22
#define D7  29
#define A0  30
#define A16 46
#define WE  48
#define OE  49
#define CS  53

File romFile;
byte pageBuffer[128];
String fileName;
int lastPage = 0;

String getName(){
  String name = "";
      while (!Serial.available()){
        name = "";
      }
      name = Serial.readString();
  return name;
}

void fillPageBuffer(unsigned long page){
  romFile.seek(page*128);
  int row = 0;
  while (romFile.available() && row < 128){
    pageBuffer[row]=romFile.read();
    row++;
  }
  lastPage = page;
}

void printBuffer(){
  for (int base = 0; base < 128; base += 16) {
    byte data[16];
    for (int offset = 0; offset <= 15; offset += 1) {
      data[offset] = pageBuffer[offset+base];
    }

    char buf[80];
    sprintf(buf, "%05x:  %02x %02x %02x %02x %02x %02x %02x %02x   %02x %02x %02x %02x %02x %02x %02x %02x",
            base+lastPage*128, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7],
            data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]);

    Serial.println(buf);
  }
}

void setAddress(unsigned long address) {
  for (int pin = A0; pin <= A16; pin ++) {
    digitalWrite(pin, address & 1);
    address = address >> 1;
  }
}

void setPage(unsigned long page) {
  for (int pin = A16-9; pin <= A16; pin ++) {
    digitalWrite(pin, page & 1);
    page = page >> 1;
  }
}

void setByte(unsigned long _byte) {
  for (int pin = A0; pin <= A16-10; pin ++) {
    digitalWrite(pin, _byte & 1);
    _byte = _byte >> 1;
  }
}


void writeByte(unsigned long row, byte data) {

  digitalWrite(WE, HIGH);
  digitalWrite(OE, HIGH);  // Set data pins to output
  setByte(row);
  for (int pin = D0; pin <= D7; pin++) {
    pinMode(pin, OUTPUT);
  }
  
  for (int pin = D0; pin <= D7; pin++) {  //Write data into pins
    digitalWrite(pin, data & 1);
    data = data >> 1;
  }

  digitalWrite(WE, LOW);  // Write data into EEPROM
  delayMicroseconds(1);
  digitalWrite(WE, HIGH);
  delayMicroseconds(1);

 }

 void writePage(unsigned long page) {
  Serial.print("Writing page ");
  Serial.print(page);
  Serial.println(" of 1024 ");
  setPage(page);
  //SDP
  writeByte(0x05555, 0xAA);
  writeByte(0x02AAA, 0x55);
  writeByte(0x05555, 0xA0);

  for (unsigned long row = 0; row < 128; row++){
      //writeByte(address, pageBuffer[row];
      writeByte(row, pageBuffer[row]);

      if (row==127) {
        delayMicroseconds(250);
        //Data polling D7
        byte pollBit = (pageBuffer[row] >> 7) & 0x01; //Data polling bit
        
        for (int pin = D0; pin <= D7; pin++) {
            pinMode(pin, INPUT);
        }
        digitalWrite(OE, LOW);
        delayMicroseconds(50);

       int validCycles = 0;
       int attempts = 0;
       while (validCycles < 2) {
          byte d = (digitalRead(D7)==HIGH ? 0x01 : 0x00);
          if( (pollBit & 0x01) != d ) {
             delayMicroseconds(1);
            validCycles = 0;
           }
          else validCycles++;
           attempts++;
           if( attempts >= 100000){
                //Serial.println("Data polling failed");
                //break;
          }
         }        
      }

  }
  delayMicroseconds(1);
}

byte readByte(unsigned long address) {
  setAddress(address);
  for (int pin = D0; pin <= D7; pin++) {
    pinMode(pin, INPUT);
  }
  digitalWrite(OE, LOW);
  delayMicroseconds(1);

  byte data = 0;
  for (int pin = D7; pin >= D0; pin--) {
    data = (data << 1) + digitalRead(pin);
  }
  digitalWrite(OE, HIGH);
  delayMicroseconds(1);
  return data;
}

void printPage(unsigned long page){
  Serial.print("Printing page ");
  Serial.println(page);
  for (unsigned long base = page*128; base < (page*128)+128; base += 16) {
    byte data[16];
    for (int offset = 0; offset <= 15; offset += 1) {
      data[offset] = readByte(offset+base);
    }

    char buf[80];
    sprintf(buf, "%05lx:  %02x %02x %02x %02x %02x %02x %02x %02x   %02x %02x %02x %02x %02x %02x %02x %02x",
            base, data[0], data[1], data[2], data[3], data[4], data[5], data[6], data[7],
            data[8], data[9], data[10], data[11], data[12], data[13], data[14], data[15]);


    Serial.println(buf);
  }
}



void setup() {
  digitalWrite(WE, HIGH);
  pinMode(WE, OUTPUT);
  digitalWrite(OE, HIGH);
  pinMode(OE, OUTPUT);
  for (int pin=A0; pin<=A16; pin++) {
    pinMode(pin, OUTPUT);
  }
   for (int pin=D0; pin<=D7; pin++) {
    pinMode(pin, OUTPUT);
    digitalWrite(pin, LOW);
  }
  Serial.begin(115200);
  Serial.println("Initializing SD ...");
  if (!SD.begin(CS)) {
    Serial.println("Error. SD could not initialize");
    return;
  }
  Serial.println("Success");

}

void loop() {
  setAddress(0x0000);

  Serial.println("Enter filename to write to the EEPROM");
  fileName = getName();
  Serial.print("File: ");
  Serial.println(fileName);
  
  romFile = SD.open(fileName);
  
  if (romFile) {
    Serial.print("File size is ");
    Serial.print(romFile.size());
    Serial.println(" bytes.");
    
    for(int page=0; page < 1024; page++){
      fillPageBuffer(page);
      writePage(page);
    }
   
    delay(1);
    for(int page=0; page < 20; page++){
      printPage(page);
    }
    
  } else{
    Serial.println("Error opening file. Try again");
  }
  

  
}
