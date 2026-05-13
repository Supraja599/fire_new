import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

checklist_files = glob.glob(os.path.join(lib_dir, '**', 'checklist.dart'), recursive=True)

count = 0
for path in checklist_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content.replace(r'\[', '[').replace(r'\]', ']').replace(r'\"', '"')
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        count += 1
        print(f"Cleaned syntax in: {os.path.relpath(path, lib_dir)}")

print(f"Total files cleaned: {count}")
