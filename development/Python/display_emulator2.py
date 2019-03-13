"""
A python script to layout the Noisebox display
Copyright (c) 2019 John Sullivan | IDMIL, McGIll University

Use with luma.emulator.capture
"""

from demo_opts import get_device
from luma.core.render import canvas
from PIL import ImageFont

# font = [] # fonts at every size from 0 to 20
# for x in range(21):
# 	font.append(ImageFont.truetype("pixelmix.ttf", x))
# 	# print(font[x])

fonts = [
	"fonts/C&C Red Alert [INET].ttf",
	"fonts/code2000.ttf",
	"fonts/fontawesome-webfont.ttf",
	"fonts/FreePixel.ttf",
	"fonts/miscfs_.ttf",
	"fonts/pixelmix.ttf",
	"fonts/ProggyTiny.ttf",
	"fonts/tiny.ttf",
	"fonts/Volter__28Goldfish_29.ttf"
	]

xmarg = 4
xoff = 27+4
yoff = 8
toff = 13

title = "Noisebox v3"
knob = []
button = []
for x in range(4): 
	knob.append([0.555, 0.555, "knob"+str(x)])
	button.append(["VAL", "btn"+str(x)])

# def update_values(address, val):


def main(): 
	while True: 
		font = [] # fonts at every size from 0 to 20
		for x in range(21):
			font.append(ImageFont.truetype(fonts[3], x))
			# print(font[x])
		print(fonts[3])
		with canvas(device) as draw: 
			# ...draw title
			draw.text((4,0), title, fill="white", font=font[15]) # title
			# ...draw knobs
			for x in range(4):
				draw.text((xmarg+(xoff*x),toff+0), str(knob[x][0]), fill="white", font=font[7]) # outVal
				draw.ellipse((6+(xoff*x), toff+yoff, 6+(xoff*x)+14, toff+yoff+14), fill="white") # knob
				# draw.text((xmarg+(xoff*x),toff+(yoff*4)), str(knob[x][1]), fill="white", font=font[7]) # normVal (for knob)
				draw.text((xmarg+(xoff*x),toff+(yoff*3.1)), knob[x][2], fill="white", font=font[7]) # label
				# ...draw buttons
				draw.rectangle((xmarg+(xoff*x),toff+(yoff*4.3), xoff*x+28, toff+(yoff*5.3)), fill="white")
				draw.text((6+(xoff*x),toff+(yoff*4.4)), str(button[x][0]), fill="black", font=font[7]) # state
				draw.text((xmarg+(xoff*x),toff+(yoff*5.4)), button[x][1], fill="white", font=font[7]) # label
		exit(0)

if __name__ == "__main__":
	try: 
		device = get_device()
		main()
	except KeyboardInterrupt:
		pass
		
