import os
import re

def get_block_end(content, start_pos):
    brace_count = 0
    for i in range(start_pos, len(content)):
        if content[i] == '{':
            brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
            if brace_count == 0:
                return i + 1
    return -1

def fix_file(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    # Find all classes
    class_matches = list(re.finditer(r'class\s+([a-zA-Z0-9_]+)\s+(extends|with)\s+([a-zA-Z0-9_<>\s]+)\{', content))
    
    new_content = content
    offset = 0
    
    for match in class_matches:
        start = match.start() + offset
        class_name = match.group(1)
        base_class = match.group(3).strip()
        
        end = get_block_end(new_content, match.end() - 1 + offset)
        if end == -1: continue
        
        class_body = new_content[match.end() + offset : end - 1]
        
        # Check if it has build and helpers
        if 'Widget build(' not in class_body: continue
        
        # Find helpers: Widget _name(...) { ... }
        helper_pattern = r'\n\s*(Widget|void|Future<.*?>|Color|int|double|String)\s+(_[a-zA-Z0-9_]+)\((.*?)\)\s*\{'
        helpers = []
        
        temp_body = class_body
        while True:
            m = re.search(helper_pattern, temp_body)
            if not m: break
            
            h_start = m.start()
            h_end = get_block_end(temp_body, m.end() - 1)
            if h_end == -1: break
            
            h_full = temp_body[h_start:h_end]
            if m.group(2) != 'build' and m.group(2) != 'initState' and m.group(2) != 'dispose':
                helpers.append(h_full)
                temp_body = temp_body[:h_start] + temp_body[h_end:]
            else:
                # Skip build/initState but keep them in temp_body to avoid infinite loop
                # Just mark this area as "processed" for searching
                # We'll replace the first char to not match again
                temp_body = temp_body[:h_start] + " " + temp_body[h_start+1:]
                continue

        if not helpers: continue
        
        # Remove helpers from original body
        for h in helpers:
            class_body = class_body.replace(h, '')
            
        # Find build method in the cleaned body
        build_match = re.search(r'Widget build\(BuildContext (context|.*?)\) \{', class_body)
        if not build_match: continue
        
        build_insertion_point = build_match.end()
        
        # Prepare helpers
        injected = ""
        for h in helpers:
            # Remove redundant width defs
            h = h.replace('final double width = MediaQuery.of(context).size.width;', '')
            # Clean up indentation
            h = "\n    " + h.strip().replace('\n', '\n    ') + "\n"
            injected += h
            
        # Inject width if used but not present in build
        width_def = "\n    final double width = MediaQuery.of(context).size.width;"
        if 'width' in "".join(helpers) + class_body and width_def not in class_body:
            injected = width_def + injected
            
        new_class_body = class_body[:build_insertion_point] + injected + class_body[build_insertion_point:]
        
        # Update content
        new_content = new_content[:match.end() + offset] + new_class_body + new_content[end - 1 + offset:]
        offset = len(new_content) - len(content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                fix_file(os.path.join(root, file))
    print("Safe Helper Fix Completed.")

if __name__ == "__main__":
    main()
