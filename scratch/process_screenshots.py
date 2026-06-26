import os
from PIL import Image

artifact_dir = r"C:\Users\ELT00048\.gemini\antigravity-ide\brain\8bbcbb0e-db7d-42f1-b68e-88f8e5d58c1c"
workspace_dir = r"c:\Users\ELT00048\Documents\supraja\fire_new-main"
assets_playstore_dir = os.path.join(workspace_dir, "assets", "playstore")

# Create assets/playstore directory if it doesn't exist
os.makedirs(assets_playstore_dir, exist_ok=True)

# Mapping files to clean readable names
screenshot_map = {
    "media__1782468143421.jpg": "screenshot_1_login.png",
    "media__1782468160414.jpg": "screenshot_2_dashboard.png",
    "media__1782468276330.jpg": "screenshot_3_details.png",
    "media__1782468287989.jpg": "screenshot_4_analytics.png",
    "media__1782468317551.jpg": "screenshot_5_scan.png"
}

# The images are 458x1024
# We will crop the top status bar (approx 45 pixels) and bottom navigation bar (approx 60 pixels)
# to make them look highly professional.
crop_top = 45
crop_bottom = 60

print("Processing and cleaning screenshots...")
for src_name, dest_name in screenshot_map.items():
    src_path = os.path.join(artifact_dir, src_name)
    dest_path = os.path.join(assets_playstore_dir, dest_name)
    dest_artifact_path = os.path.join(artifact_dir, dest_name)
    
    with Image.open(src_path) as img:
        width, height = img.size
        # Crop box: (left, upper, right, lower)
        box = (0, crop_top, width, height - crop_bottom)
        cropped_img = img.crop(box)
        
        # Save as PNG in project assets
        cropped_img.save(dest_path, "PNG")
        # Save in artifact directory too for user convenience
        cropped_img.save(dest_artifact_path, "PNG")
        print(f"Saved: {dest_name} ({cropped_img.size})")

print("All screenshots successfully processed!")
