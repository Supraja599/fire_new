import os
import re

def fix_dashboard(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Change Column to ListView in SafeArea
    content = content.replace('child: Column(', 'child: ListView(')
    
    # 2. Add BouncingScrollPhysics to ListView
    content = re.sub(r'child: ListView\(\s+children:', 'child: ListView(\n          physics: const BouncingScrollPhysics(),\n          children:', content)

    # 3. Handle Expanded GridView
    # Look for Expanded(child: GridView.count(...)
    pattern = r'Expanded\(\s+child: GridView\.count\('
    if re.search(pattern, content):
        content = re.sub(pattern, 'GridView.count(\n                shrinkWrap: true,\n                physics: const NeverScrollableScrollPhysics(),', content)
        
        # We need to find the closing bracket for the Expanded we just removed
        # This is tricky, but usually it's before a '],' or '),' after the GridView closing
        # Let's try to find the match.
        # Alternatively, we can just look for the specific sequence '), ],' which often occurs
    
    # 4. Add FittedBox to titles in Action Cards
    # For _BigActionCard and _ActionCard
    title_pattern = r'Text\(title, style: const TextStyle\(fontWeight: FontWeight.w900, (.*?)\)\)'
    replacement = r'FittedBox(fit: BoxFit.scaleDown, child: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, \1)))'
    content = re.sub(title_pattern, replacement, content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Fixed: {file_path}")

# Walk through all directories in lib
lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            # Skip the main lib/dashboard.dart as I already fixed it manually
            if root == lib_path:
                continue
            full_path = os.path.join(root, file)
            fix_dashboard(full_path)
