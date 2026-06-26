import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Paths
artifact_dir = r"C:\Users\ELT00048\.gemini\antigravity-ide\brain\8bbcbb0e-db7d-42f1-b68e-88f8e5d58c1c"
workspace_dir = r"c:\Users\ELT00048\Documents\supraja\fire_new-main"
source_image_path = os.path.join(artifact_dir, "media__1782467525545.jpg")

icon_output_path = os.path.join(workspace_dir, "playstore_icon.png")
icon_artifact_path = os.path.join(artifact_dir, "playstore_icon.png")
feature_output_path = os.path.join(workspace_dir, "feature_graphic.png")
feature_artifact_path = os.path.join(artifact_dir, "feature_graphic.png")

# 1. Generate Play Store Icon (512 x 512 PNG)
print("Generating Play Store Icon...")
with Image.open(source_image_path) as img:
    icon_img = img.resize((512, 512), Image.Resampling.LANCZOS)
    icon_img.save(icon_output_path, "PNG")
    icon_img.save(icon_artifact_path, "PNG")
    print(f"Icon saved: {icon_output_path}")

# 2. Generate Feature Graphic (1024 x 500 PNG)
print("Generating Feature Graphic...")
# Background size
fg_width, fg_height = 1024, 500
feature_img = Image.new("RGBA", (fg_width, fg_height), (4, 10, 27, 255)) # Dark Blue matching the icon squircle background

# Let's create a radial gradient/glow on the background
draw = ImageDraw.Draw(feature_img)
# Draw subtle red/orange radial gradient in the center/right to create a professional safety glow
glow_layer = Image.new("RGBA", (fg_width, fg_height), (0, 0, 0, 0))
glow_draw = ImageDraw.Draw(glow_layer)
center_x, center_y = 512, 250
for r in range(400, 0, -4):
    alpha = int((1 - r / 400.0) ** 2 * 60) # Glow opacity
    glow_draw.ellipse(
        [center_x - r, center_y - r, center_x + r, center_y + r],
        fill=(213, 0, 0, alpha) # Fire red glow
    )
feature_img = Image.alpha_composite(feature_img, glow_layer)

# Paste the icon on the left side of the feature graphic
with Image.open(source_image_path) as img:
    # Resize icon for feature graphic (e.g., 340 x 340)
    icon_size = 340
    icon_resized = img.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    # Position
    paste_x = 60
    paste_y = (fg_height - icon_size) // 2 # Centered vertically (80)
    
    # Paste icon (since it's a squircle with dark background, we can paste directly)
    feature_img.paste(icon_resized, (paste_x, paste_y))

# Add typography on the right side
draw = ImageDraw.Draw(feature_img)

# Try loading Segoe UI or Arial fonts from Windows
font_title = None
font_subtitle = None

font_paths = [
    r"C:\Windows\Fonts\segoeuib.ttf", # Segoe UI Bold
    r"C:\Windows\Fonts\arialbd.ttf",  # Arial Bold
    r"C:\Windows\Fonts\tahomabd.ttf"  # Tahoma Bold
]
font_sub_paths = [
    r"C:\Windows\Fonts\segoeui.ttf",  # Segoe UI Regular
    r"C:\Windows\Fonts\arial.ttf",    # Arial Regular
    r"C:\Windows\Fonts\tahoma.ttf"    # Tahoma Regular
]

for p in font_paths:
    if os.path.exists(p):
        try:
            font_title = ImageFont.truetype(p, 64)
            break
        except Exception:
            pass

for p in font_sub_paths:
    if os.path.exists(p):
        try:
            font_subtitle = ImageFont.truetype(p, 24)
            break
        except Exception:
            pass

if not font_title:
    font_title = ImageFont.load_default()
if not font_subtitle:
    font_subtitle = ImageFont.load_default()

# Draw text
# Title "FireSphere"
text_x = 450
text_y = 180
draw.text((text_x, text_y), "FireSphere", fill=(255, 255, 255, 255), font=font_title)

# Subtitle "Safety & Compliance Audits"
sub_text_y = text_y + 85
draw.text((text_x, sub_text_y), "Safety & Compliance Audits", fill=(213, 0, 0, 255), font=font_subtitle) # Vibrant red subtitle

# Save
feature_img.convert("RGB").save(feature_output_path, "JPEG", quality=95)
feature_img.convert("RGB").save(feature_artifact_path, "JPEG", quality=95)
print(f"Feature graphic saved: {feature_output_path}")
