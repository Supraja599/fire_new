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

    old_line = "backgroundColor: Colors.white,"
    new_line = "backgroundColor: const Color(0xFFF4F6FA)," # Ultra-elegant modern soft grey-blue shade

    if old_line in content:
        content = content.replace(old_line, new_line)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully applied shaded background Color(0xFFF4F6FA) to {count} dashboards!")
