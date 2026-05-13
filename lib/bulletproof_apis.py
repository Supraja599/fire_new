import os
import re

def make_bulletproof_readlist(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Match the pattern of _readList(dynamic decoded) {...}
    pattern = r"(List<Map<String, dynamic>>\s+_readList\s*\(\s*dynamic\s+decoded\s*\)\s*\{)(.*?)(^\s*\})"
    
    replacement = """
    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    if (decoded is Map) {
      if (decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
      if (decoded["data"] is List) return List<Map<String, dynamic>>.from(decoded["data"]);
      if (decoded["checklists"] is List) return List<Map<String, dynamic>>.from(decoded["checklists"]);
      if (decoded["records"] is List) return List<Map<String, dynamic>>.from(decoded["records"]);
    }
    return [];"""

    def replacer(match):
        return f"{match.group(1)}{replacement}\n  }}"

    new_content, count = re.subn(pattern, replacer, content, flags=re.DOTALL | re.MULTILINE)
    
    if count > 0 and new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Bulletproofed _readList in: {filepath}")
        return True
    return False

total_fixed = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            if make_bulletproof_readlist(path):
                total_fixed += 1

print(f"Done! Bulletproofed {total_fixed} files.")
