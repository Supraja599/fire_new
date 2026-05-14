import urllib.request
import ssl
import re

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

headers = {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'}

# Try another URL from subagent first
url2 = "https://eltrive.com/wp-content/uploads/2024/04/Eltrive-Logo-300x300.png"
req2 = urllib.request.Request(url2, headers=headers)
try:
    with urllib.request.urlopen(req2, context=ctx) as response, open(r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\eltrive_logo.png", "wb") as out_file:
        out_file.write(response.read())
    print("Successfully downloaded Eltrive logo 300x300 to assets!")
    exit(0)
except Exception as e:
    print(f"Error downloading 300x300: {e}")

# If that fails, fetch home page and scrape the logo URL
try:
    req_home = urllib.request.Request("https://eltrive.com/", headers=headers)
    with urllib.request.urlopen(req_home, context=ctx) as resp:
        html = resp.read().decode('utf-8')
    
    # Look for logo image in HTML
    img_urls = re.findall(r'src="([^"]*logo[^"]*)"', html, re.IGNORECASE)
    print(f"Found logo URLs in HTML: {img_urls}")
    if img_urls:
        img_url = img_urls[0]
        if img_url.startswith('//'):
            img_url = 'https:' + img_url
        elif not img_url.startswith('http'):
            img_url = 'https://eltrive.com/' + img_url.lstrip('/')
            
        print(f"Trying scraped URL: {img_url}")
        req_scrap = urllib.request.Request(img_url, headers=headers)
        with urllib.request.urlopen(req_scrap, context=ctx) as response, open(r"c:\Users\A\AndroidStudioProjects\Fire_New\assets\eltrive_logo.png", "wb") as out_file:
            out_file.write(response.read())
        print("Successfully downloaded scraped logo!")
except Exception as e:
    print(f"Error scraping: {e}")
