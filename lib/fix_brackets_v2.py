import os
import re

def fix_header_brackets(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Identify the broken block: HealthScoreWidget followed by a mess of closing tags
    # until the next Container or SizedBox or GridView
    
    pattern = r'HealthScoreWidget\(health: health\),[\s\S]*?(?=\s*(Container|SizedBox|LayoutBuilder|GridView))'
    replacement = 'HealthScoreWidget(health: health),\n                ],\n              ),\n            ),\n            '
    
    if 'HealthScoreWidget(health: health),' in content:
        new_content = re.sub(pattern, replacement, content)
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
fixed = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and ('dashboard' in file.lower() or file == 'sprinkler.dart'):
            if fix_header_brackets(os.path.join(root, file)):
                fixed += 1

print(f"Fixed header brackets in {fixed} dashboard files.")
