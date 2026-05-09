
import os
import re

def cleanup_brackets(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The script left an extra ), after the GridView.count closing
    # We look for the GridView closing and the leftover Expanded closing
    # Pattern: ),\n            ),\n          ],
    # We want: ),\n          ],
    
    new_content = re.sub(
        r'\),\s+\),\s+\],',
        r'),\n          ],',
        content, flags=re.DOTALL
    )

    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Cleaned: {file_path}")

lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            cleanup_brackets(os.path.join(root, file))
