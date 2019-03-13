from luma.core.interface.serial import spi
from luma.core.render import canvas
from luma.oled.device import ssd1325

serial = spi(device=0, port=0)
device = ssd1325(serial)

while True: 

    with canvas(device) as draw:
        draw.rectangle(device.bounding_box, outline="white", fill="black")
        draw.text((30,40), "hello World", fill="white")
