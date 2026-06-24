from PIL import Image

def make_transparent(img_path, output_path):
    img = Image.open(img_path).convert("RGBA")
    datas = img.getdata()

    new_data = []
    for item in datas:
        # Check if the pixel is white or off-white
        # item[0], item[1], item[2] are R, G, B
        r, g, b, a = item
        # If the pixel is very light (R, G, B > 240), make it transparent
        if r > 240 and g > 240 and b > 240:
            new_data.append((255, 255, 255, 0))
        # Also key out off-white shades if close in color (low saturation)
        elif r > 200 and g > 200 and b > 200 and abs(r - g) < 15 and abs(g - b) < 15 and abs(r - b) < 15:
            new_data.append((255, 255, 255, 0))
        else:
            new_data.append(item)

    img.putdata(new_data)
    img.save(output_path, "PNG")
    print("Background made transparent successfully!")

if __name__ == "__main__":
    img_path = r"c:\Users\ELT00048\Documents\supraja\fire_new-main\assets\sand_bucket.png"
    output_path = r"c:\Users\ELT00048\Documents\supraja\fire_new-main\assets\sand_bucket.png"
    make_transparent(img_path, output_path)
