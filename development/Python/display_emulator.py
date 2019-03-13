from luma.core.render import canvas
# from luma.oled.device import ssd1325
from PIL import ImageFont 
from demo_opts import get_device

font = ImageFont.truetype("pixelmix.ttf", 20)




# initialize the oled display
# serial = spi(device=0, port=0)
# device = ssd1325(serial)

def display_title(address, page):
    with canvas(device) as draw:
        draw.text((0,0), page, fill="white", font=font)
    print(address)
    print(page)

def display_all(address, val):
    # print(address)
    parsed = address.split('/')
    print(parsed)
    
    if parsed[2] == 'text':
        with canvas(device) as draw:
            draw.text((0,0), val, fill="white", font=font)
    elif parsed[2] == 'knob':
        print("knob")
        with canvas(device) as draw:
            draw.text((10,15), val, fill="white")
    elif parsed[2] == 'button':
        print("button")
        with canvas(device) as draw:
            draw.text((10,30), val, fill="white")
    else:
        pass

    if parsed[2] != "text":
        print(parsed[1], parsed[2] + parsed[3], parsed[4], val)

def handlerfunction(s):
    # Will receive message data unpacked in s, x, y
    print(s)
    # print(x)
    # print(y)
    pass

def handlerfunction2(address, s):
    # Will receive message address, and message data flattened in s, x, y
    print(address)
    print(s)
    pass

# Start the system.
osc_startup()

# Make server channels to receive packets.
osc_udp_server("127.0.0.1", 3721, "aservername")
# osc_udp_server("0.0.0.0", 3724, "anotherserver")

# Associate Python functions with message address patterns, using default
# argument scheme OSCARG_DATAUNPACK.
# osc_method("/display/*", handlerfunction)
# Too, but request the message address pattern before in argscheme

osc_method("/display/*", display_all, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)

# osc_method("/display/text", display_title, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)

# Periodically call osc4py3 processing method in your event loop.
def main():
    while True:
        # …
        osc_process()
        # …

    # Properly close the system.
    osc_terminate()

if __name__ == "__main__":
    try:
        device = get_device()
        main()
    except KeyboardInterrupt:
        pass