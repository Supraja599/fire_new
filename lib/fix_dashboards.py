import os
import re

# The responsive logic to inject
RESPONSIVE_LOGIC = """                final double width = MediaQuery.of(context).size.width;
                final double textScale = MediaQuery.of(context).textScaleFactor;
                int crossAxisCount = width > 600 ? 3 : 2;
                
                double aspectRatio = 0.95;
                if (crossAxisCount == 2) {
                   aspectRatio = (0.95 / textScale).clamp(0.7, 0.95);
                } else {
                   aspectRatio = (1.05 / textScale).clamp(0.8, 1.05);
                }"""

def update_dashboard(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Update LayoutBuilder logic
    # Find LayoutBuilder(builder: (context, constraints) { ... }
    # We want to replace the logic inside until the return GridView
    
    pattern = r'LayoutBuilder\(\s*builder:\s*\(context,\s*constraints\)\s*\{[\s\S]*?return\s+GridView'
    replacement = f'LayoutBuilder(\n              builder: (context, constraints) {{\n{RESPONSIVE_LOGIC}\n                \n                return GridView'
    
    new_content = re.sub(pattern, replacement, content)
    
    # 2. Ensure childAspectRatio uses the dynamic 'aspectRatio' variable
    new_content = re.sub(r'childAspectRatio:\s*[\d\.]+', 'childAspectRatio: aspectRatio', new_content)
    # Ensure crossAxisCount uses the variable
    new_content = re.sub(r'crossAxisCount:\s*[\w\d\.\> \? \:]+', 'crossAxisCount: crossAxisCount', new_content)

    if new_content != content:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
updated_files = []

for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and ('dashboard' in file.lower() or file == 'sprinkler.dart'):
            path = os.path.join(root, file)
            if update_dashboard(path):
                updated_files.append(file)

print(f"Updated {len(updated_files)} dashboards: {', '.join(updated_files)}")
