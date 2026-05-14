import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)'}

url = "https://eltrive.com/wp-content/uploads/2025/03/cropped-LOGO.1jpg-192x192.jpg"
req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req, context=ctx) as response, open(r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\eltrive_logo.jpg", "wb") as out_file:
        out_file.write(response.read())
    print("Successfully downloaded JPG logo!")
except Exception as e:
    print(f"Error: {e}")
