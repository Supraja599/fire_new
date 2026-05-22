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

    # 1. Scale image up from 0.12 to 0.16
    old_dims = """                width: width * 0.12,
                height: width * 0.12,"""
    
    new_dims = """                width: width * 0.16,
                height: width * 0.16,"""
    
    # 2. Optimize grid ratio for taller cards
    old_ratio = "double aspectRatio = (0.85 / textScale).clamp(0.6, 0.9);"
    new_ratio = "double aspectRatio = (0.78 / textScale).clamp(0.5, 0.85);"

    modified = False
    if old_dims in content:
        content = content.replace(old_dims, new_dims)
        modified = True
        
    if old_ratio in content:
        content = content.replace(old_ratio, new_ratio)
        modified = True

    if modified:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Enlarged images in {count} dashboards!")
