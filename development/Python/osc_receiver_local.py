# Import needed modules from osc4py3
from osc4py3.as_eventloop import *
from osc4py3 import oscmethod as osm

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
osc_method("/display/*", handlerfunction2, argscheme=osm.OSCARG_ADDRESS + osm.OSCARG_DATAUNPACK)

# Periodically call osc4py3 processing method in your event loop.
finished = False
while not finished:
    # …
    osc_process()
    # …

# Properly close the system.
osc_terminate()
