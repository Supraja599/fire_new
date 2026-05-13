import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

# Priority list of active-indicating state variable names
potential_vars = ['activeUnits', 'activeCount', 'activeLoops', 'active', 'deviceCount']

repaired_count = 0

for path in dashboards:
    if not os.path.exists(path):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Skip root dashboard since it uses 'active' explicitly and correctly
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    # Locate the state variable declaration block by finding where State begins
    state_match = re.search(r'class _.*?State extends State.*?\{([\s\S]*?)@override', content)
    if not state_match:
        continue
        
    state_block = state_match.group(1)
    
    # Find which of our variable candidates is actually defined in the state class
    actual_var = None
    for var_candidate in potential_vars:
        # Check for "int VAR =" or "int ..., VAR," or "int VAR," or similar
        # We'll do a word boundary match inside the state block to be safe
        pattern = r'\b' + re.escape(var_candidate) + r'\b'
        if re.search(pattern, state_block):
            actual_var = var_candidate
            break
            
    if not actual_var:
        print(f"WARNING: No active variable candidate found in {os.path.relpath(path, lib_dir)}! Skipping.")
        continue
        
    print(f"Mapping {os.path.relpath(path, lib_dir)} -> Active Variable: '{actual_var}'")
    
    updated = False
    # 1. Correct the text interpolation
    # Currently they all have deviceCount from the prior run
    old_interp = "${deviceCount}/"
    new_interp = "${" + actual_var + "}/"
    if old_interp in content and actual_var != 'deviceCount':
        content = content.replace(old_interp, new_interp)
        updated = True
        
    # 2. Correct the Linear Gauge equation
    old_eq = "(deviceCount /"
    new_eq = "(" + actual_var + " /"
    if old_eq in content and actual_var != 'deviceCount':
        content = content.replace(old_eq, new_eq)
        updated = True
        
    if updated:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        repaired_count += 1

print(f"\nSUCCESSFULLY HEALED {repaired_count} module dashboards back to stable compilation!")
