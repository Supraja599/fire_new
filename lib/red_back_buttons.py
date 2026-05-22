import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'splinkers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    # Skip root dashboard, we'll edit that separately
    if os.path.abspath(path) == os.path.abspath(os.path.join(lib_dir, 'dashboard.dart')):
        continue
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_line = "child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 18),"
    new_line = "child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFD50000), size: 18),"

    if old_line in content:
        content = content.replace(old_line, new_line)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Turned back button red in {count} module dashboards!")
