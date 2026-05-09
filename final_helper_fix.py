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
        
        end = get_block_end(new_content, match.end() - 1 + offset)
        if end == -1: continue
        
        class_body = new_content[match.end() + offset : end - 1]
        
        # Check if it has build and helpers
        if 'Widget build(' not in class_body: continue
        
        # Find the build method
        build_match = re.search(r'Widget build\(BuildContext (context|.*?)\) \{', class_body)
        if not build_match: continue
        
        build_body_start = build_match.end()
        build_end = get_block_end(class_body, build_match.end() - 1)
        if build_end == -1: continue
        
        build_body = class_body[build_body_start : build_end - 1]
        
        # Find all helper methods in the CLASS (not inside build)
        helper_pattern = r'\n\s*(Widget|void|Future<.*?>|Color|int|double|String)\s+(_[a-zA-Z0-9_]+)\((.*?)\)\s*\{'
        helpers = []
        
        # We need to be careful not to match helpers ALREADY inside build
        # So we only search class_body OUTSIDE build_body
        pre_build = class_body[:build_match.start()]
        post_build = class_body[build_end:]
        
        def find_helpers_in_text(text):
            found = []
            while True:
                m = re.search(helper_pattern, text)
                if not m: break
                h_start = m.start()
                h_end = get_block_end(text, m.end() - 1)
                if h_end == -1: break
                found.append(text[h_start:h_end])
                text = text[:h_start] + text[h_end:]
            return found, text

        pre_helpers, pre_build = find_helpers_in_text(pre_build)
        post_helpers, post_build = find_helpers_in_text(post_build)
        helpers = pre_helpers + post_helpers

        if not helpers and 'final double width = MediaQuery.of(context).size.width;' in build_body:
            # Still might need to move width def to top
            pass
        elif not helpers:
            continue

        # Prepare new build body
        # 1. Define width at the very top
        new_build_body = "\n    final double width = MediaQuery.of(context).size.width;"
        
        # 2. Add helpers (cleaned)
        for h in helpers:
            h = h.replace('final double width = MediaQuery.of(context).size.width;', '')
            new_build_body += "\n    " + h.strip().replace('\n', '\n    ') + "\n"
            
        # 3. Add the rest of the original build body (without redundant width def)
        build_body_cleaned = build_body.replace('final double width = MediaQuery.of(context).size.width;', '')
        new_build_body += build_body_cleaned
        
        # Assemble class body
        new_class_body = pre_build + class_body[build_match.start():build_body_start] + new_build_body + "}" + post_build
        
        # Update content
        new_content = new_content[:match.end() + offset] + new_class_body + new_content[end - 1 + offset:]
        offset = len(new_content) - len(content)

    # Final cleanup of double definitions
    new_content = re.sub(r'(final double width = MediaQuery\.of\(context\)\.size\.width;\s+){2,}', 
                         r'final double width = MediaQuery.of(context).size.width;\n', new_content)

    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)

def main():
    lib_path = 'lib'
    for root, dirs, files in os.walk(lib_path):
        for file in files:
            if file.endswith('.dart'):
                fix_file(os.path.join(root, file))
    print("Final Helper Fix Completed.")

if __name__ == "__main__":
    main()
