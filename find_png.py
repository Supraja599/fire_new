import urllib.request
import ssl
import re

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

try:
    req = urllib.request.Request("https://eltrive.com/", headers=headers)
    with urllib.request.urlopen(req, context=ctx) as resp:
        html = resp.read().decode('utf-8')
    
    # Find all png or jpg images
    all_imgs = re.findall(r'src="([^"]*\.(?:png|jpg|jpeg)[^"]*)"', html, re.IGNORECASE)
    print("PNG/JPG images found on site:")
    for img in all_imgs:
        print(img)
        
    href_imgs = re.findall(r'href="([^"]*\.(?:png|jpg|jpeg)[^"]*)"', html, re.IGNORECASE)
    print("PNG/JPG links found on site:")
    for img in href_imgs:
        print(img)
except Exception as e:
    print(f"Error: {e}")
