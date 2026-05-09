import os

def fix_syntax_errors(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # 1. Fix double commas
    new_content = content.replace('),,', '),')
    new_content = new_content.replace(',,', ',')
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    return False

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
fixed = 0
for root, dirs, files in os.walk(lib_dir):
    for file in files:
        if file.endswith('.dart'):
            if fix_syntax_errors(os.path.join(root, file)):
                fixed += 1

print(f"Fixed syntax in {fixed} files.")
