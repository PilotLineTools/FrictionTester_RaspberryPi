import serial
import time

ser = serial.Serial('/dev/ttyAMA3', 115200, timeout=1)

try: 
    while True:
        ser.write(b'Hello, Raspberry Pi!\n')
        time.sleep(1)
        print("Message sent to Raspberry Pi")

except KeyboardInterrupt:
    print("Program interrupted by user")

finally:
    ser.close()
    print("Serial connection closed")    