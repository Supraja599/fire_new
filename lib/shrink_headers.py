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

    modified = False
    
    # Scale title down from 0.07 to 0.055
    if "fontSize: width * 0.07," in content:
        content = content.replace("fontSize: width * 0.07,", "fontSize: width * 0.055,")
        modified = True
        
    # Scale subtitle down from 0.04 to 0.032
    if "fontSize: width * 0.04," in content:
        content = content.replace("fontSize: width * 0.04,", "fontSize: width * 0.032,")
        modified = True

    if modified:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        count += 1

print(f"Successfully shrunk header font sizes in {count} dashboards!")
