#Python program to read out and plot the data from the fpga
import serial.tools.list_ports
import numpy as np
import time
import matplotlib.pyplot as plt

#Values to change
NEWLINE_VALUE = 0 #Signal for new value through FPGA
FRAME_DELAY_CNT = 10 #Number of frames to drop
PLT_MIN = 100
PLT_MAX = 200
s = '/dev/cu.usbserial-210292AE3BD11' #Serial port

#Setup
plt.rcParams["figure.figsize"] = (6, 6)
array=np.zeros([16, 16])
sw_wire = 0
rd_wire = 0
frame_delay = 0
st_time = time.time()

#Program start
print("USB Port: "+str(s)) #print it if you got
if s:
    ser = serial.Serial(port = s,
        baudrate=115200,
        parity=serial.PARITY_NONE,
        stopbits=serial.STOPBITS_ONE,
        bytesize=serial.EIGHTBITS,
        timeout=0.01) #auto-connects already I guess?
    print("Serial Connected!")
    if ser.isOpen():
         print(ser.name + ' is open...')
else:
    print("No Serial Device :/ Check USB cable connections/device!")
    exit()

try:
	print("Reading...")
	while True:
		data = ser.read(1) #read the buffer (99/100 timeout will hit)
		if data != b'':  #if not nothing there.
			x = data[0]
			#print("data {}", x)

			if x == NEWLINE_VALUE:
				sw_wire = 0
				rd_wire = 0
				frame_delay += 1
				if frame_delay == FRAME_DELAY_CNT:
					frame_delay = 0
					plt.imshow(array)
					plt.colorbar()
					plt.clim(PLT_MIN, PLT_MAX)
					plt.draw()
					plt.pause(1e-10)
					plt.gcf().clear()
					#print("Time elapsed:", time.time() - st_time)
					st_time = time.time()

			else:
				array[sw_wire, rd_wire] = x

				rd_wire += 1
				if rd_wire%16==0:
					rd_wire = 0
					sw_wire += 1
					if sw_wire%16==0:
						sw_wire = 15

except Exception as e:
    print(e)


