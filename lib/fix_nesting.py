import os
import re

def fix_nested_layoutbuilders(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Target the pattern of double LayoutBuilder
    # LayoutBuilder( builder: (context, constraints) { LayoutBuilder( builder: ...
    pattern = r'LayoutBuilder\(\s*builder:\s*\(context,\s*constraints\)\s*\{\s*LayoutBuilder\(\s*builder:\s*\(context,\s*constraints\)\s*\{'
    replacement = 'LayoutBuilder(\n              builder: (context, constraints) {'
    
    new_content = re.sub(pattern, replacement, content)
    
    # Also look for double closing brackets for these nested builders
    # which might look like:
    #   },
    # ),
    #   },
    # ),
    
    # This is a bit risky, let's try to find if we have one too many closing tags at the end of the block
    # Actually, if we fix the start, the extra closing tags will cause another error, so we should fix them too.
    
    if new_content != content:
        # If we replaced the start, we likely have an extra }, ), somewhere
        # We'll look for the specific sequence that closing a nested builder would create
        new_content = re.sub(r'\}\s*,\s*\)\s*;\s*\}\s*,\s*\)\s*,', '},\n            ),', new_content)
        
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
fixed = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart') and ('dashboard' in file.lower() or file == 'sprinkler.dart'):
            if fix_nested_layoutbuilders(os.path.join(root, file)):
                fixed += 1

print(f"Fixed nested LayoutBuilders in {fixed} files.")
