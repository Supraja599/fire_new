import os
from PIL import Image

artifact_dir = r"C:\Users\ELT00048\.gemini\antigravity-ide\brain\8bbcbb0e-db7d-42f1-b68e-88f8e5d58c1c"
files = [
    "media__1782468143421.jpg",
    "media__1782468160414.jpg",
    "media__1782468276330.jpg",
    "media__1782468287989.jpg",
    "media__1782468317551.jpg"
]

print("Inspecting screenshots:")
for f in files:
    path = os.path.join(artifact_dir, f)
    with Image.open(path) as img:
        print(f"{f}: {img.size}")
