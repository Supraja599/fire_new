import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_dims = """                width: width * 0.16,
                height: width * 0.16,"""
    
    new_dims = """                width: width * 0.22,
                height: width * 0.22,"""

    if old_dims in content:
        content = content.replace(old_dims, new_dims)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully super-sized icons to width * 0.22 in {count} dashboards!")
