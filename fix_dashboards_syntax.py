import os
import re

def fix_dashboard(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # If we find the orphaned closing bracket after GridView.count
    # it usually looks like: 
    #     ],
    #   ),
    # ),
    # and we want to remove the last one.
    
    # We look for:
    # children: [ ... ],
    # ), // GridView.count ends
    # ), // Extra Expanded bracket
    
    content = content.replace('],', '],') # Ensure consistency
    
    # Pattern to find GridView ending and the extra bracket
    # Note: Using dots to match newlines/spaces
    new_content = re.sub(r'children: \[\s+(.*?)\s+\],\s+\),\s+\),', r'children: [\1\n                ],\n              ),', content, flags=re.DOTALL)
    
    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Syntax Fixed: {file_path}")

# Walk through all directories in lib
lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            if root == lib_path:
                continue
            full_path = os.path.join(root, file)
            fix_dashboard(full_path)
