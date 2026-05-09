import os
import re

def fix_dashboard(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. First, REVERT all ListView back to Column to start clean
    content = content.replace('child: ListView(', 'child: Column(')
    content = content.replace('ListView(children:', 'Column(children:')
    content = content.replace('ListView(crossAxisAlignment:', 'Column(crossAxisAlignment:')
    
    # 2. Only change the TOP-LEVEL Column (inside SafeArea) to ListView
    # This is the one that needs to scroll.
    content = content.replace('body: SafeArea(\n        child: Column(', 'body: SafeArea(\n        child: ListView(\n          physics: const BouncingScrollPhysics(),\n')
    # Alternative for different indentation
    content = content.replace('body: SafeArea(child: Column(', 'body: SafeArea(child: ListView(physics: const BouncingScrollPhysics(), ')

    # 3. Fix the GridView to be non-scrollable and shrinkWrapped
    content = re.sub(r'Expanded\(\s+child: GridView\.count\(', 'GridView.count(\n                shrinkWrap: true,\n                physics: const NeverScrollableScrollPhysics(),', content)
    
    # 4. Clean up any orphaned closing brackets from step 3
    # Look for the pattern: GridView.count(...), ), ),
    # and change to GridView.count(...), ),
    content = re.sub(r'GridView\.count\((.*?)\),\s+\),', r'GridView.count(\1),', content, flags=re.DOTALL)

    # 5. Add FittedBox to titles in Action Cards (handles both class names)
    # Target: Text(title, style: const TextStyle(fontWeight: FontWeight.w900, ...))
    title_pattern = r'Text\((title|t), style: const TextStyle\(fontWeight: FontWeight.w900, (.*?)\)\)'
    replacement = r'FittedBox(fit: BoxFit.scaleDown, child: Text(\1, style: const TextStyle(fontWeight: FontWeight.w900, \2)))'
    content = re.sub(title_pattern, replacement, content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

# Walk through all directories in lib
lib_path = 'lib'
for root, dirs, files in os.walk(lib_path):
    for file in files:
        if file == 'dashboard.dart':
            if root == lib_path:
                continue
            full_path = os.path.join(root, file)
            fix_dashboard(full_path)
    print(f"Fixed Module Dashboards in: {root}")
