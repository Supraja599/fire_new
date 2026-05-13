import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'

count = 0
for root, _, files in os.walk(lib_dir):
    if root == lib_dir: continue
    folder = os.path.basename(root)
    if folder in ['icons', 'services', 'widgets']: continue
    
    for f in files:
        if f == 'dashboard.dart' or f == 'sprinkler.dart':
            path = os.path.join(root, f)
            with open(path, 'r', encoding='utf-8') as file:
                content = file.read()
                
            original_content = content
            
            # Inject api: api, inside SafetyGaugeWidget(
            pattern = r'(SafetyGaugeWidget\([\s\S]*?moduleName: "[^"]+",)\n            \),'
            replacement = r'\1\n              api: api,\n            ),'
            
            new_content = re.sub(pattern, replacement, content)
            
            if new_content != original_content:
                with open(path, 'w', encoding='utf-8') as file:
                    file.write(new_content)
                count += 1
                print('Updated', path)

print(f'Total injected: {count}')
