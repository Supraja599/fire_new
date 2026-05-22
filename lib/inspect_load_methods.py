import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

for path in dashboards:
    if not os.path.exists(path):
        continue
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Find _loadData or _load method
    load_match = re.search(r'Future<void>\s+(_loadData|_load)\(\)\s*async\s*\{([\s\S]*?)\n\s*\}', content)
    
    print(f"\n--- FILE: {os.path.relpath(path, lib_dir)} ---")
    if load_match:
        print(load_match.group(0))
    else:
        # Fallback to finding method with setState in it
        print("No exact _loadData match")
