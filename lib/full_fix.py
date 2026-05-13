import os
import glob
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

checklist_files = glob.glob(os.path.join(lib_dir, '**', 'checklist.dart'), recursive=True)

# Replace patterns for "item["item_text"] ?? ..."
pattern_item = r'item\["item_text"\]\s*\?\?\s*""'
pattern_item_full = r'item\["item_text"\] ?? item["item"] ?? item["question"] ?? item["question_text"] ?? item["name"] ?? item["title"] ?? item["description"] ?? item["text"] ?? item["checklist_item"] ?? item["content"] ?? "Unknown Question"'

# Replace patterns for "item["item_text"] ?? item["item"] ?? ..." in case it varies
pattern_item_item = r'item\["item_text"\]\s*\?\?\s*item\["item"\]\s*\?\?\s*""'

# For "item["item_text"] ?? "").toString()"
pattern_toString = r'\(item\["item_text"\]\s*\?\?\s*""\)\.toString\(\)'
pattern_toString_full = r'(item["item_text"] ?? item["item"] ?? item["question"] ?? item["question_text"] ?? item["name"] ?? item["title"] ?? item["description"] ?? item["text"] ?? item["checklist_item"] ?? item["content"] ?? "Unknown Question").toString()'

count = 0
for path in checklist_files:
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    modified = False
    
    # 1. Handle "item["item_text"] ?? """ and "item["item_text"] ?? item["item"] ?? """
    new_content = re.sub(r'item\["item_text"\]\s*\?\?\s*item\["item"\]\s*\?\?\s*""', pattern_item_full, content)
    new_content = re.sub(r'item\["item_text"\]\s*\?\?\s*""', pattern_item_full, new_content)
    new_content = re.sub(r'\(item\["item_text"\]\s*\?\?\s*""\)\.toString\(\)', pattern_toString_full, new_content)
    
    # In some files, it might be "item['item_text']"
    new_content = re.sub(r"item\['item_text'\]\s*\?\?\s*''", pattern_item_full, new_content)
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        count += 1
        print(f"Regex fixed: {os.path.relpath(path, lib_dir)}")

print(f"Total additional files fixed: {count}")
