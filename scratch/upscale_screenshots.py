import os
from PIL import Image

workspace_dir = r"c:\Users\ELT00048\Documents\supraja\fire_new-main"
assets_playstore_dir = os.path.join(workspace_dir, "assets", "playstore")

# Target width for HD screenshots (Full HD standard mobile width)
target_width = 1080

print("Upscaling screenshots to HD for premium clarity...")
files = [f for f in os.listdir(assets_playstore_dir) if f.endswith(".png")]

for f in files:
    path = os.path.join(assets_playstore_dir, f)
    with Image.open(path) as img:
        width, height = img.size
        # Calculate new height to maintain aspect ratio perfectly
        aspect_ratio = height / width
        target_height = int(target_width * aspect_ratio)
        
        # High quality upscale using LANCZOS
        hd_img = img.resize((target_width, target_height), Image.Resampling.LANCZOS)
        hd_img.save(path, "PNG")
        print(f"Upscaled {f} to: {target_width}x{target_height}")

print("All screenshots successfully upgraded to HD quality!")
