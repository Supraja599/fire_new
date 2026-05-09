import os
import re

def absolute_repair(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Brutal backslash removal from keywords and symbols
    # These are common corruption patterns from previous regex fails
    content = content.replace(r'\(', '(')
    content = content.replace(r'\)', ')')
    content = content.replace(r'\{', '{')
    content = content.replace(r'\}', '}')
    content = content.replace(r'\ ', ' ')
    content = content.replace(r'\:', ':')
    content = content.replace(r'\$', '$')

    # 2. Fix the width variable definition
    # Look for the build method and ensure it has width
    if 'width' in content:
        if 'Widget build(BuildContext context) {' in content:
            if 'final double width = MediaQuery.of(context).size.width;' not in content:
                content = content.replace('Widget build(BuildContext context) {', 
                                          'Widget build(BuildContext context) {\n    final double width = MediaQuery.of(context).size.width;')

        # Fix helper methods
        # Find all private methods starting with Widget or void or future
        methods = re.findall(r'(Widget|void|Future<.*?>) (_[a-zA-Z0-9]+)\((.*?)\) \{', content)
        for return_type, name, params in methods:
            search_str = f'{return_type} {name}({params}) {{'
            if 'final double width =' not in content[content.find(search_str):content.find(search_str)+200]:
                # Only add if width is actually used in the next 1000 characters or so
                # To be safe, just add it if it's a private widget helper
                if return_type == 'Widget':
                    content = content.replace(search_str, f'{search_str}\n    final double width = MediaQuery.of(context).size.width;')

    # 3. Specific fix for _showDetails in WindSockMaintenancePage
    if 'void _showDetails(Map<String, dynamic> item) {' in content:
        if 'final double width = MediaQuery.of(context).size.width;' not in content[content.find('void _showDetails'):content.find('void _showDetails')+200]:
            content = content.replace('void _showDetails(Map<String, dynamic> item) {', 
                                      'void _showDetails(Map<String, dynamic> item) {\n    final double width = MediaQuery.of(context).size.width;')

    # 4. Remove duplicate width definitions
    content = re.sub(r'(final double width = MediaQuery\.of\(context\)\.size\.width;\s+){2,}', 
                     r'final double width = MediaQuery.of(context).size.width;\n', content)

    # 5. Fix double semicolons or other syntax errors
    content = content.replace(';;', ';')

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                absolute_repair(os.path.join(root, file))
    print("Absolute Repair Completed.")

if __name__ == "__main__":
    main()
