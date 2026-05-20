import os

search_roots = [
    os.path.expanduser("~"),
]

print("Searching for databases...")
for root_path in search_roots:
    for root, dirs, files in os.walk(root_path):
        # Skip some big folders
        if any(x in root for x in ["Android", ".gradle", ".android", "AppData\\Local\\Microsoft", "AppData\\Local\\Package Cache", "AppData\\Local\\Temp"]):
            del dirs[:]
            continue
            
        for f in files:
            if f.endswith(".db"):
                full_path = os.path.join(root, f)
                print(f"Found DB: {full_path} (Size: {os.path.getsize(full_path)} bytes)")
                
        # Limit depth
        depth = root.count(os.sep) - root_path.count(os.sep)
        if depth > 4:
            del dirs[:]
