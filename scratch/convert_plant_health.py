import shutil

try:
    from PIL import Image
    im = Image.open(r"C:\Users\A\.gemini\antigravity-ide\brain\f19366aa-ebec-4341-ae6b-6c0667b3cfe3\plant_health_icon_1780039321612.png")
    im.save(r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\dashboard_icons\plant_health.webp", "WEBP")
    print("Successfully converted industrial plant health icon to WebP")
except Exception as e:
    print(f"PIL not available: {e}. Falling back to standard copy.")
    shutil.copy(
        r"C:\Users\A\.gemini\antigravity-ide\brain\f19366aa-ebec-4341-ae6b-6c0667b3cfe3\plant_health_icon_1780039321612.png",
        r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\dashboard_icons\plant_health.webp"
    )
    print("Fallback copy complete.")
