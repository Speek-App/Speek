import curses
import base64
import io
from PIL import Image
import math

def display_image(screen, image_b64):
    for i in range(0, curses.COLORS):
        curses.init_pair(i*3+10, i, i);
        curses.init_pair(i*3+11, curses.COLOR_BLACK, i);
        curses.init_pair(i*3+12, curses.COLOR_WHITE, i);

    color_rgb_values2 = {
        curses.COLOR_WHITE: (255, 255, 255),
        curses.COLOR_RED: (255, 0, 0),
        curses.COLOR_GREEN: (0, 255, 0),
        curses.COLOR_YELLOW: (255, 255, 0),
        curses.COLOR_BLUE: (0, 0, 255),
        curses.COLOR_MAGENTA: (255, 0, 255),
        curses.COLOR_CYAN: (0, 255, 255),
        curses.COLOR_BLACK: (0, 0, 0),
    }
    color_rgb_values = {}
    color_rgb_values_rev_norm_non = []
    i = 0
    for c in range(len(color_rgb_values2)):
        for z in range(3):
            min3 = [-10, -20, 10][z]
            c1, c2, c3 = [max(0, min(255, color_rgb_values2[c][i] + min3)) for i in range(3)]
            color_rgb_values[i] = (c1,c2,c3)
            color_rgb_values_rev_norm_non.append(z)
            i += 1

    image = base64.b64decode(image_b64)
    image_file = io.BytesIO(image)
    img = Image.open(image_file)
    max_y, max_x = screen.getmaxyx()
    img.thumbnail((max_x/2-1,max_y-1))
    img = img.resize((img.width*2, img.height), Image.ANTIALIAS)
    
    # Convert the image to ASCII art
    pixels = img.getdata()
    ascii_image = []
    ascii_color = []
    for pixel in pixels:
        # Get the average color of the pixel
        avg_color = tuple(int(sum(color) / len(color)) for color in zip(*[pixel]*3))
        avg_color_bl = int(sum(pixel) / len(pixel))
        # Find the closest defined color
        closest_color = min(color_rgb_values.items(), key=lambda x: sum((x[1][i]-avg_color[i])**2 for i in range(3)))
        
        # Assign a character based on the difference to the closest color
        color_diff = sum((closest_color[1][i]-avg_color[i])**2 for i in range(3))
        color_intensity = int(math.sqrt(color_diff) / math.sqrt(3 * 255**2))
        
        ascii_char_list = "@#$&%*o+>;,'" if color_intensity <= 5 else "@#$&%*o+>;,'"[::-1] 
        ascii_pixel = ascii_char_list[int((avg_color_bl * len(ascii_char_list)) // 256) - 1]
        
        ascii_image.append(ascii_pixel)
        ascii_color.append(closest_color[0])
    
    # Display the ASCII image in the terminal
    for row in range(max_y - 1):
        line = "".join(ascii_image[row * (img.width) : (row + 1) * (img.width)])
        color_line = ascii_color[row * (img.width) : (row + 1) * (img.width)]
        for i, char in enumerate(line):
            screen.addstr(row, i, char, curses.color_pair(color_line[i]+10))

    screen.refresh()
    screen.getkey()
