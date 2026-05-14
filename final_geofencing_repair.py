import os
import re

def clean_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    changed = False

    # 1. Define the multiline regex pattern that captures both styles of broken Text widgets
    # [\s\S]*? allows non-greedy matching across line breaks.
    broken_pattern = r'content:\s+Text\("⚠️\s+Location\s+Verification\s+Failed![\s\S]*?to\s+perform\s+inspection\."\),'
    
    # 2. The absolutely correct Dart literal.
    # Notice we use double-backslash \\n to write literal \n characters into the file!
    correct_dart_line = 'content: Text("⚠️ Location Verification Failed!\\n\\nYou are ${result.distanceMeters?.toStringAsFixed(1)} meters away from the asset location.\\n\\nYou must stand within 100 meters of this equipment to perform inspection."),'
    
    # 3. Using a lambda function for re.sub guarantees that no escape sequences are evaluated on the replacement string!
    if re.search(broken_pattern, content):
        content = re.sub(broken_pattern, lambda m: correct_dart_line, content)
        print(f"  [Repaired String] {file_path}")
        changed = True

    # 4. Double-check and repair double @override just in case any remaining
    override_pattern = r'@override\s+@override\s+void\s+initState'
    if re.search(override_pattern, content):
        content = re.sub(override_pattern, '@override\n  void initState', content)
        print(f"  [Repaired Override] {file_path}")
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
