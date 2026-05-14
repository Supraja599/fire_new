import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
reports = glob.glob(os.path.join(lib_dir, '**', '*reports*.dart'), recursive=True)

for path in reports:
    rel = os.path.relpath(path, lib_dir)
    if rel == 'reports.dart':
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Find the build: (context) => [ array
    idx = content.find('build: (context) => [')
    if idx != -1:
        snippet = content[idx:idx+300]
        print(f"--- {rel} ---")
        print(snippet.strip())
        print("--------------------")
