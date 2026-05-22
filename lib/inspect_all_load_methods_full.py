import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

for path in dashboards:
    if not os.path.exists(path):
        continue
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Find active variable assignment and total assignment in the load/loadData method
    print(f"\n========================================\nFILE: {os.path.relpath(path, lib_dir)}")
    
    # Let's extract the whole setState block inside _load or _loadData
    set_state_match = re.search(r'setState\(\(\)\s*\{([\s\S]*?)\}\);', content)
    if set_state_match:
        print("setState block:")
        print(set_state_match.group(1).strip())
    else:
        # Maybe setState(() { ... }) without trailing semicolon or different spacing
        set_state_match = re.search(r'setState\(\(\)\s*\{([\s\S]*?)\}', content)
        if set_state_match:
            print("setState block:")
            print(set_state_match.group(1).strip())
        else:
            print("No setState block found")
            
    # Also find where the banner description string "Successfully validating ..." is defined, to see which variable it uses!
    validating_match = re.search(r'"Successfully validating [\s\S]*?"', content)
    if validating_match:
        print("Validating string:")
        print(validating_match.group(0))
    else:
        print("No validating string found")
