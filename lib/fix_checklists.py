import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

checklist_files = glob.glob(os.path.join(lib_dir, '**', 'checklist.dart'), recursive=True)

target_str = '"item": q["item_text"] ?? q["item"] ?? "Unknown Question",'
replace_str = '"item": q["item_text"] ?? q["item"] ?? q["question"] ?? q["question_text"] ?? q["name"] ?? q["title"] ?? q["description"] ?? q["text"] ?? q["checklist_item"] ?? q["content"] ?? "Unknown Question",'

count = 0
for path in checklist_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    if target_str in content:
        new_content = content.replace(target_str, replace_str)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        count += 1
        print(f"Fixed {os.path.relpath(path, lib_dir)}")

# Also fix the global checklist.dart if it has it differently
global_checklist = os.path.join(lib_dir, 'checklist.dart')
if os.path.exists(global_checklist):
    with open(global_checklist, 'r', encoding='utf-8') as f:
        content = f.read()
    global_target = '"item": item["item_text"] ?? item["item"] ?? "",'
    global_replace = '"item": item["item_text"] ?? item["item"] ?? item["question"] ?? item["question_text"] ?? item["name"] ?? item["title"] ?? item["description"] ?? item["text"] ?? item["checklist_item"] ?? item["content"] ?? "Unknown Question",'
    if global_target in content:
        new_content = content.replace(global_target, global_replace)
        with open(global_checklist, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Fixed global checklist.dart")

print(f"Total files fixed: {count}")
