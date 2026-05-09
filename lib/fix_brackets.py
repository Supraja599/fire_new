import os
import re

def fix_header_brackets(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Target the specific broken pattern: HealthScoreWidget followed by too many closing tags
    # We want it to be:
    # HealthScoreWidget(health: health),
    #             ],
    #           ),
    #         ),
    
    pattern = r'HealthScoreWidget\(health: health\),[\s\S]*?\]\s*,\s*\}\s*,\s*\)\s*,\s*\}\s*,\s*\]\s*,\s*\}\s*,\s*\)\s*,\s*\}\s*,'
    # Actually, let's just target the specific sequence of closing tags
    
    # This is safer: find the Row ending and the Padding ending
    broken_pattern = r'HealthScoreWidget\(health: health\),\s*\]\s*,\s*\}\s*,\s*\)\s*,\s*\}\s*,\s*\]\s*,\s*\}\s*,\s*\)\s*,\s*\}\s*,'
    
    # Let's try a more general replacement for the whole Row block
    row_pattern = r'Row\([\s\S]*?HealthScoreWidget\(health: health\),[\s\S]*?\}\s*,\s*\)\s*,'
    
    # Wait, let's just look at the view_file output:
    # 76:                   HealthScoreWidget(health: health),
    # 77:                         ]),
    # 78:                       ],
    # 79:                     ),
    # 80:                   ),
    # 81:                 ],
    # 82:               ),
    # 83:             ),
    
    # I'll replace the whole Padding block
    padding_pattern = r'Padding\(\s*padding: const EdgeInsets\.symmetric\(horizontal: 15, vertical: 20\),[\s\S]*?HealthScoreWidget\(health: health\),[\s\S]*?\}\s*,\s*\)\s*,'
    
    # I'll use a more surgical approach
    if 'HealthScoreWidget(health: health),' in content:
        # Match the widget and everything until the next major widget (Container)
        # and replace with correct closing tags
        new_content = re.sub(r'HealthScoreWidget\(health: health\),[\s\S]*?\}\s*,\s*Container\(', r'HealthScoreWidget(health: health),\n                ],\n              ),\n            ),\n            Container(', content)
        
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
fixed = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and ('dashboard' in file.lower() or file == 'sprinkler.dart'):
            if fix_header_brackets(os.path.join(root, file)):
                fixed += 1

print(f"Fixed header brackets in {fixed} dashboard files.")
