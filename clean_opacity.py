import os
import re

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to find .withOpacity(...)
    # Handles floats and expressions like .withOpacity(0.1)
    pattern = r'\.withOpacity\(([^)]+)\)'
    
    if re.search(pattern, content):
        fixed = re.sub(pattern, r'.withValues(alpha: \1)', content)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(fixed)
        print(f"Fixed opacity in {filepath}")

# Specifically target co_detector directory
co_dir = os.path.join('lib', 'co_detector')
for root, dirs, files in os.walk(co_dir):
    for file in files:
        if file.endswith('.dart'):
            fix_file(os.path.join(root, file))

print("Done cleaning withOpacity usages.")
