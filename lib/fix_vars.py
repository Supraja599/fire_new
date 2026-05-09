import os
import re

def fix_aspect_ratio(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Force childAspectRatio to use the variable 'aspectRatio'
    # Force crossAxisCount to use the variable 'crossAxisCount'
    
    new_content = re.sub(r'childAspectRatio:\s*[^,]+,', 'childAspectRatio: aspectRatio,', content)
    new_content = re.sub(r'crossAxisCount:\s*[^,]+,', 'crossAxisCount: crossAxisCount,', new_content)

    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
updated = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and ('dashboard' in file.lower() or file == 'sprinkler.dart'):
            if fix_aspect_ratio(os.path.join(root, file)):
                updated += 1

print(f"Fixed variable usage in {updated} files.")
