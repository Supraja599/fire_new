import os
import re

RESPONSIVE_BLOCK = """                final double width = MediaQuery.of(context).size.width;
                final double textScale = MediaQuery.of(context).textScaleFactor;
                int crossAxisCount = width > 600 ? 3 : 2;
                
                double aspectRatio = 0.95;
                if (crossAxisCount == 2) {
                   aspectRatio = (0.95 / textScale).clamp(0.7, 0.95);
                } else {
                   aspectRatio = (1.05 / textScale).clamp(0.8, 1.05);
                }"""

def repair_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Look for LayoutBuilder and inject definitions if missing or broken
    # We target the specific pattern where the build failed
    
    if 'LayoutBuilder' in content:
        # Replace the entire block starting from builder: (context, constraints) {
        # up to return GridView
        pattern = r'LayoutBuilder\(\s*builder:\s*\(context,\s*constraints\)\s*\{[\s\S]*?return\s+GridView'
        replacement = f'LayoutBuilder(\n              builder: (context, constraints) {{\n{RESPONSIVE_BLOCK}\n                \n                return GridView'
        new_content = re.sub(pattern, replacement, content)
        
        # 2. Ensure usage of crossAxisCount and aspectRatio in GridView
        new_content = re.sub(r'crossAxisCount:\s*[^,]+,', 'crossAxisCount: crossAxisCount,', new_content)
        new_content = re.sub(r'childAspectRatio:\s*[^,]+,', 'childAspectRatio: aspectRatio,', new_content)
        
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
            if repair_file(os.path.join(root, file)):
                fixed += 1

print(f"Repaired {fixed} dashboard files.")
