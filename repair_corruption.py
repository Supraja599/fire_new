import os
import re

def repair_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove backslash corruption in method signatures
    # Look for signatures like 'Widget _name\(...\) \{' and fix them
    # Pattern matches 'Widget _' followed by name, then escaped chars, then '{'
    content = re.sub(r'Widget (_[a-zA-Z0-9]+)\\(.*?) \{', r'Widget \1(\2) {', content)
    # Also handle nested escapes if any
    content = content.replace(r'\(', '(').replace(r'\)', ')').replace(r'\ ', ' ')

    # 2. Fix the 'width' insertion properly
    # We want 'Widget _method(params) {' -> 'Widget _method(params) { \n final double width = ...'
    # But only if it doesn't already have it and only if it uses 'width'
    
    # First, let's find all private widget methods
    method_pattern = r'Widget (_[a-zA-Z0-9]+)\((.*?)\) \{'
    def add_width(match):
        method_name = match.group(1)
        params = match.group(2)
        full_match = match.group(0)
        
        # Check if width is already there in the next few lines
        # We'll check the whole file for 'width' usage to be safe
        if 'width' in content and 'final double width =' not in content[match.end():match.end()+100]:
             # Check if this method actually uses width (simple check)
             # This is hard without full parsing, but we can look for 'width' in the following block
             return f'Widget {method_name}({params}) {{\n    final double width = MediaQuery.of(context).size.width;'
        return full_match

    content = re.sub(method_pattern, add_width, content)

    # 3. Fix double insertions of width
    content = re.sub(r'final double width = MediaQuery\.of\(context\)\.size\.width;\s+final double width = MediaQuery\.of\(context\)\.size\.width;', 
                     r'final double width = MediaQuery.of(context).size.width;', content)

    # 4. Final cleanup of any other corruption
    # Ensure no backslashes are left in signatures
    content = re.sub(r'Widget (_[a-zA-Z0-9]+)\s*\\\((.*?)\\\)\s*\{', r'Widget \1(\2) {', content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"Repaired: {file_path}")

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                full_path = os.path.join(root, file)
                repair_file(full_path)

if __name__ == "__main__":
    main()
