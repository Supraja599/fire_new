import shutil
from PIL import Image

src_img = r"C:\Users\ELT00048\.gemini\antigravity-ide\brain\84b625e2-1112-4f73-b4e9-f17463583448\media__1782286600210.jpg"
dest_jpg = r"c:\Users\ELT00048\Documents\supraja\fire_new-main\assets\eltrive_logo.jpg"
dest_webp = r"c:\Users\ELT00048\Documents\supraja\fire_new-main\assets\eltrive_logo.webp"

try:
    # 1. Copy as JPG
    shutil.copy(src_img, dest_jpg)
    print(f"Copied to {dest_jpg} successfully.")

    # 2. Convert and save as WEBP
    im = Image.open(src_img)
    im.save(dest_webp, "WEBP")
    print(f"Converted and saved to {dest_webp} successfully.")
except Exception as e:
    print(f"Error occurred: {e}")
