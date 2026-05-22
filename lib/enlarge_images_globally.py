import glob
import os
import re

lib_dir = r'c:\Users\A\AndroidStudioProjects\Fire_New\lib'
dashboards = glob.glob(os.path.join(lib_dir, '**', 'dashboard.dart'), recursive=True)
dashboards.append(os.path.join(lib_dir, 'sprinklers', 'sprinkler.dart'))

count = 0
for path in dashboards:
    if not os.path.exists(path):
        continue
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    
    # 1. Enlarge action card images globally inside _ActionCard
    # Match flex: 6, followed by Center and Padding with larger numbers, and replace it
    old_flex_padding = r'Expanded\(\s*\n\s*flex:\s*6,\s*\n\s*child:\s*Center\(\s*\n\s*child:\s*Padding\(\s*\n\s*padding:\s*const\s*EdgeInsets\.only\(top:\s*16\.0,\s*left:\s*12\.0,\s*right:\s*12\.0,\s*bottom:\s*4\.0\),'
    
    # Let's perform replacement with a very robust regex that handles various whitespace
    action_card_pattern = r'Expanded\(\s*flex:\s*6,\s*child:\s*Center\(\s*child:\s*Padding\(\s*padding:\s*const\s*EdgeInsets\.only\(top:\s*16\.0,\s*left:\s*12\.0,\s*right:\s*12\.0,\s*bottom:\s*4\.0\),'
    
    # Even simpler, let's just do raw string replacement since our unify_everything script set them up IDENTICALLY!
    exact_old = """            Expanded(
              flex: 6,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16.0, left: 12.0, right: 12.0, bottom: 4.0),"""
                  
    exact_new = """            Expanded(
              flex: 7,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 8.0, right: 8.0, bottom: 2.0),"""
                  
    new_content = new_content.replace(exact_old, exact_new)
    
    # 2. Enlarge the Master Console Device Image from 115px to 130px!
    # Matches both root and sub-dashboards
    new_content = re.sub(
        r'width:\s*115\s*,(?:\s*//[^\n]*)?\s*\n(\s*)height:\s*115\s*,', 
        r'width: 130,\n\1height: 130,', 
        new_content
    )
    
    if new_content != content:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Successfully expanded image sizes in {os.path.relpath(path, lib_dir)}")
        count += 1

print(f"\nFINISHED: Enlarged images across {count} dashboard files!")
