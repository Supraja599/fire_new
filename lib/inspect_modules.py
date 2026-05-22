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
        
    # Extract variables declared in class State
    state_match = re.search(r'class _.*?State extends State.*?\{([\s\S]*?)@override\s+void\s+initState', content)
    if not state_match:
        state_match = re.search(r'class _.*?State extends State.*?\{([\s\S]*?)@override\s+Widget\s+build', content)
        
    print(f"\n--- FILE: {os.path.relpath(path, lib_dir)} ---")
    if state_match:
        body = state_match.group(1)
        # Find any int declarations
        vars = re.findall(r'int\s+(\w+)\s*=\s*[^;]+;', body)
        vars2 = re.findall(r'int\s+(\w+)\s*,\s*(\w+)\s*=\s*[^;]+;', body)
        vars3 = re.findall(r'int\s+(\w+)\s*,\s*(\w+)\s*,\s*(\w+)\s*=\s*[^;]+;', body)
        print(f"Single: {vars}")
        print(f"Double: {vars2}")
        print(f"Triple: {vars3}")
    else:
        print("No state block found!")
