import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
        
    # Skip root dashboard which correctly uses 'active'
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    updated = False
    
    # 1. Replace active reference in text interpolation
    old_active_str = "${active}"
    new_deviceCount_str = "${deviceCount}"
    if old_active_str in content:
        content = content.replace(old_active_str, new_deviceCount_str)
        updated = True
        
    # 2. Replace active reference in linear gauge value equation
    old_active_eq = "(active / total)"
    new_deviceCount_eq = "(deviceCount / total)"
    if old_active_eq in content:
        content = content.replace(old_active_eq, new_deviceCount_eq)
        updated = True

    if updated:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully corrected 'active' to 'deviceCount' in {count} module dashboards!")
