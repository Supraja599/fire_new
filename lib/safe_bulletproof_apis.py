import os

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    target = """  List<Map<String, dynamic>> _readList(dynamic decoded) {
    if (decoded is Map && decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    return [];
  }"""

    replacement = """  List<Map<String, dynamic>> _readList(dynamic decoded) {
    if (decoded is List) return List<Map<String, dynamic>>.from(decoded);
    if (decoded is Map) {
      if (decoded["items"] is List) return List<Map<String, dynamic>>.from(decoded["items"]);
      if (decoded["data"] is List) return List<Map<String, dynamic>>.from(decoded["data"]);
      if (decoded["checklists"] is List) return List<Map<String, dynamic>>.from(decoded["checklists"]);
      if (decoded["records"] is List) return List<Map<String, dynamic>>.from(decoded["records"]);
    }
    return [];
  }"""

    # Try with LF
    if target in content:
        new_content = content.replace(target, replacement)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Safely bulletproofed _readList in: {filepath}")
        return True
    
    # Try with CRLF
    target_win = target.replace('\n', '\r\n')
    replacement_win = replacement.replace('\n', '\r\n')
    if target_win in content:
        new_content = content.replace(target_win, replacement_win)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Safely bulletproofed (CRLF) _readList in: {filepath}")
        return True

    return False

total_fixed = 0
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            path = os.path.join(root, file)
            if fix_file(path):
                total_fixed += 1

print(f"Done! Safely fixed {total_fixed} files.")
