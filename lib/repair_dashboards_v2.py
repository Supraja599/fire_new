import os
import re

RESPONSIVE_WRAPPER_START = """            LayoutBuilder(
              builder: (context, constraints) {
                final double width = MediaQuery.of(context).size.width;
                final double textScale = MediaQuery.of(context).textScaleFactor;
                int crossAxisCount = width > 600 ? 3 : 2;
                
                double aspectRatio = 0.95;
                if (crossAxisCount == 2) {
                   aspectRatio = (0.95 / textScale).clamp(0.7, 0.95);
                } else {
                   aspectRatio = (1.05 / textScale).clamp(0.8, 1.05);
                }
                
                return """

RESPONSIVE_WRAPPER_END = """              },
            ),"""

def repair_file(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # If GridView.count is NOT wrapped in LayoutBuilder, wrap it
    if 'GridView.count' in content and 'LayoutBuilder' not in content:
        # Match from GridView.count down to the end of the GridView (children: [ ... ],)
        # This is tricky with regex, but we'll target the pattern
        pattern = r'GridView\.count\([\s\S]*?children: \[[\s\S]*?\]\s*,?\s*\)'
        
        def wrapper(match):
            grid_code = match.group(0)
            # Ensure internal variables are used
            grid_code = re.sub(r'crossAxisCount:\s*[^,]+,', 'crossAxisCount: crossAxisCount,', grid_code)
            grid_code = re.sub(r'childAspectRatio:\s*[^,]+,', 'childAspectRatio: aspectRatio,', grid_code)
            return f"{RESPONSIVE_WRAPPER_START}{grid_code};\n{RESPONSIVE_WRAPPER_END}"
        
        new_content = re.sub(pattern, wrapper, content)
        
        if new_content != content:
            with open(path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            return True
            
    # Also handle cases where LayoutBuilder is there but missing definitions
    elif 'LayoutBuilder' in content:
        pattern = r'LayoutBuilder\(\s*builder:\s*\(context,\s*constraints\)\s*\{[\s\S]*?return\s+GridView'
        replacement = f'LayoutBuilder(\n              builder: (context, constraints) {{\n{RESPONSIVE_WRAPPER_START.split("return")[0]}                return GridView'
        new_content = re.sub(pattern, replacement, content)
        
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
