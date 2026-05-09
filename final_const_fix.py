import os
import re

def final_const_fix(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'width' not in content:
        return

    # Find all 'const' keywords and check if they wrap a block containing 'width'
    # We'll use a broad approach: search for 'const WidgetName(' and remove 'const' 
    # if 'width' appears before the matching closing parenthesis.
    
    # Actually, a simpler way is to find all 'const ' that precede a word starting with uppercase
    # and remove it if 'width' is in the file. But that's too broad.
    
    # Let's target 'const ' followed by common widgets
    widgets = [
        'Expanded', 'Flexible', 'Padding', 'SizedBox', 'Container', 'Center', 
        'Align', 'Positioned', 'Stack', 'Column', 'Row', 'Wrap', 'Text', 
        'Icon', 'IconButton', 'Card', 'ListTile', 'ElevatedButton', 'TextStyle',
        'EdgeInsets', 'BorderRadius', 'BoxDecoration', 'BoxShadow'
    ]
    
    changed = False
    for widget in widgets:
        # Pattern: const Widget(...)
        # We'll search for this and if it contains 'width', remove 'const'
        # To handle nesting, we'll look for 'const Widget(' then any characters until 'width' 
        # as long as we don't hit a ';' (which usually ends a statement)
        pattern = r'const ' + widget + r'\s*\(([^;]*?width[^;]*?)\)'
        new_content = re.sub(pattern, widget + r'(\1)', content)
        if new_content != content:
            content = new_content
            changed = True

    if changed:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed const errors in: {file_path}")

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                final_const_fix(os.path.join(root, file))

if __name__ == "__main__":
    main()
