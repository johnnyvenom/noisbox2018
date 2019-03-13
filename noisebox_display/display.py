#! /usr/bin/python3

from osc4py3.as_eventloop import *
from osc4py3 import oscmethod as osm
from luma.core.interface.serial import spi
from luma.core.render import canvas
from luma.oled.device import ssd1325
from PIL import ImageFont 

# font = ImageFont.truetype("pixelmix.ttf", 20)

font = [] # fonts at every size from 0 to 20
for x in range(21):
  font.append(ImageFont.truetype("/home/pi/Display/FreePixel.ttf", x))
  # print(font[x])

# initialize the oled display
serial = spi(device=0, port=0)
device = ssd1325(serial)

xmarg = 4   # left margin
xoff = 27+4 # x offset for four buttons/knobs
yoff = 10    # y offset between text lines (not knob)
toff = 18   # title offset

# Init values:
titleVal = "Noisebox v3"
knobVals = []
buttonVals = []
for x in range(4): 
    # each knob has 3 values: numeral, knob pos, label
    knobVals.append([0.555, 0.555, "knob"+str(x)])
    # each button has 2 values: value, label
    # button value can be any string or number
    buttonVals.append(["VAL", "btn"+str(x)])

def trunc_val(val): # round the number appropriately for display
    if round(val) >= 1000: 
        return str("%.0f" % val)
    elif round(val) >= 100 and round(val) < 1000:
        return str("%.1f" % val)
    elif round(val) >= 10 and round(val) < 100:
        return str("%.2f" % val)
    elif val >= 0 and round(val) < 10:
        return str("%.3f" % val)
    elif round(val) == 0 and val < 0:
        return str("%.2f" % val)
    elif round(val) > -10 and round(val) < 0:
        return str("%.2f" % val)
    elif round(val) > -100 and round(val) <= -10:
        return str("%.1f" % val)
    elif round(val) <= -100:
        return str("%.0f" % val)
    else: 
        pass

# this function redraws the entire display and is called any time a new OSC message is received. 
def draw_screen():
    
    # print(titleVal)
    # print(knobVals[0])
    # for x in range(4): 
    #     print("draw", knobVals[x][0])

    with canvas(device) as draw: 
        
        # ...draw title
        draw.text((4,0), titleVal, fill="white", font=font[15]) # title
        
        # ...draw knobs and buttons
        for x in range(4):
                       
            # KNOBS
            draw.text((xmarg+(xoff*x),toff+0), trunc_val(knobVals[x][0]), fill="white", font=font[9]) # outVal
            
            draw.line((xmarg+(xoff*x), toff+yoff+2, xmarg+(xoff*x)+27, toff+yoff+2), fill="white")
            draw.line((xmarg+(xoff*x), toff+yoff, xmarg+(xoff*x), toff+yoff+4), fill="white")
            draw.line((xmarg+(xoff*x)+27, toff+yoff, xmarg+(xoff*x)+27, toff+yoff+4), fill="white")
            draw.line((xmarg+(xoff*x)+(knobVals[x][1]*27), toff+yoff, xmarg+(xoff*x)+(knobVals[x][1]*27), toff+yoff+4), width=2, fill="white")


            # draw.rectangle((4+(xoff*x), toff+yoff, 4+(xoff*x)+27, toff+yoff+4), outline="white", fill="black")       
            # draw.rectangle((4+(xoff*x), toff+yoff, 4+(xoff*x)+(knobVals[x][1]*27), toff+yoff+4), fill="white")
            draw.text((xmarg+(xoff*x),toff+(yoff*1.6)), knobVals[x][2], fill="white", font=font[9]) # label
            
            # BUTTONS
            draw.rectangle((xmarg+(xoff*x),toff+(yoff*3), xoff*x+28, toff+(yoff*3.7)), fill="white")
            draw.text((6+(xoff*x),toff+(yoff*3.1)), str(buttonVals[x][0]), fill="black", font=font[8]) # state
            draw.text((xmarg+(xoff*x),toff+(yoff*3.8)), buttonVals[x][1], fill="white", font=font[9]) # label    

def update_title(address, val):
    global titleVal

    titleVal = val 
    # print("TITLE ", address, titleVal)

    draw_screen() # now draw all the values to display

def update_knob(address, val1, val2, val3):
    global knobVals
    addr = address.split('/') # breakout OSC routes

    for x in range(4):      # repeat for each knob
        if int(addr[3]) == x+1:
            knobVals[x][0] = val1    
            knobVals[x][1] = val2    
            knobVals[x][2] = val3

    # print("KNOB: ", address, knobVals)
    draw_screen() # now draw all the values to display

def update_button(address, val1, val2):
    global buttonVals
    addr = address.split('/') # breakout OSC routes

    for x in range(4):      # repeat for each button
        if int(addr[3]) == x+1:
            buttonVals[x][0] = val1
            buttonVals[x][1] = val2

    # print("BUTTON: ", address, buttonVals)
    draw_screen()   # now draw all the values to display

# Turn on display and show title
start_display = True
while start_display:
    with canvas(device) as draw: 
        # ...draw title
        draw.text((4,0), titleVal, fill="white", font=font[15]) # title
    
    start_display = False


# Start the system.
osc_startup()

# Make server channels to receive packets.
osc_udp_server("127.0.0.1", 3721, "aservername")

# call correct update function based on OSC address
osc_method("/display/title", update_title, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)
osc_method("/display/knob", update_knob, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)
osc_method("/display/button", update_button, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)

# osc_method("/display/text", display_title, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)

# Periodically call osc4py3 processing method in your event loop.
finished = False
while not finished:
    
    osc_process()
    

# Properly close the system.
osc_terminate()