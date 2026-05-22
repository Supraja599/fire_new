import os
import glob

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # The broken syntax is:
    #             ),
    #             ),
    #           ],
    #         ),
    
    broken_str = "            ),\n            ),\n          ],\n        ),"
    fixed_str = "            ),\n          ],\n        ),"
    
    if broken_str in content:
        content = content.replace(broken_str, fixed_str)
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)

print("Syntax errors fixed!")
