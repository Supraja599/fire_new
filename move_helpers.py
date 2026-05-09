import os
import re

def move_helpers_inside_build(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all classes
    class_matches = list(re.finditer(r'class\s+([a-zA-Z0-9_]+)\s+(extends|with)\s+(StatelessWidget|State<.*?>)\s*\{', content))
    
    if not class_matches:
        return

    new_content = ""
    last_end = 0
    
    for i, match in enumerate(class_matches):
        class_start = match.start()
        class_name = match.group(1)
        
        # Find the end of the class (rough estimate using curly brace counting)
        brace_count = 0
        class_end = -1
        for j in range(class_start, len(content)):
            if content[j] == '{':
                brace_count += 1
            elif content[j] == '}':
                brace_count -= 1
                if brace_count == 0:
                    class_end = j + 1
                    break
        
        if class_end == -1:
            continue
            
        class_body = content[class_start:class_end]
        
        # Find the build method inside this class
        build_match = re.search(r'Widget build\(BuildContext (context|.*?)\) \{', class_body)
        if not build_match:
            continue
            
        build_start = build_match.start()
        build_body_start = build_match.end()
        
        # Find the end of the build method
        brace_count = 1
        build_end = -1
        for j in range(build_body_start, len(class_body)):
            if class_body[j] == '{':
                brace_count += 1
            elif class_body[j] == '}':
                brace_count -= 1
                if brace_count == 0:
                    build_end = j + 1
                    break
        
        if build_end == -1:
            continue

        # Find all OTHER methods in the class that are private helpers (start with _)
        # and are NOT the build method
        helpers = []
        other_parts = []
        
        # We'll search for methods like: Widget _name(...) { ... }
        # and void _name(...) { ... }
        # excluding the build method
        
        # This is a bit complex. Let's try to extract all methods.
        method_pattern = r'\n\s*(Widget|void|Future<.*?>|Color|int|double|String)\s+(_[a-zA-Z0-9_]+)\((.*?)\)\s*\{'
        
        # We'll iterate through the class body and find methods that are NOT build
        current_pos = 0
        new_class_body_pre_build = class_body[:build_body_start]
        build_body = class_body[build_body_start:build_end-1]
        new_class_body_post_build = class_body[build_end:]
        
        found_helpers = []
        def extract_helper(m):
            # Verify it's not build
            if m.group(2) == 'build': return m.group(0)
            
            # Find method end
            h_start = m.start()
            h_brace_count = 0
            h_end = -1
            for k in range(h_start, len(class_body)):
                if class_body[k] == '{':
                    h_brace_count += 1
                elif class_body[k] == '}':
                    h_brace_count -= 1
                    if h_brace_count == 0:
                        h_end = k + 1
                        break
            if h_end != -1:
                found_helpers.append(class_body[h_start:h_end])
                return "" # Remove from original place
            return m.group(0)

        # Remove helpers from pre and post build parts
        temp_pre = re.sub(method_pattern, extract_helper, new_class_body_pre_build)
        temp_post = re.sub(method_pattern, extract_helper, new_class_body_post_build)
        
        # Filter found_helpers to ensure they are actually the ones we removed
        # (re.sub might have some side effects)
        
        if found_helpers:
            # Inject helpers into the start of build_body
            # But first, ensure 'width' is defined in build_body if not already
            if 'width' in "".join(found_helpers) and 'final double width =' not in build_body:
                build_body = "\n    final double width = MediaQuery.of(context).size.width;" + build_body
            
            # Also remove the internal 'width' definitions from helpers if they are now local
            fixed_helpers = []
            for h in found_helpers:
                h_fixed = h.replace('final double width = MediaQuery.of(context).size.width;', '')
                # Ensure no 'context' getter issue if it was using it
                # In a local function, 'context' refers to the build param
                fixed_helpers.append(h_fixed)
            
            new_build_body = "\n" + "\n".join(fixed_helpers) + build_body
            
            new_class_body = temp_pre + new_build_body + "}" + temp_post
            
            # Replace the class in the original content
            content = content[:class_start] + new_class_body + content[class_end:]
            # We need to restart or adjust because indices shifted
            # But for simplicity, we'll just process one class at a time or use a better strategy
            # Let's just do one class and return
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            return True # Success

    return False

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                full_path = os.path.join(root, file)
                # Repeat until no more classes to fix in this file
                while move_helpers_inside_build(full_path):
                    pass
    print("Helper Movement Completed.")

if __name__ == "__main__":
    main()
