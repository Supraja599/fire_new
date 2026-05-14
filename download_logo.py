import urllib.request
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url = "https://eltrive.com/wp-content/uploads/2024/05/cropped-Eltrive-Logo-1-192x192.png"
headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}
req = urllib.request.Request(url, headers=headers)

try:
    with urllib.request.urlopen(req, context=ctx) as response, open(r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\eltrive_logo.png", "wb") as out_file:
        out_file.write(response.read())
    print("Successfully downloaded Eltrive logo to assets!")
except Exception as e:
    print(f"Error downloading: {e}")
