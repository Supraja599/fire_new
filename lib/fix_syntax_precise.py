import glob
import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Highly targeted pattern: 
    # Group 1: Matches LayoutBuilder up to its closing ),\n
    # Then matches the dangling ),\n
    # Group 2: Matches the closing bracket ] of the parent ListView children array
    pattern = r'(\s*LayoutBuilder\([\s\S]*?}\s*,\s*\n\s*\)\s*,\s*\n)\s*\)\s*,\s*\n(\s*\])'
    new_content, num_subs = re.subn(pattern, r'\1\2', content)
    
    if num_subs > 0:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Correctly repaired syntax in {os.path.relpath(path, lib_dir)} ({num_subs} sub)")
        count += 1

print(f"\nDONE: Targeted fix applied successfully to {count} dashboard files.")
