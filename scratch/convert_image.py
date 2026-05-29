import os
import shutil

src = r"C:\Users\A\.gemini\antigravity-ide\brain\f19366aa-ebec-4341-ae6b-6c0667b3cfe3\analytics_icon_1780038934899.png"
dst = r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\dashboard_icons\analytics.webp"

try:
    from PIL import Image
    im = Image.open(src)
    im.save(dst, "WEBP")
    print("Successfully converted PNG to WEBP using PIL")
except Exception as e:
    print(f"PIL not available or failed: {e}. Falling back to copying PNG as WebP file name.")
    shutil.copy(src, dst)
