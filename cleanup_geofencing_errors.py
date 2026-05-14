import os
import re

def clean_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    changed = False

    # 1. Fix double @override
    override_pattern = r'@override\s+@override\s+void\s+initState'
    if re.search(override_pattern, content):
        content = re.sub(override_pattern, '@override\n  void initState', content)
        print(f"  [Fixed Override] {file_path}")
        changed = True

    # 2. Fix multiline Text widget syntax error
    broken_text_pattern = r'content:\s+Text\("⚠️\s+Location\s+Verification\s+Failed![\s\S]*?to\s+perform\s+inspection\."\),'
    
    # Correct string format using double-escaped newlines for Dart strings
    replacement_text = r'content: Text("⚠️ Location Verification Failed!\n\nYou are ${result.distanceMeters?.toStringAsFixed(1)} meters away from the asset location.\n\nYou must stand within 100 meters of this equipment to perform inspection."),'
    
    if re.search(broken_text_pattern, content):
        content = re.sub(broken_text_pattern, replacement_text, content)
        print(f"  [Fixed Text Block] {file_path}")
        changed = True

    if changed:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)

def run():
    base_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
    
    for root, dirs, files in os.walk(base_dir):
        if 'checklist.dart' in files:
            clean_file(os.path.join(root, 'checklist.dart'))

if __name__ == "__main__":
    run()
