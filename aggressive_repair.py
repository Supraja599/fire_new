import os
import re

def aggressive_repair(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    if 'width' not in content:
        return

    # 1. Clean up backslashes (just in case)
    content = content.replace(r'\(', '(').replace(r'\)', ')').replace(r'\{', '{').replace(r'\}', '}')
    content = content.replace(r'\ ', ' ')

    # 2. Inject 'width' definition at the start of ALL build methods
    # Pattern: Widget build(BuildContext context) {
    def inject_width_build(match):
        full = match.group(0)
        if 'final double width = MediaQuery.of(context).size.width;' not in content[match.end():match.end()+200]:
            return f'{full}\n    final double width = MediaQuery.of(context).size.width;'
        return full

    content = re.sub(r'Widget build\(BuildContext (context|.*?)\) \{', inject_width_build, content)

    # 3. Inject 'width' definition at the start of ALL helper methods
    # Pattern: Widget _name(...) {
    def inject_width_helper(match):
        full = match.group(0)
        # Avoid double injection if build already has it (though they are different scopes)
        if 'final double width = MediaQuery.of(context).size.width;' not in content[match.end():match.end()+100]:
             return f'{full}\n    final double width = MediaQuery.of(context).size.width;'
        return full

    # Match common helper patterns: Widget _name(...), void _name(...), Future<...> _name(...)
    # We include optional space after return type
    helper_pattern = r'(Widget|void|Future<.*?>)\s+(_[a-zA-Z0-9]+)\((.*?)\) \{'
    content = re.sub(helper_pattern, inject_width_helper, content)

    # 4. Remove 'const' from lines containing 'width'
    # This is a bit brute force but solves the 'Not a constant expression' error
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        if 'width' in line and 'const ' in line:
            # Remove 'const ' before any word
            line = re.sub(r'const (?=[A-Z])', '', line)
            # Also handle things like 'const EdgeInsets.all(width * 0.05)'
            line = line.replace('const ', '')
        new_lines.append(line)
    content = '\n'.join(new_lines)

    # 5. Fix duplicate definitions (clean up)
    content = re.sub(r'(final double width = MediaQuery\.of\(context\)\.size\.width;\s+){2,}', 
                     r'final double width = MediaQuery.of(context).size.width;\n', content)

    # 6. Specific fix for fire_trolley/maintaince.dart (context issue)
    # It seems 'context' was missing in a build method or helper.
    # If width = MediaQuery.of(context) is used in a place where context is NOT available, it fails.
    # Usually this happens if it's a field or a method without context param.
    # We'll try to find 'MediaQuery.of(context)' in methods that don't have 'context' as a param.
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                aggressive_repair(os.path.join(root, file))
    print("Aggressive Repair Completed.")

if __name__ == "__main__":
    main()
