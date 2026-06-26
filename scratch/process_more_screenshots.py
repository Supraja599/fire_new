import os
from PIL import Image

artifact_dir = r"C:\Users\ELT00048\.gemini\antigravity-ide\brain\8bbcbb0e-db7d-42f1-b68e-88f8e5d58c1c"
workspace_dir = r"c:\Users\ELT00048\Documents\supraja\fire_new-main"
assets_playstore_dir = os.path.join(workspace_dir, "assets", "playstore")

# Ensure directory exists
os.makedirs(assets_playstore_dir, exist_ok=True)

# Mapping of newly uploaded files
new_screenshot_map = {
    "media__1782468429456.jpg": "screenshot_6_bar_chart.png",
    "media__1782468499196.jpg": "screenshot_7_report_pdf.png",
    "media__1782468510518.jpg": "screenshot_8_reports_form.png"
}

# The images are 458x1024
crop_top = 45
crop_bottom = 60

print("Processing and cleaning 3 new screenshots...")
for src_name, dest_name in new_screenshot_map.items():
    src_path = os.path.join(artifact_dir, src_name)
    dest_path = os.path.join(assets_playstore_dir, dest_name)
    dest_artifact_path = os.path.join(artifact_dir, dest_name)
    
    with Image.open(src_path) as img:
        width, height = img.size
        box = (0, crop_top, width, height - crop_bottom)
        cropped_img = img.crop(box)
        
        cropped_img.save(dest_path, "PNG")
        cropped_img.save(dest_artifact_path, "PNG")
        print(f"Saved: {dest_name} ({cropped_img.size})")

print("All new screenshots successfully processed!")
